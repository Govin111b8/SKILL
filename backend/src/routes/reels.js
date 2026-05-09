const { Router } = require('express');
const { getReelsFeed } = require('../controllers/reelsController');

const router = Router();

// Public — paginated reels feed
router.get('/feed', getReelsFeed);

module.exports = router;
