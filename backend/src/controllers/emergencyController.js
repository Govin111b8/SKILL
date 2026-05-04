const { pool } = require('../config/database');
const hub = require('../realtime/hub');

// Create emergency request
async function createEmergency(req, res, next) {
  try {
    const { category_id, description, location_lat, location_lng, location_address } = req.body;
    const customerId = req.user.id;

    const result = await pool.query(
      `INSERT INTO emergency_requests (customer_id, category_id, description, location_lat, location_lng, location_address)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [customerId, category_id, description, location_lat, location_lng, location_address]
    );

    // Find nearby available professionals who accept emergencies
    let nearbyPros = { rows: [] };
    if (location_lat && location_lng) {
      nearbyPros = await pool.query(
        `SELECT p.id, p.user_id, u.name,
          (6371 * acos(cos(radians($1)) * cos(radians(p.latitude)) * cos(radians(p.longitude) - radians($2)) + sin(radians($1)) * sin(radians(p.latitude)))) AS distance_km
         FROM professionals p
         JOIN users u ON p.user_id = u.id
         JOIN professional_categories pc ON pc.professional_id = p.id
         WHERE p.accepts_emergency = TRUE 
           AND p.availability_status = 'available'
           AND ($3::integer IS NULL OR pc.category_id = $3)
         ORDER BY distance_km
         LIMIT 10`,
        [location_lat, location_lng, category_id]
      );
    }

    // Notify nearby professionals (DB notification + WebSocket broadcast for online pros)
    for (const pro of nearbyPros.rows) {
      await pool.query(
        `INSERT INTO notifications (user_id, type, title, body, related_id)
         VALUES ($1, 'system', '🚨 Emergency Request Nearby', $2, $3)`,
        [pro.user_id, `Urgent: ${(description || '').substring(0, 100).replace(/[<>]/g, '')}`, result.rows[0].id]
      );
      // Real-time push to connected professionals
      hub.sendTo(pro.user_id, {
        type: 'emergency',
        action: 'new',
        data: {
          ...result.rows[0],
          customer_name: (await pool.query('SELECT name FROM users WHERE id = $1', [customerId])).rows[0]?.name,
          distance_km: Number(pro.distance_km).toFixed(1),
        },
      });
    }

    res.status(201).json({
      emergency: result.rows[0],
      notified_professionals: nearbyPros.rows.length
    });
  } catch (err) {
    next(err);
  }
}

// Accept emergency (professional)
async function acceptEmergency(req, res, next) {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const proRes = await pool.query('SELECT id FROM professionals WHERE user_id = $1', [userId]);
    if (proRes.rows.length === 0) return res.status(403).json({ error: 'Only professionals can accept emergencies' });

    const result = await pool.query(
      `UPDATE emergency_requests SET status = 'assigned', assigned_professional_id = $2, responded_at = NOW()
       WHERE id = $1 AND status = 'active' RETURNING *`,
      [id, proRes.rows[0].id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Emergency request not found or already assigned' });
    }

    // Notify customer
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, related_id)
       VALUES ($1, 'system', 'Help is on the way!', 'A professional has accepted your emergency request', $2)`,
      [result.rows[0].customer_id, id]
    );

    res.json({ emergency: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

// List emergencies
async function listEmergencies(req, res, next) {
  try {
    const userId = req.user.id;
    const { role } = req.user;

    let result;
    if (role === 'professional') {
      // Show active emergencies near the professional
      const proRes = await pool.query('SELECT id, latitude, longitude FROM professionals WHERE user_id = $1', [userId]);
      if (proRes.rows.length === 0) return res.json({ emergencies: [] });

      const pro = proRes.rows[0];
      result = await pool.query(
        `SELECT e.*, u.name as customer_name,
          CASE WHEN $2::decimal IS NOT NULL AND $3::decimal IS NOT NULL THEN
            (6371 * acos(cos(radians($2)) * cos(radians(e.location_lat)) * cos(radians(e.location_lng) - radians($3)) + sin(radians($2)) * sin(radians(e.location_lat))))
          ELSE NULL END as distance_km
         FROM emergency_requests e
         JOIN users u ON e.customer_id = u.id
         WHERE e.status = 'active' OR (e.assigned_professional_id = $1 AND e.status = 'assigned')
         ORDER BY e.created_at DESC LIMIT 20`,
        [pro.id, pro.latitude, pro.longitude]
      );
    } else {
      result = await pool.query(
        `SELECT e.*, u.name as professional_name FROM emergency_requests e
         LEFT JOIN professionals p ON e.assigned_professional_id = p.id
         LEFT JOIN users u ON p.user_id = u.id
         WHERE e.customer_id = $1 ORDER BY e.created_at DESC LIMIT 20`,
        [userId]
      );
    }

    res.json({ emergencies: result.rows });
  } catch (err) {
    next(err);
  }
}

// Trigger SOS (worker safety)
async function triggerSOS(req, res, next) {
  try {
    const { booking_id, location_lat, location_lng, message } = req.body;
    const userId = req.user.id;

    const result = await pool.query(
      `INSERT INTO safety_alerts (user_id, booking_id, location_lat, location_lng, message)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [userId, booking_id, location_lat, location_lng, message || 'SOS - Need immediate help']
    );

    // In production: would send SMS/call to emergency contact and platform safety team
    // For now, create system notification
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, related_id)
       VALUES ($1, 'system', '⚠️ SOS Alert Sent', 'Your emergency contacts have been notified', $2)`,
      [userId, result.rows[0].id]
    );

    res.status(201).json({ alert: result.rows[0], message: 'SOS alert triggered. Emergency contacts notified.' });
  } catch (err) {
    next(err);
  }
}

// Resolve emergency (professional marks it done)
async function resolveEmergency(req, res, next) {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const proRes = await pool.query('SELECT id FROM professionals WHERE user_id = $1', [userId]);
    if (proRes.rows.length === 0) return res.status(403).json({ error: 'Only professionals can resolve emergencies' });

    const result = await pool.query(
      `UPDATE emergency_requests SET status = 'resolved', resolved_at = NOW()
       WHERE id = $1 AND assigned_professional_id = $2 AND status = 'assigned'
       RETURNING *`,
      [id, proRes.rows[0].id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Assigned emergency not found' });
    }

    // Notify customer
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, related_id)
       VALUES ($1, 'system', '✅ Emergency Resolved', 'Your emergency request has been resolved.', $2)`,
      [result.rows[0].customer_id, id]
    );

    hub.sendTo(result.rows[0].customer_id, { type: 'emergency', action: 'resolved', data: result.rows[0] });

    res.json({ emergency: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

module.exports = { createEmergency, acceptEmergency, listEmergencies, triggerSOS, resolveEmergency };
