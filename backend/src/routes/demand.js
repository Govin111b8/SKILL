const { Router } = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const { getDemandForecast, getAreaDemand, getPeakHours, logDemandSignal } = require('../controllers/demandController');

const router = Router();

router.use(authenticate);

router.get('/forecast', authorize('professional'), getDemandForecast);
router.get('/area', getAreaDemand);
router.get('/peak-hours', authorize('professional'), getPeakHours);
router.post('/log', logDemandSignal);

module.exports = router;
