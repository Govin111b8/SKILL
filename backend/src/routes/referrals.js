const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const { generateCode, applyCode, getReferralStats, getLoyaltyHistory } = require('../controllers/referralController');

const router = Router();

router.use(authenticate);

router.post('/generate', generateCode);
router.post('/apply', applyCode);
router.get('/stats', getReferralStats);
router.get('/loyalty', getLoyaltyHistory);

module.exports = router;
