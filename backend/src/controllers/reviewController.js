const crypto = require('crypto');
const { query } = require('../config/database');
const { notify } = require('../utils/notifier');

const createReview = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { professional_id, contact_id, booking_id, rating, comment } = req.body;

    if (!contact_id && !booking_id) {
      return res.status(400).json({ success: false, message: 'contact_id or booking_id is required' });
    }

    // Verify ownership / completion
    if (booking_id) {
      const b = await query(
        `SELECT id, professional_id, status FROM bookings
         WHERE id = $1 AND customer_id = $2`,
        [booking_id, userId]
      );
      if (!b.rows.length) {
        return res.status(400).json({ success: false, message: 'Booking not found.' });
      }
      if (b.rows[0].status !== 'completed') {
        return res.status(400).json({ success: false, message: 'You can review only after the booking is completed.' });
      }
      if (b.rows[0].professional_id !== professional_id) {
        return res.status(400).json({ success: false, message: 'Booking does not match this professional.' });
      }
      const dup = await query('SELECT id FROM reviews WHERE booking_id = $1', [booking_id]);
      if (dup.rows.length) {
        return res.status(400).json({ success: false, message: 'You have already reviewed this booking.' });
      }
    } else {
      const contact = await query(
        `SELECT id FROM contacts
         WHERE id = $1 AND customer_id = $2 AND professional_id = $3 AND status = 'accepted'`,
        [contact_id, userId, professional_id]
      );
      if (contact.rows.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'You can only review professionals you have contacted and completed a job with.',
        });
      }
      const existingReview = await query(
        'SELECT id FROM reviews WHERE contact_id = $1 AND customer_id = $2',
        [contact_id, userId]
      );
      if (existingReview.rows.length > 0) {
        return res.status(400).json({ success: false, message: 'You have already reviewed this contact.' });
      }
    }

    const id = crypto.randomUUID();
    const result = await query(
      `INSERT INTO reviews (id, professional_id, customer_id, contact_id, booking_id, rating, comment, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
       RETURNING *`,
      [id, professional_id, userId, contact_id || null, booking_id || null, rating, comment || null]
    );

    // Notify the pro user
    try {
      const pu = await query('SELECT user_id FROM professionals WHERE id = $1', [professional_id]);
      if (pu.rows.length) {
        await notify(pu.rows[0].user_id, {
          type: 'review_received',
          title: `New ${rating}★ review`,
          body: comment ? (comment.length > 80 ? comment.slice(0,80)+'…' : comment) : 'A customer reviewed you',
          related_id: professional_id,
        });
      }
    } catch (_) {}

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'Review created successfully.',
    });
  } catch (error) {
    next(error);
  }
};

const getReviews = async (req, res, next) => {
  try {
    const { professionalId } = req.params;
    const { page = 1, limit = 10 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const countResult = await query(
      'SELECT COUNT(*) FROM reviews WHERE professional_id = $1',
      [professionalId]
    );
    const total = parseInt(countResult.rows[0].count);

    const result = await query(
      `SELECT r.*, u.name as reviewer_name
       FROM reviews r
       JOIN users u ON r.customer_id = u.id
       WHERE r.professional_id = $1
       ORDER BY r.created_at DESC
       LIMIT $2 OFFSET $3`,
      [professionalId, parseInt(limit), offset]
    );

    res.status(200).json({
      success: true,
      data: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { createReview, getReviews, getPendingReviews };

// GET /api/reviews/pending — completed bookings the customer hasn't reviewed yet
async function getPendingReviews(req, res, next) {
  try {
    const userId = req.user.id;
    const rows = await query(
      `SELECT b.id AS booking_id, b.title, b.completed_at,
              p.id AS professional_id,
              u.name AS professional_name, u.avatar_url AS professional_avatar
       FROM bookings b
       JOIN professionals p ON b.professional_id = p.id
       JOIN users u ON p.user_id = u.id
       WHERE b.customer_id = $1
         AND b.status = 'completed'
         AND NOT EXISTS (SELECT 1 FROM reviews r WHERE r.booking_id = b.id)
       ORDER BY b.completed_at DESC`,
      [userId]
    );
    res.json({ success: true, data: rows.rows });
  } catch (error) {
    next(error);
  }
}
