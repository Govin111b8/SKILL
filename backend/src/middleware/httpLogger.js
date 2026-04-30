/**
 * HTTP request/response logging middleware using pino.
 * Replaces morgan with structured JSON logging.
 */

const logger = require('../config/logger');
const { config } = require('../config/index');

const httpLogger = (req, res, next) => {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    const level = res.statusCode >= 500 ? 'error' : res.statusCode >= 400 ? 'warn' : 'info';

    const logData = {
      requestId: req.id,
      method: req.method,
      url: req.originalUrl,
      statusCode: res.statusCode,
      duration,
      userAgent: req.headers['user-agent'],
      ...(req.user && { userId: req.user.id }),
    };

    // In production, log all requests; in dev, skip health checks
    if (config.isDevelopment && req.originalUrl === '/api/health') return;

    logger[level](logData, `${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`);
  });

  next();
};

module.exports = httpLogger;
