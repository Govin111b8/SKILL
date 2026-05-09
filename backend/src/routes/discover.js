const { Router } = require('express');
const {
  getTrending,
  getNewlyVerified,
  getHighlyResponsive,
} = require('../controllers/discoverController');

const router = Router();

// All discovery routes are public
router.get('/trending', getTrending);
router.get('/new', getNewlyVerified);
router.get('/responsive', getHighlyResponsive);

module.exports = router;
