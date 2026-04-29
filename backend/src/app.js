const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const rateLimit = require('express-rate-limit');
const errorHandler = require('./middleware/errorHandler');

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

const app = express();

// Trust proxy (required for rate limiting behind reverse proxies like Codespaces)
app.set('trust proxy', 1);

// Middleware
app.use(helmet({ contentSecurityPolicy: false, crossOriginEmbedderPolicy: false }));

// CORS — allow same-origin + Codespace URLs
const allowedOrigins = [
  /\.app\.github\.dev$/,
  /^https?:\/\/localhost(:\d+)?$/,
];
app.use(cors({
  origin: (origin, cb) => {
    if (!origin || allowedOrigins.some(p => typeof p === 'string' ? p === origin : p.test(origin))) return cb(null, true);
    cb(null, true); // permissive in dev; tighten for production
  },
  credentials: true,
}));

app.use(morgan('dev'));
app.use(express.json({ limit: '2mb' }));

// Rate limiting — protect auth endpoints from brute force
const authLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 30, message: { success: false, message: 'Too many attempts. Try again in 15 minutes.' } });
const apiLimiter = rateLimit({ windowMs: 1 * 60 * 1000, max: 200, message: { success: false, message: 'Rate limit exceeded. Slow down.' } });
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

// Health check
app.get('/api/health', (req, res) => {
  res.status(200).json({ success: true, message: 'Server is running' });
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

// Serve Flutter web app under /app/ (mobile-style app — this is the primary app)
const webBuildPath = path.join(__dirname, '../../mobile/skillconnect/build/web');
app.use('/app', express.static(webBuildPath));
app.get(/^\/app(\/.*)?$/, (req, res) => {
  res.sendFile(path.join(webBuildPath, 'index.html'));
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
