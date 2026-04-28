// Lightweight WebSocket hub: per-user channels, with auth via ?token=JWT
const { WebSocketServer } = require('ws');
const jwt = require('jsonwebtoken');

const sockets = new Map(); // userId -> Set<ws>

function attach(server) {
  const wss = new WebSocketServer({ server, path: '/ws' });
  wss.on('connection', (ws, req) => {
    let userId = null;
    try {
      const url = new URL(req.url, 'http://localhost');
      const token = url.searchParams.get('token');
      if (!token) return ws.close(4001, 'no token');
      const payload = jwt.verify(token, process.env.JWT_SECRET);
      userId = payload.id;
    } catch (e) {
      return ws.close(4002, 'bad token');
    }
    if (!sockets.has(userId)) sockets.set(userId, new Set());
    sockets.get(userId).add(ws);
    ws.send(JSON.stringify({ type: 'hello', userId }));

    ws.on('message', (raw) => {
      try {
        const msg = JSON.parse(raw.toString());
        if (msg.type === 'ping') ws.send(JSON.stringify({ type: 'pong', t: Date.now() }));
      } catch (_) {}
    });
    ws.on('close', () => {
      const s = sockets.get(userId);
      if (s) { s.delete(ws); if (s.size === 0) sockets.delete(userId); }
    });
  });
}

function sendTo(userId, payload) {
  const s = sockets.get(String(userId));
  if (!s) return 0;
  const data = JSON.stringify(payload);
  let n = 0;
  for (const ws of s) {
    if (ws.readyState === 1) { ws.send(data); n++; }
  }
  return n;
}

function broadcast(payload) {
  for (const userId of sockets.keys()) sendTo(userId, payload);
}

module.exports = { attach, sendTo, broadcast };
