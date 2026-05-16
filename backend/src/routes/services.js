const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const {
  getServices,
  addService,
  updateService,
  deleteService,
  searchServices,
} = require('../controllers/serviceController');

const router = Router();

router.get('/search', searchServices);
router.get('/:professionalId', getServices);
router.post('/:professionalId', authenticate, addService);
router.put('/item/:serviceId', authenticate, updateService);
router.delete('/item/:serviceId', authenticate, deleteService);

module.exports = router;
