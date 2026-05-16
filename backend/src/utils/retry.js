/**
 * Retry utility — exponential backoff for external service calls
 */
const logger = require('../config/logger');

/**
 * Execute a function with retry and exponential backoff.
 * @param {Function} fn - Async function to execute
 * @param {object} options
 * @param {number} options.maxRetries - Max retry attempts (default: 3)
 * @param {number} options.baseDelay - Base delay in ms (default: 1000)
 * @param {string} options.serviceName - Name for logging (default: 'unknown')
 * @param {Function} options.shouldRetry - Predicate to determine if error is retryable (default: always true)
 * @returns {Promise<*>} Result of fn
 */
async function withRetry(fn, options = {}) {
  const {
    maxRetries = 3,
    baseDelay = 1000,
    serviceName = 'unknown',
    shouldRetry = () => true,
  } = options;

  let lastError;
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;
      if (attempt >= maxRetries || !shouldRetry(err)) {
        logger.error({ err, serviceName, attempt, maxRetries }, `${serviceName} failed after ${attempt + 1} attempt(s)`);
        throw err;
      }
      const delay = baseDelay * Math.pow(2, attempt) + Math.random() * 500;
      logger.warn({ serviceName, attempt: attempt + 1, maxRetries, delay: Math.round(delay) }, `${serviceName} attempt ${attempt + 1} failed — retrying in ${Math.round(delay)}ms`);
      await new Promise(r => setTimeout(r, delay));
    }
  }
  throw lastError;
}

module.exports = { withRetry };
