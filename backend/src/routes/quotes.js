const { Router } = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const {
  createQuoteRequest,
  listMyQuoteRequests,
  getQuoteRequest,
  submitBid,
  acceptBid,
  listOpenQuoteRequests,
} = require('../controllers/quoteController');

const router = Router();

// Customer routes
router.post('/', authenticate, authorize('customer'), createQuoteRequest);
router.get('/my', authenticate, listMyQuoteRequests);
router.get('/:id', authenticate, getQuoteRequest);
router.put('/:id/accept-bid/:bidId', authenticate, authorize('customer'), acceptBid);

// Professional routes
router.get('/', authenticate, listOpenQuoteRequests);
router.post('/:id/bids', authenticate, authorize('professional'), submitBid);

module.exports = router;
