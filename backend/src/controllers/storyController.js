const { query } = require('../config/database');

const MIN_STORY_HOURS = 1;
const DEFAULT_STORY_HOURS = 24;
const MAX_STORY_HOURS = 72;

/**
 * POST /api/stories
 * Auth required (professional) — create a 24-hour story.
 */
const createStory = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { media_url, text_overlay, cta_url, cta_label, hours } = req.body;

    const expiresIn = Math.min(Math.max(parseInt(hours) || DEFAULT_STORY_HOURS, MIN_STORY_HOURS), MAX_STORY_HOURS);

    const result = await query(
      `INSERT INTO stories (professional_id, media_url, text_overlay, cta_url, cta_label, expires_at)
       VALUES ($1, $2, $3, $4, $5, NOW() + ($6 || ' hours')::interval)
       RETURNING *`,
      [userId, media_url, text_overlay || null, cta_url || null, cta_label || null, String(expiresIn)]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/stories/feed
 * Public — get active stories (not expired), optionally filtered by location.
 */
const getStoryFeed = async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(50, parseInt(req.query.limit) || 20);
    const offset = (page - 1) * limit;

    const result = await query(
      `SELECT s.id, s.media_url, s.text_overlay, s.cta_url, s.cta_label, s.view_count,
              s.expires_at, s.created_at,
              u.name as professional_name, u.avatar_url,
              p.id as professional_id, p.headline
       FROM stories s
       JOIN users u ON s.professional_id = u.id
       JOIN professionals p ON p.user_id = u.id
       WHERE s.expires_at > NOW()
       ORDER BY s.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    // Group by professional for bubble display
    const grouped = {};
    for (const story of result.rows) {
      const pid = story.professional_id;
      if (!grouped[pid]) {
        grouped[pid] = {
          professional_id: pid,
          professional_name: story.professional_name,
          avatar_url: story.avatar_url,
          stories: [],
        };
      }
      grouped[pid].stories.push(story);
    }

    res.status(200).json({
      success: true,
      data: Object.values(grouped),
      page,
      limit,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/stories/professional/:professionalId
 * Public — get active stories for a specific professional.
 */
const getProfessionalStories = async (req, res, next) => {
  try {
    const { professionalId } = req.params;

    // Get user_id for this professional
    const proResult = await query('SELECT user_id FROM professionals WHERE id = $1', [professionalId]);
    if (proResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Professional not found.' });
    }

    const result = await query(
      `SELECT s.*, u.name as professional_name, u.avatar_url
       FROM stories s
       JOIN users u ON s.professional_id = u.id
       WHERE s.professional_id = $1 AND s.expires_at > NOW()
       ORDER BY s.created_at DESC`,
      [proResult.rows[0].user_id]
    );

    res.status(200).json({ success: true, data: result.rows });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/stories/:id/view
 * Public — increment view count.
 */
const viewStory = async (req, res, next) => {
  try {
    const { id } = req.params;
    await query('UPDATE stories SET view_count = view_count + 1 WHERE id = $1', [id]);
    res.status(200).json({ success: true });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/stories/:id
 * Auth required — delete own story.
 */
const deleteStory = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const result = await query('DELETE FROM stories WHERE id = $1 AND professional_id = $2 RETURNING id', [id, userId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Story not found or not yours.' });
    }

    res.status(200).json({ success: true, message: 'Story deleted.' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createStory,
  getStoryFeed,
  getProfessionalStories,
  viewStory,
  deleteStory,
};
