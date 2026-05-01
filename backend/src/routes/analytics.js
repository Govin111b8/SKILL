const { Router } = require('express');
const { authenticate, optionalAuth } = require('../middleware/auth');
const { getAnalytics } = require('../controllers/analyticsController');
const { ingestEvents, getFunnelAnalytics, getPerformanceMetrics } = require('../controllers/analyticsEventsController');

const router = Router();

// Professional analytics dashboard
router.get('/', authenticate, getAnalytics);

// Mobile event ingestion (authenticated or anonymous for pre-login events)
router.post('/events', optionalAuth, ingestEvents);

// Admin funnel analytics
router.get('/funnel', authenticate, getFunnelAnalytics);

// Performance metrics
router.get('/performance', authenticate, getPerformanceMetrics);

module.exports = router;
