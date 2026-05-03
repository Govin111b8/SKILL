const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const { body } = require('express-validator');
const {
  becomeAgent,
  getAgentDashboard,
  onboardProvider,
  onboardCustomer,
  unlockReward,
  getWallet,
  getRewardConfig,
  getLeaderboard,
  getZones
} = require('../controllers/agentController');

const router = Router();

// Public routes
router.get('/rewards-info', getRewardConfig);
router.get('/zones', getZones);
router.get('/leaderboard', getLeaderboard);

// Authenticated routes
router.use(authenticate);

router.post('/register', [
  body('zone').optional().isString()
], becomeAgent);

router.get('/dashboard', getAgentDashboard);
router.get('/wallet', getWallet);

router.post('/onboard/provider', [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('phone').trim().notEmpty().withMessage('Phone is required'),
  body('location').optional().isString()
], onboardProvider);

router.post('/onboard/customer', [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('phone').trim().notEmpty().withMessage('Phone is required'),
  body('location').optional().isString()
], onboardCustomer);

// Admin-only reward unlock
router.post('/rewards/:reward_id/unlock', unlockReward);

module.exports = router;
