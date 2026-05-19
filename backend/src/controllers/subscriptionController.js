const { query } = require('../config/database');
const logger = require('../config/logger');

// ============================================================
// SUBSCRIPTION ENGINE CONTROLLER
// Manages recurring household services (daily/weekly/monthly)
// ============================================================

/**
 * Create a new service subscription
 */
exports.create = async (req, res, next) => {
  try {
    if (req.user.role !== 'customer') {
      return res.status(403).json({ success: false, message: 'Only customers can create subscriptions' });
    }

    const {
      professional_id, category_id, service_id, title, description,
      frequency, preferred_days, preferred_time_start, preferred_time_end,
      price_per_occurrence, currency, auto_renew, service_address,
      service_lat, service_lng, household_id, notes, start_date
    } = req.body;

    if (!title || !frequency || !price_per_occurrence) {
      return res.status(400).json({
        success: false,
        message: 'title, frequency, and price_per_occurrence are required'
      });
    }

    const validFrequencies = ['daily', 'weekly', 'biweekly', 'monthly', 'quarterly'];
    if (!validFrequencies.includes(frequency)) {
      return res.status(400).json({
        success: false,
        message: `frequency must be one of: ${validFrequencies.join(', ')}`
      });
    }

    if (price_per_occurrence <= 0 || price_per_occurrence > 1000000) {
      return res.status(400).json({
        success: false,
        message: 'price_per_occurrence must be between 1 and 10,00,000'
      });
    }

    // Calculate next occurrence
    const nextOccurrence = start_date || new Date().toISOString().split('T')[0];

    const result = await query(
      `INSERT INTO service_subscriptions 
       (customer_id, professional_id, category_id, service_id, title, description,
        frequency, preferred_days, preferred_time_start, preferred_time_end,
        price_per_occurrence, currency, auto_renew, service_address,
        service_lat, service_lng, household_id, notes, next_occurrence, country_code)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
       RETURNING *`,
      [
        req.user.id, professional_id || null, category_id || null, service_id || null,
        title, description || null, frequency, preferred_days || [],
        preferred_time_start || null, preferred_time_end || null,
        price_per_occurrence, currency || 'INR', auto_renew !== false,
        service_address || null, service_lat || null, service_lng || null,
        household_id || null, notes || null, nextOccurrence, req.user.country_code || 'IN'
      ]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * List subscriptions for the current user
 */
exports.list = async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 20));
    const offset = (page - 1) * limit;
    const status = req.query.status || null;

    let whereClause = 'WHERE s.customer_id = $1';
    const params = [req.user.id];
    let paramIdx = 2;

    if (status) {
      whereClause += ` AND s.status = $${paramIdx}`;
      params.push(status);
      paramIdx++;
    }

    params.push(limit, offset);

    const result = await query(
      `SELECT s.*, 
              c.name as category_name,
              u.name as professional_name
       FROM service_subscriptions s
       LEFT JOIN categories c ON s.category_id = c.id
       LEFT JOIN professionals p ON s.professional_id = p.id
       LEFT JOIN users u ON p.user_id = u.id
       ${whereClause}
       ORDER BY s.created_at DESC
       LIMIT $${paramIdx} OFFSET $${paramIdx + 1}`,
      params
    );

    const countResult = await query(
      `SELECT COUNT(*) FROM service_subscriptions s ${whereClause}`,
      params.slice(0, paramIdx - 1)
    );

    const total = parseInt(countResult.rows[0]?.count || '0', 10);

    res.json({
      success: true,
      data: result.rows,
      pagination: { page, limit, total, total_pages: Math.ceil(total / limit) }
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Get subscription details
 */
exports.getById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      `SELECT s.*, 
              c.name as category_name,
              u.name as professional_name,
              u.phone as professional_phone
       FROM service_subscriptions s
       LEFT JOIN categories c ON s.category_id = c.id
       LEFT JOIN professionals p ON s.professional_id = p.id
       LEFT JOIN users u ON p.user_id = u.id
       WHERE s.id = $1 AND s.customer_id = $2`,
      [id, req.user.id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Subscription not found' });
    }

    // Get recent occurrences
    const occurrences = await query(
      `SELECT * FROM subscription_occurrences 
       WHERE subscription_id = $1 
       ORDER BY scheduled_date DESC LIMIT 10`,
      [id]
    );

    res.json({
      success: true,
      data: { ...result.rows[0], recent_occurrences: occurrences.rows }
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Pause a subscription
 */
exports.pause = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason, resume_date } = req.body;

    const result = await query(
      `UPDATE service_subscriptions 
       SET status = 'paused', pause_reason = $1, paused_at = NOW(), resume_date = $2, updated_at = NOW()
       WHERE id = $3 AND customer_id = $4 AND status = 'active'
       RETURNING *`,
      [reason || null, resume_date || null, id, req.user.id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Active subscription not found' });
    }

    res.json({ success: true, data: result.rows[0], message: 'Subscription paused' });
  } catch (err) {
    next(err);
  }
};

/**
 * Resume a paused subscription
 */
exports.resume = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await query(
      `UPDATE service_subscriptions 
       SET status = 'active', pause_reason = NULL, paused_at = NULL, resume_date = NULL, 
           next_occurrence = CURRENT_DATE, updated_at = NOW()
       WHERE id = $1 AND customer_id = $2 AND status = 'paused'
       RETURNING *`,
      [id, req.user.id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Paused subscription not found' });
    }

    res.json({ success: true, data: result.rows[0], message: 'Subscription resumed' });
  } catch (err) {
    next(err);
  }
};

/**
 * Cancel a subscription
 */
exports.cancel = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    const result = await query(
      `UPDATE service_subscriptions 
       SET status = 'cancelled', cancelled_at = NOW(), pause_reason = $1, updated_at = NOW()
       WHERE id = $2 AND customer_id = $3 AND status IN ('active', 'paused')
       RETURNING *`,
      [reason || 'User cancelled', id, req.user.id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Subscription not found or already cancelled' });
    }

    res.json({ success: true, data: result.rows[0], message: 'Subscription cancelled' });
  } catch (err) {
    next(err);
  }
};

/**
 * Update subscription preferences
 */
exports.update = async (req, res, next) => {
  try {
    const { id } = req.params;
    const {
      preferred_days, preferred_time_start, preferred_time_end,
      service_address, notes, auto_renew, professional_id
    } = req.body;

    const result = await query(
      `UPDATE service_subscriptions 
       SET preferred_days = COALESCE($1, preferred_days),
           preferred_time_start = COALESCE($2, preferred_time_start),
           preferred_time_end = COALESCE($3, preferred_time_end),
           service_address = COALESCE($4, service_address),
           notes = COALESCE($5, notes),
           auto_renew = COALESCE($6, auto_renew),
           professional_id = COALESCE($7, professional_id),
           updated_at = NOW()
       WHERE id = $8 AND customer_id = $9 AND status != 'cancelled'
       RETURNING *`,
      [
        preferred_days || null, preferred_time_start || null,
        preferred_time_end || null, service_address || null,
        notes || null, auto_renew, professional_id || null,
        id, req.user.id
      ]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Subscription not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * Get subscription categories (subscription-eligible)
 */
exports.getCategories = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT id, name, description, icon, parent_id 
       FROM categories 
       WHERE is_subscription_eligible = TRUE OR engine = 'subscription'
       ORDER BY name`
    );

    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
};

/**
 * Record a subscription occurrence (professional marks service delivered)
 */
exports.recordOccurrence = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { notes, rating } = req.body;

    // Verify subscription exists
    const sub = await query(
      `SELECT * FROM service_subscriptions WHERE id = $1 AND status = 'active'`,
      [id]
    );

    if (!sub.rows[0]) {
      return res.status(404).json({ success: false, message: 'Active subscription not found' });
    }

    // Create occurrence record
    const occurrence = await query(
      `INSERT INTO subscription_occurrences 
       (subscription_id, scheduled_date, actual_date, actual_time, status, professional_id, notes, rating, completed_at)
       VALUES ($1, CURRENT_DATE, CURRENT_DATE, CURRENT_TIME, 'completed', $2, $3, $4, NOW())
       RETURNING *`,
      [id, sub.rows[0].professional_id, notes || null, rating || null]
    );

    // Update subscription stats
    await query(
      `UPDATE service_subscriptions 
       SET occurrences_completed = occurrences_completed + 1, 
           last_occurrence = CURRENT_DATE,
           updated_at = NOW()
       WHERE id = $1`,
      [id]
    );

    res.status(201).json({ success: true, data: occurrence.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * Provider: List subscriptions assigned to me
 */
exports.listProviderSubscriptions = async (req, res, next) => {
  try {
    // Get professional profile
    const pro = await query(
      `SELECT id FROM professionals WHERE user_id = $1`,
      [req.user.id]
    );

    if (!pro.rows[0]) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 20));
    const offset = (page - 1) * limit;

    const result = await query(
      `SELECT s.*, u.name as customer_name, u.phone as customer_phone, c.name as category_name
       FROM service_subscriptions s
       JOIN users u ON s.customer_id = u.id
       LEFT JOIN categories c ON s.category_id = c.id
       WHERE s.professional_id = $1 AND s.status IN ('active', 'paused')
       ORDER BY s.next_occurrence ASC
       LIMIT $2 OFFSET $3`,
      [pro.rows[0].id, limit, offset]
    );

    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
};
