const { query } = require('../config/database');
const hub = require('../realtime/hub');
const { notify } = require('../utils/notifier');

// =====================================================
// RECURRING BOOKINGS
// =====================================================

exports.createRecurring = async (req, res, next) => {
  try {
    if (req.user.role !== 'customer') {
      return res.status(403).json({ success: false, message: 'Only customers can create recurring bookings' });
    }

    const {
      professional_id, category_id, service_id, title, description,
      service_address, frequency, day_of_week, day_of_month,
      preferred_time, start_date, end_date, max_occurrences
    } = req.body;

    if (!professional_id || !title || !frequency || !start_date) {
      return res.status(400).json({
        success: false,
        message: 'professional_id, title, frequency, and start_date are required'
      });
    }

    const validFrequencies = ['daily', 'weekly', 'biweekly', 'monthly', 'quarterly'];
    if (!validFrequencies.includes(frequency)) {
      return res.status(400).json({ success: false, message: 'Invalid frequency' });
    }

    // Calculate next booking date
    const nextDate = new Date(start_date);

    const r = await query(
      `INSERT INTO recurring_bookings
        (customer_id, professional_id, category_id, service_id, title, description,
         service_address, frequency, day_of_week, day_of_month, preferred_time,
         start_date, end_date, max_occurrences, next_booking_date)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
       RETURNING *`,
      [req.user.id, professional_id, category_id || null, service_id || null,
       title, description || null, service_address || null, frequency,
       day_of_week ?? null, day_of_month ?? null, preferred_time || null,
       start_date, end_date || null, max_occurrences || null, nextDate]
    );

    res.status(201).json({ success: true, data: r.rows[0] });
  } catch (e) { next(e); }
};

exports.listRecurring = async (req, res, next) => {
  try {
    const { status } = req.query;
    let where = 'customer_id = $1';
    const params = [req.user.id];

    if (status) {
      params.push(status);
      where += ` AND status = $${params.length}`;
    }

    const r = await query(
      `SELECT rb.*, u.name AS professional_name, p.user_id AS pro_user_id
       FROM recurring_bookings rb
       JOIN professionals p ON rb.professional_id = p.id
       JOIN users u ON p.user_id = u.id
       WHERE ${where}
       ORDER BY rb.created_at DESC`,
      params
    );

    res.json({ success: true, data: r.rows });
  } catch (e) { next(e); }
};

exports.updateRecurring = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, frequency, preferred_time, day_of_week, day_of_month } = req.body;

    const existing = await query(
      'SELECT * FROM recurring_bookings WHERE id = $1 AND customer_id = $2',
      [id, req.user.id]
    );
    if (!existing.rows.length) {
      return res.status(404).json({ success: false, message: 'Recurring booking not found' });
    }

    const updates = [];
    const params = [id];
    let paramIdx = 2;

    if (status) { updates.push(`status = $${paramIdx++}`); params.push(status); }
    if (frequency) { updates.push(`frequency = $${paramIdx++}`); params.push(frequency); }
    if (preferred_time) { updates.push(`preferred_time = $${paramIdx++}`); params.push(preferred_time); }
    if (day_of_week !== undefined) { updates.push(`day_of_week = $${paramIdx++}`); params.push(day_of_week); }
    if (day_of_month !== undefined) { updates.push(`day_of_month = $${paramIdx++}`); params.push(day_of_month); }

    updates.push('updated_at = NOW()');

    const r = await query(
      `UPDATE recurring_bookings SET ${updates.join(', ')} WHERE id = $1 RETURNING *`,
      params
    );

    res.json({ success: true, data: r.rows[0] });
  } catch (e) { next(e); }
};

exports.cancelRecurring = async (req, res, next) => {
  try {
    const { id } = req.params;
    const r = await query(
      `UPDATE recurring_bookings SET status = 'cancelled', updated_at = NOW()
       WHERE id = $1 AND customer_id = $2 RETURNING *`,
      [id, req.user.id]
    );
    if (!r.rows.length) {
      return res.status(404).json({ success: false, message: 'Recurring booking not found' });
    }
    res.json({ success: true, data: r.rows[0] });
  } catch (e) { next(e); }
};

// =====================================================
// BOOKING RESCHEDULING
// =====================================================

exports.reschedule = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { new_date, new_time, reason } = req.body;

    if (!new_date) {
      return res.status(400).json({ success: false, message: 'new_date is required' });
    }

    const date = new Date(new_date);
    if (isNaN(date.getTime())) {
      return res.status(400).json({ success: false, message: 'Invalid date format' });
    }
    if (date < new Date()) {
      return res.status(400).json({ success: false, message: 'Cannot reschedule to a past date' });
    }

    // Get current booking
    const booking = await query(
      `SELECT b.*, p.user_id AS pro_user_id FROM bookings b
       JOIN professionals p ON b.professional_id = p.id
       WHERE b.id = $1`,
      [id]
    );
    if (!booking.rows.length) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const b = booking.rows[0];
    // Only allow rescheduling for active bookings
    if (['completed', 'cancelled', 'refunded'].includes(b.status)) {
      return res.status(400).json({ success: false, message: 'Cannot reschedule a completed/cancelled booking' });
    }

    // Check user is part of this booking
    const isCustomer = b.customer_id === req.user.id;
    const isPro = b.pro_user_id === req.user.id;
    if (!isCustomer && !isPro && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to reschedule this booking' });
    }

    // Save reschedule log
    await query(
      `INSERT INTO booking_reschedules (booking_id, old_date, new_date, old_time, new_time, reason, rescheduled_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [id, b.preferred_date || b.created_at, new_date, null, new_time || null, reason || null, req.user.id]
    );

    // Update booking
    const r = await query(
      `UPDATE bookings SET
        preferred_date = $2,
        original_date = COALESCE(original_date, preferred_date),
        reschedule_count = COALESCE(reschedule_count, 0) + 1,
        rescheduled_by = $3,
        reschedule_reason = $4,
        updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [id, new_date, req.user.id, reason || null]
    );

    // Notify the other party
    const notifyUser = isCustomer ? b.pro_user_id : b.customer_id;
    await notify(notifyUser, {
      type: 'booking_rescheduled',
      title: 'Booking Rescheduled',
      body: `Booking "${b.title}" has been rescheduled to ${new Date(new_date).toLocaleDateString()}`,
      link_url: `/bookings/${id}`,
      related_id: id,
    });

    hub.sendTo(notifyUser, { type: 'booking', action: 'rescheduled', data: r.rows[0] });

    res.json({ success: true, data: r.rows[0] });
  } catch (e) { next(e); }
};

exports.getRescheduleHistory = async (req, res, next) => {
  try {
    const { id } = req.params;
    const r = await query(
      `SELECT br.*, u.name AS rescheduled_by_name
       FROM booking_reschedules br
       JOIN users u ON br.rescheduled_by = u.id
       WHERE br.booking_id = $1
       ORDER BY br.created_at DESC`,
      [id]
    );
    res.json({ success: true, data: r.rows });
  } catch (e) { next(e); }
};
