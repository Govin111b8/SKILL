const { pool, query } = require('../config/database');
const { notify } = require('../utils/notifier');

// Create warranty after booking completion
async function createWarranty(req, res, next) {
  try {
    const { booking_id } = req.body;

    const bookingRes = await pool.query(
      `SELECT b.*, p.user_id as pro_user_id, c.default_warranty_days
       FROM bookings b
       JOIN professionals p ON b.professional_id = p.id
       LEFT JOIN categories c ON b.category_id = c.id
       WHERE b.id = $1 AND b.status = 'completed'`,
      [booking_id]
    );

    if (bookingRes.rows.length === 0) {
      return res.status(404).json({ error: 'Completed booking not found' });
    }

    const booking = bookingRes.rows[0];
    const warrantyDays = booking.default_warranty_days || 7;
    const startsAt = booking.completed_at || new Date();
    const expiresAt = new Date(startsAt);
    expiresAt.setDate(expiresAt.getDate() + warrantyDays);

    // Check if warranty already exists
    const existing = await pool.query(
      'SELECT id FROM service_warranties WHERE booking_id = $1', [booking_id]
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'Warranty already exists for this booking', warranty: existing.rows[0] });
    }

    const result = await pool.query(
      `INSERT INTO service_warranties (booking_id, professional_id, customer_id, category_id, warranty_days, starts_at, expires_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [booking_id, booking.professional_id, booking.customer_id, booking.category_id, warrantyDays, startsAt, expiresAt]
    );

    res.status(201).json({ warranty: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

// Claim warranty (re-service request)
async function claimWarranty(req, res, next) {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const userId = req.user.id;

    if (!reason || !reason.trim()) {
      return res.status(400).json({ error: 'Claim reason is required' });
    }

    const result = await pool.query(
      `UPDATE service_warranties 
       SET status = 'claimed', claim_reason = $2, claimed_at = NOW()
       WHERE id = $1 AND customer_id = $3 AND status = 'active' AND expires_at > NOW()
       RETURNING *`,
      [id, reason, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Active warranty not found or expired' });
    }

    // Create a new booking for re-service
    const warranty = result.rows[0];
    const newBooking = await pool.query(
      `INSERT INTO bookings (customer_id, professional_id, category_id, title, description, status)
       VALUES ($1, $2, $3, $4, $5, 'requested') RETURNING *`,
      [userId, warranty.professional_id, warranty.category_id, `Warranty Re-service`, `Warranty claim: ${reason}`]
    );

    // Notify professional
    const proRes = await pool.query('SELECT user_id FROM professionals WHERE id = $1', [warranty.professional_id]);
    if (proRes.rows.length > 0) {
      await pool.query(
        `INSERT INTO notifications (user_id, type, title, body, related_id)
         VALUES ($1, 'booking_request', 'Warranty Claim', $2, $3)`,
        [proRes.rows[0].user_id, `Customer has claimed warranty: ${reason}`, newBooking.rows[0].id]
      );
    }

    res.json({ warranty: result.rows[0], new_booking: newBooking.rows[0] });
  } catch (err) {
    next(err);
  }
}

// Get warranties for current user
async function getWarranties(req, res, next) {
  try {
    const userId = req.user.id;
    const { status } = req.query;

    let query = `SELECT w.*, b.title as booking_title, c.name as category_name,
                  u.name as professional_name
                 FROM service_warranties w
                 JOIN bookings b ON w.booking_id = b.id
                 LEFT JOIN categories c ON w.category_id = c.id
                 JOIN professionals p ON w.professional_id = p.id
                 JOIN users u ON p.user_id = u.id
                 WHERE w.customer_id = $1`;
    const params = [userId];

    if (status) {
      params.push(status);
      query += ` AND w.status = $${params.length}`;
    }

    query += ' ORDER BY w.created_at DESC';
    const result = await pool.query(query, params);

    res.json({ warranties: result.rows });
  } catch (err) {
    next(err);
  }
}

// Resolve a claimed warranty (professional marks re-service done)
async function resolveWarranty(req, res, next) {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Only the professional who owns the warranty can resolve it
    const result = await pool.query(
      `UPDATE service_warranties
       SET status = 'void'
       WHERE id = $1
         AND professional_id = (SELECT id FROM professionals WHERE user_id = $2)
         AND status = 'claimed'
       RETURNING *`,
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Claimed warranty not found or not yours to resolve' });
    }

    // Notify customer
    const warranty = result.rows[0];
    await notify(warranty.customer_id, {
      type: 'booking_completed',
      title: 'Warranty Claim Resolved',
      body: 'Your warranty claim has been resolved by the professional.',
      related_id: id,
    });

    res.json({ warranty: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

// Get warranty claims for a professional (to see what they need to service)
async function getProfessionalWarranties(req, res, next) {
  try {
    const userId = req.user.id;
    const { status } = req.query;

    const proRes = await pool.query('SELECT id FROM professionals WHERE user_id = $1', [userId]);
    if (proRes.rows.length === 0) {
      return res.status(403).json({ error: 'Professional profile not found' });
    }
    const professionalId = proRes.rows[0].id;

    let queryStr = `SELECT w.*, b.title as booking_title, c.name as category_name,
                     u.name as customer_name, u.phone as customer_phone
                    FROM service_warranties w
                    JOIN bookings b ON w.booking_id = b.id
                    LEFT JOIN categories c ON w.category_id = c.id
                    JOIN users u ON w.customer_id = u.id
                    WHERE w.professional_id = $1`;
    const params = [professionalId];

    if (status) {
      params.push(status);
      queryStr += ` AND w.status = $${params.length}`;
    }

    queryStr += ' ORDER BY w.created_at DESC';
    const result = await pool.query(queryStr, params);

    res.json({ warranties: result.rows });
  } catch (err) {
    next(err);
  }
}

module.exports = { createWarranty, claimWarranty, getWarranties, resolveWarranty, getProfessionalWarranties };
