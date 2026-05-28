const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const {
  startTracking,
  updateLocation,
  getTrackingStatus,
  uploadJobPhotos,
} = require('../controllers/trackingController');

const router = Router();

// Professional: start tracking for their booking
router.post('/start', authenticate, startTracking);

// Professional: push GPS update
router.put('/:booking_id/location', authenticate, updateLocation);

// Professional: upload before/after photos
router.put('/:booking_id/photos', authenticate, uploadJobPhotos);

// Customer: get tracking status for their booking
router.get('/:booking_id', authenticate, getTrackingStatus);

module.exports = router;
