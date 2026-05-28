const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const { query } = require('../config/database');
const { getProfile, updateProfile, changePassword, deleteAccount } = require('../controllers/userController');

const router = Router();

router.get('/profile', authenticate, getProfile);

router.put('/profile', authenticate,
  validate([
    body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
    body('phone').optional().trim().notEmpty().withMessage('Phone cannot be empty'),
  ]),
  updateProfile
);

router.put('/change-password', authenticate,
  validate([
    body('current_password').notEmpty().withMessage('Current password is required'),
    body('new_password').isLength({ min: 6 }).withMessage('New password must be at least 6 characters'),
  ]),
  changePassword
);

router.delete('/account', authenticate, deleteAccount);

// ── Push Token Management (FCM) ───────────────────────────────────────────────

router.post('/me/push-token', authenticate,
  validate([
    body('token').notEmpty().withMessage('Token required'),
    body('platform').optional().isIn(['android', 'ios', 'web']).withMessage('Invalid platform'),
    body('language').optional().isLength({ min: 2, max: 10 }).withMessage('Invalid language code'),
  ]),
  async (req, res, next) => {
    try {
      const { token, platform = 'android', language = 'en' } = req.body;

      await query(
        `INSERT INTO device_push_tokens (user_id, token, platform, language, updated_at)
         VALUES ($1, $2, $3, $4, NOW())
         ON CONFLICT (token) DO UPDATE
         SET user_id = $1, platform = COALESCE($3, device_push_tokens.platform),
             language = COALESCE($4, device_push_tokens.language), updated_at = NOW()`,
        [req.user.id, token, platform, language]
      );

      res.json({ success: true });
    } catch (err) {
      next(err);
    }
  }
);

router.post('/me/push-token/remove', authenticate,
  validate([body('token').notEmpty().withMessage('Token required')]),
  async (req, res, next) => {
    try {
      const { token } = req.body;
      await query(
        'DELETE FROM device_push_tokens WHERE token = $1 AND user_id = $2',
        [token, req.user.id]
      );
      res.json({ success: true });
    } catch (err) {
      next(err);
    }
  }
);

// ── Notification Preferences ──────────────────────────────────────────────────

const VALID_CATEGORIES = ['behavioral', 'lifecycle', 'promotional']; // transactional always enabled

router.put('/notification-preferences', authenticate, async (req, res, next) => {
  try {
    const updates = [];
    for (const category of VALID_CATEGORIES) {
      if (typeof req.body[category] === 'boolean') {
        updates.push(
          query(
            `INSERT INTO user_notification_preferences (user_id, category, enabled, updated_at)
             VALUES ($1, $2, $3, NOW())
             ON CONFLICT (user_id, category) DO UPDATE SET enabled = $3, updated_at = NOW()`,
            [req.user.id, category, req.body[category]]
          )
        );
      }
    }
    await Promise.all(updates);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

const VALID_LANGUAGES = ['en', 'hi', 'te', 'ta', 'kn', 'ml', 'mr', 'gu', 'bn'];

router.put('/notification-language', authenticate,
  validate([
    body('language').isIn(VALID_LANGUAGES).withMessage('Invalid language code'),
  ]),
  async (req, res, next) => {
    try {
      await query(
        'UPDATE device_push_tokens SET language = $1, updated_at = NOW() WHERE user_id = $2',
        [req.body.language, req.user.id]
      );
      res.json({ success: true });
    } catch (err) {
      next(err);
    }
  }
);

module.exports = router;
