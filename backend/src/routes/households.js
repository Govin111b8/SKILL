const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const householdController = require('../controllers/householdController');

// Household management
router.post('/', auth, householdController.createHousehold);
router.get('/', auth, householdController.listHouseholds);
router.get('/:id', auth, householdController.getHousehold);
router.put('/:id', auth, householdController.updateHousehold);
router.post('/:id/members', auth, householdController.addMember);
router.delete('/:id/members/:memberId', auth, householdController.removeMember);

module.exports = router;
