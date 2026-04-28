const { query } = require('../config/database');
const hub = require('../realtime/hub');
const { notify } = require('../utils/notifier');

// Resolve professional row + owner user_id
async function getPro(professionalId) {
  const r = await query('SELECT id, user_id FROM professionals WHERE id = $1', [professionalId]);
  return r.rows[0];
}

// Allowed transitions (server-enforced finite state machine)
const FSM = {
  requested:   ['quoted', 'cancelled'],
  quoted:      ['accepted', 'cancelled'],
  accepted:    ['scheduled', 'cancelled'],
  scheduled:   ['in_progress', 'cancelled'],
  in_progress: ['completed', 'disputed', 'cancelled'],
  completed:   ['disputed', 'refunded'],
  disputed:    ['refunded', 'completed'],
  cancelled:   [],
  refunded:    [],
};

// Role gating: which transitions only one side can perform
const PRO_ONLY = ['quoted', 'in_progress', 'completed'];
const CUSTOMER_ONLY = ['accepted'];

exports.FSM = FSM;
exports.PRO_ONLY = PRO_ONLY;
exports.CUSTOMER_ONLY = CUSTOMER_ONLY;

exports.create = async (req, res, next) => {
  try {
    if (req.user.role !== 'customer') return res.status(403).json({ success: false, message: 'Only customers can create bookings' });
    const { professional_id, category_id, title, description, service_address,
            service_lat, service_lng, preferred_date } = req.body;
    if (!professional_id || !title) return res.status(400).json({ success: false, message: 'professional_id and title are required' });

    const pro = await getPro(professional_id);
    if (!pro) return res.status(404).json({ success: false, message: 'Professional not found' });

    const r = await query(
      `INSERT INTO bookings (customer_id, professional_id, category_id, title, description,
        service_address, service_lat, service_lng, preferred_date)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [req.user.id, professional_id, category_id || null, title, description || null,
       service_address || null, service_lat || null, service_lng || null, preferred_date || null]
    );
    const booking = r.rows[0];

    await query(
      `INSERT INTO booking_status_log (booking_id, from_status, to_status, actor_id, note)
       VALUES ($1, NULL, 'requested', $2, 'Booking created')`,
      [booking.id, req.user.id]
    );

    await notify(pro.user_id, {
      type: 'booking_request',
      title: 'New booking request',
      body: title,
      link_url: `/bookings/${booking.id}`,
      related_id: booking.id,
    });

    hub.sendTo(pro.user_id, { type: 'booking', action: 'created', data: booking });
    res.status(201).json({ success: true, data: booking });
  } catch (e) { next(e); }
};

exports.list = async (req, res, next) => {
  try {
    const { status, role } = req.query;
    let where, params;
    const want = role || (req.user.role === 'professional' ? 'pro' : 'customer');
    if (want === 'pro') {
      const p = await query('SELECT id FROM professionals WHERE user_id = $1', [req.user.id]);
      if (!p.rows.length) return res.json({ success: true, data: [] });
      where = `b.professional_id = $1`;
      params = [p.rows[0].id];
    } else {
      where = `b.customer_id = $1`;
      params = [req.user.id];
    }
    if (status) {
      params.push(status);
      where += ` AND b.status = $${params.length}::booking_status`;
    }
    const rows = await query(
      `SELECT b.*, u.name AS customer_name, u.avatar_url AS customer_avatar,
              up.name AS pro_name, up.avatar_url AS pro_avatar
       FROM bookings b
       JOIN users u ON b.customer_id = u.id
       JOIN professionals p ON b.professional_id = p.id
       JOIN users up ON p.user_id = up.id
       WHERE ${where}
       ORDER BY b.updated_at DESC LIMIT 100`,
      params
    );
    res.json({ success: true, data: rows.rows });
  } catch (e) { next(e); }
};

exports.get = async (req, res, next) => {
  try {
    const r = await query(
      `SELECT b.*, u.name AS customer_name, up.name AS pro_name, p.user_id AS pro_user_id
       FROM bookings b
       JOIN users u ON b.customer_id = u.id
       JOIN professionals p ON b.professional_id = p.id
       JOIN users up ON p.user_id = up.id
       WHERE b.id = $1`,
      [req.params.id]
    );
    if (!r.rows.length) return res.status(404).json({ success: false, message: 'Not found' });
    const b = r.rows[0];
    if (b.customer_id !== req.user.id && b.pro_user_id !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not your booking' });
    }
    const log = await query('SELECT * FROM booking_status_log WHERE booking_id = $1 ORDER BY created_at', [req.params.id]);
    res.json({ success: true, data: { ...b, log: log.rows } });
  } catch (e) { next(e); }
};

// Generic transition endpoint — body: { to, note, payload }
exports.transition = async (req, res, next) => {
  try {
    const { to, note, payload = {} } = req.body;
    const cur = await query('SELECT b.*, p.user_id AS pro_user_id FROM bookings b JOIN professionals p ON b.professional_id = p.id WHERE b.id = $1', [req.params.id]);
    if (!cur.rows.length) return res.status(404).json({ success: false, message: 'Not found' });
    const b = cur.rows[0];
    const isPro = b.pro_user_id === req.user.id;
    const isCust = b.customer_id === req.user.id;
    if (!isPro && !isCust) return res.status(403).json({ success: false, message: 'Not your booking' });

    if (!FSM[b.status] || !FSM[b.status].includes(to)) {
      return res.status(409).json({ success: false, message: `Cannot transition from ${b.status} to ${to}` });
    }

    // Role gating per transition
    if (PRO_ONLY.includes(to) && !isPro) return res.status(403).json({ success: false, message: 'Pro action only' });
    if (CUSTOMER_ONLY.includes(to) && !isCust) return res.status(403).json({ success: false, message: 'Customer action only' });

    // Build SET clause
    const sets = [`status = $1::booking_status`, `updated_at = NOW()`];
    const params = [to];
    if (to === 'quoted' && payload.quoted_amount != null) { params.push(payload.quoted_amount); sets.push(`quoted_amount = $${params.length}::numeric`); }
    if (to === 'scheduled' && payload.scheduled_for) { params.push(payload.scheduled_for); sets.push(`scheduled_for = $${params.length}::timestamptz`); }
    if (to === 'in_progress') sets.push(`started_at = NOW()`);
    if (to === 'completed') {
      sets.push(`completed_at = NOW()`);
      if (payload.final_amount != null) { params.push(payload.final_amount); sets.push(`final_amount = $${params.length}::numeric`); }
    }
    if (to === 'cancelled') {
      if (payload.cancellation_reason) { params.push(payload.cancellation_reason); sets.push(`cancellation_reason = $${params.length}`); }
      params.push(req.user.id); sets.push(`cancelled_by = $${params.length}::uuid`);
    }
    params.push(req.params.id);
    const sql = `UPDATE bookings SET ${sets.join(', ')} WHERE id = $${params.length} RETURNING *`;
    const upd = await query(sql, params);
    const updated = upd.rows[0];

    await query(
      `INSERT INTO booking_status_log (booking_id, from_status, to_status, actor_id, note)
       VALUES ($1, $2::booking_status, $3::booking_status, $4, $5)`,
      [req.params.id, b.status, to, req.user.id, note || null]
    );

    // Notify the other party
    const otherUser = isPro ? b.customer_id : b.pro_user_id;
    const titles = {
      quoted: 'Quote received',
      accepted: 'Quote accepted',
      scheduled: 'Booking scheduled',
      in_progress: 'Job started',
      completed: 'Job completed',
      cancelled: 'Booking cancelled',
      disputed: 'Dispute raised',
      refunded: 'Refund issued',
    };
    await notify(otherUser, {
      type: `booking_${to}`,
      title: titles[to] || `Booking ${to}`,
      body: b.title,
      link_url: `/bookings/${b.id}`,
      related_id: b.id,
    });
    hub.sendTo(otherUser, { type: 'booking', action: 'updated', data: updated });
    hub.sendTo(req.user.id, { type: 'booking', action: 'updated', data: updated });

    res.json({ success: true, data: updated });
  } catch (e) { next(e); }
};
