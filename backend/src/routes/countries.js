const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const countryController = require('../controllers/countryController');

// Public routes
router.get('/', countryController.listCountries);
router.get('/currencies', countryController.getSupportedCurrencies);
router.get('/:code', countryController.getCountryConfig);

// Admin routes
router.post('/', auth, countryController.createTenant);
router.put('/:code', auth, countryController.updateTenant);
router.get('/admin/all', auth, countryController.listAllTenants);

module.exports = router;
