const { Router } = require('express');
const { search, searchHistory, clearHistory } = require('../controllers/searchController');
const { authenticate, optionalAuth } = require('../middleware/auth');

const router = Router();

router.get('/', optionalAuth, search);
router.get('/history', authenticate, searchHistory);
router.delete('/history', authenticate, clearHistory);

module.exports = router;
