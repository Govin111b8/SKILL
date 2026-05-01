/**
 * In-memory LRU cache middleware for frequently accessed data.
 * Used for search results, categories, and provider listings.
 * 
 * For production scaling:
 * - Replace with Redis when handling >10K concurrent users
 * - Current implementation handles up to ~5K concurrent users
 */

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

  return (req, res, next) => {
    // Only cache GET requests
    if (req.method !== 'GET') return next();

    // Build cache key from URL + query params
    const key = `${req.originalUrl}`;
    const cached = cacheInstance.get(key);

    if (cached) {
      res.set('X-Cache', 'HIT');
      return res.json(cached);
    }

    // Monkey-patch res.json to intercept the response
    const originalJson = res.json.bind(res);
    res.json = (body) => {
      // Only cache successful responses
      if (res.statusCode >= 200 && res.statusCode < 300 && body && body.success !== false) {
        cacheInstance.set(key, body, ttl);
      }
      res.set('X-Cache', 'MISS');
      return originalJson(body);
    };

    next();
  };
}

/**
 * Invalidate cache entries matching a pattern.
 * Call after mutations (booking created, review posted, etc.)
 */
function invalidateCache(cacheType, pattern) {
  const cacheInstance = {
    search: searchCache,
    category: categoryCache,
    provider: providerCache,
  }[cacheType];

  if (cacheInstance) {
    cacheInstance.invalidate(pattern);
  }
}

/**
 * Get cache statistics for monitoring
 */
function getCacheStats() {
  return {
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
