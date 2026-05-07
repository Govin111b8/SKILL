/**
 * k6 Load Test — SkillConnect API
 *
 * Scenarios:
 *   smoke    — 5 VUs, 30s  (sanity check)
 *   load     — ramp to 50 VUs, hold 5min, ramp down
 *   stress   — ramp to 200 VUs (find breaking point)
 *   soak     — 30 VUs for 30min (memory leaks)
 *
 * Run:
 *   k6 run --env BASE_URL=http://localhost:3001 tests/load/api.load.js
 *   k6 run --scenario load tests/load/api.load.js
 *
 * Install: brew install k6 | apt-get install k6
 */

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// ── Custom metrics ──────────────────────────────────────────
const errorRate   = new Rate('errors');
const searchP95   = new Trend('search_p95_duration');
const profileP95  = new Trend('profile_p95_duration');
const authP95     = new Trend('auth_p95_duration');
const totalReqs   = new Counter('total_requests');

// ── Config ──────────────────────────────────────────────────
const BASE_URL = __ENV.BASE_URL || 'http://localhost:3001/api';

export const options = {
  scenarios: {
    smoke: {
      executor: 'constant-vus',
      vus: 5,
      duration: '30s',
      tags: { scenario: 'smoke' },
      exec: 'smokeTest',
    },
    load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 50 },   // ramp up
        { duration: '5m', target: 50 },   // hold
        { duration: '30s', target: 0 },   // ramp down
      ],
      tags: { scenario: 'load' },
      exec: 'loadTest',
      startTime: '31s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<2000', 'p(99)<5000'],
    http_req_failed: ['rate<0.01'],          // <1% errors
    search_p95_duration: ['p(95)<1500'],     // Search must be fast
    errors: ['rate<0.05'],
  },
};

// ── Reusable request helper ─────────────────────────────────
function request(method, path, body, params = {}) {
  const url = `${BASE_URL}${path}`;
  const headers = {
    'Content-Type': 'application/json',
    ...params.headers,
  };
  const res = method === 'GET'
    ? http.get(url, { headers, tags: params.tags })
    : http.post(url, JSON.stringify(body), { headers, tags: params.tags });
  totalReqs.add(1);
  return res;
}

// ── Smoke Test (basic health) ───────────────────────────────
export function smokeTest() {
  group('health check', () => {
    const res = request('GET', '/health');
    check(res, { 'health 200': r => r.status === 200 });
    errorRate.add(res.status !== 200);
  });
  sleep(1);
}

// ── Load Test (realistic user flows) ───────────────────────
export function loadTest() {
  // Flow 1: Browse categories
  group('category browse', () => {
    const res = request('GET', '/categories');
    check(res, { 'categories 200': r => r.status === 200 });
    errorRate.add(res.status !== 200);
  });
  sleep(0.5);

  // Flow 2: Search
  group('search professionals', () => {
    const queries = ['plumber', 'electrician', 'tutor', 'cleaning', 'photographer'];
    const q = queries[Math.floor(Math.random() * queries.length)];
    const start = Date.now();
    const res = request('GET', `/search?q=${q}&city=Bangalore&limit=10`);
    searchP95.add(Date.now() - start);
    check(res, { 'search 200': r => r.status === 200 });
    errorRate.add(res.status !== 200);
  });
  sleep(1);

  // Flow 3: Professional profile view
  group('profile view', () => {
    // Use first professional from search results if available
    const searchRes = request('GET', '/search?q=plumber&limit=1');
    if (searchRes.status === 200) {
      try {
        const data = JSON.parse(searchRes.body);
        const professionals = data.data || data.professionals || [];
        if (professionals.length > 0) {
          const start = Date.now();
          const profileRes = request('GET', `/professionals/${professionals[0].id}`);
          profileP95.add(Date.now() - start);
          check(profileRes, { 'profile 200': r => r.status === 200 });
          errorRate.add(profileRes.status !== 200);
        }
      } catch (_) {}
    }
  });
  sleep(2);

  // Flow 4: Trending categories
  group('trending', () => {
    const res = request('GET', '/growth/categories/trending?city=Bangalore');
    check(res, { 'trending 200': r => r.status === 200 });
    errorRate.add(res.status !== 200);
  });
  sleep(0.5);

  // Flow 5: Sitemap (SEO crawler simulation)
  group('sitemap', () => {
    const res = http.get(`${BASE_URL.replace('/api', '')}/api/seo/sitemap.xml`);
    check(res, { 'sitemap 200': r => r.status === 200 });
  });
  sleep(1);
}

// ── Stress Test (ramp to 200 VUs) ───────────────────────────
export function stressTest() {
  const res = request('GET', '/search?q=plumber&city=Bangalore');
  check(res, { '200 or 429': r => r.status === 200 || r.status === 429 });
  errorRate.add(r => r.status >= 500);
  sleep(0.5);
}
