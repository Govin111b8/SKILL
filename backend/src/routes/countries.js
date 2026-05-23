const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const countryController = require('../controllers/countryController');

// Public routes
router.get('/', countryController.listCountries);
router.get('/currencies', countryController.getSupportedCurrencies);

// Admin routes (before :code to avoid matching 'admin' as a country code)
router.get('/admin/all', auth, countryController.listAllTenants);
router.post('/', auth, countryController.createTenant);
router.put('/:code', auth, countryController.updateTenant);

// Public parameterized route (after static routes)
router.get('/:code', countryController.getCountryConfig);

module.exports = router;
