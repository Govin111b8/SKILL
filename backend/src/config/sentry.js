/**
 * Sentry — Error Tracking & Performance Monitoring
 *
 * Initialise before requiring any other module.
 * Sentry is disabled when SENTRY_DSN is not set (dev / test).
 *
 * Required env vars:
 *   SENTRY_DSN        — DSN from Sentry project settings
 *   SENTRY_RELEASE    — semver string, e.g. "1.2.3" (optional, defaults to git sha)
 *   SENTRY_TRACES_SAMPLE_RATE — 0–1, default 0.1 (10 % sampling)
 */

const Sentry = require('@sentry/node');
const logger = require('./logger');

const DSN = process.env.SENTRY_DSN || '';
const RELEASE = process.env.SENTRY_RELEASE || process.env.GIT_SHA || 'local';
const TRACES_SAMPLE_RATE = parseFloat(process.env.SENTRY_TRACES_SAMPLE_RATE || '0.1');
const ENV = process.env.NODE_ENV || 'development';

if (DSN) {
  Sentry.init({
    dsn: DSN,
    release: RELEASE,
    environment: ENV,
    tracesSampleRate: TRACES_SAMPLE_RATE,
    // Don't report in test environment
    enabled: ENV !== 'test',
    // Scrub sensitive fields from breadcrumbs and event payloads
    beforeSend(event) {
      // Strip authorization header if captured
      if (event.request && event.request.headers) {
        delete event.request.headers['authorization'];
        delete event.request.headers['cookie'];
      }
      return event;
    },
  });
  logger.info({ release: RELEASE, env: ENV, tracesSampleRate: TRACES_SAMPLE_RATE }, 'Sentry initialised');
} else {
  logger.debug('SENTRY_DSN not set — error reporting disabled');
}

/**
 * Express error handler — must be registered AFTER all routes.
 * Forwards unhandled errors to Sentry then calls next(err).
 */
function sentryErrorHandler() {
  return Sentry.expressErrorHandler ? Sentry.expressErrorHandler() : (_err, _req, _res, next) => next(_err);
}

/**
 * Capture an exception manually (use in catch blocks for expected errors
 * that you still want visibility on).
 */
function captureException(err, context = {}) {
  if (!DSN || ENV === 'test') return;
  Sentry.withScope((scope) => {
    Object.entries(context).forEach(([k, v]) => scope.setExtra(k, v));
    Sentry.captureException(err);
  });
}

module.exports = { sentryErrorHandler, captureException, Sentry };
