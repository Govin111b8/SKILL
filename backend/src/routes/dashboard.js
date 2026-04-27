const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const { getDashboard } = require('../controllers/dashboardController');

const router = Router();

router.get('/', authenticate, getDashboard);

module.exports = router;
