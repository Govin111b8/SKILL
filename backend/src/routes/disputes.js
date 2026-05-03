const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const { createDispute, listDisputes, getDispute, addEvidence } = require('../controllers/disputeController');

const router = Router();

router.use(authenticate);

router.post('/', createDispute);
router.get('/', listDisputes);
router.get('/:id', getDispute);
router.post('/:id/evidence', addEvidence);

module.exports = router;
