const crypto = require('crypto');
const { query } = require('../config/database');
const { notify } = require('../utils/notifier');

// Simple profanity filter using a word list
const PROFANITY_PATTERNS = [
  /\b(fuck|shit|ass|bitch|bastard|damn|crap|piss|dick|cock|pussy|cunt|whore|slut|nigger|faggot)\b/i,
];

function containsProfanity(text) {
  if (!text) return false;
  return PROFANITY_PATTERNS.some((re) => re.test(text));
}

const createReview = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { professional_id, contact_id, booking_id, rating, comment } = req.body;

    if (!contact_id && !booking_id) {
      return res.status(400).json({ success: false, message: 'contact_id or booking_id is required' });
    }

    let interactionCreatedAt = null;

    // Verify ownership / completion
    if (booking_id) {
      const b = await query(
        `SELECT id, professional_id, status, created_at FROM bookings
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
      interactionCreatedAt = b.rows[0].created_at;
    } else {
      const contact = await query(
        `SELECT id, created_at FROM contacts
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
      interactionCreatedAt = contact.rows[0].created_at;
    }

    // Timing window: 1 hour to 60 days after interaction (PRD §6.6)
    if (interactionCreatedAt) {
      const hoursSinceInteraction = (Date.now() - new Date(interactionCreatedAt).getTime()) / 3600000;
      if (hoursSinceInteraction < 1) {
        return res.status(422).json({ success: false, message: 'Reviews can only be submitted at least 1 hour after contact.' });
      }
      if (hoursSinceInteraction > 60 * 24) {
        return res.status(422).json({ success: false, message: 'The 60-day review window for this interaction has passed.' });
      }
    }

    // Velocity detection: >5 reviews to same pro in 24h → hold for moderation
    const velocityCheck = await query(
      `SELECT COUNT(*) FROM reviews
       WHERE professional_id = $1 AND created_at >= NOW() - INTERVAL '24 hours'`,
      [professional_id]
    );
    const recentCount = parseInt(velocityCheck.rows[0].count);
    const heldForVelocity = recentCount >= 5;

    // Profanity / hate-speech auto-hold
    const hasProfanity = containsProfanity(comment);

    // Determine moderation_status
    let moderationStatus = 'approved';
    if (heldForVelocity) moderationStatus = 'held_for_review';
    if (hasProfanity) moderationStatus = 'held_profanity';

    const id = crypto.randomUUID();
    const result = await query(
      `INSERT INTO reviews (id, professional_id, customer_id, contact_id, booking_id, rating, comment, moderation_status, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
       RETURNING *`,
      [id, professional_id, userId, contact_id || null, booking_id || null, rating, comment || null, moderationStatus]
    );

    // Notify the professional (only for approved reviews)
    if (moderationStatus === 'approved') {
      try {
        const pu = await query('SELECT user_id FROM professionals WHERE id = $1', [professional_id]);
        if (pu.rows.length) {
          await notify(pu.rows[0].user_id, {
            type: 'review_received',
            title: `New ${rating}★ review`,
            body: comment ? (comment.length > 80 ? comment.slice(0, 80) + '…' : comment) : 'A customer reviewed you',
            related_id: professional_id,
          });
        }
      } catch (_) {}
    }

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: moderationStatus === 'approved'
        ? 'Review created successfully.'
        : 'Your review has been submitted and is being verified before publishing.',
    });
  } catch (error) {
    next(error);
  }
};

// PUT /api/reviews/:id — edit review text within 24h window (star rating locked)
const editReview = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { comment } = req.body;

    if (!comment || !comment.trim()) {
      return res.status(400).json({ success: false, message: 'comment is required' });
    }

    const existing = await query(
      'SELECT id, customer_id, created_at FROM reviews WHERE id = $1',
      [id]
    );
    if (!existing.rows.length) {
      return res.status(404).json({ success: false, message: 'Review not found.' });
    }
    if (existing.rows[0].customer_id !== userId) {
      return res.status(403).json({ success: false, message: 'You can only edit your own reviews.' });
    }

    // 24-hour edit window
    const hoursSince = (Date.now() - new Date(existing.rows[0].created_at).getTime()) / 3600000;
    if (hoursSince > 24) {
      return res.status(422).json({ success: false, message: 'The 24-hour edit window has passed.' });
    }

    const modStatus = containsProfanity(comment) ? 'held_profanity' : 'approved';

    const result = await query(
      `UPDATE reviews SET comment = $1, is_edited = TRUE, edited_at = NOW(), moderation_status = $2
       WHERE id = $3 RETURNING *`,
      [comment.trim(), modStatus, id]
    );

    res.json({ success: true, data: result.rows[0], message: 'Review updated.' });
  } catch (error) {
    next(error);
  }
};

// POST /api/reviews/:id/helpful — mark review as helpful (+1)
const markHelpful = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      `UPDATE reviews SET helpful_count = COALESCE(helpful_count, 0) + 1
       WHERE id = $1 RETURNING id, helpful_count`,
      [id]
    );
    if (!result.rows.length) {
      return res.status(404).json({ success: false, message: 'Review not found.' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

const getReviews = async (req, res, next) => {
  try {
    const { professionalId } = req.params;
    const { page = 1, limit = 10, cursor } = req.query;
    const limitNum = Math.min(100, Math.max(1, parseInt(limit)));

    let whereExtra = "AND r.moderation_status = 'approved'";
    const params = [professionalId, limitNum];

    if (cursor) {
      params.push(cursor);
      whereExtra += ` AND r.created_at < $${params.length}`;
    }

    const result = await query(
      `SELECT r.id, r.rating, r.comment, r.created_at, r.is_edited, r.helpful_count,
              r.moderation_status, u.name as reviewer_name, u.avatar_url as reviewer_avatar
       FROM reviews r
       JOIN users u ON r.customer_id = u.id
       WHERE r.professional_id = $1 ${whereExtra}
       ORDER BY r.created_at DESC
       LIMIT $2`,
      params
    );

    const countResult = await query(
      "SELECT COUNT(*) FROM reviews WHERE professional_id = $1 AND moderation_status = 'approved'",
      [professionalId]
    );

    const nextCursor = result.rows.length === limitNum
      ? result.rows[result.rows.length - 1].created_at
      : null;

    res.status(200).json({
      success: true,
      data: result.rows,
      pagination: {
        cursor: nextCursor,
        total: parseInt(countResult.rows[0].count),
        limit: limitNum,
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { createReview, editReview, markHelpful, getReviews, getPendingReviews };

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
