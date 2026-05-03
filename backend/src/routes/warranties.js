const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const { createWarranty, claimWarranty, getWarranties } = require('../controllers/warrantyController');

const router = Router();

router.use(authenticate);

router.post('/', createWarranty);
router.get('/', getWarranties);
router.post('/:id/claim', claimWarranty);

module.exports = router;
