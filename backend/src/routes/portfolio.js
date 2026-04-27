const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const {
  addPortfolioItem,
  getPortfolioItems,
  deletePortfolioItem,
} = require('../controllers/portfolioController');

const router = Router();

router.post(
  '/',
  authenticate,
  authorize('professional'),
  validate([
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('description').trim().notEmpty().withMessage('Description is required'),
    body('media_type')
      .isIn(['image', 'video', 'certificate'])
      .withMessage('Media type must be image, video, or certificate'),
    body('media_url').trim().notEmpty().withMessage('Media URL is required'),
  ]),
  addPortfolioItem
);

router.get('/:professionalId', getPortfolioItems);

router.delete('/:id', authenticate, authorize('professional'), deletePortfolioItem);

module.exports = router;
