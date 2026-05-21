const { query } = require('../config/database');
const logger = require('../config/logger');

// ============================================================
// PROVIDER INVENTORY CONTROLLER
// Equipment, supplies, and inventory tracking for providers
// ============================================================

/**
 * List provider's inventory
 */
exports.listInventory = async (req, res, next) => {
  try {
    const pro = await query(`SELECT id FROM professionals WHERE user_id = $1`, [req.user.id]);
    if (!pro.rows[0]) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 20));
    const offset = (page - 1) * limit;

    const result = await query(
      `SELECT * FROM provider_inventory 
       WHERE professional_id = $1 
       ORDER BY category, item_name
       LIMIT $2 OFFSET $3`,
      [pro.rows[0].id, limit, offset]
    );

    const countResult = await query(
      `SELECT COUNT(*) FROM provider_inventory WHERE professional_id = $1`,
      [pro.rows[0].id]
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
 * Add inventory item
 */
exports.addItem = async (req, res, next) => {
  try {
    const pro = await query(`SELECT id FROM professionals WHERE user_id = $1`, [req.user.id]);
    if (!pro.rows[0]) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const { item_name, quantity, unit_cost, currency, low_stock_threshold, category, notes } = req.body;

    if (!item_name) {
      return res.status(400).json({ success: false, message: 'item_name is required' });
    }

    const result = await query(
      `INSERT INTO provider_inventory 
       (professional_id, item_name, quantity, unit_cost, currency, low_stock_threshold, category, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        pro.rows[0].id, item_name, quantity || 1, unit_cost || null,
        currency || 'INR', low_stock_threshold || 5, category || null, notes || null
      ]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * Update inventory item
 */
exports.updateItem = async (req, res, next) => {
  try {
    const pro = await query(`SELECT id FROM professionals WHERE user_id = $1`, [req.user.id]);
    if (!pro.rows[0]) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const { id } = req.params;
    const { item_name, quantity, unit_cost, low_stock_threshold, category, notes } = req.body;

    const result = await query(
      `UPDATE provider_inventory SET
        item_name = COALESCE($1, item_name),
        quantity = COALESCE($2, quantity),
        unit_cost = COALESCE($3, unit_cost),
        low_stock_threshold = COALESCE($4, low_stock_threshold),
        category = COALESCE($5, category),
        notes = COALESCE($6, notes),
        updated_at = NOW()
       WHERE id = $7 AND professional_id = $8
       RETURNING *`,
      [item_name || null, quantity, unit_cost, low_stock_threshold, category || null, notes || null, id, pro.rows[0].id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Inventory item not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * Delete inventory item
 */
exports.deleteItem = async (req, res, next) => {
  try {
    const pro = await query(`SELECT id FROM professionals WHERE user_id = $1`, [req.user.id]);
    if (!pro.rows[0]) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const result = await query(
      `DELETE FROM provider_inventory WHERE id = $1 AND professional_id = $2 RETURNING id`,
      [req.params.id, pro.rows[0].id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Inventory item not found' });
    }

    res.json({ success: true, message: 'Item deleted' });
  } catch (err) {
    next(err);
  }
};

/**
 * Get low-stock alerts
 */
exports.getLowStockAlerts = async (req, res, next) => {
  try {
    const pro = await query(`SELECT id FROM professionals WHERE user_id = $1`, [req.user.id]);
    if (!pro.rows[0]) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const result = await query(
      `SELECT * FROM provider_inventory 
       WHERE professional_id = $1 AND quantity <= low_stock_threshold
       ORDER BY quantity ASC`,
      [pro.rows[0].id]
    );

    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
};

// ============================================================
// PROVIDER CRM — Customer relationship management
// ============================================================

/**
 * List provider's customers with relationship data
 */
exports.listCustomers = async (req, res, next) => {
  try {
    const pro = await query(`SELECT id FROM professionals WHERE user_id = $1`, [req.user.id]);
    if (!pro.rows[0]) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 20));
    const offset = (page - 1) * limit;
    const sort = req.query.sort === 'revenue' ? 'total_revenue DESC' : 'last_booking_date DESC NULLS LAST';

    const result = await query(
      `SELECT pc.*, u.name as customer_name, u.phone as customer_phone, u.email as customer_email, u.avatar_url
       FROM provider_customers pc
       JOIN users u ON pc.customer_id = u.id
       WHERE pc.professional_id = $1
       ORDER BY ${sort}
       LIMIT $2 OFFSET $3`,
      [pro.rows[0].id, limit, offset]
    );

    const countResult = await query(
      `SELECT COUNT(*) FROM provider_customers WHERE professional_id = $1`,
      [pro.rows[0].id]
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
 * Get/create a customer relationship record
 */
exports.getOrCreateCustomer = async (req, res, next) => {
  try {
    const pro = await query(`SELECT id FROM professionals WHERE user_id = $1`, [req.user.id]);
    if (!pro.rows[0]) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const { customer_id } = req.params;

    // Upsert — create if not exists
    const result = await query(
      `INSERT INTO provider_customers (professional_id, customer_id)
       VALUES ($1, $2)
       ON CONFLICT (professional_id, customer_id) DO UPDATE SET updated_at = NOW()
       RETURNING *`,
      [pro.rows[0].id, customer_id]
    );

    // Enrich with user info
    const user = await query(`SELECT name, phone, email, avatar_url FROM users WHERE id = $1`, [customer_id]);

    res.json({
      success: true,
      data: { ...result.rows[0], ...user.rows[0] }
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Update customer notes/tags
 */
exports.updateCustomerNotes = async (req, res, next) => {
  try {
    const pro = await query(`SELECT id FROM professionals WHERE user_id = $1`, [req.user.id]);
    if (!pro.rows[0]) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const { customer_id } = req.params;
    const { tags, notes, is_vip, preferred_time, special_instructions } = req.body;

    const result = await query(
      `UPDATE provider_customers SET
        tags = COALESCE($1, tags),
        notes = COALESCE($2, notes),
        is_vip = COALESCE($3, is_vip),
        preferred_time = COALESCE($4, preferred_time),
        special_instructions = COALESCE($5, special_instructions),
        updated_at = NOW()
       WHERE professional_id = $6 AND customer_id = $7
       RETURNING *`,
      [tags || null, notes || null, is_vip, preferred_time || null, special_instructions || null, pro.rows[0].id, customer_id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Customer relationship not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * Get CRM dashboard stats
 */
exports.getCRMStats = async (req, res, next) => {
  try {
    const pro = await query(`SELECT id FROM professionals WHERE user_id = $1`, [req.user.id]);
    if (!pro.rows[0]) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const stats = await query(
      `SELECT 
        COUNT(*) as total_customers,
        COUNT(*) FILTER (WHERE is_vip) as vip_customers,
        COUNT(*) FILTER (WHERE total_bookings > 1) as repeat_customers,
        COALESCE(SUM(total_revenue), 0) as total_revenue,
        COALESCE(AVG(total_bookings), 0) as avg_bookings_per_customer,
        MAX(last_booking_date) as most_recent_booking
       FROM provider_customers
       WHERE professional_id = $1`,
      [pro.rows[0].id]
    );

    res.json({ success: true, data: stats.rows[0] });
  } catch (err) {
    next(err);
  }
};
