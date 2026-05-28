const { Router } = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const {
  createSociety, listSocieties, getSociety, verifySociety, addSocietyMember,
  createServiceRequest, listOpenRequests, getSocietyRequests,
  submitBid, listBids, awardBid,
  submitB2BEnquiry, listB2BEnquiries, updateB2BEnquiry,
} = require('../controllers/societyController');

const router = Router();

// Public B2B enquiry (no auth required)
router.post('/b2b-enquiry', submitB2BEnquiry);

// Authenticated routes
router.use(authenticate);

// Society CRUD
router.post('/', createSociety);
router.get('/', listSocieties);

// Open service requests (professionals browse all)
router.get('/requests', listOpenRequests);

// B2B enquiry management (admin)
router.get('/b2b-enquiries', authorize('admin'), listB2BEnquiries);
router.put('/b2b-enquiries/:id', authorize('admin'), updateB2BEnquiry);

// Society-specific routes
router.get('/:id', getSociety);
router.put('/:id/verify', authorize('admin'), verifySociety);
router.post('/:id/members', addSocietyMember);
router.post('/:id/requests', createServiceRequest);
router.get('/:id/requests', getSocietyRequests);

// Bids on requests
router.post('/requests/:rid/bids', authorize('professional'), submitBid);
router.get('/requests/:rid/bids', listBids);
router.put('/bids/:bid_id/award', awardBid);

module.exports = router;
