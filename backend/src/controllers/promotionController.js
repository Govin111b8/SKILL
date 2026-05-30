const { query } = require('../config/database');

/**
 * GET /api/promotions
 * Returns active promotions ordered by display_order.
 * Optionally filters by current date if starts_at/ends_at are set.
 */
const getPromotions = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT id, title, subtitle, image_url, cta_url,
              gradient_from, gradient_to, emoji, display_order
       FROM promotions
       WHERE active = TRUE
         AND (starts_at IS NULL OR starts_at <= NOW())
         AND (ends_at   IS NULL OR ends_at   >= NOW())
       ORDER BY display_order ASC, created_at DESC`
    );
    res.json({ data: result.rows });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/promotions  (admin only)
 */
const createPromotion = async (req, res, next) => {
  try {
    const {
      title, subtitle, image_url, cta_url,
      gradient_from, gradient_to, emoji,
      display_order, starts_at, ends_at,
    } = req.body;

    if (!title) return res.status(400).json({ error: 'title is required' });

    const result = await query(
      `INSERT INTO promotions
         (title, subtitle, image_url, cta_url, gradient_from, gradient_to,
          emoji, display_order, starts_at, ends_at, active, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,TRUE,$11)
       RETURNING *`,
      [
        title, subtitle, image_url, cta_url,
        gradient_from || '#6366F1', gradient_to || '#8B5CF6',
        emoji || '🎁',
        display_order || 0,
        starts_at || null, ends_at || null,
        req.user.id,
      ]
    );
    res.status(201).json({ data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/promotions/:id  (admin only)
 */
const updatePromotion = async (req, res, next) => {
  try {
    const { id } = req.params;
    const {
      title, subtitle, image_url, cta_url,
      gradient_from, gradient_to, emoji,
      display_order, starts_at, ends_at, active,
    } = req.body;

    const result = await query(
      `UPDATE promotions SET
         title         = COALESCE($1, title),
         subtitle      = COALESCE($2, subtitle),
         image_url     = COALESCE($3, image_url),
         cta_url       = COALESCE($4, cta_url),
         gradient_from = COALESCE($5, gradient_from),
         gradient_to   = COALESCE($6, gradient_to),
         emoji         = COALESCE($7, emoji),
         display_order = COALESCE($8, display_order),
         starts_at     = COALESCE($9, starts_at),
         ends_at       = COALESCE($10, ends_at),
         active        = COALESCE($11, active),
         updated_at    = NOW()
       WHERE id = $12
       RETURNING *`,
      [
        title, subtitle, image_url, cta_url,
        gradient_from, gradient_to, emoji,
        display_order, starts_at, ends_at,
        active !== undefined ? active : null,
        id,
      ]
    );
    if (!result.rows.length) return res.status(404).json({ error: 'Promotion not found' });
    res.json({ data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /api/promotions/:id  (admin only)
 */
const deletePromotion = async (req, res, next) => {
  try {
    const { id } = req.params;
    await query('DELETE FROM promotions WHERE id = $1', [id]);
    res.json({ message: 'Promotion deleted' });
  } catch (err) {
    next(err);
  }
};

module.exports = { getPromotions, createPromotion, updatePromotion, deletePromotion };
