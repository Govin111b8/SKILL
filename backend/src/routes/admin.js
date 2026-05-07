/**
 * Admin Routes — Platform administration
 * All routes require authentication + admin role
 */

const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const admin = require('../controllers/adminController');
const crypto = require('crypto');
const { query } = require('../config/database');

// Admin middleware — check is_admin flag
function requireAdmin(req, res, next) {
  if (!req.user || !req.user.is_admin) {
    return res.status(403).json({ success: false, message: 'Admin access required' });
  }
  next();
}

// All admin routes require auth + admin
router.use(authenticate, requireAdmin);

// Dashboard & Analytics
router.get('/dashboard', admin.getDashboard);
router.get('/analytics', admin.getAnalytics);

// User Management
router.get('/users', admin.listUsers);
router.get('/users/:id', admin.getUser);
router.post('/users/:id/ban', admin.banUser);
router.post('/users/:id/unban', admin.unbanUser);

// KYC Management
router.get('/kyc', admin.getKYCQueue);
router.post('/kyc/:id/approve', admin.approveKYC);
router.post('/kyc/:id/reject', admin.rejectKYC);

// Dispute Management
router.get('/disputes', admin.listDisputes);
router.post('/disputes/:id/resolve', admin.resolveDispute);

// Category Management
router.post('/categories', admin.createCategory);
router.put('/categories/:id', admin.updateCategory);
router.delete('/categories/:id', admin.deleteCategory);

// Complaint Management
router.get('/complaints', admin.listComplaints);
router.post('/complaints/:id/resolve', admin.resolveComplaint);

// Audit Log
router.get('/audit-log', admin.getAuditLog);

// ── Category Requests ─────────────────────────────────────────────────────
router.get('/category-requests', async (req, res, next) => {
  try {
    const result = await query(
      `SELECT cr.*, u.name AS requester_name, u.email AS requester_email
       FROM category_requests cr
       JOIN users u ON u.id = cr.user_id
       ORDER BY cr.created_at DESC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

router.put('/category-requests/:id',
  validate([
    body('status').isIn(['approved', 'rejected']).withMessage('status must be approved or rejected'),
    body('admin_note').optional().isString(),
  ]),
  async (req, res, next) => {
    try {
      const { status, admin_note } = req.body;
      const result = await query(
        `UPDATE category_requests
         SET status = $1, admin_note = $2, reviewed_by = $3, reviewed_at = NOW()
         WHERE id = $4 RETURNING *`,
        [status, admin_note || null, req.user.id, req.params.id]
      );
      if (!result.rows.length) return res.status(404).json({ success: false, message: 'Request not found' });
      res.json({ success: true, data: result.rows[0] });
    } catch (err) { next(err); }
  }
);

// ── Featured Slots ────────────────────────────────────────────────────────
router.get('/featured-slots', async (req, res, next) => {
  try {
    const result = await query(
      `SELECT fs.*, u.name AS professional_name
       FROM featured_slots fs
       JOIN professionals p ON p.id = fs.professional_id
       JOIN users u ON u.id = p.user_id
       ORDER BY fs.start_date DESC`
    ).catch(() => ({ rows: [] }));
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

router.put('/featured-slots',
  validate([
    body('professional_id').trim().notEmpty(),
    body('slot_type').isIn(['home', 'category', 'search']),
    body('start_date').isDate(),
    body('end_date').isDate(),
  ]),
  async (req, res, next) => {
    try {
      const { professional_id, slot_type, city, category_id, start_date, end_date } = req.body;
      const result = await query(
        `INSERT INTO featured_slots (id, professional_id, slot_type, city, category_id, start_date, end_date, status, created_by, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'active', $8, NOW(), NOW())
         ON CONFLICT DO NOTHING
         RETURNING *`,
        [crypto.randomUUID(), professional_id, slot_type, city || null, category_id || null, start_date, end_date, req.user.id]
      ).catch(() => ({ rows: [] }));
      res.json({ success: true, data: result.rows[0] });
    } catch (err) { next(err); }
  }
);

router.delete('/featured-slots/:id', async (req, res, next) => {
  try {
    await query(`UPDATE featured_slots SET status = 'cancelled' WHERE id = $1`, [req.params.id]);
    res.json({ success: true, message: 'Featured slot cancelled' });
  } catch (err) { next(err); }
});

// ── Appeals ───────────────────────────────────────────────────────────────
router.get('/appeals', async (req, res, next) => {
  try {
    const result = await query(
      `SELECT a.*, u.name AS appellant_name, u.email AS appellant_email
       FROM appeals a
       JOIN users u ON u.id = a.user_id
       ORDER BY a.created_at DESC`
    ).catch(() => ({ rows: [] }));
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

router.put('/appeals/:id',
  validate([
    body('status').isIn(['approved', 'rejected']).withMessage('status must be approved or rejected'),
    body('review_note').optional().isString(),
  ]),
  async (req, res, next) => {
    try {
      const { status, review_note } = req.body;
      const result = await query(
        `UPDATE appeals SET status = $1, review_note = $2, reviewed_by = $3, reviewed_at = NOW()
         WHERE id = $4 RETURNING *`,
        [status, review_note || null, req.user.id, req.params.id]
      );
      if (!result.rows.length) return res.status(404).json({ success: false, message: 'Appeal not found' });
      res.json({ success: true, data: result.rows[0] });
    } catch (err) { next(err); }
  }
);

// ── Waitlist Management ───────────────────────────────────────────────────
router.get('/waitlist', async (req, res, next) => {
  try {
    const { city } = req.query;
    const result = await query(
      `SELECT * FROM waitlist ${city ? 'WHERE city ILIKE $1' : ''} ORDER BY created_at DESC`,
      city ? [`%${city}%`] : []
    ).catch(() => ({ rows: [] }));
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

// ── A/B Experiments ───────────────────────────────────────────────────────
router.get('/ab-experiments', async (req, res, next) => {
  try {
    const result = await query(`SELECT * FROM ab_experiments ORDER BY created_at DESC`).catch(() => ({ rows: [] }));
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

// Cache Stats (monitoring)
const { getCacheStats } = require('../middleware/cache');
router.get('/cache-stats', (req, res) => {
  res.json({ success: true, data: getCacheStats() });
});

// Queue Stats (monitoring)
const { getQueueStats } = require('../services/jobQueue');
router.get('/queue-stats', (req, res) => {
  res.json({ success: true, data: getQueueStats() });
});

// System Health
router.get('/health', (req, res) => {
  res.json({
    success: true,
    data: {
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      cache: getCacheStats(),
      queues: getQueueStats(),
    }
  });
});

module.exports = router;

