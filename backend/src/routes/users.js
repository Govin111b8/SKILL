const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const { query } = require('../config/database');
const { getProfile, updateProfile, changePassword, deleteAccount } = require('../controllers/userController');

const router = Router();

/**
 * @swagger
 * /users/profile:
 *   get:
 *     summary: Get current user profile
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User profile data
 *       401:
 *         description: Unauthorized
 */
router.get('/profile', authenticate, getProfile);

/**
 * @swagger
 * /users/profile:
 *   put:
 *     summary: Update current user profile
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               phone:
 *                 type: string
 *     responses:
 *       200:
 *         description: Profile updated successfully
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 */
router.put('/profile', authenticate,
  validate([
    body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
    body('phone').optional().trim().notEmpty().withMessage('Phone cannot be empty'),
  ]),
  updateProfile
);

/**
 * @swagger
 * /users/change-password:
 *   put:
 *     summary: Change current user password
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [current_password, new_password]
 *             properties:
 *               current_password:
 *                 type: string
 *               new_password:
 *                 type: string
 *                 minLength: 6
 *     responses:
 *       200:
 *         description: Password changed successfully
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 */
router.put('/change-password', authenticate,
  validate([
    body('current_password').notEmpty().withMessage('Current password is required'),
    body('new_password').isLength({ min: 6 }).withMessage('New password must be at least 6 characters'),
  ]),
  changePassword
);

/**
 * @swagger
 * /users/account:
 *   delete:
 *     summary: Delete current user account
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Account deleted successfully
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Account not found
 */
router.delete('/account', authenticate, deleteAccount);

// Push token management (FCM)
router.post('/me/push-token', authenticate, async (req, res) => {
  try {
    const { token, platform, language } = req.body;
    if (!token) return res.status(400).json({ error: 'Token required' });

    const validPlatforms = ['android', 'ios', 'web'];
    if (platform && !validPlatforms.includes(platform)) {
      return res.status(400).json({ error: 'Invalid platform' });
    }

    await query(
      `INSERT INTO device_push_tokens (user_id, token, platform, language, updated_at)
       VALUES ($1, $2, $3, $4, NOW())
       ON CONFLICT (token) DO UPDATE
       SET user_id = $1, platform = COALESCE($3, platform), language = COALESCE($4, language), updated_at = NOW()`,
      [req.user.id, token, platform || 'android', language || 'en']
    );

    res.json({ success: true });
  } catch (err) {
    console.error('push-token register error:', err);
    res.status(500).json({ error: 'Failed to register push token' });
  }
});

router.post('/me/push-token/remove', authenticate, async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) return res.status(400).json({ error: 'Token required' });

    await query(
      `DELETE FROM device_push_tokens WHERE token = $1 AND user_id = $2`,
      [token, req.user.id]
    );

    res.json({ success: true });
  } catch (err) {
    console.error('push-token remove error:', err);
    res.status(500).json({ error: 'Failed to remove push token' });
  }
});

// Notification preferences
router.put('/notification-preferences', authenticate, async (req, res) => {
  try {
    const { transactional, behavioral, lifecycle, promotional } = req.body;
    const categories = { transactional, behavioral, lifecycle, promotional };

    for (const [category, enabled] of Object.entries(categories)) {
      if (typeof enabled !== 'boolean') continue;
      if (category === 'transactional') continue;

      await query(
        `INSERT INTO user_notification_preferences (user_id, category, enabled, updated_at)
         VALUES ($1, $2, $3, NOW())
         ON CONFLICT (user_id, category) DO UPDATE SET enabled = $3, updated_at = NOW()`,
        [req.user.id, category, enabled]
      );
    }

    res.json({ success: true });
  } catch (err) {
    console.error('notification preferences error:', err);
    res.status(500).json({ error: 'Failed to update preferences' });
  }
});

router.put('/notification-language', authenticate, async (req, res) => {
  try {
    const { language } = req.body;
    const validLanguages = ['en', 'hi', 'te', 'ta', 'kn', 'ml', 'mr', 'gu', 'bn'];
    if (!validLanguages.includes(language)) {
      return res.status(400).json({ error: 'Invalid language code' });
    }

    await query(
      `UPDATE device_push_tokens SET language = $1, updated_at = NOW() WHERE user_id = $2`,
      [language, req.user.id]
    );

    res.json({ success: true });
  } catch (err) {
    console.error('notification language error:', err);
    res.status(500).json({ error: 'Failed to update notification language' });
  }
});

module.exports = router;
