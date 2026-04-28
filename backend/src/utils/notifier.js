const { query } = require('../config/database');
const hub = require('../realtime/hub');

async function notify(userId, payload) {
  const r = await query(
    `INSERT INTO notifications (user_id, type, title, body, link_url, related_id)
     VALUES ($1, $2::notification_type, $3, $4, $5, $6) RETURNING id, created_at`,
    [userId, payload.type, payload.title, payload.body || null, payload.link_url || null, payload.related_id || null]
  );
  hub.sendTo(userId, { type: 'notification', data: { ...payload, id: r.rows[0].id, created_at: r.rows[0].created_at } });
  return r.rows[0];
}

module.exports = { notify };
