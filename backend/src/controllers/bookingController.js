const { query } = require('../config/database');
const hub = require('../realtime/hub');
const { notify } = require('../utils/notifier');
const { completeReferral } = require('./referralController');
const { awardPoints } = require('./gamificationController');

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

    if (service_lat !== undefined && service_lat !== null) {
      const lat = parseFloat(service_lat);
      if (isNaN(lat) || lat < -90 || lat > 90) {
        return res.status(400).json({ success: false, message: 'service_lat must be a number between -90 and 90' });
      }
    }
    if (service_lng !== undefined && service_lng !== null) {
      const lng = parseFloat(service_lng);
      if (isNaN(lng) || lng < -180 || lng > 180) {
        return res.status(400).json({ success: false, message: 'service_lng must be a number between -180 and 180' });
      }
    }
    if (preferred_date) {
      const date = new Date(preferred_date);
      if (isNaN(date.getTime())) {
        return res.status(400).json({ success: false, message: 'preferred_date must be a valid date string' });
      }
      if (date < new Date()) {
        return res.status(400).json({ success: false, message: 'preferred_date cannot be in the past' });
      }
      const maxDate = new Date(Date.now() + 90 * 24 * 60 * 60 * 1000);
      if (date > maxDate) {
        return res.status(400).json({ success: false, message: 'preferred_date cannot be more than 90 days in the future' });
      }
    }

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
              up.name AS professional_name, up.avatar_url AS professional_avatar
       FROM bookings b
       JOIN users u ON b.customer_id = u.id
       JOIN professionals p ON b.professional_id = p.id
       JOIN users up ON p.user_id = up.id
       WHERE ${where}
       ORDER BY b.updated_at DESC LIMIT 50`,
      params
    );
    res.json({ success: true, data: rows.rows });
  } catch (e) { next(e); }
};

exports.get = async (req, res, next) => {
  try {
    const r = await query(
      `SELECT b.*, u.name AS customer_name, u.avatar_url AS customer_avatar,
              up.name AS professional_name, up.avatar_url AS professional_avatar,
              p.user_id AS pro_user_id
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
    const log = await query(
      `SELECT l.*, u.name AS changed_by_name
       FROM booking_status_log l
       LEFT JOIN users u ON l.actor_id = u.id
       WHERE l.booking_id = $1 ORDER BY l.created_at`,
      [req.params.id]
    );
    res.json({ success: true, data: { ...b, status_log: log.rows } });
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
    if (to === 'quoted' && payload.quoted_amount != null) {
      const amt = parseFloat(payload.quoted_amount);
      if (isNaN(amt) || amt <= 0) return res.status(400).json({ success: false, message: 'quoted_amount must be a positive number' });
      if (amt > 1000000) return res.status(400).json({ success: false, message: 'quoted_amount cannot exceed ₹10,00,000' });
      params.push(amt); sets.push(`quoted_amount = $${params.length}::numeric`);
    }
    if (to === 'scheduled' && payload.scheduled_for) {
      const dt = new Date(payload.scheduled_for);
      if (isNaN(dt.getTime()) || dt < new Date()) return res.status(400).json({ success: false, message: 'scheduled_for must be a valid future date' });
      params.push(payload.scheduled_for); sets.push(`scheduled_for = $${params.length}::timestamptz`);
    }
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

    // Auto-calculate response_time_hours for professional (average time from 'requested' to first pro action)
    if (isPro && b.status === 'requested' && (to === 'quoted' || to === 'cancelled')) {
      try {
        const proId = b.professional_id;
        // Calculate average response time for all bookings where pro responded
        const avgRes = await query(
          `SELECT AVG(EXTRACT(EPOCH FROM (log.created_at - b2.created_at)) / 3600.0) AS avg_hours
           FROM booking_status_log log
           JOIN bookings b2 ON log.booking_id = b2.id
           WHERE b2.professional_id = $1
             AND log.from_status = 'requested'
             AND log.to_status IN ('quoted', 'cancelled')
             AND log.actor_id = (SELECT user_id FROM professionals WHERE id = $1)`,
          [proId]
        );
        const avgHours = avgRes.rows[0]?.avg_hours;
        if (avgHours != null && !isNaN(parseFloat(avgHours))) {
          await query(
            `UPDATE professionals SET response_time_hours = $1 WHERE id = $2`,
            [parseFloat(avgHours).toFixed(1), proId]
          );
        }
      } catch (_) { /* non-critical */ }
    }

    // Post a system message in the chat thread for this booking (if one exists)
    try {
      const threadRes = await query(
        `SELECT id, customer_id, professional_id FROM message_threads
         WHERE (booking_id = $1) OR (customer_id = $2 AND professional_id = $3 AND booking_id IS NULL)
         ORDER BY booking_id DESC NULLS LAST LIMIT 1`,
        [b.id, b.customer_id, b.professional_id]
      );
      if (threadRes.rows.length) {
        const thread = threadRes.rows[0];
        const systemBody = `📋 Booking "${b.title}" → ${(titles[to] || to).toUpperCase()}${note ? ': ' + note : ''}`;
        await query(
          `INSERT INTO messages (thread_id, sender_id, body, is_system) VALUES ($1, $2, $3, true) RETURNING id`,
          [thread.id, req.user.id, systemBody]
        );
        await query(`UPDATE message_threads SET last_message_at = NOW() WHERE id = $1`, [thread.id]);
        // Push system message via WS to both parties
        const sysMsgPayload = { type: 'message', data: { thread_id: thread.id, body: systemBody, message_type: 'system', sender_id: req.user.id, is_system: true, created_at: new Date().toISOString() } };
        hub.sendTo(b.customer_id, sysMsgPayload);
        hub.sendTo(b.pro_user_id, sysMsgPayload);
      }
    } catch (_) { /* non-critical — don't fail the transition */ }

    // Auto-create warranty when booking is completed
    if (to === 'completed') {
      try {
        const catInfo = await query(
          `SELECT default_warranty_days FROM categories WHERE id = $1`,
          [b.category_id]
        );
        const warrantyDays = catInfo.rows[0]?.default_warranty_days || 7;
        const startsAt = new Date();
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + warrantyDays);

        // Only create if not already exists
        const existing = await query('SELECT id FROM service_warranties WHERE booking_id = $1', [b.id]);
        if (existing.rows.length === 0) {
          await query(
            `INSERT INTO service_warranties (booking_id, professional_id, customer_id, category_id, warranty_days, starts_at, expires_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7)`,
            [b.id, b.professional_id, b.customer_id, b.category_id, warrantyDays, startsAt, expiresAt]
          );
        }

        // Auto-increment completed_jobs on professional
        await query(`UPDATE professionals SET completed_jobs = completed_jobs + 1 WHERE id = $1`, [b.professional_id]);

        // Auto-release escrow payment when booking completes
        try {
          await query(
            `UPDATE payments SET status = 'released', escrow_released_at = NOW(), updated_at = NOW()
             WHERE booking_id = $1 AND status = 'held_in_escrow'`,
            [b.id]
          );
        } catch (_) { /* non-critical */ }

        // Complete referral reward (first booking completion)
        try {
          await completeReferral(b.customer_id);
        } catch (_) { /* ignore */ }

        // Award gamification points to customer (50 pts per booking)
        try {
          const paidAmt = await query(
            `SELECT amount FROM payments WHERE booking_id = $1 AND status IN ('completed','released') LIMIT 1`,
            [b.id]
          );
          const pts = paidAmt.rows[0] ? Math.floor(Number(paidAmt.rows[0].amount) / 10) : 50;
          await awardPoints(b.customer_id, pts, 'booking_complete', b.id);
        } catch (_) { /* non-critical */ }
      } catch (_) { /* non-critical */ }
    }

    res.json({ success: true, data: updated });
  } catch (e) { next(e); }
};
