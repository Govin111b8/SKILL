const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const { createEmergency, acceptEmergency, listEmergencies, triggerSOS, resolveEmergency } = require('../controllers/emergencyController');

const router = Router();

router.use(authenticate);

router.post('/', createEmergency);
router.get('/', listEmergencies);
router.post('/:id/accept', acceptEmergency);
router.post('/:id/resolve', resolveEmergency);
router.post('/sos', triggerSOS);

module.exports = router;
