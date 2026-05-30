const router = require('express').Router();
const { authenticate, authorize } = require('../middleware/auth');
const c = require('../controllers/kycController');

// User self-service
router.get('/me', authenticate, c.listMine);
router.get('/allowed-types', authenticate, c.allowedTypes);
router.post('/submit', authenticate, c.submit);
router.post('/aadhaar/initiate', authenticate, c.initiateAadhaarOtp);
router.post('/aadhaar/verify', authenticate, c.verifyAadhaarOtp);
router.delete('/:id', authenticate, c.remove);

// Public (any authenticated user can read another user's non-PII summary)
router.get('/users/:userId/summary', c.publicSummary);

// Admin moderation
router.put('/:id/review', authenticate, authorize('admin'), c.adminReview);

module.exports = router;
