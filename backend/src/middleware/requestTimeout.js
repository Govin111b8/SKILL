/**
 * Request Timeout Middleware
 * 
 * Enforces maximum request duration to prevent hung connections and
 * resource exhaustion attacks. Returns 408 if the request exceeds
 * the configured timeout.
 * 
 * Default: 30s for most endpoints, 60s for search/analytics/AI endpoints.
 */

const logger = require('../config/logger');

// Paths that get extended timeout (60s)
const EXTENDED_TIMEOUT_PATHS = [
  '/api/search',
  '/api/analytics',
  '/api/ai',
  '/api/demand',
  '/api/admin',
  '/api/discover',
];

const DEFAULT_TIMEOUT_MS = 30000;   // 30 seconds
const EXTENDED_TIMEOUT_MS = 60000;  // 60 seconds

/**
 * Creates a timeout middleware with configurable duration.
 * @param {number} [timeoutMs] - Optional override timeout in milliseconds
 */
function requestTimeout(timeoutMs) {
  return (req, res, next) => {
    // Determine timeout: explicit override > path-based > default
    let timeout = timeoutMs || DEFAULT_TIMEOUT_MS;

    if (!timeoutMs) {
      const path = req.path || req.url || '';
      if (EXTENDED_TIMEOUT_PATHS.some((p) => path.startsWith(p))) {
        timeout = EXTENDED_TIMEOUT_MS;
      }
    }

    const timer = setTimeout(() => {
      if (!res.headersSent) {
        logger.warn({
          method: req.method,
          path: req.path,
          timeout,
          userId: req.user?.id,
        }, 'Request timed out');

        res.status(408).json({
          success: false,
          message: 'Request timeout. Please try again.',
        });
      }
    }, timeout);

    // Clean up timer when response finishes
    res.on('close', () => clearTimeout(timer));
    res.on('finish', () => clearTimeout(timer));

    next();
  };
}

module.exports = { requestTimeout, DEFAULT_TIMEOUT_MS, EXTENDED_TIMEOUT_MS };
