/**
 * Prometheus Metrics — SkillConnect Backend
 *
 * Exposes: GET /metrics  (text/plain; version=0.0.4)
 *
 * Collected metrics:
 *   - Default Node.js metrics (event loop lag, GC, heap, etc.)
 *   - HTTP request duration histogram (per route × method × status)
 *   - HTTP request throughput counter
 *   - Active WebSocket connections gauge
 *   - Job queue depth gauge
 *   - Database query duration histogram
 */

const client = require('prom-client');

// Use a dedicated registry so tests can reset it
const register = new client.Registry();

// Add default Node.js metrics (GC, heap, event-loop lag …)
client.collectDefaultMetrics({ register, prefix: 'skillconnect_' });

// ── HTTP ────────────────────────────────────────────────────────────────────

const httpRequestDuration = new client.Histogram({
  name: 'skillconnect_http_request_duration_seconds',
  help: 'HTTP request latency in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
  registers: [register],
});

const httpRequestTotal = new client.Counter({
  name: 'skillconnect_http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

// ── WebSocket ───────────────────────────────────────────────────────────────

const wsConnections = new client.Gauge({
  name: 'skillconnect_ws_connections_active',
  help: 'Active WebSocket connections',
  registers: [register],
});

// ── Job Queue ───────────────────────────────────────────────────────────────

const jobQueueDepth = new client.Gauge({
  name: 'skillconnect_job_queue_depth',
  help: 'Number of jobs pending in the background queue',
  labelNames: ['queue'],
  registers: [register],
});

const jobQueueProcessed = new client.Counter({
  name: 'skillconnect_job_queue_processed_total',
  help: 'Total background jobs processed',
  labelNames: ['queue', 'status'],
  registers: [register],
});

// ── Database ────────────────────────────────────────────────────────────────

const dbQueryDuration = new client.Histogram({
  name: 'skillconnect_db_query_duration_seconds',
  help: 'PostgreSQL query latency in seconds',
  buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.5, 1],
  registers: [register],
});

// ── Business KPIs ───────────────────────────────────────────────────────────

const bookingsTotal = new client.Counter({
  name: 'skillconnect_bookings_total',
  help: 'Total bookings created',
  labelNames: ['status'],
  registers: [register],
});

const activeUsers = new client.Gauge({
  name: 'skillconnect_active_users',
  help: 'Users active in the last 24 hours',
  labelNames: ['role'],
  registers: [register],
});

// ── Middleware ──────────────────────────────────────────────────────────────

/**
 * Express middleware: records request duration + count per route.
 * Normalises dynamic segments (/bookings/123 → /bookings/:id) to avoid
 * high-cardinality label explosion.
 */
function metricsMiddleware(req, res, next) {
  const start = process.hrtime();

  res.on('finish', () => {
    const [s, ns] = process.hrtime(start);
    const durationSec = s + ns / 1e9;

    // Normalise route — use Express matched route or raw URL with IDs stripped
    const route = req.route
      ? req.baseUrl + req.route.path
      : req.path.replace(/\/[0-9a-f-]{8,}/gi, '/:id').replace(/\/\d+/g, '/:id');

    const labels = {
      method: req.method,
      route,
      status_code: String(res.statusCode),
    };

    httpRequestDuration.observe(labels, durationSec);
    httpRequestTotal.inc(labels);
  });

  next();
}

module.exports = {
  register,
  metricsMiddleware,
  // Exported gauges for external update (hub.js, jobQueue.js)
  wsConnections,
  jobQueueDepth,
  jobQueueProcessed,
  dbQueryDuration,
  bookingsTotal,
  activeUsers,
};
