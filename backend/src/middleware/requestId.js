/**
 * Middleware to attach a unique correlation ID to every request.
 * Used for distributed tracing and log correlation.
 */

const crypto = require('crypto');
const logger = require('../config/logger');

const requestId = (req, res, next) => {
  const id = req.headers['x-request-id'] || crypto.randomUUID();
  req.id = id;
  res.setHeader('X-Request-Id', id);

  // Attach a child logger with request context
  req.log = logger.child({ requestId: id });

  next();
};

module.exports = requestId;
