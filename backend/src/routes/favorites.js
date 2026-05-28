const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const { listFavorites, toggleFavorite, checkFavorite } = require('../controllers/favoriteController');

const router = Router();

/**
 * @swagger
 * /favorites:
 *   get:
 *     summary: List current user's favorite professionals
 *     tags: [Favorites]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Favorites retrieved successfully
 *       401:
 *         description: Unauthorized
 */
router.get('/', authenticate, listFavorites);
/**
 * @swagger
 * /favorites/toggle:
 *   post:
 *     summary: Add or remove a professional from favorites
 *     tags: [Favorites]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [professionalId]
 *             properties:
 *               professionalId:
 *                 type: string
 *     responses:
 *       200:
 *         description: Favorite status updated
 *       400:
 *         description: Invalid request
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Professional not found
 */
router.post('/toggle', authenticate, toggleFavorite);
/**
 * @swagger
 * /favorites/check/{professionalId}:
 *   get:
 *     summary: Check whether a professional is in favorites
 *     tags: [Favorites]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: professionalId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Favorite status retrieved
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Professional not found
 */
router.get('/check/:professionalId', authenticate, checkFavorite);

module.exports = router;
