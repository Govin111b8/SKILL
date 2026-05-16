/**
 * Webhook Routes — External service callbacks
 * Handles Razorpay payment webhooks with GST invoice generation
 */

const express = require('express');
const router = express.Router();
const { pool } = require('../config/database');
const logger = require('../config/logger');
const razorpay = require('../services/razorpay');
const gstInvoice = require('../services/gstInvoice');
const emailService = require('../services/email');

// Razorpay sends raw body — we need to capture it before JSON parsing
router.post('/razorpay', express.raw({ type: 'application/json' }), async (req, res) => {
  try {
    const signature = req.headers['x-razorpay-signature'];
    const rawBody = req.body.toString();

    // Verify webhook signature
    if (!razorpay.verifyWebhookSignature(rawBody, signature)) {
      logger.warn('Invalid Razorpay webhook signature');
      return res.status(400).json({ error: 'Invalid signature' });
    }

    const event = JSON.parse(rawBody);
    const { event: eventName, payload } = event;

    logger.info({ eventName }, 'Razorpay webhook received');

    switch (eventName) {
      case 'payment.captured': {
        const payment = payload.payment.entity;
        const orderId = payment.order_id;
        const notes = payment.notes || {};

        // Find our payment record by the razorpay order ID stored in metadata
        const result = await pool.query(
          `UPDATE payments SET status = 'held_in_escrow',
           transaction_ref = $2, metadata = metadata || $3::jsonb, updated_at = NOW()
           WHERE metadata->>'razorpay_order_id' = $1 AND status = 'pending'
           RETURNING *`,
          [orderId, payment.id, JSON.stringify({ razorpay_payment_id: payment.id, captured_at: new Date().toISOString() })]
        );

        if (result.rows.length > 0) {
          const paymentRecord = result.rows[0];
          logger.info({ paymentId: paymentRecord.id, razorpayId: payment.id }, 'Payment captured via webhook');

          // Update booking status (for booking payments)
          if (paymentRecord.booking_id) {
            await pool.query(
              `UPDATE bookings SET status = 'accepted', updated_at = NOW() WHERE id = $1 AND status = 'quoted'`,
              [paymentRecord.booking_id]
            );
          }

          // ── Subscription activation (when notes.subscription_plan is set) ──
          const subscriptionPlan = notes.subscription_plan || paymentRecord.metadata?.subscription_plan;
          const professionalId = notes.professional_id || paymentRecord.metadata?.professional_id;
          // billing_cycle: 'monthly' | 'annual' — annual gets 33% discount, 12 months duration
          const billingCycle = notes.billing_cycle || paymentRecord.metadata?.billing_cycle || 'monthly';

          if (subscriptionPlan && professionalId) {
            const durationMonths = billingCycle === 'annual' ? 12 : 1;
            const endDate = new Date();
            endDate.setMonth(endDate.getMonth() + durationMonths);
            const graceEnd = new Date(endDate);
            graceEnd.setDate(graceEnd.getDate() + 3);

            // Upsert subscription record
            const subResult = await pool.query(
              `INSERT INTO subscriptions (professional_id, plan, amount_paid, payment_id, razorpay_order_id,
                 start_date, end_date, grace_period_end, status)
               VALUES ($1, $2::subscription_plan, $3, $4, $5, NOW(), $6, $7, 'active')
               ON CONFLICT DO NOTHING
               RETURNING id`,
              [professionalId, subscriptionPlan, payment.amount / 100, payment.id, orderId, endDate, graceEnd]
            ).catch((err) => { logger.error({ err, professionalId }, 'Failed to insert subscription record — will retry on next webhook'); return { rows: [] }; });

            // Update professional's subscription tier
            await pool.query(
              `UPDATE professionals SET
                 subscription_plan = $1::subscription_plan,
                 subscription_expires_at = $2,
                 updated_at = NOW()
               WHERE id = $3`,
              [subscriptionPlan, endDate, professionalId]
            );

            // Payout log (audit trail)
            await pool.query(
              `INSERT INTO payout_log (professional_id, subscription_id, amount, gateway_ref, status)
               VALUES ($1, $2, $3, $4, 'completed')`,
              [professionalId, subResult.rows[0]?.id || null, payment.amount / 100, payment.id]
            ).catch((err) => logger.error({ err, professionalId }, 'Failed to insert payout log record'));

            // ── Generate GST invoice ──────────────────────────────────
            try {
              const proRow = await pool.query(
                `SELECT p.gstin, u.name, u.email, u.location FROM professionals p JOIN users u ON u.id = p.user_id WHERE p.id = $1`,
                [professionalId]
              );
              if (proRow.rows.length > 0) {
                const pro = proRow.rows[0];
                const baseAmount = (payment.amount / 100) / (1 + 0.18); // extract base from gross
                const invoice = await gstInvoice.createInvoice({
                  professionalId,
                  subscriptionId: subResult.rows[0]?.id || null,
                  plan: subscriptionPlan,
                  baseAmount: Math.round(baseAmount * 100) / 100,
                  customerName: pro.name,
                  customerEmail: pro.email,
                  customerGstin: pro.gstin || null,
                  customerState: pro.location || 'India',
                  customerStateCode: '',
                });

                // Save invoice record
                if (subResult.rows[0]?.id) {
                  await pool.query(
                    `INSERT INTO gst_invoices (subscription_id, professional_id, invoice_number, invoice_type,
                       gstin, amount, cgst, sgst, igst, total, pdf_url)
                     VALUES ($1, $2, $3, $4::invoice_type, $5, $6, $7, $8, $9, $10, $11)`,
                    [subResult.rows[0].id, professionalId, invoice.invoiceNumber, invoice.invoiceType,
                     pro.gstin || null, baseAmount, invoice.cgst, invoice.sgst, invoice.igst,
                     invoice.total, invoice.pdfUrl]
                  ).catch((err) => logger.error({ err, professionalId }, 'Failed to save GST invoice record'));
                }

                // Email invoice to professional
                await emailService.sendEmail({
                  to: pro.email,
                  subject: `SkillConnect Invoice ${invoice.invoiceNumber}`,
                  text: `Hi ${pro.name},\n\nThank you for subscribing to SkillConnect ${subscriptionPlan} plan!\n\nInvoice Number: ${invoice.invoiceNumber}\nAmount: ₹${invoice.total}\n\nDownload your invoice: ${invoice.pdfUrl}\n\nThe SkillConnect Team`,
                }).catch((err) => logger.error({ err, professionalId }, 'Failed to email GST invoice to professional'));

                logger.info({ invoiceNumber: invoice.invoiceNumber, professionalId }, 'GST invoice created and emailed');
              }
            } catch (invoiceErr) {
              logger.error({ err: invoiceErr }, 'GST invoice generation failed (non-fatal)');
            }
          }
        }
        break;
      }

      case 'payment.failed': {
        const payment = payload.payment.entity;
        const orderId = payment.order_id;

        await pool.query(
          `UPDATE payments SET status = 'failed', metadata = metadata || $2::jsonb, updated_at = NOW()
           WHERE metadata->>'razorpay_order_id' = $1 AND status = 'pending'`,
          [orderId, JSON.stringify({ failure_reason: payment.error_description, failed_at: new Date().toISOString() })]
        );
        break;
      }

      case 'refund.processed': {
        const refund = payload.refund.entity;
        const paymentId = refund.payment_id;

        await pool.query(
          `UPDATE payments SET status = 'refunded',
           metadata = metadata || $2::jsonb, updated_at = NOW()
           WHERE transaction_ref = $1`,
          [paymentId, JSON.stringify({ refund_id: refund.id, refunded_at: new Date().toISOString() })]
        );
        break;
      }

      default:
        logger.info({ eventName }, 'Unhandled webhook event');
    }

    res.json({ status: 'ok' });
  } catch (err) {
    logger.error({ err }, 'Webhook processing error');
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});

module.exports = router;
