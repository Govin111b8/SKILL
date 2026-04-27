const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const { createReview, getReviews } = require('../controllers/reviewController');

const router = Router();

router.post(
  '/',
  authenticate,
  validate([
    body('professional_id').trim().notEmpty().withMessage('Professional ID is required'),
    body('contact_id').trim().notEmpty().withMessage('Contact ID is required'),
    body('rating')
      .isInt({ min: 1, max: 5 })
      .withMessage('Rating must be between 1 and 5'),
    body('comment').trim().notEmpty().withMessage('Comment is required'),
  ]),
  createReview
);

router.get('/:professionalId', getReviews);

module.exports = router;
