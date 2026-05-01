/**
 * Admin Routes — Platform administration
 * All routes require authentication + admin role
 */

const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const admin = require('../controllers/adminController');

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
