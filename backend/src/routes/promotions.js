const { Router } = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const {
  getPromotions,
  createPromotion,
  updatePromotion,
  deletePromotion,
} = require('../controllers/promotionController');

const router = Router();

/**
 * @swagger
 * /promotions:
 *   get:
 *     summary: List active promotions
 *     tags: [Promotions]
 *     security: []
 *     responses:
 *       200:
 *         description: List of active promotions
 */
router.get('/', getPromotions);

/**
 * @swagger
 * /promotions:
 *   post:
 *     summary: Create a promotion (admin only)
 *     tags: [Promotions]
 *     security:
 *       - bearerAuth: []
 */
router.post(
  '/',
  authenticate,
  authorize('admin'),
  [body('title').notEmpty().withMessage('title is required')],
  validate,
  createPromotion
);

/**
 * @swagger
 * /promotions/{id}:
 *   put:
 *     summary: Update a promotion (admin only)
 *     tags: [Promotions]
 *     security:
 *       - bearerAuth: []
 */
router.put('/:id', authenticate, authorize('admin'), updatePromotion);

/**
 * @swagger
 * /promotions/{id}:
 *   delete:
 *     summary: Delete a promotion (admin only)
 *     tags: [Promotions]
 *     security:
 *       - bearerAuth: []
 */
router.delete('/:id', authenticate, authorize('admin'), deletePromotion);

module.exports = router;
