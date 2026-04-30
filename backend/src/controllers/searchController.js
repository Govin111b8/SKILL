const { query } = require('../config/database');

const search = async (req, res, next) => {
  try {
    const {
      q,
      category_id,
      min_rating,
      max_price,
      latitude,
      longitude,
      radius_km,
      availability,
      sort_by = 'reputation',
      page = 1,
      limit = 20,
    } = req.query;

    // Save search to history if user is authenticated and has a query
    if (req.user && q && q.trim()) {
      query(
        `INSERT INTO search_history (user_id, query_text, filters_json) VALUES ($1, $2, $3)`,
        [req.user.id, q.trim().substring(0, 255), JSON.stringify({ category_id, availability, sort_by })]
      ).catch(() => {});
    }

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const params = [];
    const conditions = [];
    let paramIndex = 1;

    // Base query
    let selectClause = `
      SELECT p.*, u.name, u.location, u.email, u.government_id_verified,
             COALESCE(AVG(r.rating), 0) as average_rating,
             COUNT(DISTINCT r.id) as review_count
    `;

    // Add distance calculation if coordinates provided
    if (latitude && longitude) {
      selectClause += `,
        (6371 * acos(cos(radians($${paramIndex})) * cos(radians(p.latitude))
        * cos(radians(p.longitude) - radians($${paramIndex + 1}))
        + sin(radians($${paramIndex})) * sin(radians(p.latitude)))) AS distance
      `;
      params.push(parseFloat(latitude), parseFloat(longitude));
      paramIndex += 2;
    }

    let fromClause = `
      FROM professionals p
      JOIN users u ON p.user_id = u.id
      LEFT JOIN reviews r ON p.id = r.professional_id
    `;

    // Category filter
    if (category_id) {
      fromClause += ` JOIN professional_categories pc ON p.id = pc.professional_id`;
      conditions.push(`pc.category_id = $${paramIndex}`);
      params.push(category_id);
      paramIndex++;
    }

    // Text search — escape special LIKE/ILIKE characters to prevent pattern injection
    if (q) {
      const escapedQ = q.replace(/[%_\\]/g, '\\$&');
      conditions.push(
        `(u.name ILIKE $${paramIndex} OR p.headline ILIKE $${paramIndex} OR p.bio ILIKE $${paramIndex})`
      );
      params.push(`%${escapedQ}%`);
      paramIndex++;
    }

    // Max price filter
    if (max_price) {
      conditions.push(`p.pricing_estimate <= $${paramIndex}`);
      params.push(parseFloat(max_price));
      paramIndex++;
    }

    // Availability filter
    if (availability) {
      conditions.push(`p.availability_status = $${paramIndex}`);
      params.push(availability);
      paramIndex++;
    }

    // Distance filter
    if (latitude && longitude && radius_km) {
      conditions.push(`
        (6371 * acos(cos(radians($${paramIndex})) * cos(radians(p.latitude))
        * cos(radians(p.longitude) - radians($${paramIndex + 1}))
        + sin(radians($${paramIndex})) * sin(radians(p.latitude)))) <= $${paramIndex + 2}
      `);
      params.push(parseFloat(latitude), parseFloat(longitude), parseFloat(radius_km));
      paramIndex += 3;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const groupByClause = `GROUP BY p.id, u.name, u.location, u.email, u.government_id_verified`;

    // Having clause for min rating
    let havingClause = '';
    if (min_rating) {
      havingClause = `HAVING COALESCE(AVG(r.rating), 0) >= $${paramIndex}`;
      params.push(parseFloat(min_rating));
      paramIndex++;
    }

    // Sort
    let orderClause = 'ORDER BY ';
    switch (sort_by) {
      case 'distance':
        orderClause += latitude && longitude ? 'distance ASC' : 'p.created_at DESC';
        break;
      case 'experience':
        orderClause += 'p.years_of_experience DESC';
        break;
      case 'rating':
        orderClause += 'average_rating DESC';
        break;
      case 'response_time':
        orderClause += 'p.response_time_hours ASC NULLS LAST';
        break;
      case 'reputation':
      default:
        orderClause += 'average_rating DESC, review_count DESC';
        break;
    }

    // Count query
    const countQuery = `SELECT COUNT(*) FROM (${selectClause} ${fromClause} ${whereClause} ${groupByClause} ${havingClause}) as filtered`;
    const countResult = await query(countQuery, params);
    const total = parseInt(countResult.rows[0].count);

    // Main query with pagination
    params.push(parseInt(limit), offset);
    const mainQuery = `${selectClause} ${fromClause} ${whereClause} ${groupByClause} ${havingClause} ${orderClause} LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    const result = await query(mainQuery, params);

    res.status(200).json({
      success: true,
      data: result.rows.map((row) => ({
        ...row,
        average_rating: parseFloat(row.average_rating),
        distance: row.distance ? parseFloat(row.distance.toFixed(2)) : undefined,
      })),
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

// Get recent search history for autocomplete
const searchHistory = async (req, res, next) => {
  try {
    const r = await query(
      `SELECT DISTINCT ON (query_text) query_text, created_at
       FROM search_history WHERE user_id = $1
       ORDER BY query_text, created_at DESC
       LIMIT 10`,
      [req.user.id]
    );
    res.json({ success: true, data: r.rows.map(row => row.query_text) });
  } catch (e) { next(e); }
};

// Clear search history
const clearHistory = async (req, res, next) => {
  try {
    await query('DELETE FROM search_history WHERE user_id = $1', [req.user.id]);
    res.json({ success: true });
  } catch (e) { next(e); }
};

module.exports = { search, searchHistory, clearHistory };
