const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const { createPayment, verifyPayment, releaseEscrow, refundPayment, getPayments, getEarnings } = require('../controllers/paymentController');

const router = Router();

router.use(authenticate);

router.post('/', createPayment);
router.post('/:payment_id/verify', verifyPayment);
router.get('/', getPayments);
router.get('/earnings', getEarnings);
router.post('/:payment_id/release', releaseEscrow);
router.post('/:payment_id/refund', refundPayment);

module.exports = router;
