/**
 * Job Tracking Controller
 *
 * Real-time GPS tracking for active bookings:
 *   - Professional updates their GPS location during the job
 *   - Customer polls or subscribes via WebSocket to get ETA and location
 *   - Before/after photos uploaded at job start/end
 */

const { query } = require('../config/database');
const logger = require('../config/logger');

// ── Professional: start tracking for a booking ───────────────────────────────

const startTracking = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { booking_id } = req.body;

    if (!booking_id) return res.status(400).json({ success: false, message: 'booking_id is required.' });

    // Get professional ID
    const profRes = await query('SELECT id FROM professionals WHERE user_id = $1', [userId]);
    if (profRes.rows.length === 0) return res.status(403).json({ success: false, message: 'Professional profile required.' });
    const professional_id = profRes.rows[0].id;

    // Get booking to find customer_id
    const bookingRes = await query('SELECT id, user_id AS customer_id FROM bookings WHERE id = $1', [booking_id]);
    if (bookingRes.rows.length === 0) return res.status(404).json({ success: false, message: 'Booking not found.' });
    const customer_id = bookingRes.rows[0].customer_id;

    // Upsert tracking record
    const result = await query(
      `INSERT INTO job_tracking (booking_id, professional_id, customer_id, status, started_at)
       VALUES ($1, $2, $3, 'en_route', NOW())
       ON CONFLICT (booking_id) DO UPDATE SET
         status = 'en_route',
         started_at = COALESCE(job_tracking.started_at, NOW()),
         updated_at = NOW()
       RETURNING *`,
      [booking_id, professional_id, customer_id]
    );

    res.status(201).json({ success: true, data: result.rows[0], message: 'Job tracking started.' });
  } catch (error) {
    next(error);
  }
};

// ── Professional: update GPS location ────────────────────────────────────────

const updateLocation = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { booking_id } = req.params;
    const { latitude, longitude, accuracy_meters, heading_degrees, speed_kmh, eta_minutes, status } = req.body;

    if (latitude == null || longitude == null) {
      return res.status(400).json({ success: false, message: 'latitude and longitude are required.' });
    }

    const profRes = await query('SELECT id FROM professionals WHERE user_id = $1', [userId]);
    if (profRes.rows.length === 0) return res.status(403).json({ success: false, message: 'Professional profile required.' });
    const professional_id = profRes.rows[0].id;

    const validStatuses = ['en_route', 'arrived', 'in_progress', 'completed'];
    const newStatus = status && validStatuses.includes(status) ? status : undefined;

    const fields = [
      'latitude = $1', 'longitude = $2', 'last_location_at = NOW()', 'updated_at = NOW()',
    ];
    const values = [latitude, longitude];
    let idx = 3;

    if (accuracy_meters != null) { fields.push(`accuracy_meters = $${idx++}`); values.push(accuracy_meters); }
    if (heading_degrees != null) { fields.push(`heading_degrees = $${idx++}`); values.push(heading_degrees); }
    if (speed_kmh != null) { fields.push(`speed_kmh = $${idx++}`); values.push(speed_kmh); }
    if (eta_minutes != null) { fields.push(`eta_minutes = $${idx++}`); values.push(eta_minutes); }
    if (newStatus) {
      fields.push(`status = $${idx++}`);
      values.push(newStatus);
      if (newStatus === 'arrived') { fields.push(`arrived_at = COALESCE(arrived_at, NOW())`); }
      if (newStatus === 'completed') { fields.push(`completed_at = NOW()`); }
    }

    values.push(booking_id, professional_id);

    const result = await query(
      `UPDATE job_tracking SET ${fields.join(', ')}
       WHERE booking_id = $${idx} AND professional_id = $${idx + 1}
       RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Tracking record not found for this booking.' });
    }

    // Broadcast via WebSocket if hub is available (fire-and-forget)
    broadcastTrackingUpdate(result.rows[0]).catch((err) =>
      logger.warn({ err, booking_id }, 'WebSocket broadcast for tracking failed')
    );

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

// ── Customer: get current tracking status for a booking ──────────────────────

const getTrackingStatus = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { booking_id } = req.params;

    // Verify customer owns this booking
    const bookingRes = await query('SELECT id FROM bookings WHERE id = $1 AND user_id = $2', [booking_id, userId]);
    if (bookingRes.rows.length === 0) return res.status(404).json({ success: false, message: 'Booking not found.' });

    const result = await query(
      `SELECT jt.*, p.business_name, u.full_name AS pro_name, u.phone AS pro_phone, u.profile_photo
       FROM job_tracking jt
       JOIN professionals p ON jt.professional_id = p.id
       JOIN users u ON p.user_id = u.id
       WHERE jt.booking_id = $1`,
      [booking_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Tracking not started for this booking yet.' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

// ── Professional: upload before/after photos ──────────────────────────────────

const uploadJobPhotos = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { booking_id } = req.params;
    const { before_photos, after_photos } = req.body;

    const profRes = await query('SELECT id FROM professionals WHERE user_id = $1', [userId]);
    if (profRes.rows.length === 0) return res.status(403).json({ success: false, message: 'Professional profile required.' });
    const professional_id = profRes.rows[0].id;

    const fields = [];
    const values = [];
    let idx = 1;

    if (before_photos && Array.isArray(before_photos) && before_photos.length) {
      fields.push(`before_photos = $${idx++}`);
      values.push(before_photos);
    }
    if (after_photos && Array.isArray(after_photos) && after_photos.length) {
      fields.push(`after_photos = $${idx++}`);
      values.push(after_photos);
    }

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'Provide before_photos or after_photos array.' });
    }

    fields.push(`updated_at = NOW()`);
    values.push(booking_id, professional_id);

    const result = await query(
      `UPDATE job_tracking SET ${fields.join(', ')}
       WHERE booking_id = $${idx} AND professional_id = $${idx + 1}
       RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Tracking record not found.' });
    }

    res.json({ success: true, data: result.rows[0], message: 'Photos uploaded.' });
  } catch (error) {
    next(error);
  }
};

// ── Internal: broadcast via WebSocket hub ─────────────────────────────────────

async function broadcastTrackingUpdate(trackingRow) {
  try {
    const wsHub = require('../config/websocket');
    if (wsHub && typeof wsHub.broadcastToUser === 'function') {
      wsHub.broadcastToUser(String(trackingRow.customer_id), {
        type: 'JOB_TRACKING_UPDATE',
        data: {
          booking_id: trackingRow.booking_id,
          status: trackingRow.status,
          latitude: trackingRow.latitude,
          longitude: trackingRow.longitude,
          eta_minutes: trackingRow.eta_minutes,
          last_location_at: trackingRow.last_location_at,
        },
      });
    }
  } catch (err) {
    // WebSocket broadcast is best-effort
    logger.warn({ err }, 'WebSocket hub not available for tracking broadcast');
  }
}

module.exports = {
  startTracking,
  updateLocation,
  getTrackingStatus,
  uploadJobPhotos,
};
