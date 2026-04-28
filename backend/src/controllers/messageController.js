const { query } = require('../config/database');
const hub = require('../realtime/hub');
const { notify } = require('../utils/notifier');

// Get or create thread between current user (customer) and a professional, optionally tied to a booking
async function getOrCreateThread({ customerId, professionalId, bookingId = null }) {
  let r;
  if (bookingId) {
    r = await query(
      `SELECT * FROM message_threads
       WHERE customer_id = $1 AND professional_id = $2 AND booking_id = $3`,
      [customerId, professionalId, bookingId]
    );
  } else {
    r = await query(
      `SELECT * FROM message_threads
       WHERE customer_id = $1 AND professional_id = $2 AND booking_id IS NULL`,
      [customerId, professionalId]
    );
  }
  if (r.rows.length) return r.rows[0];
  const ins = await query(
    `INSERT INTO message_threads (customer_id, professional_id, booking_id)
     VALUES ($1, $2, $3) RETURNING *`,
    [customerId, professionalId, bookingId]
  );
  return ins.rows[0];
}

// List all threads for current user
exports.listThreads = async (req, res, next) => {
  try {
    let where, params;
    if (req.user.role === 'professional') {
      const p = await query('SELECT id FROM professionals WHERE user_id = $1', [req.user.id]);
      if (!p.rows.length) return res.json({ success: true, data: [] });
      where = `t.professional_id = $1`;
      params = [p.rows[0].id];
    } else {
      where = `t.customer_id = $1`;
      params = [req.user.id];
    }
    const r = await query(
      `SELECT t.*,
              uc.name AS customer_name, uc.avatar_url AS customer_avatar,
              up.name AS pro_name, up.avatar_url AS pro_avatar,
              (SELECT body FROM messages m WHERE m.thread_id = t.id ORDER BY m.created_at DESC LIMIT 1) AS last_message,
              (SELECT sender_id FROM messages m WHERE m.thread_id = t.id ORDER BY m.created_at DESC LIMIT 1) AS last_sender
       FROM message_threads t
       JOIN users uc ON t.customer_id = uc.id
       JOIN professionals p ON t.professional_id = p.id
       JOIN users up ON p.user_id = up.id
       WHERE ${where}
       ORDER BY t.last_message_at DESC LIMIT 100`,
      params
    );
    res.json({ success: true, data: r.rows });
  } catch (e) { next(e); }
};

exports.openThread = async (req, res, next) => {
  try {
    if (req.user.role !== 'customer') return res.status(403).json({ success: false, message: 'Customer action' });
    const { professional_id, booking_id } = req.body;
    if (!professional_id) return res.status(400).json({ success: false, message: 'professional_id required' });
    const thread = await getOrCreateThread({
      customerId: req.user.id,
      professionalId: professional_id,
      bookingId: booking_id || null,
    });
    res.json({ success: true, data: thread });
  } catch (e) { next(e); }
};

async function authorizeThread(threadId, userId) {
  const r = await query(
    `SELECT t.*, p.user_id AS pro_user_id
     FROM message_threads t
     JOIN professionals p ON t.professional_id = p.id
     WHERE t.id = $1`,
    [threadId]
  );
  if (!r.rows.length) return null;
  const t = r.rows[0];
  if (t.customer_id !== userId && t.pro_user_id !== userId) return null;
  return t;
}

exports.listMessages = async (req, res, next) => {
  try {
    const t = await authorizeThread(req.params.threadId, req.user.id);
    if (!t) return res.status(404).json({ success: false, message: 'Thread not found' });
    const r = await query(
      `SELECT * FROM messages WHERE thread_id = $1 ORDER BY created_at ASC LIMIT 500`,
      [req.params.threadId]
    );
    // Mark as read for current side
    if (t.customer_id === req.user.id) {
      await query(`UPDATE message_threads SET customer_unread = 0 WHERE id = $1`, [t.id]);
    } else {
      await query(`UPDATE message_threads SET pro_unread = 0 WHERE id = $1`, [t.id]);
    }
    await query(`UPDATE messages SET read_at = NOW() WHERE thread_id = $1 AND sender_id <> $2 AND read_at IS NULL`, [t.id, req.user.id]);
    res.json({ success: true, data: r.rows, thread: t });
  } catch (e) { next(e); }
};

exports.sendMessage = async (req, res, next) => {
  try {
    const { body, attachment_url } = req.body;
    if (!body || !body.trim()) return res.status(400).json({ success: false, message: 'Body required' });
    const t = await authorizeThread(req.params.threadId, req.user.id);
    if (!t) return res.status(404).json({ success: false, message: 'Thread not found' });

    const ins = await query(
      `INSERT INTO messages (thread_id, sender_id, body, attachment_url) VALUES ($1, $2, $3, $4) RETURNING *`,
      [t.id, req.user.id, body.trim(), attachment_url || null]
    );
    const msg = ins.rows[0];

    // Update thread metadata
    const isFromCustomer = t.customer_id === req.user.id;
    await query(
      `UPDATE message_threads SET last_message_at = NOW(),
         customer_unread = CASE WHEN $2 THEN customer_unread ELSE customer_unread + 1 END,
         pro_unread = CASE WHEN $2 THEN pro_unread + 1 ELSE pro_unread END
       WHERE id = $1`,
      [t.id, isFromCustomer]
    );

    const recipientUserId = isFromCustomer ? t.pro_user_id : t.customer_id;
    hub.sendTo(recipientUserId, { type: 'message', data: { ...msg, thread_id: t.id } });
    hub.sendTo(req.user.id, { type: 'message', data: { ...msg, thread_id: t.id, _self: true } });

    // Push notification (skip if recipient is actively in thread is hard to know; always notify)
    await notify(recipientUserId, {
      type: 'message',
      title: 'New message',
      body: body.length > 80 ? body.slice(0, 80) + '…' : body,
      link_url: `/threads/${t.id}`,
      related_id: t.id,
    });

    res.status(201).json({ success: true, data: msg });
  } catch (e) { next(e); }
};
