/**
 * Per-User Rate Limiting Middleware
 * 
 * Uses Redis (with in-memory fallback) to enforce per-user limits on
 * expensive operations like search, AI, and analytics endpoints.
 * 
 * Unlike express-rate-limit which is per-IP, this tracks by authenticated
 * user ID for more accurate limiting.
 */

const redis = require('../config/redis');
const logger = require('../config/logger');

// In-memory fallback when Redis is unavailable
const memoryStore = new Map();

// Cleanup stale entries every 5 minutes
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of memoryStore) {
    if (now > entry.expiresAt) {
      memoryStore.delete(key);
    }
  }
}, 300000);

/**
 * Create a per-user rate limiter for expensive operations.
 * 
 * @param {Object} options
 * @param {number} options.windowMs - Time window in milliseconds
 * @param {number} options.max - Maximum requests per user in the window
 * @param {string} options.prefix - Redis key prefix for this limiter
 * @param {string} [options.message] - Custom error message
 */
function perUserRateLimit({ windowMs, max, prefix, message }) {
  const ttlSeconds = Math.ceil(windowMs / 1000);
  const defaultMessage = message || `Rate limit exceeded. Maximum ${max} requests per ${Math.round(windowMs / 60000)} minutes.`;

  return async (req, res, next) => {
    // Use user ID if authenticated, fall back to IP
    const identifier = req.user?.id || req.ip;
    const key = `ratelimit:${prefix}:${identifier}`;

    try {
      let count;
      let remaining;

      if (redis.isAvailable()) {
        // Atomic increment with TTL in Redis
        count = await redis.incr(key);
        if (count === 1) {
          await redis.expire(key, ttlSeconds);
        }
        remaining = Math.max(0, max - count);
      } else {
        // In-memory fallback
        const now = Date.now();
        const entry = memoryStore.get(key);

        if (!entry || now > entry.expiresAt) {
          memoryStore.set(key, { count: 1, expiresAt: now + windowMs });
          count = 1;
        } else {
          entry.count++;
          count = entry.count;
        }
        remaining = Math.max(0, max - count);
      }

      // Set rate limit headers
      res.setHeader('X-RateLimit-Limit', max);
      res.setHeader('X-RateLimit-Remaining', remaining);

      if (count > max) {
        logger.warn({
          userId: req.user?.id,
          ip: req.ip,
          path: req.path,
          prefix,
          count,
          max,
        }, 'Per-user rate limit exceeded');

        return res.status(429).json({
          success: false,
          message: defaultMessage,
        });
      }

      next();
    } catch (err) {
      // On error, allow the request through (fail-open for availability)
      logger.error({ err, key }, 'Per-user rate limit error');
      next();
    }
  };
}

// Pre-configured limiters for common expensive operations
const searchRateLimit = perUserRateLimit({
  windowMs: 60 * 1000,     // 1 minute
  max: 30,                  // 30 searches per minute
  prefix: 'search',
  message: 'Too many search requests. Please wait a moment.',
});

const aiRateLimit = perUserRateLimit({
  windowMs: 60 * 1000,     // 1 minute
  max: 10,                  // 10 AI requests per minute
  prefix: 'ai',
  message: 'Too many AI requests. Please wait before trying again.',
});

const analyticsRateLimit = perUserRateLimit({
  windowMs: 60 * 1000,     // 1 minute
  max: 20,                  // 20 analytics requests per minute
  prefix: 'analytics',
  message: 'Too many analytics requests. Please slow down.',
});

module.exports = {
  perUserRateLimit,
  searchRateLimit,
  aiRateLimit,
  analyticsRateLimit,
};
