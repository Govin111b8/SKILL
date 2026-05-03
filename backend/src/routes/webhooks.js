/**
 * Webhook Routes — External service callbacks
 * Handles Razorpay payment webhooks
 */

const express = require('express');
const router = express.Router();
const { pool } = require('../config/database');
const logger = require('../config/logger');
const razorpay = require('../services/razorpay');

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

        // Find our payment record by the razorpay order ID stored in metadata
        const result = await pool.query(
          `UPDATE payments SET status = 'held_in_escrow', 
           transaction_ref = $2, metadata = metadata || $3::jsonb, updated_at = NOW()
           WHERE metadata->>'razorpay_order_id' = $1 AND status = 'pending'
           RETURNING *`,
          [orderId, payment.id, JSON.stringify({ razorpay_payment_id: payment.id, captured_at: new Date().toISOString() })]
        );

        if (result.rows.length > 0) {
          logger.info({ paymentId: result.rows[0].id, razorpayId: payment.id }, 'Payment captured via webhook');

          // Update booking status
          await pool.query(
            `UPDATE bookings SET status = 'accepted', updated_at = NOW() WHERE id = $1 AND status = 'quoted'`,
            [result.rows[0].booking_id]
          );
        }
        break;
      }

      case 'payment.failed': {
        const payment = payload.payment.entity;
        const orderId = payment.order_id;

        await pool.query(
          `UPDATE payments SET status = 'failed', metadata = metadata || $2::jsonb, updated_at = NOW()
           WHERE metadata->>'razorpay_order_id' = $1 AND status = 'pending'`,
          [orderId, JSON.stringify({ failure_reason: payment.error_description })]
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
