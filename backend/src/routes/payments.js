const { Router } = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const { createPayment, verifyPayment, releaseEscrow, confirmCOD, refundPayment, getPayments, getEarnings } = require('../controllers/paymentController');
const { pool } = require('../config/database');
const storage = require('../services/storage');
const logger = require('../config/logger');

const router = Router();

router.use(authenticate);

/**
 * @swagger
 * /payments:
 *   post:
 *     summary: Create a payment for a booking or order
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               booking_id:
 *                 type: string
 *               method:
 *                 type: string
 *               amount:
 *                 type: number
 *     responses:
 *       201:
 *         description: Payment created successfully
 *       400:
 *         description: Invalid payment request
 *       401:
 *         description: Unauthorized
 */
router.post('/', createPayment);
/**
 * @swagger
 * /payments/{payment_id}/verify:
 *   post:
 *     summary: Verify a payment transaction
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: payment_id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               razorpay_payment_id:
 *                 type: string
 *               razorpay_signature:
 *                 type: string
 *     responses:
 *       200:
 *         description: Payment verified successfully
 *       400:
 *         description: Verification failed
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Payment not found
 */
router.post('/:payment_id/verify', verifyPayment);
/**
 * @swagger
 * /payments:
 *   get:
 *     summary: List payments for the current user
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Payments retrieved successfully
 *       401:
 *         description: Unauthorized
 */
router.get('/', getPayments);
/**
 * @swagger
 * /payments/earnings:
 *   get:
 *     summary: Get earnings summary for the current professional
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Earnings retrieved successfully
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 */
router.get('/earnings', getEarnings);
/**
 * @swagger
 * /payments/{payment_id}/release:
 *   post:
 *     summary: Release escrow funds for a payment
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: payment_id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Escrow released successfully
 *       400:
 *         description: Payment cannot be released
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Payment not found
 */
router.post('/:payment_id/release', releaseEscrow);
/**
 * @swagger
 * /payments/{payment_id}/cod-confirm:
 *   post:
 *     summary: Confirm a cash on delivery payment
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: payment_id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Cash on delivery payment confirmed
 *       400:
 *         description: Invalid COD confirmation
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Payment not found
 */
router.post('/:payment_id/cod-confirm', confirmCOD);
/**
 * @swagger
 * /payments/{payment_id}/refund:
 *   post:
 *     summary: Refund a payment
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: payment_id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: Payment refunded successfully
 *       400:
 *         description: Refund failed
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Payment not found
 */
router.post('/:payment_id/refund', refundPayment);

// My Invoices — professional can download their GST invoices
router.get('/invoices', authorize('professional'), async (req, res, next) => {
  try {
    const proRow = await pool.query('SELECT id FROM professionals WHERE user_id = $1', [req.user.id]);
    if (!proRow.rows.length) return res.status(404).json({ success: false, message: 'Professional profile not found' });

    const invoices = await pool.query(
      `SELECT gi.*, s.plan, s.start_date, s.end_date
       FROM gst_invoices gi
       JOIN subscriptions s ON s.id = gi.subscription_id
       WHERE gi.professional_id = $1
       ORDER BY gi.issued_at DESC`,
      [proRow.rows[0].id]
    );

    // Generate signed URLs for PDF files
    const data = await Promise.all(invoices.rows.map(async (inv) => {
      let downloadUrl = inv.pdf_url;
      if (inv.pdf_url && inv.pdf_url.startsWith('/')) {
        downloadUrl = inv.pdf_url; // local path — served as static
      } else if (inv.pdf_url) {
        try {
          // Generate 15-min signed URL for S3 objects
          const key = inv.pdf_url.split('/invoices/')[1];
          if (key) downloadUrl = await storage.getSignedUrl(`invoices/${key}`, 900);
        } catch (err) { logger.warn({ err: err.message }, 'Failed to generate signed URL for invoice'); }
      }
      return { ...inv, download_url: downloadUrl };
    }));

    res.json({ success: true, data });
  } catch (err) { next(err); }
});

// Download a single invoice (with signed URL)
router.get('/invoices/:id', authorize('professional'), async (req, res, next) => {
  try {
    const proRow = await pool.query('SELECT id FROM professionals WHERE user_id = $1', [req.user.id]);
    if (!proRow.rows.length) return res.status(404).json({ success: false, message: 'Professional profile not found' });

    const inv = await pool.query(
      `SELECT gi.*, s.plan FROM gst_invoices gi JOIN subscriptions s ON s.id = gi.subscription_id
       WHERE gi.id = $1 AND gi.professional_id = $2`,
      [req.params.id, proRow.rows[0].id]
    );
    if (!inv.rows.length) return res.status(404).json({ success: false, message: 'Invoice not found' });

    let downloadUrl = inv.rows[0].pdf_url;
    try {
      const key = inv.rows[0].pdf_url?.split('/invoices/')[1];
      if (key) downloadUrl = await storage.getSignedUrl(`invoices/${key}`, 900);
    } catch (err) { logger.warn({ err: err.message, invoiceId: req.params.id }, 'Failed to generate signed URL for invoice'); }

    res.json({ success: true, data: { ...inv.rows[0], download_url: downloadUrl } });
  } catch (err) { next(err); }
});

module.exports = router;
