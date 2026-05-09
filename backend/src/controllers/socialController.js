const { query } = require('../config/database');

/**
 * POST /api/social/follow/:professionalId
 * Auth required — follow a professional (by their user_id).
 */
const followProfessional = async (req, res, next) => {
  try {
    const followerId = req.user.id;
    const { professionalId } = req.params;

    // Get the user_id of the professional
    const proResult = await query('SELECT user_id FROM professionals WHERE id = $1', [professionalId]);
    if (proResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Professional not found.' });
    }

    const followingId = proResult.rows[0].user_id;

    if (followerId === followingId) {
      return res.status(400).json({ success: false, message: 'You cannot follow yourself.' });
    }

    await query(
      `INSERT INTO follows (follower_id, following_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
      [followerId, followingId]
    );

    res.status(200).json({ success: true, following: true, message: 'Followed successfully.' });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/social/unfollow/:professionalId
 * Auth required — unfollow a professional.
 */
const unfollowProfessional = async (req, res, next) => {
  try {
    const followerId = req.user.id;
    const { professionalId } = req.params;

    const proResult = await query('SELECT user_id FROM professionals WHERE id = $1', [professionalId]);
    if (proResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Professional not found.' });
    }

    const followingId = proResult.rows[0].user_id;

    await query('DELETE FROM follows WHERE follower_id = $1 AND following_id = $2', [followerId, followingId]);

    res.status(200).json({ success: true, following: false, message: 'Unfollowed.' });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/social/following
 * Auth required — list professionals the current user follows.
 */
const getFollowing = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(50, parseInt(req.query.limit) || 20);
    const offset = (page - 1) * limit;

    const result = await query(
      `SELECT p.id as professional_id, u.name, u.avatar_url, u.location,
              p.headline, p.completed_jobs,
              COALESCE(AVG(r.rating), 0) as average_rating,
              f.created_at as followed_at
       FROM follows f
       JOIN users u ON f.following_id = u.id
       JOIN professionals p ON p.user_id = u.id
       LEFT JOIN reviews r ON r.professional_id = p.id
       WHERE f.follower_id = $1
       GROUP BY p.id, u.name, u.avatar_url, u.location, p.headline, p.completed_jobs, f.created_at
       ORDER BY f.created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    res.status(200).json({ success: true, data: result.rows, page, limit });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/social/check/:professionalId
 * Auth required — check if current user follows a professional.
 */
const checkFollow = async (req, res, next) => {
  try {
    const followerId = req.user.id;
    const { professionalId } = req.params;

    const proResult = await query('SELECT user_id FROM professionals WHERE id = $1', [professionalId]);
    if (proResult.rows.length === 0) {
      return res.status(200).json({ success: true, following: false });
    }

    const followingId = proResult.rows[0].user_id;
    const result = await query(
      'SELECT id FROM follows WHERE follower_id = $1 AND following_id = $2',
      [followerId, followingId]
    );

    res.status(200).json({ success: true, following: result.rows.length > 0 });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/social/feed
 * Auth required — aggregated feed from followed professionals.
 */
const getFeed = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(50, parseInt(req.query.limit) || 20);
    const offset = (page - 1) * limit;

    // Get activity from followed professionals: portfolio items + stories
    const result = await query(
      `SELECT 'portfolio' as feed_type, pi.id, pi.title, pi.description, pi.media_url,
              pi.created_at, u.name as professional_name, u.avatar_url, p.id as professional_id
       FROM follows f
       JOIN users u ON f.following_id = u.id
       JOIN professionals p ON p.user_id = u.id
       JOIN portfolio_items pi ON pi.professional_id = p.id
       WHERE f.follower_id = $1
       UNION ALL
       SELECT 'story' as feed_type, s.id, s.text_overlay as title, s.cta_label as description, s.media_url,
              s.created_at, u.name as professional_name, u.avatar_url, p.id as professional_id
       FROM follows f
       JOIN users u ON f.following_id = u.id
       JOIN professionals p ON p.user_id = u.id
       JOIN stories s ON s.professional_id = u.id AND s.expires_at > NOW()
       WHERE f.follower_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    res.status(200).json({ success: true, data: result.rows, page, limit });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  followProfessional,
  unfollowProfessional,
  getFollowing,
  checkFollow,
  getFeed,
};
