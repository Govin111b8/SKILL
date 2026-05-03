/**
 * Growth Routes — Newsletter subscriptions, waitlist, lead capture
 */
const express = require('express');
const router = express.Router();
const { pool } = require('../config/database');
const logger = require('../config/logger');
const { body, validationResult } = require('express-validator');

/**
 * POST /api/growth/subscribe
 * Newsletter/waitlist subscription
 */
router.post('/subscribe',
  body('email').isEmail().normalizeEmail(),
  body('source').optional().isString().trim(),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: 'Please provide a valid email address' });
    }

    const { email, source } = req.body;

    try {
      // Upsert — don't error if already subscribed
      await pool.query(
        `INSERT INTO newsletter_subscribers (email, source, subscribed_at)
         VALUES ($1, $2, NOW())
         ON CONFLICT (email) DO UPDATE SET source = COALESCE($2, newsletter_subscribers.source)`,
        [email, source || 'website_footer']
      );

      logger.info({ email, source }, 'New newsletter subscription');
      res.json({ success: true, message: 'Successfully subscribed! Watch your inbox.' });
    } catch (err) {
      logger.error({ err, email }, 'Newsletter subscribe failed');
      res.status(500).json({ error: 'Something went wrong. Please try again.' });
    }
  }
);

/**
 * POST /api/growth/waitlist
 * Professional waitlist for new cities/categories
 */
router.post('/waitlist',
  body('email').isEmail().normalizeEmail(),
  body('name').optional().isString().trim(),
  body('phone').optional().isMobilePhone(),
  body('city').optional().isString().trim(),
  body('category').optional().isString().trim(),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: 'Please provide a valid email address' });
    }

    const { email, name, phone, city, category } = req.body;

    try {
      await pool.query(
        `INSERT INTO waitlist (email, name, phone, city, category, created_at)
         VALUES ($1, $2, $3, $4, $5, NOW())
         ON CONFLICT (email) DO UPDATE SET 
           name = COALESCE($2, waitlist.name),
           city = COALESCE($4, waitlist.city)`,
        [email, name, phone, city, category]
      );

      logger.info({ email, city, category }, 'New waitlist entry');
      res.json({ success: true, message: "You're on the list! We'll notify you when we launch in your area." });
    } catch (err) {
      logger.error({ err, email }, 'Waitlist signup failed');
      res.status(500).json({ error: 'Something went wrong. Please try again.' });
    }
  }
);

/**
 * POST /api/growth/track-event
 * Simple analytics event tracking for growth metrics
 */
router.post('/track-event',
  body('event').isString().trim().notEmpty(),
  body('properties').optional().isObject(),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: 'Invalid event data' });
    }

    const { event, properties } = req.body;
    const userId = req.user?.id || null;

    try {
      await pool.query(
        `INSERT INTO growth_events (user_id, event_name, properties, created_at)
         VALUES ($1, $2, $3, NOW())`,
        [userId, event, JSON.stringify(properties || {})]
      );
      res.json({ success: true });
    } catch (err) {
      // Non-critical — don't fail the response
      logger.warn({ err, event }, 'Growth event tracking failed');
      res.json({ success: true });
    }
  }
);

module.exports = router;
