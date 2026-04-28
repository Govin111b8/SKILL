const { query } = require('../config/database');

exports.list = async (req, res, next) => {
  try {
    const { unread_only } = req.query;
    const sql = unread_only === 'true'
      ? 'SELECT * FROM notifications WHERE user_id = $1 AND read_at IS NULL ORDER BY created_at DESC LIMIT 100'
      : 'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 100';
    const r = await query(sql, [req.user.id]);
    const c = await query('SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND read_at IS NULL', [req.user.id]);
    res.json({ success: true, data: r.rows, unread_count: parseInt(c.rows[0].count, 10) });
  } catch (e) { next(e); }
};

exports.markRead = async (req, res, next) => {
  try {
    await query(`UPDATE notifications SET read_at = NOW() WHERE user_id = $1 AND id = $2 AND read_at IS NULL`, [req.user.id, req.params.id]);
    res.json({ success: true });
  } catch (e) { next(e); }
};

exports.markAllRead = async (req, res, next) => {
  try {
    await query(`UPDATE notifications SET read_at = NOW() WHERE user_id = $1 AND read_at IS NULL`, [req.user.id]);
    res.json({ success: true });
  } catch (e) { next(e); }
};

// Favorites
exports.listFavorites = async (req, res, next) => {
  try {
    const r = await query(
      `SELECT f.created_at, p.id, p.headline, p.pricing_estimate, p.reputation_score,
              p.availability_status, u.name, u.location, u.avatar_url, u.kyc_level, u.trust_score
       FROM favorites f
       JOIN professionals p ON f.professional_id = p.id
       JOIN users u ON p.user_id = u.id
       WHERE f.user_id = $1
       ORDER BY f.created_at DESC LIMIT 200`,
      [req.user.id]
    );
    res.json({ success: true, data: r.rows });
  } catch (e) { next(e); }
};

exports.toggleFavorite = async (req, res, next) => {
  try {
    const exists = await query(
      'SELECT 1 FROM favorites WHERE user_id = $1 AND professional_id = $2',
      [req.user.id, req.params.professionalId]
    );
    if (exists.rows.length) {
      await query('DELETE FROM favorites WHERE user_id = $1 AND professional_id = $2', [req.user.id, req.params.professionalId]);
      return res.json({ success: true, favored: false });
    }
    await query('INSERT INTO favorites (user_id, professional_id) VALUES ($1, $2) ON CONFLICT DO NOTHING', [req.user.id, req.params.professionalId]);
    res.json({ success: true, favored: true });
  } catch (e) { next(e); }
};

// Device token (push)
exports.registerDevice = async (req, res, next) => {
  try {
    const { token, platform } = req.body;
    if (!token || !platform) return res.status(400).json({ success: false, message: 'token & platform required' });
    await query(
      `INSERT INTO device_tokens (user_id, token, platform) VALUES ($1, $2, $3)
       ON CONFLICT (user_id, token) DO UPDATE SET is_active = TRUE, last_used_at = NOW()`,
      [req.user.id, token, platform]
    );
    res.json({ success: true });
  } catch (e) { next(e); }
};
