import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: Number(__ENV.VUS || 10),
  duration: __ENV.DURATION || '30s',
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<1000'],
  },
};

const BASE_URL = (__ENV.BASE_URL || 'http://localhost:5000/api').replace(/\/$/, '');
const AUTH_TOKEN = __ENV.AUTH_TOKEN || '';
const CITY = __ENV.CITY || 'Bengaluru';

function headers() {
  const base = { 'Content-Type': 'application/json' };
  if (AUTH_TOKEN) base.Authorization = 'Bearer ' + AUTH_TOKEN;
  return base;
}

export default function () {
  const q = encodeURIComponent(__ENV.SEARCH_QUERY || 'plumber');
  const res = http.get(`${BASE_URL}/search?q=${q}&city=${encodeURIComponent(CITY)}&page=1&limit=20`, { headers: headers() });
  check(res, {
    'search status is 200': (r) => r.status === 200,
  });
  sleep(1);
}
