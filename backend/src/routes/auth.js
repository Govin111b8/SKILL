const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const { register, login, getMe } = require('../controllers/authController');

const router = Router();

router.get('/me', authenticate, getMe);

router.post(
  '/register',
  validate([
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('password')
      .isLength({ min: 6 })
      .withMessage('Password must be at least 6 characters')
      .matches(/[A-Za-z]/)
      .withMessage('Password must contain at least one letter')
      .matches(/\d/)
      .withMessage('Password must contain at least one number'),
    body('phone').optional({ checkFalsy: true }).trim(),
    body('role')
      .isIn(['customer', 'professional'])
      .withMessage('Role must be customer or professional'),
    body('location').optional({ checkFalsy: true }).trim(),
  ]),
  register
);

router.post(
  '/login',
  validate([
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required'),
  ]),
  login
);

module.exports = router;
