/**
 * Demand Prediction Controller
 *
 * Provides AI-powered demand forecasting and area-level demand analytics
 * for professionals and platform administrators.
 *
 * Endpoints:
 *   GET  /api/demand/forecast          — professional's upcoming demand forecast
 *   GET  /api/demand/area              — city/category demand summary (admin)
 *   GET  /api/demand/peak-hours        — best hours to work for a professional
 *   POST /api/demand/log               — internal: log a demand signal (search/quote)
 */

const { pool } = require('../config/database');
const logger = require('../config/logger');

// Days-of-week labels
const DOW_LABELS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/**
 * GET /api/demand/forecast
 * Returns a 7-day demand forecast for the authenticated professional.
 * Falls back to computed heuristics when no ML data is available.
 */
async function getDemandForecast(req, res, next) {
  try {
    const userId = req.user.id;

    // Resolve professional record
    const proRes = await pool.query(
      'SELECT p.id, p.city FROM professionals p WHERE p.user_id = $1',
      [userId]
    );
    if (proRes.rows.length === 0) {
      return res.status(404).json({ error: 'Professional profile not found' });
    }
    const { id: proId, city } = proRes.rows[0];

    // Fetch stored forecasts for next 7 days
    const today = new Date().toISOString().split('T')[0];
    const stored = await pool.query(
      `SELECT df.*, c.name as category_name
       FROM demand_forecasts df
       LEFT JOIN categories c ON c.id = df.category_id
       WHERE df.professional_id = $1 AND df.forecast_date >= $2
       ORDER BY df.forecast_date ASC
       LIMIT 7`,
      [proId, today]
    );

    if (stored.rows.length > 0) {
      return res.json({ forecasts: stored.rows, source: 'model' });
    }

    // Heuristic fallback: derive from historical booking patterns for the pro's city
    const histRes = await pool.query(
      `SELECT
         dow.dow,
         COALESCE(AVG(b.cnt), 0) AS avg_bookings
       FROM generate_series(0, 6) AS dow(dow)
       LEFT JOIN (
         SELECT EXTRACT(DOW FROM b.scheduled_at) AS dow, COUNT(*) AS cnt
         FROM bookings b
         JOIN professionals p ON p.id = b.professional_id
         WHERE p.user_id = $1
           AND b.status IN ('completed', 'accepted')
           AND b.scheduled_at >= NOW() - INTERVAL '90 days'
         GROUP BY EXTRACT(DOW FROM b.scheduled_at)
       ) b ON b.dow = dow.dow
       GROUP BY dow.dow ORDER BY dow.dow`,
      [userId]
    );

    const maxAvg = Math.max(...histRes.rows.map((r) => parseFloat(r.avg_bookings)), 1);

    const forecasts = [];
    for (let i = 0; i < 7; i++) {
      const d = new Date();
      d.setDate(d.getDate() + i);
      const dow = d.getDay();
      const avgRow = histRes.rows.find((r) => parseInt(r.dow, 10) === dow);
      const avg = avgRow ? parseFloat(avgRow.avg_bookings) : 0;
      const score = Math.min(100, Math.round((avg / maxAvg) * 85) + 10);
      forecasts.push({
        forecast_date: d.toISOString().split('T')[0],
        day_label: DOW_LABELS[dow],
        demand_score: score,
        trend: score > 60 ? 'rising' : score < 30 ? 'falling' : 'stable',
        confidence_level: histRes.rows.some((r) => parseInt(r.dow, 10) === dow && parseFloat(r.avg_bookings) > 0) ? 'medium' : 'low',
        predicted_bookings: Math.round(avg),
        peak_hours: score > 50 ? [9, 10, 14, 15, 16, 17] : [10, 11, 15],
        insight: score > 70
          ? 'High demand expected — ensure availability'
          : score < 30
            ? 'Low demand day — good for training or portfolio updates'
            : 'Moderate demand — typical day',
        city,
      });
    }

    res.json({ forecasts, source: 'heuristic' });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/demand/area?city=&category_id=
 * Area-level demand summary for admins or supply-demand matching.
 */
async function getAreaDemand(req, res, next) {
  try {
    const { city, category_id } = req.query;

    if (!city) {
      return res.status(400).json({ error: 'city is required' });
    }

    // Stored summaries for the last 30 days
    const summaryRes = await pool.query(
      `SELECT ads.*, c.name AS category_name
       FROM area_demand_summary ads
       LEFT JOIN categories c ON c.id = ads.category_id
       WHERE ads.city ILIKE $1
         ${category_id ? 'AND ads.category_id = $2' : ''}
       ORDER BY ads.summary_date DESC
       LIMIT 30`,
      category_id ? [city, category_id] : [city]
    );

    // Live unmet demand: bookings without assigned professional in city
    const unmetRes = await pool.query(
      `SELECT COUNT(*) AS unmet
       FROM bookings b
       WHERE b.status = 'pending'
         AND b.scheduled_at >= NOW()
         AND EXISTS (
           SELECT 1 FROM users u WHERE u.id = b.customer_id AND u.city ILIKE $1
         )`,
      [city]
    );

    // Available professionals in city
    const prosRes = await pool.query(
      `SELECT COUNT(*) AS available
       FROM professionals p
       JOIN users u ON u.id = p.user_id
       WHERE p.is_available = true AND u.city ILIKE $1
         ${category_id ? 'AND p.category_id = $2' : ''}`,
      category_id ? [city, category_id] : [city]
    );

    res.json({
      city,
      category_id: category_id || null,
      unmet_demand: parseInt(unmetRes.rows[0].unmet, 10),
      available_professionals: parseInt(prosRes.rows[0].available, 10),
      historical_summaries: summaryRes.rows,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/demand/peak-hours
 * Returns the best hours to work for the authenticated professional based on
 * historical booking data and city-level demand logs.
 */
async function getPeakHours(req, res, next) {
  try {
    const userId = req.user.id;

    const proRes = await pool.query(
      'SELECT p.id, p.city, p.category_id FROM professionals p WHERE p.user_id = $1',
      [userId]
    );
    if (proRes.rows.length === 0) {
      return res.status(404).json({ error: 'Professional profile not found' });
    }
    const { city, category_id } = proRes.rows[0];

    // Hour-level demand from logs
    const logsRes = await pool.query(
      `SELECT hour_of_day, SUM(booking_count) AS total_bookings, SUM(search_count) AS total_searches
       FROM service_demand_logs
       WHERE city ILIKE $1
         ${category_id ? 'AND category_id = $2' : ''}
         AND week_start >= CURRENT_DATE - INTERVAL '8 weeks'
       GROUP BY hour_of_day
       ORDER BY hour_of_day`,
      category_id ? [city, category_id] : [city]
    );

    // Historical personal bookings by hour
    const personalRes = await pool.query(
      `SELECT EXTRACT(HOUR FROM b.scheduled_at) AS hour, COUNT(*) AS cnt
       FROM bookings b
       JOIN professionals p ON p.id = b.professional_id
       WHERE p.user_id = $1
         AND b.status IN ('completed', 'accepted')
         AND b.scheduled_at >= NOW() - INTERVAL '90 days'
       GROUP BY EXTRACT(HOUR FROM b.scheduled_at)
       ORDER BY cnt DESC`,
      [userId]
    );

    const hourScores = Array.from({ length: 24 }, (_, h) => {
      const log = logsRes.rows.find((r) => parseInt(r.hour_of_day, 10) === h);
      const personal = personalRes.rows.find((r) => parseInt(r.hour, 10) === h);
      return {
        hour: h,
        label: `${h.toString().padStart(2, '0')}:00`,
        demand_score: log ? parseInt(log.total_bookings, 10) + parseInt(log.total_searches, 10) / 2 : 0,
        personal_bookings: personal ? parseInt(personal.cnt, 10) : 0,
      };
    });

    const maxScore = Math.max(...hourScores.map((h) => h.demand_score), 1);
    const normalised = hourScores.map((h) => ({
      ...h,
      demand_index: Math.round((h.demand_score / maxScore) * 100),
    }));

    const peakHours = normalised
      .filter((h) => h.demand_index >= 60)
      .map((h) => h.hour);

    res.json({
      city,
      peak_hours: peakHours.length > 0 ? peakHours : [9, 10, 14, 15, 16],
      hourly_breakdown: normalised,
      recommendation: peakHours.length > 0
        ? `Be available during ${peakHours.map((h) => `${h}:00`).join(', ')} for maximum bookings`
        : 'Demand data still accumulating — check back after your first few bookings',
    });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/demand/log (internal — called by search/quote controllers)
 * Logs a demand signal for later aggregation by the cron job.
 */
async function logDemandSignal(req, res, next) {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Admin only' });
    }

    const { category_id, city, signal_type = 'search' } = req.body;
    if (!city || !category_id) {
      return res.status(400).json({ error: 'category_id and city are required' });
    }

    const now = new Date();
    const hour = now.getHours();
    const dow = now.getDay();
    const weekStart = new Date(now);
    weekStart.setDate(now.getDate() - dow);
    const weekStartStr = weekStart.toISOString().split('T')[0];

    const col = signal_type === 'quote' ? 'quote_count' : 'search_count';
    await pool.query(
      `INSERT INTO service_demand_logs (category_id, city, hour_of_day, day_of_week, week_start, ${col})
       VALUES ($1, $2, $3, $4, $5, 1)
       ON CONFLICT (category_id, city, hour_of_day, day_of_week, week_start)
       DO UPDATE SET ${col} = service_demand_logs.${col} + 1`,
      [category_id, city, hour, dow, weekStartStr]
    );

    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}

module.exports = { getDemandForecast, getAreaDemand, getPeakHours, logDemandSignal };
