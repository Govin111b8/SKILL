const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const { getProfile, updateProfile, changePassword, deleteAccount } = require('../controllers/userController');

const router = Router();

router.get('/profile', authenticate, getProfile);

router.put('/profile', authenticate,
  validate([
    body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
    body('phone').optional().trim().notEmpty().withMessage('Phone cannot be empty'),
  ]),
  updateProfile
);

router.put('/change-password', authenticate,
  validate([
    body('current_password').notEmpty().withMessage('Current password is required'),
    body('new_password').isLength({ min: 6 }).withMessage('New password must be at least 6 characters'),
  ]),
  changePassword
);

router.delete('/account', authenticate, deleteAccount);

module.exports = router;
