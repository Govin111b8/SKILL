const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
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

// Middleware
app.use(helmet({ contentSecurityPolicy: false, crossOriginEmbedderPolicy: false }));
app.use(cors({ origin: true, credentials: true }));
app.use(morgan('dev'));
app.use(express.json());

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

// APK download
app.get('/api/download/apk', (req, res) => {
  const apkPath = path.join(__dirname, '../../mobile/skillconnect/build/app/outputs/flutter-apk/app-debug.apk');
  res.download(apkPath, 'SkillConnect.apk');
});

// Serve Flutter web app under /app/ (mobile-style app — this is the main app)
const webBuildPath = path.join(__dirname, '../../mobile/skillconnect/build/web');
app.use('/app', express.static(webBuildPath));
app.get(/^\/app(\/.*)?$/, (req, res) => {
  res.sendFile(path.join(webBuildPath, 'index.html'));
});

// Serve React customer web app under /react/
const reactAppPath = path.join(__dirname, '../public/react');
app.use('/react', express.static(reactAppPath));
app.get(/^\/react(\/.*)?$/, (req, res) => {
  res.sendFile(path.join(reactAppPath, 'index.html'));
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
