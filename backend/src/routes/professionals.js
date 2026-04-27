const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const {
  createProfile,
  getProfile,
  updateProfile,
} = require('../controllers/professionalController');

const router = Router();

router.post(
  '/',
  authenticate,
  authorize('professional'),
  validate([
    body('headline').trim().notEmpty().withMessage('Headline is required'),
    body('bio').trim().notEmpty().withMessage('Bio is required'),
    body('years_of_experience')
      .isInt({ min: 0 })
      .withMessage('Years of experience must be a non-negative integer'),
    body('pricing_estimate')
      .isFloat({ min: 0 })
      .withMessage('Pricing estimate must be a positive number'),
    body('service_location_radius_km')
      .isFloat({ min: 0 })
      .withMessage('Service location radius must be a positive number'),
    body('latitude').isFloat({ min: -90, max: 90 }).withMessage('Valid latitude is required'),
    body('longitude').isFloat({ min: -180, max: 180 }).withMessage('Valid longitude is required'),
    body('category_ids')
      .isArray({ min: 1 })
      .withMessage('At least one category is required'),
  ]),
  createProfile
);

router.get('/:id', getProfile);

router.put(
  '/:id',
  authenticate,
  authorize('professional'),
  updateProfile
);

module.exports = router;
