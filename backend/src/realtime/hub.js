// Production WebSocket hub: per-user channels, auth, heartbeat, presence, typing, read receipts
const { WebSocketServer } = require('ws');
const jwt = require('jsonwebtoken');
const { query } = require('../config/database');
const { config } = require('../config');
const logger = require('../config/logger');

const sockets = new Map(); // userId -> Set<ws>
const presence = new Map(); // userId -> { lastSeen: Date, status: 'online'|'away'|'offline' }

const HEARTBEAT_INTERVAL = 30000; // 30s sweep

function attach(server) {
  const wss = new WebSocketServer({ server, path: '/ws' });

  // Heartbeat sweep — kill dead sockets
  const heartbeat = setInterval(() => {
    wss.clients.forEach((ws) => {
      if (ws._alive === false) { ws.terminate(); return; }
      ws._alive = false;
      ws.ping();
    });
  }, HEARTBEAT_INTERVAL);

  wss.on('close', () => clearInterval(heartbeat));

  wss.on('connection', (ws, req) => {
    let userId = null;
    try {
      const url = new URL(req.url, 'http://localhost');
      const token = url.searchParams.get('token');
      if (!token) return ws.close(4001, 'no token');
      const payload = jwt.verify(token, config.jwt.secret);
      userId = payload.id;
    } catch (e) {
      return ws.close(4002, 'bad token');
    }

    // Track connection
    ws._alive = true;
    ws._userId = userId;
    if (!sockets.has(userId)) sockets.set(userId, new Set());
    sockets.get(userId).add(ws);

    // Update presence
    presence.set(userId, { lastSeen: new Date(), status: 'online' });

    ws.send(JSON.stringify({ type: 'hello', userId, ts: Date.now() }));

    ws.on('pong', () => { ws._alive = true; });

    ws.on('message', (raw) => {
      try {
        const msg = JSON.parse(raw.toString());
        switch (msg.type) {
          case 'ping':
            ws._alive = true;
            ws.send(JSON.stringify({ type: 'pong', t: Date.now() }));
            break;
          case 'typing':
            if (msg.threadId && msg.to) {
              sendTo(msg.to, { type: 'typing', threadId: msg.threadId, userId, typing: msg.typing !== false });
            }
            break;
          case 'read_receipt':
            if (msg.threadId) handleReadReceipt(userId, msg.threadId);
            break;
          case 'presence':
            if (msg.status) presence.set(userId, { lastSeen: new Date(), status: msg.status });
            break;
        }
      } catch (_) {}
    });

    ws.on('close', () => {
      const s = sockets.get(userId);
      if (s) { s.delete(ws); if (s.size === 0) sockets.delete(userId); }
      if (!sockets.has(userId)) {
        presence.set(userId, { lastSeen: new Date(), status: 'offline' });
      }
    });

    ws.on('error', () => ws.terminate());
  });
}

async function handleReadReceipt(userId, threadId) {
  try {
    await query(
      `UPDATE messages SET read_at = NOW() WHERE thread_id = $1 AND sender_id <> $2 AND read_at IS NULL`,
      [threadId, userId]
    );
    const t = await query(
      `SELECT t.customer_id, p.user_id AS pro_user_id
       FROM message_threads t JOIN professionals p ON t.professional_id = p.id WHERE t.id = $1`,
      [threadId]
    );
    if (!t.rows.length) return;
    const thread = t.rows[0];
    const isCustomer = thread.customer_id === userId;
    if (isCustomer) {
      await query(`UPDATE message_threads SET customer_unread = 0 WHERE id = $1`, [threadId]);
    } else {
      await query(`UPDATE message_threads SET pro_unread = 0 WHERE id = $1`, [threadId]);
    }
    const otherUserId = isCustomer ? thread.pro_user_id : thread.customer_id;
    sendTo(otherUserId, { type: 'messages_read', threadId, by: userId, at: Date.now() });
  } catch (_) {}
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
  const data = JSON.stringify(payload);
  for (const [, set] of sockets) {
    for (const ws of set) { if (ws.readyState === 1) ws.send(data); }
  }
}

function isOnline(userId) {
  return sockets.has(String(userId)) && sockets.get(String(userId)).size > 0;
}

function getPresence(userId) {
  const p = presence.get(String(userId));
  if (!p) return { status: 'offline', lastSeen: null };
  if (isOnline(userId)) return { status: p.status || 'online', lastSeen: p.lastSeen };
  return { status: 'offline', lastSeen: p.lastSeen };
}

module.exports = { attach, sendTo, broadcast, isOnline, getPresence };
