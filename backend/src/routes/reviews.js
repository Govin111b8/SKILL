const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const { createReview, getReviews, getPendingReviews } = require('../controllers/reviewController');

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

router.get('/pending', authenticate, getPendingReviews);
router.get('/:professionalId', getReviews);
router.get('/:professionalId/distribution', async (req, res, next) => {
  try {
    const { query: dbQuery } = require('../config/database');
    const r = await dbQuery(
      `SELECT rating, COUNT(*)::int as count FROM reviews WHERE professional_id = $1 GROUP BY rating ORDER BY rating DESC`,
      [req.params.professionalId]
    );
    // Fill in missing ratings with 0
    const dist = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    for (const row of r.rows) dist[row.rating] = row.count;
    res.json({ success: true, data: dist });
  } catch (e) { next(e); }
});

module.exports = router;
