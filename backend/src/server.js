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
