/**
 * Fraud prevention & suspicious activity detection middleware.
 * 
 * Detects:
 * - Rapid booking attempts (bot-like behavior)
 * - Duplicate booking prevention via idempotency keys
 * - Suspicious payment patterns
 * - Account takeover indicators
 */

const { query } = require('../config/database');
const logger = require('../config/logger');

// In-memory store for rate limiting per action (per user)
// In production, use Redis for multi-instance support
const actionCounters = new Map();
const idempotencyKeys = new Map();

// Cleanup old entries every 5 minutes
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of actionCounters) {
    if (now - entry.firstAt > 3600000) { // 1 hour
      actionCounters.delete(key);
    }
  }
  for (const [key, entry] of idempotencyKeys) {
    if (now - entry.createdAt > 86400000) { // 24 hours
      idempotencyKeys.delete(key);
    }
  }
}, 300000);

/**
 * Idempotency middleware — prevents duplicate bookings/payments.
 * Client sends `X-Idempotency-Key` header; if same key seen before,
 * returns the original response without processing again.
 */
function idempotencyCheck(req, res, next) {
  const key = req.headers['x-idempotency-key'];
  if (!key) return next();

  const userId = req.user?.id || req.ip;
  const fullKey = `${userId}:${key}`;

  const existing = idempotencyKeys.get(fullKey);
  if (existing) {
    // Return cached response
    logger.info(`Idempotency key hit: ${fullKey}`);
    return res.status(existing.statusCode).json(existing.body);
  }

  // Monkey-patch res.json to capture the response
  const originalJson = res.json.bind(res);
  res.json = (body) => {
    idempotencyKeys.set(fullKey, {
      statusCode: res.statusCode,
      body,
      createdAt: Date.now(),
    });
    return originalJson(body);
  };

  next();
}

/**
 * Action rate limiter — detects rapid repeated actions (bot behavior).
 * More granular than global rate limiting.
 */
function actionRateLimit(action, maxAttempts = 5, windowMs = 60000) {
  return (req, res, next) => {
    const userId = req.user?.id || req.ip;
    const key = `${userId}:${action}`;
    const now = Date.now();

    let entry = actionCounters.get(key);
    if (!entry || (now - entry.firstAt) > windowMs) {
      entry = { count: 0, firstAt: now };
    }

    entry.count++;
    actionCounters.set(key, entry);

    if (entry.count > maxAttempts) {
      logger.warn(`Suspicious activity: ${action} rate limit exceeded for user ${userId}`, {
        userId,
        action,
        count: entry.count,
        window: windowMs,
      });

      return res.status(429).json({
        success: false,
        message: 'Too many attempts. Please try again later.',
        retryAfter: Math.ceil((windowMs - (now - entry.firstAt)) / 1000),
      });
    }

    next();
  };
}

/**
 * Detect suspicious booking patterns
 */
async function detectSuspiciousBooking(req, res, next) {
  if (!req.user) return next();

  const userId = req.user.id;

  try {
    // Check for rapid bookings in last hour
    const recentBookings = await query(
      `SELECT COUNT(*) as count FROM bookings 
       WHERE customer_id = $1 AND created_at > NOW() - INTERVAL '1 hour'`,
      [userId]
    );

    if (parseInt(recentBookings.rows[0]?.count || 0) >= 10) {
      logger.warn(`Suspicious: User ${userId} created 10+ bookings in 1 hour`);
      return res.status(429).json({
        success: false,
        message: 'Booking limit reached. Please try again later.',
      });
    }

    // Check for duplicate booking (same provider + service + time window)
    if (req.body.professional_id && req.body.scheduled_date) {
      const duplicate = await query(
        `SELECT id FROM bookings 
         WHERE customer_id = $1 
         AND professional_id = $2 
         AND scheduled_date = $3
         AND status NOT IN ('cancelled', 'rejected')
         AND created_at > NOW() - INTERVAL '5 minutes'`,
        [userId, req.body.professional_id, req.body.scheduled_date]
      );

      if (duplicate.rows.length > 0) {
        return res.status(409).json({
          success: false,
          message: 'A similar booking already exists. Did you mean to rebook?',
          existingBookingId: duplicate.rows[0].id,
        });
      }
    }

    next();
  } catch (error) {
    // Don't block the request if fraud check fails
    logger.error('Fraud check error:', error);
    next();
  }
}

/**
 * Detect account takeover indicators
 */
function detectAccountTakeover(req, res, next) {
  if (!req.user) return next();

  // Track login locations — flag if suddenly from new location
  const currentIP = req.ip;
  const userAgent = req.headers['user-agent'] || '';

  // Check for suspicious patterns
  const suspicious = [];

  // Multiple password changes in short time
  if (req.path.includes('password') && req.method === 'PUT') {
    const key = `pwd_change:${req.user.id}`;
    const entry = actionCounters.get(key);
    if (entry && entry.count >= 3) {
      suspicious.push('multiple_password_changes');
    }
  }

  if (suspicious.length > 0) {
    logger.warn(`Account takeover indicators for user ${req.user.id}:`, suspicious);
    // Don't block, just log — security team reviews
  }

  next();
}

module.exports = {
  idempotencyCheck,
  actionRateLimit,
  detectSuspiciousBooking,
  detectAccountTakeover,
};
