const { pool } = require('../config/database');

// Get worker's weekly schedule
async function getSchedule(req, res, next) {
  try {
    const proRes = await pool.query(
      'SELECT id FROM professionals WHERE user_id = $1', [req.user.id]
    );
    if (proRes.rows.length === 0) return res.status(404).json({ error: 'Professional profile not found' });
    const proId = proRes.rows[0].id;

    const schedule = await pool.query(
      'SELECT * FROM worker_schedule WHERE professional_id = $1 ORDER BY day_of_week, start_time',
      [proId]
    );

    res.json({ schedule: schedule.rows });
  } catch (err) {
    next(err);
  }
}

// Set/update weekly schedule
async function setSchedule(req, res, next) {
  try {
    const { slots } = req.body; // Array of { day_of_week, start_time, end_time, is_active }

    const proRes = await pool.query(
      'SELECT id FROM professionals WHERE user_id = $1', [req.user.id]
    );
    if (proRes.rows.length === 0) return res.status(404).json({ error: 'Professional profile not found' });
    const proId = proRes.rows[0].id;

    // Clear existing schedule
    await pool.query('DELETE FROM worker_schedule WHERE professional_id = $1', [proId]);

    // Insert new schedule
    if (slots && slots.length > 0) {
      const values = slots.map((s, i) => {
        const base = i * 5;
        return `($${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5})`;
      }).join(',');

      const params = slots.flatMap(s => [proId, s.day_of_week, s.start_time, s.end_time, s.is_active !== false]);

      await pool.query(
        `INSERT INTO worker_schedule (professional_id, day_of_week, start_time, end_time, is_active) VALUES ${values}`,
        params
      );
    }

    const result = await pool.query(
      'SELECT * FROM worker_schedule WHERE professional_id = $1 ORDER BY day_of_week, start_time',
      [proId]
    );

    res.json({ schedule: result.rows });
  } catch (err) {
    next(err);
  }
}

// Get available time slots for a professional on a date
async function getAvailableSlots(req, res, next) {
  try {
    const { professional_id, date } = req.query;

    if (!professional_id || !date) {
      return res.status(400).json({ error: 'professional_id and date are required' });
    }

    // Check if date is blocked
    const blocked = await pool.query(
      'SELECT 1 FROM worker_blocked_dates WHERE professional_id = $1 AND blocked_date = $2',
      [professional_id, date]
    );
    if (blocked.rows.length > 0) {
      return res.json({ slots: [], blocked: true, message: 'Professional is unavailable on this date' });
    }

    const dayOfWeek = new Date(date).getDay();

    // Get schedule for that day
    const schedule = await pool.query(
      'SELECT start_time, end_time FROM worker_schedule WHERE professional_id = $1 AND day_of_week = $2 AND is_active = TRUE ORDER BY start_time',
      [professional_id, dayOfWeek]
    );

    if (schedule.rows.length === 0) {
      return res.json({ slots: [], message: 'Professional does not work on this day' });
    }

    // Get already booked slots
    const bookedSlots = await pool.query(
      `SELECT start_time, end_time FROM time_slots WHERE professional_id = $1 AND slot_date = $2 AND status = 'booked'`,
      [professional_id, date]
    );

    // Generate available 1-hour slots from schedule
    const slots = [];
    for (const sched of schedule.rows) {
      let startHour = parseInt(sched.start_time.split(':')[0]);
      const endHour = parseInt(sched.end_time.split(':')[0]);

      while (startHour < endHour) {
        const slotStart = `${String(startHour).padStart(2, '0')}:00`;
        const slotEnd = `${String(startHour + 1).padStart(2, '0')}:00`;

        const isBooked = bookedSlots.rows.some(
          b => b.start_time <= slotStart && b.end_time > slotStart
        );

        slots.push({
          start_time: slotStart,
          end_time: slotEnd,
          available: !isBooked
        });
        startHour++;
      }
    }

    res.json({ slots, date });
  } catch (err) {
    next(err);
  }
}

// Book a time slot
async function bookSlot(req, res, next) {
  try {
    const { professional_id, date, start_time, end_time, booking_id } = req.body;

    const result = await pool.query(
      `INSERT INTO time_slots (professional_id, slot_date, start_time, end_time, status, booking_id)
       VALUES ($1, $2, $3, $4, 'booked', $5)
       ON CONFLICT (professional_id, slot_date, start_time) 
       DO UPDATE SET status = 'booked', booking_id = $5
       WHERE time_slots.status = 'available'
       RETURNING *`,
      [professional_id, date, start_time, end_time, booking_id]
    );

    if (result.rows.length === 0) {
      return res.status(409).json({ error: 'Slot is no longer available' });
    }

    res.status(201).json({ slot: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

// Block dates (vacation mode)
async function blockDates(req, res, next) {
  try {
    const { dates, reason } = req.body; // Array of date strings

    const proRes = await pool.query(
      'SELECT id FROM professionals WHERE user_id = $1', [req.user.id]
    );
    if (proRes.rows.length === 0) return res.status(404).json({ error: 'Professional profile not found' });
    const proId = proRes.rows[0].id;

    const values = dates.map((_, i) => `($${i * 3 + 1}, $${i * 3 + 2}, $${i * 3 + 3})`).join(',');
    const params = dates.flatMap(d => [proId, d, reason || 'Vacation']);

    await pool.query(
      `INSERT INTO worker_blocked_dates (professional_id, blocked_date, reason) VALUES ${values} ON CONFLICT DO NOTHING`,
      params
    );

    res.json({ message: `Blocked ${dates.length} date(s)` });
  } catch (err) {
    next(err);
  }
}

// Unblock dates
async function unblockDates(req, res, next) {
  try {
    const { dates } = req.body;

    const proRes = await pool.query(
      'SELECT id FROM professionals WHERE user_id = $1', [req.user.id]
    );
    if (proRes.rows.length === 0) return res.status(404).json({ error: 'Professional profile not found' });
    const proId = proRes.rows[0].id;

    await pool.query(
      'DELETE FROM worker_blocked_dates WHERE professional_id = $1 AND blocked_date = ANY($2)',
      [proId, dates]
    );

    res.json({ message: `Unblocked ${dates.length} date(s)` });
  } catch (err) {
    next(err);
  }
}

// Get blocked dates
async function getBlockedDates(req, res, next) {
  try {
    const proId = req.params.professional_id || null;
    let professionalId = proId;

    if (!professionalId) {
      const proRes = await pool.query('SELECT id FROM professionals WHERE user_id = $1', [req.user.id]);
      if (proRes.rows.length === 0) return res.status(404).json({ error: 'Professional profile not found' });
      professionalId = proRes.rows[0].id;
    }

    const result = await pool.query(
      'SELECT * FROM worker_blocked_dates WHERE professional_id = $1 AND blocked_date >= CURRENT_DATE ORDER BY blocked_date',
      [professionalId]
    );

    res.json({ blocked_dates: result.rows });
  } catch (err) {
    next(err);
  }
}

module.exports = { getSchedule, setSchedule, getAvailableSlots, bookSlot, blockDates, unblockDates, getBlockedDates };
