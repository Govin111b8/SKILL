const { query } = require('../config/database');

/**
 * GET /api/reels/feed
 * Public — paginated reels feed from storefront_media of type 'reel'.
 */
const getReelsFeed = async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(20, parseInt(req.query.limit) || 10);
    const offset = (page - 1) * limit;
    const { category } = req.query;

    let sql = `
      SELECT sm.id, sm.media_url, sm.thumbnail_url, sm.caption, sm.created_at,
             p.id as professional_id, u.name as professional_name, u.avatar_url,
             p.headline, u.location,
             COALESCE(AVG(r.rating), 0) as average_rating
      FROM storefront_media sm
      JOIN professionals p ON sm.storefront_id = p.id
      JOIN users u ON p.user_id = u.id
      LEFT JOIN reviews r ON r.professional_id = p.id
    `;
    const params = [];

    if (category) {
      sql += `
        JOIN professional_categories pc ON pc.professional_id = p.id
        JOIN categories c ON c.id = pc.category_id AND c.name ILIKE $1
      `;
      params.push(`%${category}%`);
    }

    sql += ` WHERE sm.type = 'reel'`;

    sql += `
      GROUP BY sm.id, sm.media_url, sm.thumbnail_url, sm.caption, sm.created_at,
               p.id, u.name, u.avatar_url, p.headline, u.location
      ORDER BY sm.created_at DESC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2}
    `;
    params.push(limit, offset);

    const result = await query(sql, params);

    res.status(200).json({
      success: true,
      data: result.rows.map((row) => ({
        ...row,
        average_rating: parseFloat(row.average_rating),
      })),
      page,
      limit,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getReelsFeed,
};
