const { query } = require('../config/database');

// =====================================================
// COUPON MANAGEMENT
// =====================================================

exports.validateCoupon = async (req, res, next) => {
  try {
    const { code, amount, category_id } = req.body;

    if (!code) {
      return res.status(400).json({ success: false, message: 'Coupon code is required' });
    }

    const r = await query(
      `SELECT * FROM coupons WHERE code = $1 AND is_active = true`,
      [code.toUpperCase().trim()]
    );

    if (!r.rows.length) {
      return res.status(404).json({ success: false, message: 'Invalid coupon code' });
    }

    const coupon = r.rows[0];

    // Check validity period
    const now = new Date();
    if (coupon.valid_from && new Date(coupon.valid_from) > now) {
      return res.status(400).json({ success: false, message: 'Coupon is not yet active' });
    }
    if (coupon.valid_until && new Date(coupon.valid_until) < now) {
      return res.status(400).json({ success: false, message: 'Coupon has expired' });
    }

    // Check usage limit
    if (coupon.usage_limit && coupon.used_count >= coupon.usage_limit) {
      return res.status(400).json({ success: false, message: 'Coupon usage limit reached' });
    }

    // Check per-user limit
    if (coupon.per_user_limit) {
      const userUsage = await query(
        'SELECT COUNT(*) FROM coupon_usages WHERE coupon_id = $1 AND user_id = $2',
        [coupon.id, req.user.id]
      );
      if (parseInt(userUsage.rows[0].count) >= coupon.per_user_limit) {
        return res.status(400).json({ success: false, message: 'You have already used this coupon' });
      }
    }

    // Check min order amount
    const orderAmount = parseFloat(amount) || 0;
    if (coupon.min_order_amount && orderAmount < parseFloat(coupon.min_order_amount)) {
      return res.status(400).json({
        success: false,
        message: `Minimum order amount is ₹${coupon.min_order_amount}`
      });
    }

    // Check category restriction
    if (coupon.categories && coupon.categories.length > 0 && category_id) {
      if (!coupon.categories.includes(category_id)) {
        return res.status(400).json({ success: false, message: 'Coupon not valid for this category' });
      }
    }

    // Calculate discount
    let discount = 0;
    if (coupon.discount_type === 'percentage') {
      discount = (orderAmount * parseFloat(coupon.discount_value)) / 100;
      if (coupon.max_discount) {
        discount = Math.min(discount, parseFloat(coupon.max_discount));
      }
    } else {
      discount = parseFloat(coupon.discount_value);
    }

    discount = Math.min(discount, orderAmount);

    res.json({
      success: true,
      data: {
        coupon_id: coupon.id,
        code: coupon.code,
        description: coupon.description,
        discount_type: coupon.discount_type,
        discount_value: parseFloat(coupon.discount_value),
        discount_amount: Math.round(discount * 100) / 100,
        final_amount: Math.round((orderAmount - discount) * 100) / 100,
      }
    });
  } catch (e) { next(e); }
};

exports.applyCoupon = async (req, res, next) => {
  try {
    const { coupon_id, booking_id, discount_applied } = req.body;

    if (!coupon_id || !booking_id) {
      return res.status(400).json({ success: false, message: 'coupon_id and booking_id are required' });
    }

    // Record usage
    await query(
      `INSERT INTO coupon_usages (coupon_id, user_id, booking_id, discount_applied)
       VALUES ($1, $2, $3, $4)`,
      [coupon_id, req.user.id, booking_id, discount_applied || 0]
    );

    // Increment used_count
    await query(
      'UPDATE coupons SET used_count = used_count + 1 WHERE id = $1',
      [coupon_id]
    );

    res.json({ success: true, message: 'Coupon applied successfully' });
  } catch (e) { next(e); }
};

exports.listCoupons = async (req, res, next) => {
  try {
    const now = new Date().toISOString();
    const r = await query(
      `SELECT id, code, description, discount_type, discount_value,
              min_order_amount, max_discount, valid_until, categories
       FROM coupons
       WHERE is_active = true
         AND (valid_from IS NULL OR valid_from <= $1)
         AND (valid_until IS NULL OR valid_until >= $1)
         AND (usage_limit IS NULL OR used_count < usage_limit)
       ORDER BY discount_value DESC`,
      [now]
    );
    res.json({ success: true, data: r.rows });
  } catch (e) { next(e); }
};

// Admin: create coupon
exports.createCoupon = async (req, res, next) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Admin only' });
    }

    const {
      code, description, discount_type, discount_value,
      min_order_amount, max_discount, usage_limit, per_user_limit,
      valid_from, valid_until, categories
    } = req.body;

    if (!code || !discount_type || !discount_value) {
      return res.status(400).json({ success: false, message: 'code, discount_type, and discount_value are required' });
    }

    const r = await query(
      `INSERT INTO coupons (code, description, discount_type, discount_value,
        min_order_amount, max_discount, usage_limit, per_user_limit,
        valid_from, valid_until, categories, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
       RETURNING *`,
      [code.toUpperCase().trim(), description || null, discount_type, discount_value,
       min_order_amount || 0, max_discount || null, usage_limit || null,
       per_user_limit || 1, valid_from || null, valid_until || null,
       categories || null, req.user.id]
    );

    res.status(201).json({ success: true, data: r.rows[0] });
  } catch (e) { next(e); }
};
