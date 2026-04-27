const crypto = require('crypto');
const { query } = require('../config/database');

const createProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const {
      headline,
      bio,
      years_of_experience,
      pricing_estimate,
      service_location_radius_km,
      latitude,
      longitude,
      category_ids,
    } = req.body;

    // Check if profile already exists
    const existing = await query(
      'SELECT id FROM professionals WHERE user_id = $1',
      [userId]
    );
    if (existing.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Professional profile already exists.',
      });
    }

    const id = crypto.randomUUID();
    const result = await query(
      `INSERT INTO professionals (id, user_id, headline, bio, years_of_experience, pricing_estimate, service_location_radius_km, latitude, longitude, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
       RETURNING *`,
      [id, userId, headline, bio, years_of_experience, pricing_estimate, service_location_radius_km, latitude, longitude]
    );

    // Associate categories
    if (category_ids && category_ids.length > 0) {
      const categoryValues = category_ids
        .map((catId, idx) => `($${idx * 2 + 1}, $${idx * 2 + 2})`)
        .join(', ');
      const categoryParams = category_ids.flatMap((catId) => [id, catId]);
      await query(
        `INSERT INTO professional_categories (professional_id, category_id) VALUES ${categoryValues}`,
        categoryParams
      );
    }

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'Professional profile created successfully.',
    });
  } catch (error) {
    next(error);
  }
};

const getProfile = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT p.*, u.name, u.email, u.phone, u.location,
              COALESCE(AVG(r.rating), 0) as average_rating,
              COUNT(r.id) as review_count
       FROM professionals p
       JOIN users u ON p.user_id = u.id
       LEFT JOIN reviews r ON p.id = r.professional_id
       WHERE p.id = $1
       GROUP BY p.id, u.name, u.email, u.phone, u.location`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Professional profile not found.',
      });
    }

    // Get categories
    const categories = await query(
      `SELECT c.id, c.name FROM categories c
       JOIN professional_categories pc ON c.id = pc.category_id
       WHERE pc.professional_id = $1`,
      [id]
    );

    const professional = {
      ...result.rows[0],
      average_rating: parseFloat(result.rows[0].average_rating),
      categories: categories.rows,
    };

    res.status(200).json({
      success: true,
      data: professional,
    });
  } catch (error) {
    next(error);
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Verify ownership
    const existing = await query(
      'SELECT id FROM professionals WHERE id = $1 AND user_id = $2',
      [id, userId]
    );
    if (existing.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'You can only update your own profile.',
      });
    }

    const {
      headline,
      bio,
      years_of_experience,
      pricing_estimate,
      service_location_radius_km,
      latitude,
      longitude,
      category_ids,
    } = req.body;

    const result = await query(
      `UPDATE professionals
       SET headline = COALESCE($1, headline),
           bio = COALESCE($2, bio),
           years_of_experience = COALESCE($3, years_of_experience),
           pricing_estimate = COALESCE($4, pricing_estimate),
           service_location_radius_km = COALESCE($5, service_location_radius_km),
           latitude = COALESCE($6, latitude),
           longitude = COALESCE($7, longitude),
           updated_at = NOW()
       WHERE id = $8
       RETURNING *`,
      [headline, bio, years_of_experience, pricing_estimate, service_location_radius_km, latitude, longitude, id]
    );

    // Update categories if provided
    if (category_ids && category_ids.length > 0) {
      await query('DELETE FROM professional_categories WHERE professional_id = $1', [id]);
      const categoryValues = category_ids
        .map((catId, idx) => `($${idx * 2 + 1}, $${idx * 2 + 2})`)
        .join(', ');
      const categoryParams = category_ids.flatMap((catId) => [id, catId]);
      await query(
        `INSERT INTO professional_categories (professional_id, category_id) VALUES ${categoryValues}`,
        categoryParams
      );
    }

    res.status(200).json({
      success: true,
      data: result.rows[0],
      message: 'Profile updated successfully.',
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { createProfile, getProfile, updateProfile };
