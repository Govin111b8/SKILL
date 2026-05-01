const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const { getAnalytics } = require('../controllers/analyticsController');

const router = Router();

router.get('/', authenticate, getAnalytics);

module.exports = router;
