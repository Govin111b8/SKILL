const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const marketplaceController = require('../controllers/marketplaceController');

// Customer routes
router.post('/', auth, marketplaceController.createProposal);
router.get('/customer', auth, marketplaceController.listCustomerProposals);
router.post('/:id/accept', auth, marketplaceController.acceptQuote);

// Professional routes
router.get('/professional', auth, marketplaceController.listProfessionalProposals);
router.post('/:id/quote', auth, marketplaceController.submitQuote);

// Milestone routes
router.get('/:id/milestones', auth, marketplaceController.getMilestones);
router.post('/:id/milestones', auth, marketplaceController.addMilestone);
router.put('/:id/milestones/:milestoneId', auth, marketplaceController.updateMilestone);

// Shared routes
router.get('/:id', auth, marketplaceController.getProposal);
router.put('/:id/status', auth, marketplaceController.updateStatus);

module.exports = router;
