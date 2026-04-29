const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const {
  createProfile,
  getProfile,
  updateProfile,
  toggleAvailability,
  getProfileByUser,
} = require('../controllers/professionalController');

const router = Router();

// Get own professional profile (for dashboard)
router.get('/me', authenticate, authorize('professional'), getProfileByUser);

// Toggle availability
router.put('/me/availability', authenticate, authorize('professional'),
  validate([
    body('availability_status').isIn(['available', 'busy', 'offline']).withMessage('Invalid status'),
  ]),
  toggleAvailability
);

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
