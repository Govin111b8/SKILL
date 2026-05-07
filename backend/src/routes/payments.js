const { Router } = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const { createPayment, verifyPayment, releaseEscrow, refundPayment, getPayments, getEarnings } = require('../controllers/paymentController');
const { pool } = require('../config/database');
const storage = require('../services/storage');

const router = Router();

router.use(authenticate);

router.post('/', createPayment);
router.post('/:payment_id/verify', verifyPayment);
router.get('/', getPayments);
router.get('/earnings', getEarnings);
router.post('/:payment_id/release', releaseEscrow);
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
        } catch (_) {}
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
    } catch (_) {}

    res.json({ success: true, data: { ...inv.rows[0], download_url: downloadUrl } });
  } catch (err) { next(err); }
});

module.exports = router;
