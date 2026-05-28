const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const {
  listHomeProfiles,
  getHomeProfile,
  createHomeProfile,
  updateHomeProfile,
  deleteHomeProfile,
  setDefaultHomeProfile,
} = require('../controllers/homeProfileController');

const router = Router();

router.use(authenticate);

router.get('/', listHomeProfiles);
router.post('/', createHomeProfile);
router.get('/:id', getHomeProfile);
router.put('/:id', updateHomeProfile);
router.delete('/:id', deleteHomeProfile);
router.post('/:id/set-default', setDefaultHomeProfile);

module.exports = router;
