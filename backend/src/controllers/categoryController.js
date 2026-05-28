const { query } = require('../config/database');

const getCategories = async (req, res, next) => {
  try {
    // Include professional counts per category + service metadata
    const result = await query(
      `SELECT c.id, c.name, c.parent_id, c.description, c.icon,
              c.service_mode, c.default_pricing_type, c.hsn_code,
              c.women_only_option, c.requires_site_visit,
              c.typical_duration_hours, c.sort_priority,
              COUNT(DISTINCT pc.professional_id)::int AS pro_count
       FROM categories c
       LEFT JOIN professional_categories pc ON pc.category_id = c.id
       GROUP BY c.id ORDER BY c.sort_priority DESC, c.name`
    );

    const categories = result.rows;
    const categoryMap = {};
    const roots = [];

    categories.forEach((cat) => {
      categoryMap[cat.id] = { ...cat, children: [] };
    });

    categories.forEach((cat) => {
      if (cat.parent_id && categoryMap[cat.parent_id]) {
        categoryMap[cat.parent_id].children.push(categoryMap[cat.id]);
        // Roll up pro_count to parent
        categoryMap[cat.parent_id].pro_count = (categoryMap[cat.parent_id].pro_count || 0) + (cat.pro_count || 0);
      } else {
        roots.push(categoryMap[cat.id]);
      }
    });

    res.status(200).json({
      success: true,
      data: roots,
    });
  } catch (error) {
    next(error);
  }
};


const getCategory = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT c.id, c.name, c.parent_id, c.description, c.icon,
              c.service_mode, c.default_pricing_type, c.hsn_code,
              c.women_only_option, c.requires_site_visit,
              c.typical_duration_hours, c.sort_priority,
              COUNT(DISTINCT pc.professional_id)::int AS pro_count
       FROM categories c
       LEFT JOIN professional_categories pc ON pc.category_id = c.id
       WHERE c.id = $1
       GROUP BY c.id`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Category not found.' });
    }

    // Get subcategories with pro counts and service metadata
    const subcategories = await query(
      `SELECT c.id, c.name, c.description, c.icon,
              c.service_mode, c.default_pricing_type, c.requires_site_visit,
              c.women_only_option, c.sort_priority,
              COUNT(DISTINCT pc.professional_id)::int AS pro_count
       FROM categories c
       LEFT JOIN professional_categories pc ON pc.category_id = c.id
       WHERE c.parent_id = $1
       GROUP BY c.id ORDER BY c.sort_priority DESC, c.name`,
      [id]
    );

    // Parent category (if this is a subcategory)
    let parent = null;
    if (result.rows[0].parent_id) {
      const pr = await query('SELECT id, name FROM categories WHERE id = $1', [result.rows[0].parent_id]);
      parent = pr.rows[0] || null;
    }

    res.status(200).json({
      success: true,
      data: { ...result.rows[0], subcategories: subcategories.rows, parent },
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/categories/:id/professionals  — top-rated pros in a category (or its subcategories)
const getCategoryProfessionals = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { sort_by = 'rating', limit = 20, page = 1, availability } = req.query;
    const pageNum = Math.max(1, parseInt(page) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit) || 20));
    const offset = (pageNum - 1) * limitNum;

    // Include pros from this category AND any subcategories
    let orderClause;
    switch (sort_by) {
      case 'price_asc':  orderClause = 'p.pricing_estimate ASC NULLS LAST'; break;
      case 'price_desc': orderClause = 'p.pricing_estimate DESC NULLS LAST'; break;
      case 'jobs':       orderClause = 'p.completed_jobs DESC'; break;
      case 'newest':     orderClause = 'p.created_at DESC'; break;
      default:           orderClause = 'COALESCE(AVG(r.rating),0) DESC, p.completed_jobs DESC';
    }

    const params = [parseInt(id), limitNum, offset];
    let availFilter = '';
    if (availability) {
      availFilter = `AND p.availability_status = $${params.length + 1}`;
      params.push(availability);
    }

    const rows = await query(
      `SELECT p.*, u.name, u.location, u.government_id_verified,
              COALESCE(AVG(r.rating), 0)::float AS average_rating,
              COUNT(DISTINCT r.id)::int AS review_count,
              MAX(cat.name) AS primary_category
       FROM professionals p
       JOIN users u ON p.user_id = u.id
       JOIN professional_categories pc ON pc.professional_id = p.id
       JOIN categories cat ON cat.id = pc.category_id
       LEFT JOIN reviews r ON r.professional_id = p.id
       WHERE (pc.category_id = $1 OR EXISTS (
         SELECT 1 FROM categories sub WHERE sub.id = pc.category_id AND sub.parent_id = $1
       )) ${availFilter}
       GROUP BY p.id, u.name, u.location, u.government_id_verified
       ORDER BY ${orderClause}
       LIMIT $2 OFFSET $3`,
      params
    );

    const countRow = await query(
      `SELECT COUNT(DISTINCT p.id)::int AS total
       FROM professionals p
       JOIN professional_categories pc ON pc.professional_id = p.id
       WHERE pc.category_id = $1 OR EXISTS (
         SELECT 1 FROM categories sub WHERE sub.id = pc.category_id AND sub.parent_id = $1
       )`,
      [parseInt(id)]
    );

    res.status(200).json({
      success: true,
      data: rows.rows,
      pagination: { total: countRow.rows[0].total, page: pageNum, limit: limitNum },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { getCategories, getCategory, getCategoryProfessionals };
