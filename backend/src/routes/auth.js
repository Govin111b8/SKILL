const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate, optionalAuth } = require('../middleware/auth');
const {
  register, login, getMe, refreshTokenHandler,
  sendVerificationEmail, verifyEmail,
  forgotPassword, resetPassword,
  sendPhoneOTP, verifyPhoneOTP,
  logout,
} = require('../controllers/authController');

const router = Router();

/**
 * @swagger
 * /auth/me:
 *   get:
 *     summary: Get current user profile
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Current user data
 *       401:
 *         description: Not authenticated
 */
router.get('/me', authenticate, getMe);

/**
 * @swagger
 * /auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Auth]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name, email, password, role]
 *             properties:
 *               name:
 *                 type: string
 *                 example: Rajesh Kumar
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *                 minLength: 8
 *                 description: Must contain uppercase, lowercase, number, and special character
 *               phone:
 *                 type: string
 *               role:
 *                 type: string
 *                 enum: [customer, professional, agent]
 *               location:
 *                 type: string
 *     responses:
 *       201:
 *         description: User registered successfully
 *       400:
 *         description: Validation error or user already exists
 */

router.post(
  '/register',
  validate([
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters')
      .matches(/[A-Z]/)
      .withMessage('Password must contain at least one uppercase letter')
      .matches(/[a-z]/)
      .withMessage('Password must contain at least one lowercase letter')
      .matches(/\d/)
      .withMessage('Password must contain at least one number')
      .matches(/[!@#$%^&*(),.?":{}|<>]/)
      .withMessage('Password must contain at least one special character'),
    body('phone').optional({ checkFalsy: true }).trim(),
    body('role')
      .isIn(['customer', 'professional', 'agent'])
      .withMessage('Role must be customer, professional, or agent'),
    body('location').optional({ checkFalsy: true }).trim(),
  ]),
  register
);

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Login with email and password
 *     tags: [Auth]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login successful, returns access and refresh tokens
 *       401:
 *         description: Invalid credentials
 *       429:
 *         description: Account locked due to too many failed attempts
 */
router.post(
  '/login',
  validate([
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required'),
  ]),
  login
);

/**
 * @swagger
 * /auth/refresh:
 *   post:
 *     summary: Refresh access token
 *     tags: [Auth]
 *     security: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [refreshToken]
 *             properties:
 *               refreshToken:
 *                 type: string
 *     responses:
 *       200:
 *         description: New access and refresh tokens
 *       401:
 *         description: Invalid or expired refresh token
 */
router.post(
  '/refresh',
  validate([
    body('refreshToken').notEmpty().withMessage('Refresh token is required'),
  ]),
  refreshTokenHandler
);

// Email verification
router.post('/send-verification', authenticate, sendVerificationEmail);
router.post('/verify-email', validate([
  body('token').notEmpty().withMessage('Token is required'),
]), verifyEmail);

// Password reset
router.post('/forgot-password', validate([
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
]), forgotPassword);

router.post('/reset-password', validate([
  body('token').notEmpty().withMessage('Token is required'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
]), resetPassword);

// Phone OTP
router.post('/send-otp', validate([
  body('phone').notEmpty().withMessage('Phone number is required'),
]), sendPhoneOTP);

router.post('/verify-otp', optionalAuth, validate([
  body('phone').notEmpty().withMessage('Phone is required'),
  body('otp').notEmpty().withMessage('OTP is required'),
]), verifyPhoneOTP);

// Logout (token revocation)
router.post('/logout', authenticate, logout);

module.exports = router;
