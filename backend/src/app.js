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

const app = express();

// Trust proxy (required for rate limiting behind reverse proxies)
app.set('trust proxy', 1);

// Request correlation ID — must come before logging
app.use(requestId);

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
app.use('/api/bookings', bookingRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/favorites', favoriteRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/schedule', scheduleRoutes);
app.use('/api/disputes', disputeRoutes);
app.use('/api/warranties', warrantyRoutes);
app.use('/api/emergency', emergencyRoutes);
app.use('/api/referrals', referralRoutes);

// Serve uploaded files
app.use('/uploads', express.static(path.join(__dirname, '../uploads'), { maxAge: '7d' }));

// Health check — includes DB connectivity verification
app.get('/api/health', async (req, res) => {
  const { pool } = require('./config/database');
  const checks = { server: 'ok', database: 'unknown' };
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
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
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

// Error handler
app.use(errorHandler);

module.exports = app;
