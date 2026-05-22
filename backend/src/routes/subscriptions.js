const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const subscriptionController = require('../controllers/subscriptionController');

// Customer subscription management
router.post('/', auth, subscriptionController.create);
router.get('/', auth, subscriptionController.list);
router.get('/categories', subscriptionController.getCategories);
router.get('/provider', auth, subscriptionController.listProviderSubscriptions);
router.post('/vacation', auth, subscriptionController.setVacationMode);
router.get('/:id', auth, subscriptionController.getById);
router.put('/:id', auth, subscriptionController.update);
router.post('/:id/pause', auth, subscriptionController.pause);
router.post('/:id/resume', auth, subscriptionController.resume);
router.post('/:id/cancel', auth, subscriptionController.cancel);
router.post('/:id/occurrence', auth, subscriptionController.recordOccurrence);
router.post('/:id/replace-provider', auth, subscriptionController.requestReplacement);

module.exports = router;
