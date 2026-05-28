const router = require('express').Router();
const { authenticate, authorize } = require('../middleware/auth');
const c = require('../controllers/gamificationController');

// ── Customer points ────────────────────────────────────────────────────────────
router.get('/points', authenticate, c.getMyPoints);
router.post('/points/redeem', authenticate, c.redeemPoints);
router.get('/leaderboard', authenticate, c.getCustomerLeaderboard);

// ── Professional stats & leaderboard ─────────────────────────────────────────
router.get('/professional/stats', authenticate, c.getProfessionalStats);
router.get('/professional/leaderboard', c.getProfessionalLeaderboard);

module.exports = router;
