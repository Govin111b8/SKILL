const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const {
  followProfessional,
  unfollowProfessional,
  getFollowing,
  checkFollow,
  getFeed,
} = require('../controllers/socialController');

const router = Router();

// All social routes require authentication
router.use(authenticate);

// Follow / unfollow a professional
/**
 * @swagger
 * /social/follow/{professionalId}:
 *   post:
 *     summary: Follow a professional
 *     tags: [Social]
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
 *         description: Professional followed successfully
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Professional not found
 */
router.post('/follow/:professionalId', followProfessional);
/**
 * @swagger
 * /social/unfollow/{professionalId}:
 *   delete:
 *     summary: Unfollow a professional
 *     tags: [Social]
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
 *         description: Professional unfollowed successfully
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Professional not found
 */
router.delete('/unfollow/:professionalId', unfollowProfessional);

// Check if following a professional
/**
 * @swagger
 * /social/check/{professionalId}:
 *   get:
 *     summary: Check whether the current user follows a professional
 *     tags: [Social]
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
 *         description: Follow status retrieved
 *       401:
 *         description: Unauthorized
 */
router.get('/check/:professionalId', checkFollow);

// List followed professionals
/**
 * @swagger
 * /social/following:
 *   get:
 *     summary: List professionals followed by the current user
 *     tags: [Social]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Following list retrieved
 *       401:
 *         description: Unauthorized
 */
router.get('/following', getFollowing);

// Aggregated feed from followed professionals
/**
 * @swagger
 * /social/feed:
 *   get:
 *     summary: Get the social feed from followed professionals
 *     tags: [Social]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Social feed retrieved
 *       401:
 *         description: Unauthorized
 */
router.get('/feed', getFeed);

module.exports = router;
