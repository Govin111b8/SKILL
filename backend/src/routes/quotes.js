const { Router } = require('express');
const { authenticate, requireRole } = require('../middleware/auth');
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
router.post('/', authenticate, createQuoteRequest);
router.get('/my', authenticate, listMyQuoteRequests);
router.get('/:id', authenticate, getQuoteRequest);
router.put('/:id/accept-bid/:bidId', authenticate, acceptBid);

// Professional routes
router.get('/', authenticate, listOpenQuoteRequests);
router.post('/:id/bids', authenticate, submitBid);

module.exports = router;
