require('dotenv').config();

const http = require('http');
const app = require('./app');
const hub = require('./realtime/hub');

const PORT = process.env.PORT || 5000;
const server = http.createServer(app);
hub.attach(server);

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT} (HTTP + WebSocket /ws)`);
});

// Graceful shutdown
function shutdown(signal) {
  console.log(`\n${signal} received. Shutting down gracefully...`);
  server.close(() => {
    console.log('HTTP server closed.');
    process.exit(0);
  });
  // Force exit after 10s if connections don't drain
  setTimeout(() => { process.exit(1); }, 10000);
}
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
