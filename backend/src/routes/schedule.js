const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const { getSchedule, setSchedule, getAvailableSlots, bookSlot, blockDates, unblockDates, getBlockedDates } = require('../controllers/scheduleController');

const router = Router();

router.get('/slots', authenticate, getAvailableSlots);
router.get('/blocked/:professional_id', getBlockedDates);

// Authenticated routes (for professionals managing their schedule)
router.use(authenticate);
router.get('/', getSchedule);
router.put('/', setSchedule);
router.post('/', setSchedule); // POST alias for mobile compatibility
router.get('/blocked-dates', getBlockedDates);
router.post('/slots/book', bookSlot);
router.post('/block', blockDates);
router.post('/block-dates', blockDates); // alias for mobile
router.post('/unblock', unblockDates);
router.post('/unblock-dates', unblockDates); // alias for mobile
router.get('/blocked', getBlockedDates);

module.exports = router;
