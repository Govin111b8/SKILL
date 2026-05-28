/**
 * Gamification Controller — Phase 8
 * Handles loyalty points, streaks, leaderboards, and professional growth stats.
 */
const { query } = require('../config/database');
const logger = require('../config/logger');

// ─── Customer Points ──────────────────────────────────────────────────────────

/**
 * GET /gamification/points
 * Returns the current user's points balance, level, and recent transactions.
 */
exports.getMyPoints = async (req, res, next) => {
  try {
    const userId = req.user.id;

    // Ensure row exists
    await query(
      `INSERT INTO user_points (user_id, points_balance, lifetime_points, level)
       VALUES ($1, 0, 0, 1)
       ON CONFLICT (user_id) DO NOTHING`,
      [userId],
    );

    const pointsRes = await query(
      `SELECT points_balance, lifetime_points, level FROM user_points WHERE user_id = $1`,
      [userId],
    );
    const points = pointsRes.rows[0] || { points_balance: 0, lifetime_points: 0, level: 1 };

    const txRes = await query(
      `SELECT id, type, points, reason, created_at
       FROM point_transactions
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 20`,
      [userId],
    );

    res.json({
      success: true,
      data: {
        points_balance: parseInt(points.points_balance || 0),
        lifetime_points: parseInt(points.lifetime_points || 0),
        level: parseInt(points.level || 1),
        level_name: getLevelName(parseInt(points.level || 1)),
        next_level_at: getNextLevelThreshold(parseInt(points.level || 1)),
        recent_transactions: txRes.rows,
      },
    });
  } catch (e) {
    next(e);
  }
};

/**
 * POST /gamification/points/redeem
 * Redeems points for a discount on a booking.
 */
exports.redeemPoints = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { points, booking_id } = req.body;

    if (!points || points < 100) {
      return res.status(400).json({ success: false, message: 'Minimum redemption is 100 points' });
    }
    if (!booking_id) {
      return res.status(400).json({ success: false, message: 'booking_id is required' });
    }

    const pointsRes = await query(
      `SELECT points_balance FROM user_points WHERE user_id = $1`,
      [userId],
    );
    const balance = parseInt(pointsRes.rows[0]?.points_balance || 0);

    if (balance < points) {
      return res.status(422).json({ success: false, message: `Insufficient points. You have ${balance} points.` });
    }

    // 1 point = ₹0.10 discount (i.e., 100 points = ₹10)
    const discountAmount = (points / 100) * 10;

    await query(
      `UPDATE user_points
       SET points_balance = points_balance - $1
       WHERE user_id = $2`,
      [points, userId],
    );

    await query(
      `INSERT INTO point_transactions (user_id, type, points, reason, reference_id)
       VALUES ($1, 'redeem', $2, $3, $4)
       ON CONFLICT DO NOTHING`,
      [userId, points, `Redeemed for ₹${discountAmount} discount on booking`, booking_id],
    );

    res.json({
      success: true,
      data: {
        points_redeemed: points,
        discount_applied: discountAmount,
        new_balance: balance - points,
      },
    });
  } catch (e) {
    next(e);
  }
};

/**
 * GET /gamification/leaderboard
 * Top customers by lifetime points — optionally filtered by city.
 */
exports.getCustomerLeaderboard = async (req, res, next) => {
  try {
    const limit = Math.min(parseInt(req.query.limit || 20), 50);

    const rows = await query(
      `SELECT up.user_id, u.name, u.avatar_url, up.lifetime_points, up.level,
              RANK() OVER (ORDER BY up.lifetime_points DESC) AS rank
       FROM user_points up
       JOIN users u ON u.id = up.user_id
       WHERE up.lifetime_points > 0
       ORDER BY up.lifetime_points DESC
       LIMIT $1`,
      [limit],
    );

    res.json({ success: true, data: rows.rows });
  } catch (e) {
    next(e);
  }
};

// ─── Professional Gamification ────────────────────────────────────────────────

/**
 * GET /gamification/professional/stats
 * Returns streaks, rank, progress, and actionable tips for a professional.
 */
exports.getProfessionalStats = async (req, res, next) => {
  try {
    const userId = req.user.id;

    // Get professional profile
    const profRes = await query(
      `SELECT p.id, p.average_rating, p.completed_jobs, p.response_time_hours,
              p.availability_status, p.trust_score, p.kyc_level,
              u.location
       FROM professionals p
       JOIN users u ON p.user_id = u.id
       WHERE p.user_id = $1`,
      [userId],
    );

    if (!profRes.rows.length) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const prof = profRes.rows[0];

    // Response streak — days in a row with at least one accepted booking or message reply
    // (Simplified: count bookings accepted in last N consecutive days)
    const streakRes = await query(
      `WITH daily AS (
         SELECT DATE(updated_at) AS day
         FROM bookings
         WHERE professional_id = $1
           AND status IN ('accepted','in_progress','completed')
           AND updated_at >= NOW() - INTERVAL '30 days'
         GROUP BY day
         ORDER BY day DESC
       )
       SELECT COUNT(*)::int AS streak_days FROM daily`,
      [prof.id],
    );
    const streakDays = streakRes.rows[0]?.streak_days || 0;

    // Category rank — position among pros in same category by avg rating
    const rankRes = await query(
      `WITH ranked AS (
         SELECT p.id,
                RANK() OVER (ORDER BY p.average_rating DESC, p.completed_jobs DESC) AS rank,
                COUNT(*) OVER () AS total
         FROM professionals p
         JOIN professional_categories pc ON pc.professional_id = p.id
         WHERE pc.category_id IN (
           SELECT category_id FROM professional_categories WHERE professional_id = $1
         )
       )
       SELECT rank, total FROM ranked WHERE id = $1 LIMIT 1`,
      [prof.id],
    );
    const rankRow = rankRes.rows[0];

    // Weekly bookings received
    const weeklyBookings = await query(
      `SELECT COUNT(*)::int AS count
       FROM bookings
       WHERE professional_id = $1
         AND created_at >= NOW() - INTERVAL '7 days'`,
      [prof.id],
    );

    // Build actionable tips
    const tips = buildProfessionalTips(prof);

    // Portfolio completeness
    const portfolioRes = await query(
      `SELECT COUNT(*)::int AS count FROM portfolio_items WHERE professional_id = $1`,
      [prof.id],
    );

    res.json({
      success: true,
      data: {
        professional_id: prof.id,
        streak_days: streakDays,
        rank: rankRow ? parseInt(rankRow.rank) : null,
        total_in_category: rankRow ? parseInt(rankRow.total) : null,
        completed_jobs: parseInt(prof.completed_jobs || 0),
        average_rating: parseFloat(prof.average_rating || 0),
        trust_score: parseInt(prof.trust_score || 0),
        kyc_level: parseInt(prof.kyc_level || 0),
        response_time_hours: parseFloat(prof.response_time_hours || 0),
        weekly_bookings: weeklyBookings.rows[0]?.count || 0,
        portfolio_items: portfolioRes.rows[0]?.count || 0,
        tips,
      },
    });
  } catch (e) {
    next(e);
  }
};

/**
 * GET /gamification/professional/leaderboard
 * Top professionals in a category by completed jobs or rating.
 */
exports.getProfessionalLeaderboard = async (req, res, next) => {
  try {
    const { category_id, city, sort_by = 'jobs' } = req.query;
    const limit = Math.min(parseInt(req.query.limit || 20), 50);

    let whereClause = 'WHERE p.completed_jobs > 0';
    const params = [];

    if (category_id) {
      params.push(parseInt(category_id));
      whereClause += ` AND EXISTS (
        SELECT 1 FROM professional_categories pc
        WHERE pc.professional_id = p.id AND pc.category_id = $${params.length}
      )`;
    }

    if (city) {
      params.push(`%${city}%`);
      whereClause += ` AND u.location ILIKE $${params.length}`;
    }

    const orderCol = sort_by === 'rating' ? 'p.average_rating' : 'p.completed_jobs';
    params.push(limit);

    const rows = await query(
      `SELECT p.id, u.name, u.avatar_url, p.average_rating,
              p.completed_jobs, p.trust_score, u.location,
              RANK() OVER (ORDER BY ${orderCol} DESC) AS rank
       FROM professionals p
       JOIN users u ON p.user_id = u.id
       ${whereClause}
       ORDER BY ${orderCol} DESC
       LIMIT $${params.length}`,
      params,
    );

    res.json({ success: true, data: rows.rows });
  } catch (e) {
    next(e);
  }
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

function getLevelName(level) {
  const names = { 1: 'Bronze', 2: 'Silver', 3: 'Gold', 4: 'Platinum', 5: 'Diamond' };
  return names[Math.min(level, 5)] || 'Bronze';
}

function getNextLevelThreshold(level) {
  const thresholds = { 1: 500, 2: 1500, 3: 5000, 4: 15000, 5: null };
  return thresholds[Math.min(level, 5)];
}

function buildProfessionalTips(prof) {
  const tips = [];
  if (parseInt(prof.kyc_level || 0) < 2) {
    tips.push({ priority: 'high', icon: '🛡️', message: 'Complete KYC verification to unlock the Verified badge and rank higher.' });
  }
  if (parseFloat(prof.average_rating || 0) < 4.5) {
    tips.push({ priority: 'medium', icon: '⭐', message: 'Respond promptly and ask satisfied customers to leave a review.' });
  }
  if (parseFloat(prof.response_time_hours || 99) > 2) {
    tips.push({ priority: 'high', icon: '⚡', message: 'Respond to inquiries within 1 hour to earn the Fast Responder badge.' });
  }
  if (prof.availability_status !== 'available') {
    tips.push({ priority: 'medium', icon: '🟢', message: 'Mark yourself as Available Today to appear in priority search results.' });
  }
  tips.push({ priority: 'low', icon: '📸', message: 'Add portfolio photos to increase profile completeness and customer trust.' });
  return tips.slice(0, 3);
}

/**
 * Award points to a user (called internally from other controllers or cron).
 * type: 'booking_complete' | 'review_posted' | 'referral' | 'daily_login'
 */
exports.awardPoints = async (userId, type, referenceId = null) => {
  const POINT_VALUES = {
    booking_complete: 50,
    review_posted: 20,
    referral: 200,
    daily_login: 5,
    profile_complete: 100,
  };

  const points = POINT_VALUES[type];
  if (!points) return;

  try {
    await query(
      `INSERT INTO user_points (user_id, points_balance, lifetime_points, level)
       VALUES ($1, $2, $2, 1)
       ON CONFLICT (user_id) DO UPDATE
       SET points_balance = user_points.points_balance + $2,
           lifetime_points = user_points.lifetime_points + $2,
           level = CASE
             WHEN user_points.lifetime_points + $2 >= 15000 THEN 4
             WHEN user_points.lifetime_points + $2 >= 5000  THEN 3
             WHEN user_points.lifetime_points + $2 >= 1500  THEN 2
             ELSE 1
           END`,
      [userId, points],
    );

    await query(
      `INSERT INTO point_transactions (user_id, type, points, reason, reference_id)
       VALUES ($1, 'earn', $2, $3, $4)`,
      [userId, points, type.replace(/_/g, ' '), referenceId],
    );
  } catch (err) {
    logger.warn({ err, userId, type }, 'Failed to award points');
  }
};
