const logger = require('../config/logger');
const { config } = require('../config');

const errorHandler = (err, req, res, _next) => {
  const statusCode = err.statusCode || 500;

  // Structured error logging
  const logPayload = {
    requestId: req.id,
    method: req.method,
    url: req.originalUrl,
    statusCode,
    err,
    ...(req.user && { userId: req.user.id }),
  };

  if (statusCode >= 500) {
    logger.error(logPayload, `Unhandled error: ${err.message}`);
  } else {
    logger.warn(logPayload, `Client error: ${err.message}`);
  }

  // Never expose raw DB or internal errors to clients
  let message;
  if (statusCode < 500) {
    message = err.message || 'Bad request';
  } else {
    message = config.isDevelopment ? err.message : 'Internal server error';
  }

  res.status(statusCode).json({
    success: false,
    message,
    ...(config.isDevelopment && { stack: err.stack }),
    ...(req.id && { requestId: req.id }),
  });
};

module.exports = errorHandler;
