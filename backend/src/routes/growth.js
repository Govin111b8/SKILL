/**
 * Growth Routes — Waitlist, trending categories, search suggestions,
 *                 similar professionals, block customer, language,
 *                 DPDPA data export, account deletion, recently viewed
 */
const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const { authenticate, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');
const growth = require('../controllers/growthController');
const logger = require('../config/logger');

// ── Public ────────────────────────────────────────────────────────────────
router.get('/supported-cities', growth.getSupportedCities);
router.get('/categories/trending', growth.getTrendingCategories);
router.get('/search/suggestions', growth.getSearchSuggestions);
router.get('/professionals/:id/similar', growth.getSimilarProfessionals);

router.post('/waitlist',
  validate([
    body('city').trim().notEmpty().withMessage('city is required'),
    body('email').optional({ nullable: true }).isEmail().withMessage('Valid email required'),
    body('phone').optional({ nullable: true }).isMobilePhone().withMessage('Valid phone required'),
  ]),
  growth.joinWaitlist
);

// Legacy newsletter subscribe (keep backward compat)
router.post('/subscribe', async (req, res) => {
  const { email, source } = req.body;
  if (!email) return res.status(400).json({ error: 'Email required' });
  // Reuse waitlist
  req.body = { email, city: 'Unknown', source };
  return growth.joinWaitlist(req, res, (err) => {
    if (err) return res.status(500).json({ error: 'Failed' });
  });
});

// ── Authenticated ─────────────────────────────────────────────────────────

// Profile completeness (professionals only)
router.get('/professionals/profile-completeness', authenticate, authorize('professional'), growth.getProfileCompleteness);

// Block a customer (professionals only)
router.post('/professionals/block-customer/:userId', authenticate, authorize('professional'), growth.blockCustomer);

// Language preference (any user)
router.put('/users/language', authenticate,
  validate([body('language').trim().notEmpty()]),
  growth.updateLanguage
);

// Recently viewed professionals (customers)
router.get('/users/recently-viewed', authenticate, growth.getRecentlyViewed);

// DPDPA data export
router.get('/professionals/export-data', authenticate, growth.exportData);
router.get('/users/export-data', authenticate, growth.exportData);

// Account deletion (soft delete, 30 days)
router.delete('/users/account', authenticate,
  validate([body('reason').optional().isString()]),
  growth.deleteAccount
);

module.exports = router;

