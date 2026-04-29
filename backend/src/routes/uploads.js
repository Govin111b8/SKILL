const router = require('express').Router();
const { authenticate } = require('../middleware/auth');
const { uploadFile, updateAvatar } = require('../controllers/uploadController');

router.post('/', authenticate, uploadFile);
router.post('/avatar', authenticate, updateAvatar);

module.exports = router;
