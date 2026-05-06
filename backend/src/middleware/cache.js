/**
 * Cache middleware — Redis-first, in-memory LRU fallback.
 *
 * When Redis is configured (REDIS_URL / REDIS_HOST), all cache reads and
 * writes go through Redis so that multiple API server instances share the
 * same cache state (horizontal scaling).
 *
 * When Redis is NOT configured the existing in-memory LRU is used, which
 * works correctly for single-instance deployments.
 *
 * For production scaling:
 * - Set REDIS_URL=redis://<host>:6379 in your environment
 * - All instances will share the cache automatically
 */

const redis = require('../config/redis');

class LRUCache {
  constructor(maxSize = 500, defaultTTL = 300) {
    this.maxSize = maxSize;
    this.defaultTTL = defaultTTL * 1000; // Convert to ms
    this.cache = new Map();
    this.hits = 0;
    this.misses = 0;
  }

  get(key) {
    const entry = this.cache.get(key);
    if (!entry) {
      this.misses++;
      return null;
    }

    // Check TTL
    if (Date.now() > entry.expiry) {
      this.cache.delete(key);
      this.misses++;
      return null;
    }

    // Move to end (most recently used)
    this.cache.delete(key);
    this.cache.set(key, entry);
    this.hits++;
    return entry.value;
  }

  set(key, value, ttl) {
    // Evict oldest if at capacity
    if (this.cache.size >= this.maxSize) {
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }

    this.cache.set(key, {
      value,
      expiry: Date.now() + (ttl ? ttl * 1000 : this.defaultTTL),
      createdAt: Date.now(),
    });
  }

  invalidate(pattern) {
    if (typeof pattern === 'string') {
      this.cache.delete(pattern);
    } else if (pattern instanceof RegExp) {
      for (const key of this.cache.keys()) {
        if (pattern.test(key)) {
          this.cache.delete(key);
        }
      }
    }
  }

  clear() {
    this.cache.clear();
  }

  stats() {
    const total = this.hits + this.misses;
    return {
      size: this.cache.size,
      maxSize: this.maxSize,
      hits: this.hits,
      misses: this.misses,
      hitRate: total > 0 ? ((this.hits / total) * 100).toFixed(1) + '%' : '0%',
    };
  }
}

// Singleton cache instances
const searchCache = new LRUCache(200, 60);       // 60s TTL for search
const categoryCache = new LRUCache(50, 600);     // 10min TTL for categories
const providerCache = new LRUCache(300, 120);    // 2min TTL for provider data

/**
 * Express middleware for response caching.
 * Usage: app.get('/search', cacheMiddleware('search', 60), searchController)
 */
function cacheMiddleware(cacheType = 'search', ttl = 60) {
  const cacheInstance = {
    search: searchCache,
    category: categoryCache,
    provider: providerCache,
  }[cacheType] || searchCache;

  return async (req, res, next) => {
    // Only cache GET requests
    if (req.method !== 'GET') return next();

    const key = `cache:${cacheType}:${req.originalUrl}`;

    // --- Redis read ---
    if (redis.isAvailable()) {
      try {
        const cached = await redis.get(key);
        if (cached) {
          res.set('X-Cache', 'HIT');
          return res.json(cached);
        }
      } catch (_) { /* fall through to in-memory */ }
    } else {
      // --- In-memory read ---
      const cached = cacheInstance.get(req.originalUrl);
      if (cached) {
        res.set('X-Cache', 'HIT');
        return res.json(cached);
      }
    }

    // Monkey-patch res.json to intercept the response
    const originalJson = res.json.bind(res);
    res.json = async (body) => {
      if (res.statusCode >= 200 && res.statusCode < 300 && body && body.success !== false) {
        if (redis.isAvailable()) {
          try { await redis.set(key, body, ttl); } catch (_) { /* ignore */ }
        } else {
          cacheInstance.set(req.originalUrl, body, ttl);
        }
      }
      res.set('X-Cache', 'MISS');
      return originalJson(body);
    };

    next();
  };
}

/**
 * Check whether a Redis cache key matches the given pattern.
 * Extracted for readability and testability.
 * @param {string} key
 * @param {string|RegExp|undefined} pattern
 * @returns {boolean}
 */
function matchesPattern(key, pattern) {
  if (!pattern) return true;
  if (typeof pattern === 'string') return key.includes(pattern);
  if (pattern instanceof RegExp) return pattern.test(key);
  return true;
}

/**
 * Invalidate cache entries matching a pattern.
 * Purges both Redis (pattern scan) and in-memory.
 * Call after mutations (booking created, review posted, etc.)
 */
async function invalidateCache(cacheType, pattern) {
  // In-memory invalidation
  const cacheInstance = {
    search: searchCache,
    category: categoryCache,
    provider: providerCache,
  }[cacheType];

  if (cacheInstance) {
    cacheInstance.invalidate(pattern);
  }

  // Redis invalidation — scan for matching keys and delete them
  if (redis.isAvailable() && redis.client) {
    try {
      const prefix = `cache:${cacheType}:`;
      const stream = redis.client.scanStream({ match: `${prefix}*`, count: 100 });
      const keysToDelete = [];

      await new Promise((resolve, reject) => {
        stream.on('data', (keys) => {
          for (const k of keys) {
            if (matchesPattern(k, pattern)) keysToDelete.push(k);
          }
        });
        stream.on('end', resolve);
        stream.on('error', reject);
      });

      if (keysToDelete.length > 0) {
        await redis.del(...keysToDelete);
      }
    } catch (_) { /* Redis scan errors are non-critical */ }
  }
}

/**
 * Get cache statistics for monitoring
 */
function getCacheStats() {
  return {
    redis: redis.isAvailable() ? 'connected' : 'not configured',
    search: searchCache.stats(),
    category: categoryCache.stats(),
    provider: providerCache.stats(),
  };
}

module.exports = {
  LRUCache,
  cacheMiddleware,
  invalidateCache,
  getCacheStats,
  searchCache,
  categoryCache,
  providerCache,
};
