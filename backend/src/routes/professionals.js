const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const {
  createProfile,
  getProfile,
  updateProfile,
  updateOwnProfile,
  toggleAvailability,
  getAvailability,
  getProfileByUser,
} = require('../controllers/professionalController');

const router = Router();

// Get own professional profile (for dashboard)
router.get('/me', authenticate, authorize('professional'), getProfileByUser);

// Get availability status
router.get('/me/availability', authenticate, authorize('professional'), getAvailability);

// Toggle availability (POST for mobile widget compatibility)
router.post('/me/availability', authenticate, authorize('professional'),
  validate([
    body('status').isIn(['available', 'busy', 'offline']).withMessage('Invalid status'),
  ]),
  (req, res, next) => { req.body.availability_status = req.body.status; next(); },
  toggleAvailability
);

// Toggle availability (PUT — original)
router.put('/me/availability', authenticate, authorize('professional'),
  validate([
    body('availability_status').isIn(['available', 'busy', 'offline']).withMessage('Invalid status'),
  ]),
  toggleAvailability
);

// Update own professional profile (convenience for onboarding — resolves ID from auth)
router.put('/profile', authenticate, authorize('professional'), updateOwnProfile);

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
    body('provider_type')
      .optional()
      .isIn(['individual', 'organization'])
      .withMessage('Provider type must be individual or organization'),
    body('company_name')
      .optional()
      .trim()
      .isLength({ max: 255 })
      .withMessage('Company name must be 255 characters or less'),
    body('team_size')
      .optional()
      .isInt({ min: 1 })
      .withMessage('Team size must be a positive integer'),
  ]),
  createProfile
);

router.get('/:id', getProfile);

// Get online presence for a professional (quick WS check)
router.get('/:id/presence', (req, res) => {
  const hub = require('../realtime/hub');
  const { query: dbQuery } = require('../config/database');
  dbQuery('SELECT user_id FROM professionals WHERE id = $1', [req.params.id])
    .then(r => {
      if (!r.rows.length) return res.json({ success: true, data: { status: 'offline', lastSeen: null } });
      const presence = hub.getPresence(r.rows[0].user_id);
      res.json({ success: true, data: presence });
    })
    .catch(() => res.json({ success: true, data: { status: 'offline', lastSeen: null } }));
});

router.put(
  '/:id',
  authenticate,
  authorize('professional'),
  updateProfile
);

module.exports = router;
