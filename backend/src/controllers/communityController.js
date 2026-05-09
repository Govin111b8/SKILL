const { query } = require('../config/database');

/**
 * POST /api/community/posts
 * Auth required (professional) — create a community post / tip.
 */
const createPost = async (req, res, next) => {
  try {
    const authorId = req.user.id;
    const { title, content, category, media_urls } = req.body;

    const result = await query(
      `INSERT INTO community_posts (author_id, title, content, category, media_urls)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [authorId, title, content, category || null, media_urls ? JSON.stringify(media_urls) : '[]']
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/community/posts
 * Public — list community posts with optional category filter.
 */
const getPosts = async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(50, parseInt(req.query.limit) || 20);
    const offset = (page - 1) * limit;
    const { category } = req.query;

    let sql = `
      SELECT cp.*, u.name as author_name, u.avatar_url as author_avatar,
             p.id as professional_id, p.headline as author_headline
      FROM community_posts cp
      JOIN users u ON cp.author_id = u.id
      LEFT JOIN professionals p ON p.user_id = u.id
    `;
    const params = [];

    if (category) {
      sql += ' WHERE cp.category = $1';
      params.push(category);
    }

    sql += ` ORDER BY cp.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await query(sql, params);

    res.status(200).json({ success: true, data: result.rows, page, limit });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/community/posts/:id
 * Public — get a single post.
 */
const getPost = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT cp.*, u.name as author_name, u.avatar_url as author_avatar,
              p.id as professional_id, p.headline as author_headline
       FROM community_posts cp
       JOIN users u ON cp.author_id = u.id
       LEFT JOIN professionals p ON p.user_id = u.id
       WHERE cp.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Post not found.' });
    }

    // Check if current user liked
    let user_liked = false;
    if (req.user) {
      const likeCheck = await query(
        'SELECT 1 FROM community_post_likes WHERE user_id = $1 AND post_id = $2',
        [req.user.id, id]
      );
      user_liked = likeCheck.rows.length > 0;
    }

    res.status(200).json({ success: true, data: { ...result.rows[0], user_liked } });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/community/posts/:id/like
 * Auth required — toggle like on a post.
 */
const toggleLike = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    // Check existing like
    const existing = await query(
      'SELECT 1 FROM community_post_likes WHERE user_id = $1 AND post_id = $2',
      [userId, id]
    );

    if (existing.rows.length > 0) {
      // Unlike
      await query('DELETE FROM community_post_likes WHERE user_id = $1 AND post_id = $2', [userId, id]);
      await query('UPDATE community_posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = $1', [id]);
      return res.status(200).json({ success: true, liked: false });
    }

    // Like
    await query(
      'INSERT INTO community_post_likes (user_id, post_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [userId, id]
    );
    await query('UPDATE community_posts SET likes_count = likes_count + 1 WHERE id = $1', [id]);

    res.status(200).json({ success: true, liked: true });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/community/posts/:id
 * Auth required — delete own post.
 */
const deletePost = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const result = await query(
      'DELETE FROM community_posts WHERE id = $1 AND author_id = $2 RETURNING id',
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Post not found or not yours.' });
    }

    res.status(200).json({ success: true, message: 'Post deleted.' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createPost,
  getPosts,
  getPost,
  toggleLike,
  deletePost,
};
