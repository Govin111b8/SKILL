/**
 * k6 WebSocket Load Test — SkillConnect Real-Time Hub
 *
 * Tests WebSocket connection resilience under load.
 *
 * Run:
 *   k6 run --env BASE_URL=ws://localhost:3001 tests/load/websocket.load.js
 */

import ws from 'k6/ws';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';

const wsErrors    = new Rate('ws_errors');
const wsConnects  = new Counter('ws_connections');
const wsMessages  = new Counter('ws_messages_received');

const BASE_URL = __ENV.BASE_URL || 'ws://localhost:3001';

export const options = {
  scenarios: {
    ws_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 20 },
        { duration: '2m',  target: 20 },
        { duration: '15s', target: 0 },
      ],
    },
  },
  thresholds: {
    ws_errors: ['rate<0.05'],
  },
};

export default function() {
  // Use a dummy token for load testing — real test requires valid JWT
  const token = __ENV.TEST_TOKEN || 'dummy_token_for_load_test';
  const url = `${BASE_URL}/ws?token=${token}`;

  const res = ws.connect(url, {}, function(socket) {
    wsConnects.add(1);

    socket.on('open', () => {
      socket.send(JSON.stringify({ type: 'ping' }));
    });

    socket.on('message', (data) => {
      wsMessages.add(1);
      try {
        const msg = JSON.parse(data);
        check(msg, { 'has type field': m => !!m.type });
      } catch (_) {}
    });

    socket.on('error', () => {
      wsErrors.add(1);
    });

    // Hold connection for 5 seconds, send heartbeat
    socket.setTimeout(() => {
      socket.send(JSON.stringify({ type: 'ping' }));
      socket.setTimeout(() => {
        socket.close();
      }, 3000);
    }, 2000);
  });

  // Accept 4001/4002 as expected (no token) and 101 as success
  check(res, {
    'ws connected or rejected cleanly': r => [101, 4001, 4002].includes(r.status),
  });
  wsErrors.add(res.status >= 500);
  sleep(1);
}
