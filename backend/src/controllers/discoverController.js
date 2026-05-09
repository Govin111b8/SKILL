const { query } = require('../config/database');

/**
 * GET /api/discover/trending
 * Public — most-booked professionals this week.
 */
const getTrending = async (req, res, next) => {
  try {
    const limit = Math.min(20, parseInt(req.query.limit) || 10);
    const category = req.query.category;

    let sql = `
      SELECT p.id, u.name, u.avatar_url, u.location, p.headline, p.completed_jobs,
             p.availability_status, p.response_time_hours,
             COALESCE(AVG(r.rating), 0) as average_rating,
             COUNT(DISTINCT r.id)::int as review_count
      FROM professionals p
      JOIN users u ON p.user_id = u.id
      LEFT JOIN reviews r ON r.professional_id = p.id
    `;
    const params = [];

    if (category) {
      sql += ` JOIN professional_categories pc ON pc.professional_id = p.id
               JOIN categories c ON c.id = pc.category_id AND c.name ILIKE $1`;
      params.push(`%${category}%`);
    }

    sql += ` GROUP BY p.id, u.name, u.avatar_url, u.location, p.headline, p.completed_jobs,
                      p.availability_status, p.response_time_hours
             ORDER BY p.completed_jobs DESC, average_rating DESC
             LIMIT $${params.length + 1}`;
    params.push(limit);

    const result = await query(sql, params);

    res.status(200).json({
      success: true,
      data: result.rows.map((row) => ({
        ...row,
        average_rating: parseFloat(row.average_rating),
      })),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/discover/new
 * Public — recently verified professionals.
 */
const getNewlyVerified = async (req, res, next) => {
  try {
    const limit = Math.min(20, parseInt(req.query.limit) || 10);

    const result = await query(
      `SELECT p.id, u.name, u.avatar_url, u.location, p.headline, p.completed_jobs,
              p.availability_status, p.created_at,
              COALESCE(AVG(r.rating), 0) as average_rating,
              COUNT(r.id)::int as review_count
       FROM professionals p
       JOIN users u ON p.user_id = u.id AND u.government_id_verified = true
       LEFT JOIN reviews r ON r.professional_id = p.id
       GROUP BY p.id, u.name, u.avatar_url, u.location, p.headline, p.completed_jobs,
                p.availability_status, p.created_at
       ORDER BY p.created_at DESC
       LIMIT $1`,
      [limit]
    );

    res.status(200).json({
      success: true,
      data: result.rows.map((row) => ({
        ...row,
        average_rating: parseFloat(row.average_rating),
      })),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/discover/responsive
 * Public — professionals with fastest response times.
 */
const getHighlyResponsive = async (req, res, next) => {
  try {
    const limit = Math.min(20, parseInt(req.query.limit) || 10);

    const result = await query(
      `SELECT p.id, u.name, u.avatar_url, u.location, p.headline, p.completed_jobs,
              p.availability_status, p.response_time_hours,
              COALESCE(AVG(r.rating), 0) as average_rating,
              COUNT(r.id)::int as review_count
       FROM professionals p
       JOIN users u ON p.user_id = u.id
       LEFT JOIN reviews r ON r.professional_id = p.id
       WHERE p.response_time_hours IS NOT NULL AND p.response_time_hours > 0
       GROUP BY p.id, u.name, u.avatar_url, u.location, p.headline, p.completed_jobs,
                p.availability_status, p.response_time_hours
       ORDER BY p.response_time_hours ASC
       LIMIT $1`,
      [limit]
    );

    res.status(200).json({
      success: true,
      data: result.rows.map((row) => ({
        ...row,
        average_rating: parseFloat(row.average_rating),
      })),
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getTrending,
  getNewlyVerified,
  getHighlyResponsive,
};
