const crypto = require('crypto');
const { query } = require('../config/database');

const getServices = async (req, res, next) => {
  try {
    const { professionalId } = req.params;

    const result = await query(
      `SELECT ps.*, c.name AS category_name
       FROM professional_services ps
       LEFT JOIN categories c ON ps.category_id = c.id
       WHERE ps.professional_id = $1 AND ps.is_active = true
       ORDER BY ps.sort_order ASC, ps.created_at DESC`,
      [professionalId]
    );

    res.status(200).json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    next(error);
  }
};

const addService = async (req, res, next) => {
  try {
    const { professionalId } = req.params;
    const userId = req.user.id;

    // Check ownership
    const prof = await query('SELECT id FROM professionals WHERE id = $1 AND user_id = $2', [professionalId, userId]);
    if (prof.rows.length === 0) {
      return res.status(403).json({ success: false, message: 'Not authorized to manage services for this professional.' });
    }

    const { name, description, category_id, price_min, price_max, duration_minutes } = req.body;

    // Validate required fields
    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, message: 'Service name is required.' });
    }
    if (price_min !== undefined && price_min !== null && Number(price_min) < 0) {
      return res.status(400).json({ success: false, message: 'price_min must be >= 0.' });
    }
    if (duration_minutes !== undefined && duration_minutes !== null && Number(duration_minutes) <= 0) {
      return res.status(400).json({ success: false, message: 'duration_minutes must be > 0.' });
    }

    const id = crypto.randomUUID();

    const result = await query(
      `INSERT INTO professional_services (id, professional_id, category_id, name, description, price_min, price_max, duration_minutes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [id, professionalId, category_id || null, name.trim(), description || null, price_min || null, price_max || null, duration_minutes || null]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'Service added successfully.',
    });
  } catch (error) {
    next(error);
  }
};

const updateService = async (req, res, next) => {
  try {
    const { serviceId } = req.params;
    const userId = req.user.id;

    // Verify ownership
    const ownership = await query(
      `SELECT ps.id FROM professional_services ps
       JOIN professionals p ON ps.professional_id = p.id
       WHERE ps.id = $1 AND p.user_id = $2`,
      [serviceId, userId]
    );
    if (ownership.rows.length === 0) {
      return res.status(403).json({ success: false, message: 'You can only update your own services.' });
    }

    const { name, description, category_id, price_min, price_max, duration_minutes, is_active, sort_order } = req.body;

    // Validate if provided
    if (name !== undefined && (!name || !name.trim())) {
      return res.status(400).json({ success: false, message: 'Service name cannot be empty.' });
    }
    if (price_min !== undefined && price_min !== null && Number(price_min) < 0) {
      return res.status(400).json({ success: false, message: 'price_min must be >= 0.' });
    }
    if (duration_minutes !== undefined && duration_minutes !== null && Number(duration_minutes) <= 0) {
      return res.status(400).json({ success: false, message: 'duration_minutes must be > 0.' });
    }

    // Build dynamic update
    const fields = [];
    const values = [];
    let idx = 1;

    if (name !== undefined) { fields.push(`name = $${idx++}`); values.push(name.trim()); }
    if (description !== undefined) { fields.push(`description = $${idx++}`); values.push(description); }
    if (category_id !== undefined) { fields.push(`category_id = $${idx++}`); values.push(category_id); }
    if (price_min !== undefined) { fields.push(`price_min = $${idx++}`); values.push(price_min); }
    if (price_max !== undefined) { fields.push(`price_max = $${idx++}`); values.push(price_max); }
    if (duration_minutes !== undefined) { fields.push(`duration_minutes = $${idx++}`); values.push(duration_minutes); }
    if (is_active !== undefined) { fields.push(`is_active = $${idx++}`); values.push(is_active); }
    if (sort_order !== undefined) { fields.push(`sort_order = $${idx++}`); values.push(sort_order); }

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields to update.' });
    }

    fields.push(`updated_at = NOW()`);
    values.push(serviceId);

    const result = await query(
      `UPDATE professional_services SET ${fields.join(', ')} WHERE id = $${idx} RETURNING *`,
      values
    );

    res.status(200).json({
      success: true,
      data: result.rows[0],
      message: 'Service updated successfully.',
    });
  } catch (error) {
    next(error);
  }
};

const deleteService = async (req, res, next) => {
  try {
    const { serviceId } = req.params;
    const userId = req.user.id;

    // Verify ownership
    const ownership = await query(
      `SELECT ps.id FROM professional_services ps
       JOIN professionals p ON ps.professional_id = p.id
       WHERE ps.id = $1 AND p.user_id = $2`,
      [serviceId, userId]
    );
    if (ownership.rows.length === 0) {
      return res.status(403).json({ success: false, message: 'You can only delete your own services.' });
    }

    await query('DELETE FROM professional_services WHERE id = $1', [serviceId]);

    res.status(200).json({
      success: true,
      message: 'Service deleted successfully.',
    });
  } catch (error) {
    next(error);
  }
};

const searchServices = async (req, res, next) => {
  try {
    const searchTerm = req.query.q || '';
    const category = req.query.category || null;
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 20));
    const offset = (page - 1) * limit;

    const conditions = ['ps.is_active = true'];
    const values = [];
    let idx = 1;

    if (searchTerm.trim()) {
      conditions.push(`to_tsvector('english', ps.name) @@ plainto_tsquery('english', $${idx})`);
      values.push(searchTerm.trim());
      idx++;
    }
    if (category) {
      conditions.push(`ps.category_id = $${idx}`);
      values.push(category);
      idx++;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countQuery = `SELECT COUNT(*)::int AS total FROM professional_services ps ${whereClause}`;
    const dataQuery = `
      SELECT ps.*, c.name AS category_name,
             p.business_name AS professional_name, p.avg_rating AS professional_rating,
             p.city AS professional_city
      FROM professional_services ps
      LEFT JOIN categories c ON ps.category_id = c.id
      JOIN professionals p ON ps.professional_id = p.id
      ${whereClause}
      ORDER BY ps.created_at DESC
      LIMIT $${idx} OFFSET $${idx + 1}`;

    const dataValues = [...values, limit, offset];

    const [countResult, dataResult] = await Promise.all([
      query(countQuery, values),
      query(dataQuery, dataValues),
    ]);

    const total_count = countResult.rows[0].total;

    res.status(200).json({
      success: true,
      data: dataResult.rows,
      pagination: {
        page,
        limit,
        total_count,
        total_pages: Math.ceil(total_count / limit),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Add service using authenticated user's professional ID (convenience for onboarding).
 */
const addOwnService = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const prof = await query('SELECT id FROM professionals WHERE user_id = $1', [userId]);
    if (prof.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Professional profile not found.' });
    }
    req.params.professionalId = prof.rows[0].id;
    return addService(req, res, next);
  } catch (error) {
    next(error);
  }
};

module.exports = { getServices, addService, addOwnService, updateService, deleteService, searchServices };
