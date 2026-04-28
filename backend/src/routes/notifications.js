const router = require('express').Router();
const { authenticate } = require('../middleware/auth');
const c = require('../controllers/notificationController');

router.use(authenticate);
router.get('/', c.list);
router.put('/:id/read', c.markRead);
router.put('/read-all', c.markAllRead);
router.get('/favorites', c.listFavorites);
router.post('/favorites/:professionalId', c.toggleFavorite);
router.post('/devices', c.registerDevice);

module.exports = router;
