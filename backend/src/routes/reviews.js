const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const { createReview, editReview, markHelpful, getReviews, getPendingReviews } = require('../controllers/reviewController');

const router = Router();

/**
 * @swagger
 * /reviews:
 *   post:
 *     summary: Create a review for a professional
 *     tags: [Reviews]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [professional_id, rating]
 *             properties:
 *               professional_id:
 *                 type: string
 *               booking_id:
 *                 type: string
 *               rating:
 *                 type: integer
 *               comment:
 *                 type: string
 *     responses:
 *       201:
 *         description: Review created successfully
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Professional or booking not found
 */
router.post(
  '/',
  authenticate,
  validate([
    body('professional_id').trim().notEmpty().withMessage('Professional ID is required'),
    body('contact_id').optional({ nullable: true }).isString(),
    body('booking_id').optional({ nullable: true }).isString(),
    body('rating')
      .isInt({ min: 1, max: 5 })
      .withMessage('Rating must be between 1 and 5'),
    body('comment').optional({ nullable: true }).isString(),
  ]),
  createReview
);

// Edit review text within 24h window
/**
 * @swagger
 * /reviews/{id}:
 *   put:
 *     summary: Edit a review comment
 *     tags: [Reviews]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [comment]
 *             properties:
 *               comment:
 *                 type: string
 *     responses:
 *       200:
 *         description: Review updated successfully
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Review not found
 */
router.put(
  '/:id',
  authenticate,
  validate([body('comment').trim().notEmpty().withMessage('Comment is required')]),
  editReview
);

// Mark review as helpful
/**
 * @swagger
 * /reviews/{id}/helpful:
 *   post:
 *     summary: Mark a review as helpful
 *     tags: [Reviews]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Helpful vote recorded
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Review not found
 */
router.post('/:id/helpful', authenticate, markHelpful);

/**
 * @swagger
 * /reviews/pending:
 *   get:
 *     summary: List reviews pending for the current user
 *     tags: [Reviews]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Pending reviews retrieved
 *       401:
 *         description: Unauthorized
 */
router.get('/pending', authenticate, getPendingReviews);
/**
 * @swagger
 * /reviews/{professionalId}:
 *   get:
 *     summary: Get reviews for a professional
 *     tags: [Reviews]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: professionalId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Reviews retrieved successfully
 *       404:
 *         description: Professional not found
 */
router.get('/:professionalId', getReviews);
router.get('/:professionalId/distribution', async (req, res, next) => {
  try {
    const { query: dbQuery } = require('../config/database');
    const r = await dbQuery(
      `SELECT rating, COUNT(*)::int as count FROM reviews WHERE professional_id = $1 AND moderation_status = 'approved' GROUP BY rating ORDER BY rating DESC`,
      [req.params.professionalId]
    );
    const dist = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    for (const row of r.rows) dist[row.rating] = row.count;
    res.json({ success: true, data: dist });
  } catch (e) { next(e); }
});

module.exports = router;

