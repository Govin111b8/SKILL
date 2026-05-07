const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const { createReview, editReview, markHelpful, getReviews, getPendingReviews } = require('../controllers/reviewController');

const router = Router();

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
router.put(
  '/:id',
  authenticate,
  validate([body('comment').trim().notEmpty().withMessage('Comment is required')]),
  editReview
);

// Mark review as helpful
router.post('/:id/helpful', authenticate, markHelpful);

router.get('/pending', authenticate, getPendingReviews);
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

