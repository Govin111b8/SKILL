/**
 * Redis client — ioredis
 *
 * Required env vars (only when REDIS_URL or REDIS_HOST is set):
 *   REDIS_URL          e.g. redis://localhost:6379
 *   REDIS_HOST         e.g. localhost  (used when REDIS_URL is absent)
 *   REDIS_PORT         default 6379
 *   REDIS_PASSWORD     optional
 *   REDIS_TLS          'true' to enable TLS (Upstash, ElastiCache)
 *
 * Falls back to a no-op stub when Redis is not configured so that
 * the app works in development without Redis installed.
 */

const logger = require('./logger');

const REDIS_URL = process.env.REDIS_URL || '';
const REDIS_HOST = process.env.REDIS_HOST || '';
const REDIS_ENABLED = !!(REDIS_URL || REDIS_HOST);

/** @type {import('ioredis').Redis | null} */
let client = null;

if (REDIS_ENABLED) {
  try {
    const Redis = require('ioredis');
    const options = {
      maxRetriesPerRequest: 3,
      lazyConnect: false,
      enableReadyCheck: true,
      retryStrategy: (times) => {
        if (times > 5) {
          logger.error('Redis connection failed after 5 retries — giving up');
          return null; // Stop retrying
        }
        return Math.min(times * 200, 2000);
      },
    };

    if (REDIS_URL) {
      client = new Redis(REDIS_URL, options);
    } else {
      client = new Redis({
        host: REDIS_HOST,
        port: parseInt(process.env.REDIS_PORT || '6379', 10),
        password: process.env.REDIS_PASSWORD || undefined,
        tls: process.env.REDIS_TLS === 'true' ? {} : undefined,
        ...options,
      });
    }

    client.on('connect', () => logger.info('Redis connected'));
    client.on('error', (err) => logger.error({ err }, 'Redis error'));
    client.on('close', () => logger.warn('Redis connection closed'));
  } catch (err) {
    logger.error({ err }, 'Failed to initialise Redis client — falling back to in-memory');
    client = null;
  }
} else {
  logger.info('Redis not configured — using in-memory fallback');
}

/**
 * Set a key with an optional TTL (seconds).
 * Falls back to no-op when Redis is unavailable.
 */
async function set(key, value, ttlSeconds = 0) {
  if (!client) return;
  const serialised = typeof value === 'string' ? value : JSON.stringify(value);
  if (ttlSeconds > 0) {
    await client.setex(key, ttlSeconds, serialised);
  } else {
    await client.set(key, serialised);
  }
}

/**
 * Get a value. Returns null when key not found or Redis unavailable.
 * Automatically parses JSON if the stored value is a JSON string.
 */
async function get(key) {
  if (!client) return null;
  const raw = await client.get(key);
  if (raw === null) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return raw; // Return as plain string if not JSON
  }
}

/** Delete one or more keys. */
async function del(...keys) {
  if (!client) return;
  await client.del(...keys);
}

/** Set TTL on an existing key. */
async function expire(key, ttlSeconds) {
  if (!client) return;
  await client.expire(key, ttlSeconds);
}

/** Increment a counter (atomic). Returns the new value. */
async function incr(key) {
  if (!client) return 0;
  return client.incr(key);
}

/** Check if Redis is available. */
function isAvailable() {
  return !!client;
}

/** Gracefully close the connection (called on shutdown). */
async function quit() {
  if (client) await client.quit();
}

module.exports = {
  client,
  set,
  get,
  del,
  expire,
  incr,
  isAvailable,
  quit,
};
