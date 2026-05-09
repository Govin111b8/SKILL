const { query } = require('../config/database');

/**
 * POST /api/collections
 * Auth required — create a new collection.
 */
const createCollection = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { name, is_public } = req.body;

    const result = await query(
      `INSERT INTO collections (user_id, name, is_public) VALUES ($1, $2, $3) RETURNING *`,
      [userId, name, is_public || false]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/collections
 * Auth required — list current user's collections with item counts.
 */
const getCollections = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT c.*, COUNT(ci.id)::int as item_count
       FROM collections c
       LEFT JOIN collection_items ci ON ci.collection_id = c.id
       WHERE c.user_id = $1
       GROUP BY c.id
       ORDER BY c.updated_at DESC`,
      [userId]
    );

    res.status(200).json({ success: true, data: result.rows });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/collections/:id
 * Auth required — get a collection with its items.
 */
const getCollection = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const collection = await query(
      'SELECT * FROM collections WHERE id = $1 AND (user_id = $2 OR is_public = true)',
      [id, userId]
    );

    if (collection.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Collection not found.' });
    }

    // Get items with professional details
    const items = await query(
      `SELECT ci.*, p.headline, u.name as professional_name, u.avatar_url, u.location,
              COALESCE(AVG(r.rating), 0) as average_rating
       FROM collection_items ci
       LEFT JOIN professionals p ON ci.item_type = 'professional' AND ci.item_id = p.id
       LEFT JOIN users u ON p.user_id = u.id
       LEFT JOIN reviews r ON r.professional_id = p.id
       WHERE ci.collection_id = $1
       GROUP BY ci.id, p.headline, u.name, u.avatar_url, u.location
       ORDER BY ci.added_at DESC`,
      [id]
    );

    res.status(200).json({
      success: true,
      data: {
        ...collection.rows[0],
        items: items.rows.map((row) => ({
          ...row,
          average_rating: parseFloat(row.average_rating),
        })),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/collections/:id/items
 * Auth required — add an item to a collection.
 */
const addItem = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { item_type, item_id } = req.body;

    // Verify ownership
    const col = await query('SELECT id FROM collections WHERE id = $1 AND user_id = $2', [id, userId]);
    if (col.rows.length === 0) {
      return res.status(403).json({ success: false, message: 'Not your collection.' });
    }

    const result = await query(
      `INSERT INTO collection_items (collection_id, item_type, item_id)
       VALUES ($1, $2, $3)
       ON CONFLICT (collection_id, item_type, item_id) DO NOTHING
       RETURNING *`,
      [id, item_type, item_id]
    );

    // Touch the collection updated_at
    await query('UPDATE collections SET updated_at = NOW() WHERE id = $1', [id]);

    res.status(201).json({ success: true, data: result.rows[0] || { already_exists: true } });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/collections/:id/items/:itemId
 * Auth required — remove an item from a collection.
 */
const removeItem = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id, itemId } = req.params;

    // Verify ownership
    const col = await query('SELECT id FROM collections WHERE id = $1 AND user_id = $2', [id, userId]);
    if (col.rows.length === 0) {
      return res.status(403).json({ success: false, message: 'Not your collection.' });
    }

    await query('DELETE FROM collection_items WHERE id = $1 AND collection_id = $2', [itemId, id]);

    res.status(200).json({ success: true, message: 'Item removed.' });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/collections/:id
 * Auth required — delete a collection.
 */
const deleteCollection = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const result = await query('DELETE FROM collections WHERE id = $1 AND user_id = $2 RETURNING id', [id, userId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Collection not found.' });
    }

    res.status(200).json({ success: true, message: 'Collection deleted.' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createCollection,
  getCollections,
  getCollection,
  addItem,
  removeItem,
  deleteCollection,
};
