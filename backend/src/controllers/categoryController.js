const { query } = require('../config/database');

const getCategories = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT id, name, parent_id, description FROM categories ORDER BY name`
    );

    // Build nested structure
    const categories = result.rows;
    const categoryMap = {};
    const roots = [];

    categories.forEach((cat) => {
      categoryMap[cat.id] = { ...cat, children: [] };
    });

    categories.forEach((cat) => {
      if (cat.parent_id && categoryMap[cat.parent_id]) {
        categoryMap[cat.parent_id].children.push(categoryMap[cat.id]);
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
      'SELECT id, name, parent_id, description FROM categories WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Category not found.',
      });
    }

    // Get subcategories
    const subcategories = await query(
      'SELECT id, name, description FROM categories WHERE parent_id = $1 ORDER BY name',
      [id]
    );

    const category = {
      ...result.rows[0],
      subcategories: subcategories.rows,
    };

    res.status(200).json({
      success: true,
      data: category,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { getCategories, getCategory };
