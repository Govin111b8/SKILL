const { Router } = require('express');
const {
  getBadges,
  getTimeline,
  explainTrust,
  getTrustLevel,
  getNeighborhoodTrust,
  getTopInNeighborhood,
} = require('../controllers/trustController');

const router = Router();

// All trust routes are public
router.get('/neighborhood/top', getTopInNeighborhood);
router.get('/:professionalId/badges', getBadges);
router.get('/:professionalId/timeline', getTimeline);
router.get('/:professionalId/explain', explainTrust);
router.get('/:professionalId/level', getTrustLevel);
router.get('/:professionalId/neighborhood', getNeighborhoodTrust);

module.exports = router;
