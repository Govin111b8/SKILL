const { query } = require('../config/database');

// =====================================================
// SAVED SEARCHES WITH ALERTS
// =====================================================

exports.saveSearch = async (req, res, next) => {
  try {
    const { name, query: searchQuery, filters, alert_enabled, alert_frequency } = req.body;

    if (!searchQuery && !filters) {
      return res.status(400).json({ success: false, message: 'query or filters required' });
    }

    const r = await query(
      `INSERT INTO saved_searches (user_id, name, query, filters, alert_enabled, alert_frequency)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [req.user.id, name || searchQuery || 'Unnamed Search', searchQuery || '',
       JSON.stringify(filters || {}), alert_enabled || false, alert_frequency || 'daily']
    );

    res.status(201).json({ success: true, data: r.rows[0] });
  } catch (e) { next(e); }
};

exports.listSavedSearches = async (req, res, next) => {
  try {
    const r = await query(
      `SELECT * FROM saved_searches WHERE user_id = $1 ORDER BY created_at DESC`,
      [req.user.id]
    );
    res.json({ success: true, data: r.rows });
  } catch (e) { next(e); }
};

exports.updateSavedSearch = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, alert_enabled, alert_frequency } = req.body;

    const updates = [];
    const params = [id, req.user.id];
    let idx = 3;

    if (name !== undefined) { updates.push(`name = $${idx++}`); params.push(name); }
    if (alert_enabled !== undefined) { updates.push(`alert_enabled = $${idx++}`); params.push(alert_enabled); }
    if (alert_frequency) { updates.push(`alert_frequency = $${idx++}`); params.push(alert_frequency); }
    updates.push('updated_at = NOW()');

    const r = await query(
      `UPDATE saved_searches SET ${updates.join(', ')} WHERE id = $1 AND user_id = $2 RETURNING *`,
      params
    );

    if (!r.rows.length) {
      return res.status(404).json({ success: false, message: 'Saved search not found' });
    }
    res.json({ success: true, data: r.rows[0] });
  } catch (e) { next(e); }
};

exports.deleteSavedSearch = async (req, res, next) => {
  try {
    const { id } = req.params;
    const r = await query(
      'DELETE FROM saved_searches WHERE id = $1 AND user_id = $2 RETURNING id',
      [id, req.user.id]
    );
    if (!r.rows.length) {
      return res.status(404).json({ success: false, message: 'Saved search not found' });
    }
    res.json({ success: true, message: 'Deleted' });
  } catch (e) { next(e); }
};

// =====================================================
// PROFESSIONAL COMPARISON
// =====================================================

exports.compareProfessionals = async (req, res, next) => {
  try {
    const { ids } = req.query;
    if (!ids) {
      return res.status(400).json({ success: false, message: 'ids query param required (comma-separated)' });
    }

    const professionalIds = ids.split(',').slice(0, 5); // Max 5 at a time

    // Validate each id is a valid UUID
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const invalidIds = professionalIds.filter(id => !uuidRegex.test(id.trim()));
    if (invalidIds.length > 0) {
      return res.status(400).json({ success: false, message: 'Invalid professional id(s) — must be UUIDs' });
    }

    const r = await query(
      `SELECT p.id, p.provider_type, p.company_name, p.team_size, p.experience_years,
              p.pricing_estimate, p.availability_status, p.total_bookings, p.repeat_client_rate,
              p.response_time_hours, p.completion_rate,
              u.name, u.avatar_url, u.city,
              COALESCE(AVG(r.rating), 0) AS average_rating,
              COUNT(DISTINCT r.id) AS review_count,
              ARRAY_AGG(DISTINCT c.name) FILTER (WHERE c.name IS NOT NULL) AS categories,
              ARRAY_AGG(DISTINCT ps.service_name) FILTER (WHERE ps.service_name IS NOT NULL) AS services
       FROM professionals p
       JOIN users u ON p.user_id = u.id
       LEFT JOIN reviews r ON r.professional_id = p.id
       LEFT JOIN professional_categories pc ON pc.professional_id = p.id
       LEFT JOIN categories c ON pc.category_id = c.id
       LEFT JOIN professional_services ps ON ps.professional_id = p.id
       WHERE p.id = ANY($1::uuid[])
       GROUP BY p.id, u.name, u.avatar_url, u.city`,
      [professionalIds]
    );

    // Track comparison session
    if (req.user) {
      await query(
        `INSERT INTO comparison_sessions (user_id, professional_ids) VALUES ($1, $2)`,
        [req.user.id, professionalIds]
      ).catch(() => {}); // Non-critical
    }

    res.json({ success: true, data: r.rows });
  } catch (e) { next(e); }
};

// =====================================================
// PAYMENT HISTORY & INVOICES
// =====================================================

exports.getPaymentHistory = async (req, res, next) => {
  try {
    const pageNum = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
    const { from, to, status } = req.query;
    const offset = (pageNum - 1) * limitNum;
    const params = [req.user.id];
    let where = '(pm.payer_id = $1 OR pm.payee_id = $1)';
    let idx = 2;

    if (from) { where += ` AND pm.created_at >= $${idx++}`; params.push(from); }
    if (to) { where += ` AND pm.created_at <= $${idx++}`; params.push(to); }
    if (status) { where += ` AND pm.status = $${idx++}`; params.push(status); }

    // Capture count params before appending LIMIT/OFFSET
    const countParams = [...params];

    params.push(limitNum);
    params.push(offset);

    const r = await query(
      `SELECT pm.*, b.title AS booking_title, u.name AS other_party_name
       FROM payments pm
       LEFT JOIN bookings b ON pm.booking_id = b.id
       LEFT JOIN users u ON (CASE WHEN pm.payer_id = $1 THEN pm.payee_id ELSE pm.payer_id END) = u.id
       WHERE ${where}
       ORDER BY pm.created_at DESC
       LIMIT $${idx++} OFFSET $${idx}`,
      params
    );

    const countR = await query(
      `SELECT COUNT(*) FROM payments pm WHERE ${where}`,
      countParams
    );

    res.json({
      success: true,
      data: r.rows,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total: parseInt(countR.rows[0].count),
        total_pages: Math.ceil(parseInt(countR.rows[0].count) / limitNum)
      }
    });
  } catch (e) { next(e); }
};

// =====================================================
// PROMOTIONAL BANNERS
// =====================================================

exports.getActiveBanners = async (req, res, next) => {
  try {
    const now = new Date().toISOString();
    const r = await query(
      `SELECT * FROM promotional_banners
       WHERE is_active = true
         AND (starts_at IS NULL OR starts_at <= $1)
         AND (ends_at IS NULL OR ends_at >= $1)
       ORDER BY position ASC, created_at DESC
       LIMIT 10`,
      [now]
    );
    res.json({ success: true, data: r.rows });
  } catch (e) { next(e); }
};

exports.createBanner = async (req, res, next) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Admin only' });
    }

    const { title, subtitle, image_url, link_url, cta_text, position, starts_at, ends_at, target_roles } = req.body;
    if (!title) {
      return res.status(400).json({ success: false, message: 'title is required' });
    }

    const r = await query(
      `INSERT INTO promotional_banners (title, subtitle, image_url, link_url, cta_text, position, starts_at, ends_at, target_roles, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
      [title, subtitle || null, image_url || null, link_url || null, cta_text || null,
       position || 0, starts_at || null, ends_at || null, target_roles || ['customer'], req.user.id]
    );
    res.status(201).json({ success: true, data: r.rows[0] });
  } catch (e) { next(e); }
};

// =====================================================
// QUICK REPLY TEMPLATES
// =====================================================

exports.getQuickReplies = async (req, res, next) => {
  try {
    const r = await query(
      'SELECT * FROM quick_replies WHERE user_id = $1 ORDER BY usage_count DESC, created_at DESC',
      [req.user.id]
    );
    res.json({ success: true, data: r.rows });
  } catch (e) { next(e); }
};

exports.createQuickReply = async (req, res, next) => {
  try {
    const { title, content, shortcut } = req.body;
    if (!title || !content) {
      return res.status(400).json({ success: false, message: 'title and content required' });
    }

    const r = await query(
      `INSERT INTO quick_replies (user_id, title, content, shortcut) VALUES ($1,$2,$3,$4) RETURNING *`,
      [req.user.id, title, content, shortcut || null]
    );
    res.status(201).json({ success: true, data: r.rows[0] });
  } catch (e) { next(e); }
};

exports.deleteQuickReply = async (req, res, next) => {
  try {
    const { id } = req.params;
    const r = await query('DELETE FROM quick_replies WHERE id = $1 AND user_id = $2 RETURNING id', [id, req.user.id]);
    if (!r.rows.length) {
      return res.status(404).json({ success: false, message: 'Quick reply not found' });
    }
    res.json({ success: true, message: 'Deleted' });
  } catch (e) { next(e); }
};

// =====================================================
// PROFESSIONAL GOALS
// =====================================================

exports.getGoals = async (req, res, next) => {
  try {
    const pro = await query('SELECT id FROM professionals WHERE user_id = $1', [req.user.id]);
    if (!pro.rows.length) return res.json({ success: true, data: [] });

    const r = await query(
      `SELECT * FROM professional_goals WHERE professional_id = $1 ORDER BY created_at DESC`,
      [pro.rows[0].id]
    );
    res.json({ success: true, data: r.rows });
  } catch (e) { next(e); }
};

exports.createGoal = async (req, res, next) => {
  try {
    const { goal_type, target_value, period, start_date, end_date } = req.body;
    if (!goal_type || !target_value || !period || !start_date || !end_date) {
      return res.status(400).json({ success: false, message: 'All goal fields required' });
    }

    const pro = await query('SELECT id FROM professionals WHERE user_id = $1', [req.user.id]);
    if (!pro.rows.length) {
      return res.status(403).json({ success: false, message: 'Professional profile required' });
    }

    const r = await query(
      `INSERT INTO professional_goals (professional_id, goal_type, target_value, period, start_date, end_date)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [pro.rows[0].id, goal_type, target_value, period, start_date, end_date]
    );
    res.status(201).json({ success: true, data: r.rows[0] });
  } catch (e) { next(e); }
};

exports.updateGoal = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { current_value, status } = req.body;

    const pro = await query('SELECT id FROM professionals WHERE user_id = $1', [req.user.id]);
    if (!pro.rows.length) return res.status(403).json({ success: false, message: 'Not a professional' });

    const updates = [];
    const params = [id, pro.rows[0].id];
    let idx = 3;

    if (current_value !== undefined) { updates.push(`current_value = $${idx++}`); params.push(current_value); }
    if (status) { updates.push(`status = $${idx++}`); params.push(status); }

    if (!updates.length) return res.status(400).json({ success: false, message: 'Nothing to update' });

    const r = await query(
      `UPDATE professional_goals SET ${updates.join(', ')} WHERE id = $1 AND professional_id = $2 RETURNING *`,
      params
    );
    res.json({ success: true, data: r.rows[0] });
  } catch (e) { next(e); }
};

// =====================================================
// USER ADDRESSES
// =====================================================

exports.getAddresses = async (req, res, next) => {
  try {
    const r = await query(
      'SELECT * FROM user_addresses WHERE user_id = $1 ORDER BY is_default DESC, created_at DESC',
      [req.user.id]
    );
    res.json({ success: true, data: r.rows });
  } catch (e) { next(e); }
};

exports.createAddress = async (req, res, next) => {
  try {
    const { label, address_line1, address_line2, city, state, pincode, lat, lng, is_default } = req.body;
    if (!address_line1) {
      return res.status(400).json({ success: false, message: 'address_line1 is required' });
    }

    // If setting as default, unset others
    if (is_default) {
      await query('UPDATE user_addresses SET is_default = false WHERE user_id = $1', [req.user.id]);
    }

    const r = await query(
      `INSERT INTO user_addresses (user_id, label, address_line1, address_line2, city, state, pincode, lat, lng, is_default)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
      [req.user.id, label || 'Home', address_line1, address_line2 || null,
       city || null, state || null, pincode || null, lat || null, lng || null, is_default || false]
    );
    res.status(201).json({ success: true, data: r.rows[0] });
  } catch (e) { next(e); }
};

exports.updateAddress = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { label, address_line1, address_line2, city, state, pincode, lat, lng, is_default } = req.body;

    if (is_default) {
      await query('UPDATE user_addresses SET is_default = false WHERE user_id = $1', [req.user.id]);
    }

    const r = await query(
      `UPDATE user_addresses SET
        label = COALESCE($3, label), address_line1 = COALESCE($4, address_line1),
        address_line2 = COALESCE($5, address_line2), city = COALESCE($6, city),
        state = COALESCE($7, state), pincode = COALESCE($8, pincode),
        lat = COALESCE($9, lat), lng = COALESCE($10, lng),
        is_default = COALESCE($11, is_default)
       WHERE id = $1 AND user_id = $2 RETURNING *`,
      [id, req.user.id, label, address_line1, address_line2, city, state, pincode, lat, lng, is_default]
    );

    if (!r.rows.length) return res.status(404).json({ success: false, message: 'Address not found' });
    res.json({ success: true, data: r.rows[0] });
  } catch (e) { next(e); }
};

exports.deleteAddress = async (req, res, next) => {
  try {
    const { id } = req.params;
    const r = await query('DELETE FROM user_addresses WHERE id = $1 AND user_id = $2 RETURNING id', [id, req.user.id]);
    if (!r.rows.length) {
      return res.status(404).json({ success: false, message: 'Address not found' });
    }
    res.json({ success: true, message: 'Deleted' });
  } catch (e) { next(e); }
};
