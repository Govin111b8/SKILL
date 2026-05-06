/**
 * Feature Flag Middleware
 *
 * Gates API routes behind environment-variable feature flags.
 * When a feature is disabled, the middleware returns 404 with a
 * clear message rather than exposing an internal error.
 *
 * Usage in routes:
 *   const { requireFeature } = require('../middleware/featureFlags');
 *   router.use(requireFeature('BOOKINGS'));  // All routes in file
 *   router.post('/create', requireFeature('BOOKINGS'), handler);
 *
 * Configuration (environment variables):
 *   FEATURE_SEARCH=true
 *   FEATURE_BOOKINGS=true
 *   FEATURE_CHAT=true
 *   FEATURE_DISPUTES=true
 *   FEATURE_EMERGENCIES=false   ← disabled by default
 *   FEATURE_WARRANTIES=false    ← disabled by default
 *   FEATURE_AGENTS=false        ← disabled by default
 */

const logger = require('../config/logger');

// Default feature flag values (conservative — disable risky features by default)
const DEFAULTS = {
  SEARCH: true,
  PROFILES: true,
  CONTACT_REVEAL: true,
  PORTFOLIO: true,
  SUBSCRIPTIONS: true,
  REVIEWS: true,
  KYC: true,
  NOTIFICATIONS: true,
  FAVORITES: true,
  BOOKINGS: true,
  CHAT: true,
  DISPUTES: true,
  EMERGENCIES: false,    // Require explicit opt-in
  WARRANTIES: false,     // Require explicit opt-in
  AGENTS: false,         // Require explicit opt-in
  ANALYTICS: true,
  ADMIN: true,
};

/**
 * Check whether a feature flag is enabled.
 * @param {string} feature - Feature name (e.g., 'BOOKINGS')
 * @returns {boolean}
 */
function isEnabled(feature) {
  const envKey = `FEATURE_${feature.toUpperCase()}`;
  const envValue = process.env[envKey];

  if (envValue === undefined) {
    // Fall back to default
    return DEFAULTS[feature.toUpperCase()] ?? true;
  }

  return envValue.toLowerCase() !== 'false' && envValue !== '0';
}

/**
 * Express middleware that blocks a route when its feature flag is disabled.
 * @param {string} feature - Feature name (e.g., 'BOOKINGS')
 */
function requireFeature(feature) {
  return (req, res, next) => {
    if (isEnabled(feature)) {
      return next();
    }
    logger.info({ feature, path: req.path }, 'Feature disabled — returning 404');
    return res.status(404).json({
      success: false,
      message: `This feature is not currently available. Contact support@skillconnect.in for more information.`,
    });
  };
}

/**
 * Get all feature flags (for admin health endpoint)
 */
function getAllFlags() {
  return Object.keys(DEFAULTS).reduce((acc, key) => {
    acc[key] = isEnabled(key);
    return acc;
  }, {});
}

module.exports = { requireFeature, isEnabled, getAllFlags };
