/**
 * Analytics event ingestion controller.
 * Receives batched events from mobile app for:
 * - User behavior tracking (funnel analysis)
 * - Drop-off point detection
 * - Performance metrics
 * - Feature usage analytics
 */

const { query } = require('../config/database');
const logger = require('../config/logger');

/**
 * Ingest a batch of analytics events from the mobile app.
 * POST /analytics/events
 */
const ingestEvents = async (req, res, next) => {
  try {
    const userId = req.user?.id || null;
    const { events, session_id, session_duration_ms } = req.body;

    if (!events || !Array.isArray(events) || events.length === 0) {
      return res.status(400).json({ success: false, message: 'Events array required' });
    }

    // Batch insert events
    const values = [];
    const params = [];
    let paramIndex = 1;

    for (const event of events.slice(0, 100)) { // Max 100 events per batch
      values.push(`($${paramIndex++}, $${paramIndex++}, $${paramIndex++}, $${paramIndex++}, $${paramIndex++})`);
      params.push(
        userId,
        event.event || 'unknown',
        event.timestamp || new Date().toISOString(),
        session_id || null,
        JSON.stringify(event.properties || {}),
      );
    }

    await query(
      `INSERT INTO analytics_events (user_id, event_name, event_timestamp, session_id, properties)
       VALUES ${values.join(', ')}`,
      params
    );

    // Log session duration for session-level analytics
    if (session_id && session_duration_ms) {
      await query(
        `INSERT INTO analytics_sessions (user_id, session_id, duration_ms, events_count, started_at)
         VALUES ($1, $2, $3, $4, NOW())
         ON CONFLICT (session_id) DO UPDATE SET duration_ms = $3, events_count = analytics_sessions.events_count + $4`,
        [userId, session_id, session_duration_ms, events.length]
      );
    }

    res.json({ success: true, ingested: events.length });
  } catch (error) {
    // Don't fail the request — analytics shouldn't block the user
    logger.error('Analytics ingestion error:', error);
    res.json({ success: true, ingested: 0 });
  }
};

/**
 * Get funnel analytics for admin dashboard.
 * GET /analytics/funnel
 * Shows conversion rates: search → profile_view → booking_started → booking_confirmed
 */
const getFunnelAnalytics = async (req, res, next) => {
  try {
    const { days = 30 } = req.query;

    const funnel = await query(
      `SELECT 
         event_name,
         COUNT(DISTINCT user_id) as unique_users,
         COUNT(*) as total_events
       FROM analytics_events
       WHERE event_timestamp > NOW() - INTERVAL '${parseInt(days)} days'
         AND event_name IN ('searchCompleted', 'providerProfileViewed', 'bookingStarted', 'bookingConfirmed', 'paymentCompleted')
       GROUP BY event_name
       ORDER BY total_events DESC`,
      []
    );

    // Drop-off analysis
    const dropoffs = await query(
      `SELECT 
         properties->>'last_step' as last_step,
         properties->>'reason' as reason,
         COUNT(*) as count
       FROM analytics_events
       WHERE event_name = 'bookingDropOff'
         AND event_timestamp > NOW() - INTERVAL '${parseInt(days)} days'
       GROUP BY properties->>'last_step', properties->>'reason'
       ORDER BY count DESC
       LIMIT 20`,
      []
    );

    res.json({
      success: true,
      data: {
        funnel: funnel.rows,
        dropoffs: dropoffs.rows,
        period_days: parseInt(days),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get performance metrics
 * GET /analytics/performance
 */
const getPerformanceMetrics = async (req, res, next) => {
  try {
    const { days = 7 } = req.query;

    const metrics = await query(
      `SELECT 
         event_name,
         AVG((properties->>'duration_ms')::int) as avg_duration,
         MAX((properties->>'duration_ms')::int) as max_duration,
         COUNT(*) as sample_count
       FROM analytics_events
       WHERE event_name IN ('cold_start', 'screen_load', 'slow_api')
         AND event_timestamp > NOW() - INTERVAL '${parseInt(days)} days'
         AND properties->>'duration_ms' IS NOT NULL
       GROUP BY event_name`,
      []
    );

    res.json({
      success: true,
      data: {
        metrics: metrics.rows,
        period_days: parseInt(days),
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { ingestEvents, getFunnelAnalytics, getPerformanceMetrics };
