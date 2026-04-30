require('dotenv').config();

const http = require('http');
const { config, validateConfig } = require('./config');
const logger = require('./config/logger');

// Validate configuration before starting
try {
  validateConfig();
} catch (err) {
  logger.fatal({ err }, 'Configuration validation failed');
  process.exit(1);
}

const app = require('./app');
const hub = require('./realtime/hub');

const server = http.createServer(app);
hub.attach(server);

server.listen(config.port, () => {
  logger.info({ port: config.port, env: config.env }, `Server running on port ${config.port} (HTTP + WebSocket /ws)`);
});

// Graceful shutdown
function shutdown(signal) {
  logger.info({ signal }, 'Shutdown signal received, draining connections...');
  server.close(() => {
    logger.info('HTTP server closed.');
    process.exit(0);
  });
  // Force exit after 10s if connections don't drain
  setTimeout(() => { process.exit(1); }, 10000);
}
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// Catch unhandled rejections
process.on('unhandledRejection', (reason) => {
  logger.fatal({ err: reason }, 'Unhandled promise rejection');
  process.exit(1);
});
process.on('uncaughtException', (err) => {
  logger.fatal({ err }, 'Uncaught exception');
  process.exit(1);
});
