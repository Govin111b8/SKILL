const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const pbc = require('../controllers/providerBusinessController');

// Inventory management
router.get('/inventory', auth, pbc.listInventory);
router.get('/inventory/low-stock', auth, pbc.getLowStockAlerts);
router.post('/inventory', auth, pbc.addItem);
router.put('/inventory/:id', auth, pbc.updateItem);
router.delete('/inventory/:id', auth, pbc.deleteItem);

// CRM — customer relationship management
router.get('/customers', auth, pbc.listCustomers);
router.get('/customers/stats', auth, pbc.getCRMStats);
router.get('/customers/:customer_id', auth, pbc.getOrCreateCustomer);
router.put('/customers/:customer_id', auth, pbc.updateCustomerNotes);

module.exports = router;
