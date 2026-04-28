const router = require('express').Router();
const { authenticate } = require('../middleware/auth');
const c = require('../controllers/bookingController');

router.use(authenticate);
router.get('/', c.list);
router.post('/', c.create);
router.get('/:id', c.get);
router.post('/:id/transition', c.transition);

module.exports = router;
