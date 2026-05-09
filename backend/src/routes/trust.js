const { Router } = require('express');
const {
  getBadges,
  getTimeline,
  explainTrust,
} = require('../controllers/trustController');

const router = Router();

// All trust routes are public
router.get('/:professionalId/badges', getBadges);
router.get('/:professionalId/timeline', getTimeline);
router.get('/:professionalId/explain', explainTrust);

module.exports = router;
