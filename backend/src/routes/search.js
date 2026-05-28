const { Router } = require('express');
const { search, searchHistory, clearHistory } = require('../controllers/searchController');
const { authenticate, optionalAuth } = require('../middleware/auth');
const { cacheMiddleware } = require('../middleware/cache');

const router = Router();

// Cache search results for 60 seconds
/**
 * @swagger
 * /search:
 *   get:
 *     summary: Search professionals and services
 *     tags: [Search]
 *     security: []
 *     parameters:
 *       - in: query
 *         name: q
 *         schema:
 *           type: string
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *       - in: query
 *         name: latitude
 *         schema:
 *           type: number
 *       - in: query
 *         name: longitude
 *         schema:
 *           type: number
 *     responses:
 *       200:
 *         description: Search results returned successfully
 *       400:
 *         description: Invalid search request
 */
router.get('/', optionalAuth, cacheMiddleware('search', 60), search);
router.get('/history', authenticate, searchHistory);
router.delete('/history', authenticate, clearHistory);

module.exports = router;
