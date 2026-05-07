/**
 * Growth & Discovery Controller
 * Handles: waitlist, trending categories, search suggestions, similar professionals,
 *          block customer, DPDPA data export, language update, featured slots
 */

const crypto = require('crypto');
const { query } = require('../config/database');
const redis = require('../config/redis');
const emailService = require('../services/email');
const logger = require('../config/logger');

// ─── POST /waitlist ──────────────────────────────────────────────────────────
const joinWaitlist = async (req, res, next) => {
  try {
    const { email, phone, city, service_interest, source } = req.body;
    if (!city) return res.status(400).json({ success: false, message: 'city is required' });
    if (!email && !phone) return res.status(400).json({ success: false, message: 'email or phone is required' });

    // Dedup check
    if (email) {
      const dup = await query('SELECT id FROM waitlist WHERE email = $1', [email]);
      if (dup.rows.length) {
        return res.status(200).json({ success: true, message: 'You are already on the waitlist!' });
      }
    }

    await query(
      `INSERT INTO waitlist (id, email, phone, city, service_interest, source, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())`,
      [crypto.randomUUID(), email || null, phone || null, city.trim(), service_interest || null, source || 'web']
    );

    // Send confirmation email
    if (email) {
      emailService.send({
        to: email,
        subject: `SkillConnect is coming to ${city}!`,
        text: `Hi!\n\nThank you for joining the SkillConnect waitlist for ${city}. We'll notify you as soon as we launch in your city.\n\nThe SkillConnect Team`,
      }).catch(() => {});
    }

    res.status(201).json({ success: true, message: `You are on the waitlist for ${city}!` });
  } catch (err) { next(err); }
};

// ─── GET /categories/trending ────────────────────────────────────────────────
const getTrendingCategories = async (req, res, next) => {
  try {
    const city = req.query.city || 'Bangalore';
    const cacheKey = `trending_cats:${city.toLowerCase()}`;

    if (redis.isAvailable()) {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json({ success: true, data: cached });
    }

    const result = await query(
      `SELECT c.id, c.name, c.icon,
              COUNT(sh.id)::int AS search_count
       FROM categories c
       JOIN search_history sh ON sh.filters_json->>'category_id' = c.id::text
       WHERE sh.created_at >= NOW() - INTERVAL '7 days'
       GROUP BY c.id, c.name, c.icon
       ORDER BY search_count DESC
       LIMIT 8`,
      []
    ).catch(() => ({ rows: [] }));

    // If search_history is sparse, fallback to professional count per category
    let data = result.rows;
    if (data.length < 4) {
      const fallback = await query(
        `SELECT c.id, c.name, c.icon, COUNT(pc.professional_id)::int AS search_count
         FROM categories c
         JOIN professional_categories pc ON pc.category_id = c.id
         JOIN professionals p ON p.id = pc.professional_id
         JOIN users u ON u.id = p.user_id
         WHERE u.government_id_verified = TRUE
         GROUP BY c.id, c.name, c.icon
         ORDER BY search_count DESC
         LIMIT 8`
      );
      data = fallback.rows;
    }

    if (redis.isAvailable()) await redis.set(cacheKey, data, 3600); // 1h TTL

    res.json({ success: true, data });
  } catch (err) { next(err); }
};

// ─── GET /search/suggestions ─────────────────────────────────────────────────
const getSearchSuggestions = async (req, res, next) => {
  try {
    const { q = '', city = '' } = req.query;
    if (!q || q.trim().length < 2) return res.json({ success: true, data: [] });

    const prefix = q.trim().toLowerCase();
    const cacheKey = `suggestions:${prefix}:${city.toLowerCase()}`;

    if (redis.isAvailable()) {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json({ success: true, data: cached });
    }

    // 1. Popular searches from history
    const historyRes = await query(
      `SELECT DISTINCT query_text, COUNT(*) AS freq
       FROM search_history
       WHERE query_text ILIKE $1
       GROUP BY query_text
       ORDER BY freq DESC
       LIMIT 5`,
      [`${prefix}%`]
    ).catch(() => ({ rows: [] }));

    // 2. Category names matching
    const catRes = await query(
      `SELECT CONCAT('category:', id::text) AS id, name AS query_text, 'category' AS type
       FROM categories
       WHERE name ILIKE $1
       LIMIT 3`,
      [`${prefix}%`]
    ).catch(() => ({ rows: [] }));

    const suggestions = [
      ...historyRes.rows.map(r => ({ text: r.query_text, type: 'recent_search' })),
      ...catRes.rows.map(r => ({ text: r.query_text, type: 'category' })),
    ].slice(0, 5);

    if (redis.isAvailable()) await redis.set(cacheKey, suggestions, 300); // 5 min TTL

    res.json({ success: true, data: suggestions });
  } catch (err) { next(err); }
};

// ─── GET /professionals/:id/similar ─────────────────────────────────────────
const getSimilarProfessionals = async (req, res, next) => {
  try {
    const { id } = req.params;
    const cacheKey = `similar:${id}`;

    if (redis.isAvailable()) {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json({ success: true, data: cached });
    }

    // Get target professional's categories and location
    const target = await query(
      `SELECT p.latitude, p.longitude, array_agg(pc.category_id) AS cat_ids
       FROM professionals p
       JOIN professional_categories pc ON pc.professional_id = p.id
       WHERE p.id = $1
       GROUP BY p.id`,
      [id]
    );
    if (!target.rows.length) return res.status(404).json({ success: false, message: 'Professional not found' });

    const { latitude, longitude, cat_ids } = target.rows[0];

    const result = await query(
      `SELECT p.id, u.name, u.avatar_url, p.avg_rating, p.trust_index,
              p.subscription_plan, p.headline,
              (SELECT c.name FROM categories c
               JOIN professional_categories pc2 ON pc2.category_id = c.id
               WHERE pc2.professional_id = p.id LIMIT 1) AS primary_category
       FROM professionals p
       JOIN users u ON u.id = p.user_id
       JOIN professional_categories pc ON pc.professional_id = p.id
       WHERE pc.category_id = ANY($1::int[])
         AND p.id != $2
         AND u.government_id_verified = TRUE
         AND p.is_available = TRUE
       GROUP BY p.id, u.name, u.avatar_url, p.avg_rating, p.trust_index, p.subscription_plan, p.headline
       ORDER BY p.trust_index DESC NULLS LAST, p.avg_rating DESC NULLS LAST
       LIMIT 5`,
      [cat_ids, id]
    );

    if (redis.isAvailable()) await redis.set(cacheKey, result.rows, 900); // 15 min TTL

    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
};

// ─── POST /professionals/block-customer/:userId ──────────────────────────────
const blockCustomer = async (req, res, next) => {
  try {
    const proUserId = req.user.id;
    const { userId: blockedUserId } = req.params;
    const { reason } = req.body;

    // Get professional id from user_id
    const prof = await query('SELECT id FROM professionals WHERE user_id = $1', [proUserId]);
    if (!prof.rows.length) return res.status(403).json({ success: false, message: 'Professional profile required' });

    // Verify the user to block exists
    const target = await query('SELECT id FROM users WHERE id = $1', [blockedUserId]);
    if (!target.rows.length) return res.status(404).json({ success: false, message: 'User not found' });

    await query(
      `INSERT INTO blocked_users (id, blocker_id, blocked_id, reason, created_at)
       VALUES ($1, $2, $3, $4, NOW())
       ON CONFLICT (blocker_id, blocked_id) DO UPDATE SET reason = EXCLUDED.reason`,
      [crypto.randomUUID(), proUserId, blockedUserId, reason || null]
    );

    res.json({ success: true, message: 'User blocked successfully.' });
  } catch (err) { next(err); }
};

// ─── PUT /users/language ─────────────────────────────────────────────────────
const updateLanguage = async (req, res, next) => {
  try {
    const { language } = req.body;
    const SUPPORTED_LANGS = ['en', 'hi', 'te', 'ta', 'kn', 'ml', 'mr', 'bn', 'gu', 'pa'];
    if (!SUPPORTED_LANGS.includes(language)) {
      return res.status(400).json({ success: false, message: `Unsupported language. Supported: ${SUPPORTED_LANGS.join(', ')}` });
    }
    await query('UPDATE users SET preferred_language = $1 WHERE id = $2', [language, req.user.id]);
    res.json({ success: true, message: 'Language preference updated.' });
  } catch (err) { next(err); }
};

// ─── GET /professionals/export-data ─────────────────────────────────────────
// DPDPA 2023 §11 — Data Principal right to access own data
const exportData = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const [userRes, profRes, contactsRes, reviewsRes, bookingsRes] = await Promise.all([
      query(`SELECT id, name, email, phone, role, location, created_at, preferred_language, timezone FROM users WHERE id = $1`, [userId]),
      query(`SELECT * FROM professionals WHERE user_id = $1`, [userId]),
      query(`SELECT * FROM contacts WHERE customer_id = $1 ORDER BY created_at DESC LIMIT 200`, [userId]),
      query(`SELECT id, rating, comment, created_at FROM reviews WHERE customer_id = $1 ORDER BY created_at DESC`, [userId]),
      query(`SELECT id, title, status, created_at, scheduled_at FROM bookings WHERE customer_id = $1 ORDER BY created_at DESC LIMIT 200`, [userId]).catch(() => ({ rows: [] })),
    ]);

    // Log the export in audit_log
    await query(
      `INSERT INTO audit_log (id, user_id, action, details, ip_address, created_at)
       VALUES ($1, $2, 'data_export', '{"type":"dpdpa_export"}'::jsonb, $3, NOW())`,
      [crypto.randomUUID(), userId, req.ip || null]
    ).catch(() => {});

    const exportPayload = {
      exported_at: new Date().toISOString(),
      user: userRes.rows[0] || null,
      professional_profile: profRes.rows[0] || null,
      contacts: contactsRes.rows,
      reviews: reviewsRes.rows,
      bookings: bookingsRes.rows,
    };

    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename="skillconnect-data-${userId}.json"`);
    res.json(exportPayload);
  } catch (err) { next(err); }
};

// ─── DELETE /users/account ───────────────────────────────────────────────────
// DPDPA 2023 §12 — Right to erasure (30-day soft delete)
const deleteAccount = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { reason } = req.body;

    // Soft delete: set deleted_at, anonymise PII
    await query(
      `UPDATE users SET
         deleted_at = NOW(),
         name = 'Deleted User',
         email = CONCAT('deleted_', id, '@deleted.local'),
         phone = NULL,
         avatar_url = NULL,
         is_active = FALSE
       WHERE id = $1`,
      [userId]
    );

    // Hide professional profile
    await query(
      `UPDATE professionals SET is_available = FALSE WHERE user_id = $1`,
      [userId]
    ).catch(() => {});

    // Log soft delete
    await query(
      `INSERT INTO soft_deletes_log (id, entity_type, entity_id, deleted_by, reason, deleted_at, can_restore)
       VALUES ($1, 'user', $2, $2, $3, NOW(), TRUE)`,
      [crypto.randomUUID(), userId, reason || 'User requested account deletion']
    ).catch(() => {});

    res.json({ success: true, message: 'Your account has been scheduled for deletion. Data will be permanently removed within 30 days.' });
  } catch (err) { next(err); }
};

// ─── GET /supported-cities ───────────────────────────────────────────────────
const getSupportedCities = async (req, res, next) => {
  try {
    const result = await query(
      'SELECT id, name, state, is_active FROM supported_cities ORDER BY name ASC'
    ).catch(() => ({ rows: [] }));
    res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
};

// ─── GET /professionals/profile-completeness ─────────────────────────────────
const getProfileCompleteness = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const prof = await query(
      `SELECT p.id, p.headline, p.bio, p.latitude, p.cover_image_url,
              u.avatar_url, u.government_id_verified,
              (SELECT COUNT(*) FROM portfolio_items pi WHERE pi.professional_id = p.id) AS portfolio_count,
              (SELECT COUNT(*) FROM certifications cert WHERE cert.professional_id = p.id) AS cert_count,
              (SELECT COUNT(*) FROM professional_categories pc WHERE pc.professional_id = p.id) AS cat_count
       FROM professionals p
       JOIN users u ON u.id = p.user_id
       WHERE p.user_id = $1`,
      [userId]
    );
    if (!prof.rows.length) return res.status(404).json({ success: false, message: 'Professional profile not found' });

    const p = prof.rows[0];
    const items = [
      { key: 'headline', label: 'Add a headline', done: !!(p.headline && p.headline.trim()), points: 10 },
      { key: 'bio', label: 'Write your bio', done: !!(p.bio && p.bio.trim()), points: 10 },
      { key: 'location', label: 'Set your location', done: !!p.latitude, points: 10 },
      { key: 'cover_image', label: 'Add a cover image', done: !!p.cover_image_url, points: 5 },
      { key: 'avatar', label: 'Upload a profile photo', done: !!p.avatar_url, points: 5 },
      { key: 'verification', label: 'Complete KYC verification', done: !!p.government_id_verified, points: 20 },
      { key: 'portfolio', label: 'Add at least 3 portfolio items', done: parseInt(p.portfolio_count) >= 3, points: 20 },
      { key: 'certifications', label: 'Add a certification', done: parseInt(p.cert_count) > 0, points: 10 },
      { key: 'categories', label: 'Select service categories', done: parseInt(p.cat_count) > 0, points: 10 },
    ];

    const completeness = items.reduce((sum, item) => sum + (item.done ? item.points : 0), 0);

    res.json({
      success: true,
      data: {
        professional_id: p.id,
        completeness_pct: completeness,
        items,
        boost_unlocked: completeness >= 60,
      },
    });
  } catch (err) { next(err); }
};

// ─── GET /users/recently-viewed ──────────────────────────────────────────────
const getRecentlyViewed = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const cacheKey = `recently_viewed:${userId}`;

    let ids = [];
    if (redis.isAvailable()) {
      ids = (await redis.get(cacheKey)) || [];
    }

    if (!ids.length) return res.json({ success: true, data: [] });

    // Fetch profiles for the IDs
    const placeholders = ids.map((_, i) => `$${i + 1}`).join(',');
    const result = await query(
      `SELECT p.id, u.name, u.avatar_url, p.avg_rating, p.trust_index,
              p.subscription_plan, p.headline,
              (SELECT c.name FROM categories c
               JOIN professional_categories pc ON pc.category_id = c.id
               WHERE pc.professional_id = p.id LIMIT 1) AS primary_category
       FROM professionals p
       JOIN users u ON u.id = p.user_id
       WHERE p.id IN (${placeholders}) AND u.is_active = TRUE`,
      ids
    );

    // Preserve the order from Redis list
    const profMap = Object.fromEntries(result.rows.map(r => [r.id, r]));
    const ordered = ids.map(id => profMap[id]).filter(Boolean);

    res.json({ success: true, data: ordered });
  } catch (err) { next(err); }
};

// Middleware called by professional GET endpoint to track recently viewed
const trackRecentlyViewed = async (userId, professionalId) => {
  try {
    if (!redis.isAvailable() || !userId || !professionalId) return;
    const key = `recently_viewed:${userId}`;
    let ids = (await redis.get(key)) || [];
    ids = [professionalId, ...ids.filter(id => id !== professionalId)].slice(0, 10);
    await redis.set(key, ids, 30 * 24 * 3600); // 30 days TTL
  } catch (_) {}
};

module.exports = {
  joinWaitlist,
  getTrendingCategories,
  getSearchSuggestions,
  getSimilarProfessionals,
  blockCustomer,
  updateLanguage,
  exportData,
  deleteAccount,
  getSupportedCities,
  getProfileCompleteness,
  getRecentlyViewed,
  trackRecentlyViewed,
};
