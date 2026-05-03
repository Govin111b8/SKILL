const { Router } = require('express');
const { search, searchHistory, clearHistory } = require('../controllers/searchController');
const { authenticate, optionalAuth } = require('../middleware/auth');
const { cacheMiddleware } = require('../middleware/cache');

const router = Router();

// Cache search results for 60 seconds
router.get('/', optionalAuth, cacheMiddleware('search', 60), search);
router.get('/history', authenticate, searchHistory);
router.delete('/history', authenticate, clearHistory);

module.exports = router;
