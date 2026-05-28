const { Router } = require('express');
const {
  getBadges,
  getTimeline,
  explainTrust,
  getTrustLevel,
  getNeighborhoodTrust,
  getTopInNeighborhood,
} = require('../controllers/trustController');

const router = Router();

// All trust routes are public
router.get('/neighborhood/top', getTopInNeighborhood);
/**
 * @swagger
 * /trust/{professionalId}/badges:
 *   get:
 *     summary: Get trust badges for a professional
 *     tags: [Trust]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: professionalId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Trust badges retrieved successfully
 *       404:
 *         description: Professional not found
 */
router.get('/:professionalId/badges', getBadges);
/**
 * @swagger
 * /trust/{professionalId}/timeline:
 *   get:
 *     summary: Get trust timeline for a professional
 *     tags: [Trust]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: professionalId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Trust timeline retrieved successfully
 *       404:
 *         description: Professional not found
 */
router.get('/:professionalId/timeline', getTimeline);
/**
 * @swagger
 * /trust/{professionalId}/explain:
 *   get:
 *     summary: Explain trust score signals for a professional
 *     tags: [Trust]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: professionalId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Trust explanation retrieved successfully
 *       404:
 *         description: Professional not found
 */
router.get('/:professionalId/explain', explainTrust);
/**
 * @swagger
 * /trust/{professionalId}/level:
 *   get:
 *     summary: Get trust level for a professional
 *     tags: [Trust]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: professionalId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Trust level retrieved successfully
 *       404:
 *         description: Professional not found
 */
router.get('/:professionalId/level', getTrustLevel);
router.get('/:professionalId/neighborhood', getNeighborhoodTrust);

module.exports = router;
