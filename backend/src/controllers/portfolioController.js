const crypto = require('crypto');
const { query } = require('../config/database');

// PRD §6.5 — Portfolio upload limits per subscription tier
const TIER_LIMITS = {
  basic: { images: 5, videos: 0 },
  premium: { images: 20, videos: 5 },
  featured: { images: 20, videos: 5 },
};

const addPortfolioItem = async (req, res, next) => {
  try {
    const userId = req.user.id;

    // Get professional ID + subscription plan
    const profResult = await query(
      'SELECT id, subscription_plan FROM professionals WHERE user_id = $1',
      [userId]
    );
    if (profResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Professional profile not found.',
      });
    }

    const professionalId = profResult.rows[0].id;
    const plan = profResult.rows[0].subscription_plan || 'basic';
    const limits = TIER_LIMITS[plan] || TIER_LIMITS.basic;
    const { title, description, media_type, media_url } = req.body;

    // Count existing items by media type
    const countResult = await query(
      `SELECT
         COUNT(*) FILTER (WHERE media_type = 'image') AS image_count,
         COUNT(*) FILTER (WHERE media_type = 'video') AS video_count
       FROM portfolio_items WHERE professional_id = $1`,
      [professionalId]
    );
    const imageCount = parseInt(countResult.rows[0]?.image_count || 0);
    const videoCount = parseInt(countResult.rows[0]?.video_count || 0);

    if (media_type === 'image' && imageCount >= limits.images) {
      return res.status(422).json({
        success: false,
        message: `Your ${plan} plan allows up to ${limits.images} images. Upgrade to add more.`,
        limit: limits.images,
        current: imageCount,
        upgrade_required: plan === 'basic',
      });
    }
    if (media_type === 'video' && videoCount >= limits.videos) {
      return res.status(422).json({
        success: false,
        message: limits.videos === 0
          ? 'Video portfolio items require a Premium or Featured subscription.'
          : `Your ${plan} plan allows up to ${limits.videos} videos. Upgrade to add more.`,
        limit: limits.videos,
        current: videoCount,
        upgrade_required: true,
      });
    }

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
