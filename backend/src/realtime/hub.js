// Production WebSocket hub: per-user channels, auth, heartbeat, presence, typing, read receipts
const { WebSocketServer } = require('ws');
const jwt = require('jsonwebtoken');
const { query } = require('../config/database');
const { config } = require('../config');
const logger = require('../config/logger');
const redis = require('../config/redis');

const sockets = new Map(); // userId -> Set<ws>
const presence = new Map(); // userId -> { lastSeen: Date, status: 'online'|'away'|'offline' }

const HEARTBEAT_INTERVAL = 30000; // 30s sweep


const REDIS_USER_CHANNEL_PATTERN = 'ws:user:*';
const REDIS_BROADCAST_CHANNEL = 'ws:broadcast';
let redisSubscriber = null;
let redisSubscriberReady = false;
let redisSubscriberInit = null;

function normalizeUserId(userId) {
  return String(userId);
}

function deliverToLocal(userId, payload) {
  const s = sockets.get(normalizeUserId(userId));
  if (!s) return 0;
  const data = JSON.stringify(payload);
  let sent = 0;
  for (const ws of s) {
    if (ws.readyState === 1) {
      ws.send(data);
      sent++;
    }
  }
  return sent;
}

function deliverBroadcastLocal(payload) {
  const data = JSON.stringify(payload);
  for (const [, set] of sockets) {
    for (const ws of set) {
      if (ws.readyState === 1) ws.send(data);
    }
  }
}

async function ensureRedisSubscriber() {
  if (!redis.isAvailable() || !redis.client) return null;
  if (redisSubscriberReady) return redisSubscriber;
  if (redisSubscriberInit) return redisSubscriberInit;

  redisSubscriberInit = (async () => {
    redisSubscriber = redis.client.duplicate();

    redisSubscriber.on('pmessage', (pattern, channel, message) => {
      try {
        if (!channel.startsWith('ws:user:')) return;
        const userId = channel.replace('ws:user:', '');
        deliverToLocal(userId, JSON.parse(message));
      } catch (err) {
        logger.warn({ err: err.message, channel }, 'Failed to deliver Redis user WebSocket message');
      }
    });

    redisSubscriber.on('message', (channel, message) => {
      if (channel !== REDIS_BROADCAST_CHANNEL) return;
      try {
        deliverBroadcastLocal(JSON.parse(message));
      } catch (err) {
        logger.warn({ err: err.message, channel }, 'Failed to deliver Redis broadcast WebSocket message');
      }
    });

    redisSubscriber.on('error', (err) => {
      redisSubscriberReady = false;
      logger.error({ err: err.message }, 'Redis WebSocket subscriber error');
    });

    await redisSubscriber.connect();
    await redisSubscriber.psubscribe(REDIS_USER_CHANNEL_PATTERN);
    await redisSubscriber.subscribe(REDIS_BROADCAST_CHANNEL);
    redisSubscriberReady = true;
    logger.info('Redis WebSocket pub/sub enabled');
    return redisSubscriber;
  })().catch((err) => {
    redisSubscriberReady = false;
    redisSubscriberInit = null;
    logger.error({ err: err.message }, 'Failed to initialize Redis WebSocket pub/sub');
    return null;
  });

  return redisSubscriberInit;
}

async function publishToRedis(channel, payload) {
  if (!redis.isAvailable() || !redis.client || !redisSubscriberReady) return false;
  try {
    await redis.client.publish(channel, JSON.stringify(payload));
    return true;
  } catch (err) {
    logger.warn({ err: err.message, channel }, 'Failed to publish WebSocket event to Redis');
    return false;
  }
}

function attach(server) {
  ensureRedisSubscriber().catch((err) => logger.error({ err: err.message }, 'Redis pub/sub bootstrap failed'));

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
      userId = normalizeUserId(payload.id);
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
      } catch (err) { logger.warn({ err: err.message }, 'Failed to parse WebSocket message'); }
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
  } catch (err) { logger.warn({ err: err.message, threadId }, 'Failed to mark messages as read'); }
}

function sendTo(userId, payload) {
  const normalizedUserId = normalizeUserId(userId);
  if (redisSubscriberReady) {
    publishToRedis(`ws:user:${normalizedUserId}`, payload);
    return sockets.get(normalizedUserId)?.size || 0;
  }
  return deliverToLocal(normalizedUserId, payload);
}

function broadcast(payload) {
  if (redisSubscriberReady) {
    publishToRedis(REDIS_BROADCAST_CHANNEL, payload);
    return;
  }
  deliverBroadcastLocal(payload);
}

function isOnline(userId) {
  const normalizedUserId = normalizeUserId(userId);
  return sockets.has(normalizedUserId) && sockets.get(normalizedUserId).size > 0;
}

function getPresence(userId) {
  const p = presence.get(normalizeUserId(userId));
  if (!p) return { status: 'offline', lastSeen: null };
  if (isOnline(userId)) return { status: p.status || 'online', lastSeen: p.lastSeen };
  return { status: 'offline', lastSeen: p.lastSeen };
}

module.exports = { attach, sendTo, broadcast, isOnline, getPresence };
