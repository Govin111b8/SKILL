const { Router } = require('express');
const { authenticate, optionalAuth } = require('../middleware/auth');
const aiController = require('../controllers/aiController');

const router = Router();

// All AI endpoints require authentication except chat (optional auth)
router.post('/search-intent', optionalAuth, aiController.searchIntent);
router.post('/recommendations', authenticate, aiController.recommendations);
router.post('/sentiment', authenticate, aiController.sentiment);
router.post('/categorize', authenticate, aiController.categorize);
router.post('/pricing', authenticate, aiController.pricing);
router.post('/chat', optionalAuth, aiController.chat);

module.exports = router;
