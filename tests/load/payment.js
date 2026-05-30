import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: Number(__ENV.VUS || 5),
  duration: __ENV.DURATION || '20s',
  thresholds: {
    http_req_failed: ['rate<0.1'],
    http_req_duration: ['p(95)<1500'],
  },
};

const BASE_URL = (__ENV.BASE_URL || 'http://localhost:5000/api').replace(/\/$/, '');
const AUTH_TOKEN = __ENV.AUTH_TOKEN || '';
const BOOKING_ID = __ENV.BOOKING_ID || '00000000-0000-4000-8000-000000000001';
const METHOD = __ENV.PAYMENT_METHOD || 'cod';

export default function () {
  const payload = JSON.stringify({
    booking_id: BOOKING_ID,
    method: METHOD,
  });

  const headers = { 'Content-Type': 'application/json' };
  if (AUTH_TOKEN) headers.Authorization = 'Bearer ' + AUTH_TOKEN;

  const res = http.post(`${BASE_URL}/payments`, payload, {
    headers,
  });

  check(res, {
    'payment request handled': (r) => [200, 201, 400, 404].includes(r.status),
  });
  sleep(1);
}
