const { query } = require('../config/database');

/**
 * GET /api/storefront/:id
 * Public — aggregates professional profile, storefront fields, portfolio, reviews & rating distribution.
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

    res.status(200).json({
      success: true,
      data: {
        ...professional,
        average_rating: parseFloat(professional.average_rating),
        categories: categories.rows,
        portfolio: portfolio.rows,
        reviews: reviews.rows,
        rating_distribution: distribution,
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
    } = req.body;

    const result = await query(
      `UPDATE professionals
       SET announcement = COALESCE($1, announcement),
           whatsapp_number = COALESCE($2, whatsapp_number),
           instagram_handle = COALESCE($3, instagram_handle),
           website_url = COALESCE($4, website_url),
           cover_image_url = COALESCE($5, cover_image_url),
           accent_color = COALESCE($6, accent_color),
           show_rating = COALESCE($7, show_rating),
           return_policy = COALESCE($8, return_policy),
           operating_hours = COALESCE($9, operating_hours),
           operating_days = COALESCE($10, operating_days),
           updated_at = NOW()
       WHERE id = $11
       RETURNING *`,
      [announcement, whatsapp_number, instagram_handle, website_url, cover_image_url, accent_color, show_rating, return_policy, operating_hours, operating_days, id]
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

module.exports = { getStorefront, updateStorefront };
