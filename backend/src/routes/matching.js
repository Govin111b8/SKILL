const { Router } = require('express');
const { optionalAuth } = require('../middleware/auth');
const { matchProviders } = require('../controllers/matchingController');

const router = Router();

// GET /api/match?category_id=X&latitude=Y&longitude=Z&limit=10&radius_km=50
/**
 * @swagger
 * /match:
 *   get:
 *     summary: Match providers based on category and location
 *     tags: [Matching]
 *     security: []
 *     parameters:
 *       - in: query
 *         name: category_id
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
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *       - in: query
 *         name: radius_km
 *         schema:
 *           type: number
 *     responses:
 *       200:
 *         description: Matching providers retrieved successfully
 *       400:
 *         description: Invalid match request
 */
router.get('/', optionalAuth, matchProviders);

module.exports = router;
