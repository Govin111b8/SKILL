const { query } = require('../config/database');

// List user's favorites
const listFavorites = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const result = await query(
      `SELECT f.created_at AS favorited_at, p.id, p.headline, p.pricing_estimate,
              p.reputation_score, p.availability_status, u.name, u.avatar_url, u.location,
              COALESCE(AVG(r.rating), 0)::float AS avg_rating,
              COUNT(r.id)::int AS review_count
       FROM favorites f
       JOIN professionals p ON f.professional_id = p.id
       JOIN users u ON p.user_id = u.id
       LEFT JOIN reviews r ON r.professional_id = p.id
       WHERE f.user_id = $1
       GROUP BY f.created_at, p.id, u.name, u.avatar_url, u.location
       ORDER BY f.created_at DESC`,
      [userId]
    );
    res.json({ success: true, data: result.rows });
  } catch (error) {
    next(error);
  }
};

// Toggle favorite (add or remove)
const toggleFavorite = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { professional_id } = req.body;

    if (!professional_id) {
      return res.status(400).json({ success: false, message: 'professional_id is required' });
    }

    // Check if already favorited
    const existing = await query(
      `SELECT 1 FROM favorites WHERE user_id = $1 AND professional_id = $2`,
      [userId, professional_id]
    );

    if (existing.rows.length > 0) {
      // Remove
      await query(
        `DELETE FROM favorites WHERE user_id = $1 AND professional_id = $2`,
        [userId, professional_id]
      );
      return res.json({ success: true, favorited: false, message: 'Removed from favorites' });
    }

    // Add
    await query(
      `INSERT INTO favorites (user_id, professional_id) VALUES ($1, $2)`,
      [userId, professional_id]
    );
    res.json({ success: true, favorited: true, message: 'Added to favorites' });
  } catch (error) {
    next(error);
  }
};

// Check if a professional is favorited
const checkFavorite = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { professionalId } = req.params;
    const result = await query(
      `SELECT 1 FROM favorites WHERE user_id = $1 AND professional_id = $2`,
      [userId, professionalId]
    );
    res.json({ success: true, favorited: result.rows.length > 0 });
  } catch (error) {
    next(error);
  }
};

module.exports = { listFavorites, toggleFavorite, checkFavorite };
