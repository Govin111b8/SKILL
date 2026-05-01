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
router.post('/slots/book', bookSlot);
router.post('/block', blockDates);
router.post('/unblock', unblockDates);
router.get('/blocked', getBlockedDates);

module.exports = router;
