const router = require('express').Router();
const { authenticate } = require('../middleware/auth');
const c = require('../controllers/messageController');

router.use(authenticate);
router.get('/threads', c.listThreads);
router.post('/threads', c.openThread);
router.get('/threads/:threadId', c.listMessages);
router.post('/threads/:threadId', c.sendMessage);

module.exports = router;
