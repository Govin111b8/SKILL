const router = require('express').Router();
const { authenticate, authorize } = require('../middleware/auth');
const c = require('../controllers/gamificationController');

// ── Customer points ────────────────────────────────────────────────────────────
/**
 * @swagger
 * /gamification/points:
 *   get:
 *     summary: Get points balance for the current user
 *     tags: [Gamification]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Points retrieved successfully
 *       401:
 *         description: Unauthorized
 */
router.get('/points', authenticate, c.getMyPoints);
/**
 * @swagger
 * /gamification/points/redeem:
 *   post:
 *     summary: Redeem loyalty points
 *     tags: [Gamification]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [points]
 *             properties:
 *               points:
 *                 type: integer
 *               reward_type:
 *                 type: string
 *     responses:
 *       200:
 *         description: Points redeemed successfully
 *       400:
 *         description: Invalid redemption request
 *       401:
 *         description: Unauthorized
 */
router.post('/points/redeem', authenticate, c.redeemPoints);
/**
 * @swagger
 * /gamification/leaderboard:
 *   get:
 *     summary: Get the customer gamification leaderboard
 *     tags: [Gamification]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Customer leaderboard retrieved
 *       401:
 *         description: Unauthorized
 */
router.get('/leaderboard', authenticate, c.getCustomerLeaderboard);

// ── Professional stats & leaderboard ─────────────────────────────────────────
router.get('/professional/stats', authenticate, c.getProfessionalStats);
/**
 * @swagger
 * /gamification/professional/leaderboard:
 *   get:
 *     summary: Get the professional gamification leaderboard
 *     tags: [Gamification]
 *     security: []
 *     responses:
 *       200:
 *         description: Professional leaderboard retrieved
 */
router.get('/professional/leaderboard', c.getProfessionalLeaderboard);

module.exports = router;
