const { pool } = require('../config/database');

// Create a dispute
async function createDispute(req, res, next) {
  try {
    const { booking_id, reason, description, evidence_urls } = req.body;
    const raisedBy = req.user.id;

    // Verify booking exists and user is part of it
    const bookingRes = await pool.query(
      `SELECT b.*, p.user_id as pro_user_id FROM bookings b JOIN professionals p ON b.professional_id = p.id WHERE b.id = $1`,
      [booking_id]
    );

    if (bookingRes.rows.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    const booking = bookingRes.rows[0];
    if (booking.customer_id !== raisedBy && booking.pro_user_id !== raisedBy) {
      return res.status(403).json({ error: 'You are not part of this booking' });
    }

    const againstUser = booking.customer_id === raisedBy ? booking.pro_user_id : booking.customer_id;

    const result = await pool.query(
      `INSERT INTO disputes (booking_id, raised_by, against_user, reason, description, evidence_urls)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [booking_id, raisedBy, againstUser, reason, description, JSON.stringify(evidence_urls || [])]
    );

    // Update booking status to disputed
    await pool.query(
      `UPDATE bookings SET status = 'disputed', updated_at = NOW() WHERE id = $1 AND status NOT IN ('disputed', 'refunded')`,
      [booking_id]
    );

    // Notify the other party
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, related_id)
       VALUES ($1, 'booking_disputed', 'Dispute Raised', $2, $3)`,
      [againstUser, `A dispute has been raised for booking: ${booking.title}`, booking_id]
    );

    res.status(201).json({ dispute: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

// List disputes for current user
async function listDisputes(req, res, next) {
  try {
    const userId = req.user.id;
    const { status, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    let query = `SELECT d.*, b.title as booking_title, 
                  u1.name as raised_by_name, u2.name as against_name
                 FROM disputes d
                 JOIN bookings b ON d.booking_id = b.id
                 JOIN users u1 ON d.raised_by = u1.id
                 JOIN users u2 ON d.against_user = u2.id
                 WHERE (d.raised_by = $1 OR d.against_user = $1)`;
    const params = [userId];

    if (status) {
      params.push(status);
      query += ` AND d.status = $${params.length}`;
    }

    query += ` ORDER BY d.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);
    res.json({ disputes: result.rows });
  } catch (err) {
    next(err);
  }
}

// Get dispute details
async function getDispute(req, res, next) {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const result = await pool.query(
      `SELECT d.*, b.title as booking_title, b.quoted_amount, b.final_amount,
              u1.name as raised_by_name, u2.name as against_name
       FROM disputes d
       JOIN bookings b ON d.booking_id = b.id
       JOIN users u1 ON d.raised_by = u1.id
       JOIN users u2 ON d.against_user = u2.id
       WHERE d.id = $1 AND (d.raised_by = $2 OR d.against_user = $2)`,
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Dispute not found' });
    }

    res.json({ dispute: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

// Add evidence to a dispute
async function addEvidence(req, res, next) {
  try {
    const { id } = req.params;
    const { urls } = req.body;
    const userId = req.user.id;

    const result = await pool.query(
      `UPDATE disputes SET evidence_urls = evidence_urls || $2::jsonb, updated_at = NOW()
       WHERE id = $1 AND (raised_by = $3 OR against_user = $3) RETURNING *`,
      [id, JSON.stringify(urls), userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Dispute not found' });
    }

    res.json({ dispute: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

module.exports = { createDispute, listDisputes, getDispute, addEvidence };
