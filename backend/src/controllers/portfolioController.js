const crypto = require('crypto');
const { query } = require('../config/database');

const addPortfolioItem = async (req, res, next) => {
  try {
    const userId = req.user.id;

    // Get professional ID
    const profResult = await query(
      'SELECT id FROM professionals WHERE user_id = $1',
      [userId]
    );
    if (profResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Professional profile not found.',
      });
    }

    const professionalId = profResult.rows[0].id;
    const { title, description, media_type, media_url } = req.body;
    const id = crypto.randomUUID();

    const result = await query(
      `INSERT INTO portfolio_items (id, professional_id, title, description, media_type, media_url, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())
       RETURNING *`,
      [id, professionalId, title, description, media_type, media_url]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'Portfolio item added successfully.',
    });
  } catch (error) {
    next(error);
  }
};

const getPortfolioItems = async (req, res, next) => {
  try {
    const { professionalId } = req.params;

    const result = await query(
      'SELECT * FROM portfolio_items WHERE professional_id = $1 ORDER BY created_at DESC',
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

const deletePortfolioItem = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Verify ownership
    const item = await query(
      `SELECT pi.id FROM portfolio_items pi
       JOIN professionals p ON pi.professional_id = p.id
       WHERE pi.id = $1 AND p.user_id = $2`,
      [id, userId]
    );

    if (item.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own portfolio items.',
      });
    }

    await query('DELETE FROM portfolio_items WHERE id = $1', [id]);

    res.status(200).json({
      success: true,
      message: 'Portfolio item deleted successfully.',
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { addPortfolioItem, getPortfolioItems, deletePortfolioItem };
