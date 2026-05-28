const { Router } = require('express');
const { authenticate, requireRole } = require('../middleware/auth');
const {
  listAmcPlans,
  getAmcPlan,
  subscribeAmcPlan,
  listMyAmcSubscriptions,
  cancelAmcSubscription,
  createAmcPlan,
  listBundlePackages,
} = require('../controllers/amcController');

const router = Router();

// Public: list plans and bundles
router.get('/plans', listAmcPlans);
router.get('/plans/:id', getAmcPlan);
router.get('/bundles', listBundlePackages);

// Authenticated: subscribe / manage
router.post('/subscribe', authenticate, subscribeAmcPlan);
router.get('/my-subscriptions', authenticate, listMyAmcSubscriptions);
router.delete('/my-subscriptions/:id', authenticate, cancelAmcSubscription);

// Admin: create plans
router.post('/plans', authenticate, requireRole('admin'), createAmcPlan);

module.exports = router;
