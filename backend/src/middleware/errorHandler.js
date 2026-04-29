const errorHandler = (err, req, res, _next) => {
  console.error(err.stack);

  const statusCode = err.statusCode || 500;

  // Never expose raw DB or internal errors to clients
  let message;
  if (statusCode < 500) {
    message = err.message || 'Bad request';
  } else {
    message = process.env.NODE_ENV === 'development' ? err.message : 'Internal server error';
  }

  res.status(statusCode).json({
    success: false,
    message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

module.exports = errorHandler;
