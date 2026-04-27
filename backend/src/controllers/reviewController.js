const crypto = require('crypto');
const { query } = require('../config/database');

const createReview = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { professional_id, contact_id, rating, comment } = req.body;

    // Verify that the user has contacted this professional
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

    // Check if already reviewed for this contact
    const existingReview = await query(
      'SELECT id FROM reviews WHERE contact_id = $1 AND customer_id = $2',
      [contact_id, userId]
    );
    if (existingReview.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'You have already reviewed this contact.',
      });
    }

    const id = crypto.randomUUID();
    const result = await query(
      `INSERT INTO reviews (id, professional_id, customer_id, contact_id, rating, comment, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())
       RETURNING *`,
      [id, professional_id, userId, contact_id, rating, comment]
    );

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

module.exports = { createReview, getReviews };
