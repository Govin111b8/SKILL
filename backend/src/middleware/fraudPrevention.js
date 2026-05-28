/**
 * Fraud prevention & suspicious activity detection middleware.
 * 
 * Detects:
 * - Rapid booking attempts (bot-like behavior)
 * - Duplicate booking prevention via idempotency keys
 * - Suspicious payment patterns
 * - Account takeover indicators
 * 
 * Uses Redis for distributed state (multi-instance safe).
 * Falls back to in-memory Maps when Redis is unavailable.
 */

const { query } = require('../config/database');
const logger = require('../config/logger');
const redis = require('../config/redis');

// In-memory fallback stores (only used when Redis is unavailable)
const actionCounters = new Map();
const idempotencyKeys = new Map();

// Cleanup old in-memory entries every 5 minutes (fallback only)
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of actionCounters) {
    if (now - entry.firstAt > 3600000) {
      actionCounters.delete(key);
    }
  }
  for (const [key, entry] of idempotencyKeys) {
    if (now - entry.createdAt > 86400000) {
      idempotencyKeys.delete(key);
    }
  }
}, 300000);

const IDEMPOTENCY_PREFIX = 'idempotency:';
const ACTION_COUNTER_PREFIX = 'action_counter:';
const IDEMPOTENCY_TTL = 86400; // 24 hours
const ACTION_COUNTER_TTL = 3600; // 1 hour

/**
 * Idempotency middleware — prevents duplicate bookings/payments.
 * Client sends `X-Idempotency-Key` header; if same key seen before,
 * returns the original response without processing again.
 */
async function idempotencyCheck(req, res, next) {
  const key = req.headers['x-idempotency-key'];
  if (!key) return next();

  const userId = req.user?.id || req.ip;
  const fullKey = `${userId}:${key}`;

  try {
    let existing;

    if (redis.isAvailable()) {
      existing = await redis.get(`${IDEMPOTENCY_PREFIX}${fullKey}`);
    } else {
      existing = idempotencyKeys.get(fullKey);
    }

    if (existing) {
      logger.info({ fullKey }, 'Idempotency key hit');
      return res.status(existing.statusCode).json(existing.body);
    }

    // Monkey-patch res.json to capture the response
    const originalJson = res.json.bind(res);
    res.json = (body) => {
      const entry = {
        statusCode: res.statusCode,
        body,
        createdAt: Date.now(),
      };

      if (redis.isAvailable()) {
        redis.set(`${IDEMPOTENCY_PREFIX}${fullKey}`, entry, IDEMPOTENCY_TTL).catch((err) => {
          logger.error({ err, fullKey }, 'Failed to store idempotency key in Redis');
        });
      } else {
        idempotencyKeys.set(fullKey, entry);
      }

      return originalJson(body);
    };

    next();
  } catch (err) {
    logger.error({ err }, 'Idempotency check error');
    next();
  }
}

/**
 * Action rate limiter — detects rapid repeated actions (bot behavior).
 * Uses Redis for distributed counting, falls back to in-memory.
 */
function actionRateLimit(action, maxAttempts = 5, windowMs = 60000) {
  const ttlSeconds = Math.ceil(windowMs / 1000);

  return async (req, res, next) => {
    const userId = req.user?.id || req.ip;
    const key = `${userId}:${action}`;
    const now = Date.now();

    try {
      let count;

      if (redis.isAvailable()) {
        const redisKey = `${ACTION_COUNTER_PREFIX}${key}`;
        count = await redis.incr(redisKey);
        if (count === 1) {
          await redis.expire(redisKey, ttlSeconds);
        }
      } else {
        let entry = actionCounters.get(key);
        if (!entry || (now - entry.firstAt) > windowMs) {
          entry = { count: 0, firstAt: now };
        }
        entry.count++;
        actionCounters.set(key, entry);
        count = entry.count;
      }

      if (count > maxAttempts) {
        logger.warn({
          userId,
          action,
          count,
          window: windowMs,
        }, 'Suspicious activity: action rate limit exceeded');

        return res.status(429).json({
          success: false,
          message: 'Too many attempts. Please try again later.',
          retryAfter: ttlSeconds,
        });
      }

      next();
    } catch (err) {
      logger.error({ err, key }, 'Action rate limit error');
      next();
    }
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
      logger.warn({ userId }, 'Suspicious: User created 10+ bookings in 1 hour');
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
    logger.error({ err: error }, 'Fraud check error');
    next();
  }
}

/**
 * Detect account takeover indicators
 */
async function detectAccountTakeover(req, res, next) {
  if (!req.user) return next();

  // Track password change attempts
  if (req.path.includes('password') && req.method === 'PUT') {
    const userId = req.user.id;
    const key = `pwd_change:${userId}`;

    try {
      let count;
      if (redis.isAvailable()) {
        const redisKey = `${ACTION_COUNTER_PREFIX}${key}`;
        count = await redis.incr(redisKey);
        if (count === 1) {
          await redis.expire(redisKey, 3600); // 1 hour window
        }
      } else {
        const entry = actionCounters.get(key) || { count: 0, firstAt: Date.now() };
        entry.count++;
        actionCounters.set(key, entry);
        count = entry.count;
      }

      if (count >= 3) {
        logger.warn({ userId, count }, 'Account takeover indicator: multiple password changes');
      }
    } catch (err) {
      logger.error({ err }, 'Account takeover detection error');
    }
  }

  next();
}

module.exports = {
  idempotencyCheck,
  actionRateLimit,
  detectSuspiciousBooking,
  detectAccountTakeover,
};
