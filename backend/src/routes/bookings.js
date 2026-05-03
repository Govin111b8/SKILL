const router = require('express').Router();
const { authenticate } = require('../middleware/auth');
const c = require('../controllers/bookingController');
const { idempotencyCheck, actionRateLimit, detectSuspiciousBooking } = require('../middleware/fraudPrevention');

router.use(authenticate);
router.get('/', c.list);
router.post('/', idempotencyCheck, actionRateLimit('booking_create', 10, 60000), detectSuspiciousBooking, c.create);
router.get('/:id', c.get);
router.post('/:id/transition', c.transition);

module.exports = router;
