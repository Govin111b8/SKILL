const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const path = require('path');
const rateLimit = require('express-rate-limit');
const { config } = require('./config');
const logger = require('./config/logger');
const errorHandler = require('./middleware/errorHandler');
const requestId = require('./middleware/requestId');
const httpLogger = require('./middleware/httpLogger');
const { requireFeature, getAllFlags } = require('./middleware/featureFlags');
const { register: metricsRegistry, metricsMiddleware } = require('./config/metrics');
const { sentryErrorHandler } = require('./config/sentry');

const authRoutes = require('./routes/auth');
const professionalRoutes = require('./routes/professionals');
const categoryRoutes = require('./routes/categories');
const searchRoutes = require('./routes/search');
const portfolioRoutes = require('./routes/portfolio');
const reviewRoutes = require('./routes/reviews');
const contactRoutes = require('./routes/contacts');
const complaintRoutes = require('./routes/complaints');
const dashboardRoutes = require('./routes/dashboard');
const userRoutes = require('./routes/users');
const kycRoutes = require('./routes/kyc');
const bookingRoutes = require('./routes/bookings');
const messageRoutes = require('./routes/messages');
const notificationRoutes = require('./routes/notifications');
const uploadRoutes = require('./routes/uploads');
const favoriteRoutes = require('./routes/favorites');
const analyticsRoutes = require('./routes/analytics');
const paymentRoutes = require('./routes/payments');
const scheduleRoutes = require('./routes/schedule');
const disputeRoutes = require('./routes/disputes');
const warrantyRoutes = require('./routes/warranties');
const emergencyRoutes = require('./routes/emergency');
const referralRoutes = require('./routes/referrals');
const adminRoutes = require('./routes/admin');
const webhookRoutes = require('./routes/webhooks');
const storefrontRoutes = require('./routes/storefront');
const agentRoutes = require('./routes/agents');
const matchingRoutes = require('./routes/matching');
const seoRoutes = require('./routes/seo');
const growthRoutes = require('./routes/growth');
const aiRoutes = require('./routes/ai');
const socialRoutes = require('./routes/social');
const storyRoutes = require('./routes/stories');
const trustRoutes = require('./routes/trust');
const discoverRoutes = require('./routes/discover');
const collectionsRoutes = require('./routes/collections');
const communityRoutes = require('./routes/community');
const reelsRoutes = require('./routes/reels');
const serviceRoutes = require('./routes/services');
const subscriptionRoutes = require('./routes/subscriptions');
const householdRoutes = require('./routes/households');
const countryRoutes = require('./routes/countries');
const marketplaceRoutes = require('./routes/marketplace');
const providerBusinessRoutes = require('./routes/providerBusiness');

const app = express();

// Trust proxy (required for rate limiting behind reverse proxies)
app.set('trust proxy', 1);

// Request correlation ID — must come before logging
app.use(requestId);

// Prometheus HTTP metrics — record duration/count per route
app.use(metricsMiddleware);

// Middleware
app.use(helmet({
  contentSecurityPolicy: config.isProduction ? undefined : false,
  crossOriginEmbedderPolicy: false,
}));

// Compression for all responses
app.use(compression());

// CORS — strict in production, permissive in development
const allowedOrigins = [
  /\.app\.github\.dev$/,
  /^https?:\/\/localhost(:\d+)?$/,
  ...config.cors.allowedOrigins.map((o) => new RegExp(`^${o.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`)),
];
app.use(cors({
  origin: (origin, cb) => {
    // Allow requests with no origin (server-to-server, mobile apps)
    if (!origin) return cb(null, true);
    if (allowedOrigins.some((p) => (typeof p === 'string' ? p === origin : p.test(origin)))) {
      return cb(null, true);
    }
    if (config.isDevelopment) return cb(null, true);
    logger.warn({ origin }, 'CORS request from disallowed origin');
    cb(new Error('Not allowed by CORS'));
  },
  credentials: true,
}));

// Structured HTTP logging (replaces morgan)
app.use(httpLogger);

app.use(express.json({ limit: '1mb' }));

// XSS sanitization — strip HTML/script tags from all text body fields
const sanitize = require('./middleware/sanitize');
app.use(sanitize);

// Rate limiting — protect auth endpoints from brute force
const authLimiter = rateLimit({
  windowMs: config.rateLimit.auth.windowMs,
  max: config.rateLimit.auth.max,
  message: { success: false, message: 'Too many attempts. Try again in 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});
const apiLimiter = rateLimit({
  windowMs: config.rateLimit.api.windowMs,
  max: config.rateLimit.api.max,
  message: { success: false, message: 'Rate limit exceeded. Slow down.' },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/auth', authLimiter);
app.use('/api', apiLimiter);

// Stricter rate limiting for sensitive endpoints
const paymentLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: { success: false, message: 'Too many payment requests. Please wait.' },
  standardHeaders: true,
  legacyHeaders: false,
});
const kycLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 10,
  message: { success: false, message: 'Too many KYC requests. Please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});
const adminLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  message: { success: false, message: 'Admin rate limit exceeded.' },
  standardHeaders: true,
  legacyHeaders: false,
});
const uploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 50,
  message: { success: false, message: 'Upload rate limit exceeded. Try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// Apply stricter limits before route handlers
app.use('/api/payments', paymentLimiter);
app.use('/api/kyc', kycLimiter);
app.use('/api/admin', adminLimiter);
app.use('/api/upload', uploadLimiter);

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/professionals', professionalRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/portfolio', portfolioRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/contacts', contactRoutes);
app.use('/api/complaints', complaintRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/users', userRoutes);
app.use('/api/kyc', kycRoutes);
// Extended features — gated by feature flags (see PLATFORM_CHANGE_RECORD.md)
app.use('/api/bookings', requireFeature('BOOKINGS'), bookingRoutes);
app.use('/api/messages', requireFeature('CHAT'), messageRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/favorites', favoriteRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/schedule', scheduleRoutes);
app.use('/api/disputes', requireFeature('DISPUTES'), disputeRoutes);
app.use('/api/warranties', requireFeature('WARRANTIES'), warrantyRoutes);
app.use('/api/emergency', requireFeature('EMERGENCIES'), emergencyRoutes);
app.use('/api/referrals', referralRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/webhooks', webhookRoutes);
app.use('/api/storefront', storefrontRoutes);
app.use('/api/agents', requireFeature('AGENTS'), agentRoutes);
app.use('/api/match', matchingRoutes);
app.use('/api/social', socialRoutes);
app.use('/api/stories', storyRoutes);
app.use('/api/trust', trustRoutes);
app.use('/api/discover', discoverRoutes);
app.use('/api/collections', collectionsRoutes);
app.use('/api/community', communityRoutes);
app.use('/api/reels', reelsRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/subscriptions', subscriptionRoutes);
app.use('/api/households', householdRoutes);
app.use('/api/countries', countryRoutes);
app.use('/api/marketplace', marketplaceRoutes);
app.use('/api/provider-business', providerBusinessRoutes);

// SEO — sitemap.xml and robots.txt (no rate limiting, public)
app.use('/sitemap.xml', (req, res, next) => { req.url = '/sitemap.xml'; seoRoutes(req, res, next); });
app.use('/robots.txt', (req, res, next) => { req.url = '/robots.txt'; seoRoutes(req, res, next); });
app.use('/api/seo', seoRoutes);
app.use('/api/growth', growthRoutes);
app.use('/api/ai', aiRoutes);

// Prometheus metrics — accessible only from internal network in production
// (expose on a separate port or protect with IP allowlist via nginx)
app.get('/metrics', async (req, res) => {
  // Restrict to localhost in production to avoid leaking internal metrics
  if (config.isProduction) {
    const ip = req.ip || req.connection.remoteAddress || '';
    const isLocal = ip === '127.0.0.1' || ip === '::1' || ip === '::ffff:127.0.0.1';
    if (!isLocal) {
      return res.status(403).json({ success: false, message: 'Metrics endpoint restricted' });
    }
  }
  try {
    res.set('Content-Type', metricsRegistry.contentType);
    res.end(await metricsRegistry.metrics());
  } catch (err) {
    res.status(500).end(err.message);
  }
});

// Serve uploaded files
app.use('/uploads', express.static(path.join(__dirname, '../uploads'), { maxAge: '7d' }));

// Health check — includes DB connectivity verification
app.get('/api/health', async (req, res) => {
  const { pool } = require('./config/database');
  const redisClient = require('./config/redis');
  const { getCacheStats } = require('./middleware/cache');
  const checks = { server: 'ok', database: 'unknown', redis: redisClient.isAvailable() ? 'ok' : 'not configured' };
  try {
    const result = await pool.query('SELECT 1');
    checks.database = result.rows.length ? 'ok' : 'error';
  } catch (err) {
    checks.database = 'error';
    logger.error({ err }, 'Health check DB connectivity failed');
  }
  const healthy = checks.database === 'ok';
  res.status(healthy ? 200 : 503).json({
    success: healthy,
    message: healthy ? 'All systems operational' : 'Degraded — database unreachable',
    checks,
    features: getAllFlags(),
    cache: getCacheStats(),
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '1.0.0',
  });
});

// APK download — serves the release APK if built, debug APK as fallback
app.get('/api/download/apk', (req, res) => {
  const releaseApk = path.join(__dirname, '../../mobile/skillconnect/build/app/outputs/flutter-apk/app-release.apk');
  const debugApk = path.join(__dirname, '../../mobile/skillconnect/build/app/outputs/flutter-apk/app-debug.apk');
  const fs = require('fs');
  const apkPath = fs.existsSync(releaseApk) ? releaseApk : debugApk;
  if (!fs.existsSync(apkPath)) {
    return res.status(404).json({ success: false, message: 'APK not yet built' });
  }
  res.download(apkPath, 'SkillConnect.apk');
});

// Serve Flutter web app under /app/ — try deployed public/app first, fall back to build/web
const deployedAppPath = path.join(__dirname, '../public/app');
const webBuildPath = path.join(__dirname, '../../mobile/skillconnect/build/web');
const fs = require('fs');
const appServePath = fs.existsSync(path.join(deployedAppPath, 'index.html')) ? deployedAppPath : webBuildPath;
app.use('/app', express.static(appServePath, { maxAge: '1h', etag: true }));
app.get(/^\/app(\/.*)?$/, (req, res) => {
  res.sendFile(path.join(appServePath, 'index.html'));
});

// Serve Pro portal under /pro/
const proPotalPath = path.join(__dirname, '../public/pro');
app.use('/pro', express.static(proPotalPath));
app.get(/^\/pro(\/.*)?$/, (req, res) => {
  res.sendFile(path.join(proPotalPath, 'index.html'));
});

// Root → redirect to Flutter mobile app
const publicPath = path.join(__dirname, '../public');
app.get('/', (req, res) => {
  res.redirect(301, '/app/');
});

// Serve other public static files (excluding index.html at root)
app.use(express.static(publicPath));

// Sentry error handler — must be BEFORE the app error handler
app.use(sentryErrorHandler());

// Error handler
app.use(errorHandler);

module.exports = app;
