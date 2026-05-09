const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const {
  createStory,
  getStoryFeed,
  getProfessionalStories,
  viewStory,
  deleteStory,
} = require('../controllers/storyController');

const router = Router();

// Public — get active story feed
router.get('/feed', getStoryFeed);

// Public — get stories for a specific professional
router.get('/professional/:professionalId', getProfessionalStories);

// Public — increment view count
router.post('/:id/view', viewStory);

// Auth — create a story (professionals only)
router.post(
  '/',
  authenticate,
  authorize('professional'),
  validate([
    body('media_url').notEmpty().withMessage('media_url is required'),
    body('text_overlay').optional().isString().isLength({ max: 500 }),
    body('cta_url').optional().isString(),
    body('cta_label').optional().isString().isLength({ max: 50 }),
    body('hours').optional().isInt({ min: 1, max: 72 }).withMessage('Story duration: 1–72 hours'),
  ]),
  createStory
);

// Auth — delete own story
router.delete('/:id', authenticate, deleteStory);

module.exports = router;
