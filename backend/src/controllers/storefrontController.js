const { query } = require('../config/database');
const logger = require('../config/logger');

/**
 * GET /api/storefront/:id
 * Public — aggregates professional profile, storefront fields, portfolio,
 * reviews, rating distribution, theme, badges, media, packages, and follow count.
 */
const getStorefront = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Profile + storefront fields
    const profileResult = await query(
      `SELECT p.*, u.name, u.email, u.phone, u.location, u.avatar_url,
              COALESCE(AVG(r.rating), 0) as average_rating,
              COUNT(r.id) as review_count
       FROM professionals p
       JOIN users u ON p.user_id = u.id
       LEFT JOIN reviews r ON p.id = r.professional_id
       WHERE p.id = $1
       GROUP BY p.id, u.name, u.email, u.phone, u.location, u.avatar_url`,
      [id]
    );

    if (profileResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Professional not found.' });
    }

    const professional = profileResult.rows[0];

    // Categories
    const categories = await query(
      `SELECT c.id, c.name FROM categories c
       JOIN professional_categories pc ON c.id = pc.category_id
       WHERE pc.professional_id = $1`,
      [id]
    );

    // Portfolio
    const portfolio = await query(
      `SELECT id, title, description, media_type, media_url, created_at
       FROM portfolio_items
       WHERE professional_id = $1
       ORDER BY created_at DESC`,
      [id]
    );

    // Reviews (latest 20)
    const reviews = await query(
      `SELECT r.id, r.rating, r.comment, r.created_at, u.name as reviewer_name, u.avatar_url as reviewer_avatar
       FROM reviews r
       JOIN users u ON r.customer_id = u.id
       WHERE r.professional_id = $1
       ORDER BY r.created_at DESC
       LIMIT 20`,
      [id]
    );

    // Rating distribution
    const ratingDist = await query(
      `SELECT rating, COUNT(*)::int as count
       FROM reviews
       WHERE professional_id = $1
       GROUP BY rating
       ORDER BY rating DESC`,
      [id]
    );

    const distribution = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    ratingDist.rows.forEach((row) => {
      distribution[row.rating] = row.count;
    });

    // Theme (best-effort — table may not exist yet)
    let theme = null;
    try {
      const themeResult = await query(
        'SELECT * FROM storefront_themes WHERE storefront_id = $1',
        [id]
      );
      theme = themeResult.rows[0] || null;
    } catch (err) { logger.warn({ err: err.message, id }, 'Storefront theme query failed'); }

    // Storefront media (best-effort)
    let media = [];
    try {
      const mediaResult = await query(
        `SELECT id, type, media_url, thumbnail_url, caption, before_url, sort_order, created_at
         FROM storefront_media
         WHERE storefront_id = $1
         ORDER BY sort_order ASC, created_at DESC`,
        [id]
      );
      media = mediaResult.rows;
    } catch (err) { logger.warn({ err: err.message, id }, 'Storefront media query failed'); }

    // Service packages (best-effort)
    let packages = [];
    try {
      const pkgResult = await query(
        `SELECT id, name, tier, price, description, features, is_popular, sort_order
         FROM service_packages
         WHERE professional_id = $1
         ORDER BY sort_order ASC`,
        [id]
      );
      packages = pkgResult.rows;
    } catch (err) { logger.warn({ err: err.message, id }, 'Service packages query failed'); }

    // Badges (best-effort)
    let badges = [];
    try {
      const badgeResult = await query(
        'SELECT badge_type, earned_at, metadata FROM professional_badges WHERE professional_id = $1',
        [id]
      );
      badges = badgeResult.rows;
    } catch (err) { logger.warn({ err: err.message, id }, 'Badges query failed'); }

    // Follower count (best-effort)
    let follower_count = 0;
    try {
      const followResult = await query(
        'SELECT COUNT(*)::int as count FROM follows WHERE following_id = (SELECT user_id FROM professionals WHERE id = $1)',
        [id]
      );
      follower_count = followResult.rows[0]?.count || 0;
    } catch (err) { logger.warn({ err: err.message, id }, 'Follower count query failed'); }

    res.status(200).json({
      success: true,
      data: {
        ...professional,
        average_rating: parseFloat(professional.average_rating),
        categories: categories.rows,
        portfolio: portfolio.rows,
        reviews: reviews.rows,
        rating_distribution: distribution,
        theme,
        media,
        packages,
        badges,
        follower_count,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/storefront/:id
 * Auth required — owner only. Updates storefront-specific fields.
 */
const updateStorefront = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Verify ownership
    const existing = await query(
      'SELECT id FROM professionals WHERE id = $1 AND user_id = $2',
      [id, userId]
    );
    if (existing.rows.length === 0) {
      return res.status(403).json({ success: false, message: 'You can only update your own storefront.' });
    }

    const {
      announcement,
      whatsapp_number,
      instagram_handle,
      website_url,
      cover_image_url,
      accent_color,
      show_rating,
      return_policy,
      operating_hours,
      operating_days,
      tagline,
      intro_video_url,
    } = req.body;

    // Use undefined check (not COALESCE) so empty strings can clear fields
    const fields = { announcement, whatsapp_number, instagram_handle, website_url, cover_image_url, accent_color, show_rating, return_policy, operating_hours, operating_days, tagline, intro_video_url };
    const setClauses = [];
    const values = [];
    let paramIndex = 1;

    for (const [key, value] of Object.entries(fields)) {
      if (value !== undefined) {
        setClauses.push(`${key} = $${paramIndex}`);
        values.push(value);
        paramIndex++;
      }
    }

    if (setClauses.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields to update.' });
    }

    setClauses.push('updated_at = NOW()');
    values.push(id);

    const result = await query(
      `UPDATE professionals SET ${setClauses.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    res.status(200).json({
      success: true,
      data: result.rows[0],
      message: 'Storefront updated successfully.',
    });
  } catch (error) {
    next(error);
  }
};

// ── Storefront Media CRUD ──────────────────────────────────

/**
 * POST /api/storefront/:id/media
 * Auth required — owner only. Add media item to storefront.
 */
const addMedia = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const existing = await query('SELECT id FROM professionals WHERE id = $1 AND user_id = $2', [id, userId]);
    if (existing.rows.length === 0) {
      return res.status(403).json({ success: false, message: 'You can only update your own storefront.' });
    }

    const { type, media_url, thumbnail_url, caption, before_url, sort_order } = req.body;

    const result = await query(
      `INSERT INTO storefront_media (storefront_id, type, media_url, thumbnail_url, caption, before_url, sort_order)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [id, type || 'gallery', media_url, thumbnail_url || null, caption || null, before_url || null, sort_order || 0]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/storefront/:id/media/:mediaId
 * Auth required — owner only.
 */
const deleteMedia = async (req, res, next) => {
  try {
    const { id, mediaId } = req.params;
    const userId = req.user.id;

    const existing = await query('SELECT id FROM professionals WHERE id = $1 AND user_id = $2', [id, userId]);
    if (existing.rows.length === 0) {
      return res.status(403).json({ success: false, message: 'You can only update your own storefront.' });
    }

    await query('DELETE FROM storefront_media WHERE id = $1 AND storefront_id = $2', [mediaId, id]);
    res.status(200).json({ success: true, message: 'Media deleted.' });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/storefront/:id/media
 * Public — list storefront media with optional type filter.
 */
const getMedia = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { type } = req.query;
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(50, parseInt(req.query.limit) || 20);
    const offset = (page - 1) * limit;

    let sql = 'SELECT * FROM storefront_media WHERE storefront_id = $1';
    const params = [id];

    if (type) {
      sql += ' AND type = $2';
      params.push(type);
    }

    sql += ' ORDER BY sort_order ASC, created_at DESC LIMIT $' + (params.length + 1) + ' OFFSET $' + (params.length + 2);
    params.push(limit, offset);

    const result = await query(sql, params);
    res.status(200).json({ success: true, data: result.rows, page, limit });
  } catch (error) {
    next(error);
  }
};

// ── Theme ──────────────────────────────────────────────────

/**
 * PUT /api/storefront/:id/theme
 * Auth required — owner only. Upsert storefront theme.
 */
const updateTheme = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const existing = await query('SELECT id FROM professionals WHERE id = $1 AND user_id = $2', [id, userId]);
    if (existing.rows.length === 0) {
      return res.status(403).json({ success: false, message: 'You can only update your own storefront.' });
    }

    const { theme_name, primary_color, accent_color, layout, section_order, custom_intro } = req.body;

    const result = await query(
      `INSERT INTO storefront_themes (storefront_id, theme_name, primary_color, accent_color, layout, section_order, custom_intro, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
       ON CONFLICT (storefront_id)
       DO UPDATE SET
         theme_name = COALESCE($2, storefront_themes.theme_name),
         primary_color = COALESCE($3, storefront_themes.primary_color),
         accent_color = COALESCE($4, storefront_themes.accent_color),
         layout = COALESCE($5, storefront_themes.layout),
         section_order = COALESCE($6, storefront_themes.section_order),
         custom_intro = COALESCE($7, storefront_themes.custom_intro),
         updated_at = NOW()
       RETURNING *`,
      [
        id,
        theme_name || 'modern',
        primary_color || '#6366F1',
        accent_color || '#8B5CF6',
        layout || 'centered',
        section_order ? JSON.stringify(section_order) : null,
        custom_intro || null,
      ]
    );

    res.status(200).json({ success: true, data: result.rows[0], message: 'Theme updated.' });
  } catch (error) {
    next(error);
  }
};

// ── Service Packages ───────────────────────────────────────

/**
 * GET /api/storefront/:id/packages
 * Public — list service packages.
 */
const getPackages = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      'SELECT * FROM service_packages WHERE professional_id = $1 ORDER BY sort_order ASC',
      [id]
    );
    res.status(200).json({ success: true, data: result.rows });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/storefront/:id/packages
 * Auth required — owner only.
 */
const addPackage = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const existing = await query('SELECT id FROM professionals WHERE id = $1 AND user_id = $2', [id, userId]);
    if (existing.rows.length === 0) {
      return res.status(403).json({ success: false, message: 'You can only update your own storefront.' });
    }

    const { name, tier, price, description, features, is_popular, sort_order } = req.body;

    const result = await query(
      `INSERT INTO service_packages (professional_id, name, tier, price, description, features, is_popular, sort_order)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [id, name, tier || 'standard', price || null, description || null, features ? JSON.stringify(features) : '[]', is_popular || false, sort_order || 0]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/storefront/:id/packages/:packageId
 */
const deletePackage = async (req, res, next) => {
  try {
    const { id, packageId } = req.params;
    const userId = req.user.id;

    const existing = await query('SELECT id FROM professionals WHERE id = $1 AND user_id = $2', [id, userId]);
    if (existing.rows.length === 0) {
      return res.status(403).json({ success: false, message: 'You can only update your own storefront.' });
    }

    await query('DELETE FROM service_packages WHERE id = $1 AND professional_id = $2', [packageId, id]);
    res.status(200).json({ success: true, message: 'Package deleted.' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getStorefront,
  updateStorefront,
  addMedia,
  deleteMedia,
  getMedia,
  updateTheme,
  getPackages,
  addPackage,
  deletePackage,
};
