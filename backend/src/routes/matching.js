const { Router } = require('express');
const { optionalAuth } = require('../middleware/auth');
const { matchProviders } = require('../controllers/matchingController');

const router = Router();

// GET /api/match?category_id=X&latitude=Y&longitude=Z&limit=10&radius_km=50
router.get('/', optionalAuth, matchProviders);

module.exports = router;
