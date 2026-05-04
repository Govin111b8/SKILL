const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const { createWarranty, claimWarranty, getWarranties, resolveWarranty, getProfessionalWarranties } = require('../controllers/warrantyController');

const router = Router();

router.use(authenticate);

router.post('/', createWarranty);
router.get('/', getWarranties);
router.get('/professional', getProfessionalWarranties);
router.post('/:id/claim', claimWarranty);
router.post('/:id/resolve', resolveWarranty);

module.exports = router;
