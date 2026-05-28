/**
 * CSRF Protection Middleware
 * Uses the Synchronizer Token Pattern via csrf-sync.
 * 
 * - Generates a CSRF token and sends it as a cookie
 * - Validates the token from the X-CSRF-Token header on state-changing requests
 * - Skips validation for webhook endpoints and API-key authenticated requests
 */

const { csrfSync } = require('csrf-sync');
const logger = require('../config/logger');

const {
  csrfSynchronisedProtection,
  generateToken,
} = csrfSync({
  getTokenFromRequest: (req) => {
    // Check header first, then body field
    return req.headers['x-csrf-token'] || req.body?._csrf || '';
  },
  getTokenFromState: (req) => {
    return req.cookies?.['csrf-token'] || '';
  },
  storeTokenInState: (req, res, token) => {
    // Store in a cookie so it's sent with every request
    res.cookie('csrf-token', token, {
      httpOnly: false, // Must be readable by JS to send in header
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 3600000, // 1 hour
      path: '/',
    });
  },
  size: 64,
});

/**
 * Paths that should skip CSRF validation (webhooks, health checks, etc.)
 */
const CSRF_SKIP_PATHS = [
  '/api/webhooks',
  '/api/health',
  '/metrics',
  '/api/auth/login',
  '/api/auth/register',
  '/api/auth/refresh',
  '/api/auth/forgot-password',
  '/api/auth/send-otp',
  '/api/auth/verify-otp',
];

/**
 * CSRF protection that skips safe methods and whitelisted paths.
 */
function csrfProtection(req, res, next) {
  // Skip safe (read-only) methods
  if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
    return next();
  }

  // Skip whitelisted paths
  const path = req.path || req.url;
  if (CSRF_SKIP_PATHS.some((skip) => path.startsWith(skip))) {
    return next();
  }

  // Skip if request has ****** (API authentication — not browser session)
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    return next();
  }

  // Apply CSRF check for cookie-based sessions
  try {
    csrfSynchronisedProtection(req, res, next);
  } catch (err) {
    logger.warn({ path: req.path, ip: req.ip }, 'CSRF validation failed');
    return res.status(403).json({
      success: false,
      message: 'CSRF token validation failed. Please refresh and try again.',
    });
  }
}

/**
 * Endpoint to get a fresh CSRF token.
 * Called by the frontend on page load.
 */
function getCsrfToken(req, res) {
  const token = generateToken(req, res);
  res.json({ success: true, data: { csrfToken: token } });
}

module.exports = { csrfProtection, getCsrfToken };
