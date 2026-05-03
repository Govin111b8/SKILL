const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const { getStorefront, updateStorefront } = require('../controllers/storefrontController');

const router = Router();

// Public — get aggregated storefront data
router.get('/:id', getStorefront);

// Auth — update storefront fields (owner only)
router.put(
  '/:id',
  authenticate,
  authorize('professional'),
  validate([
    body('announcement').optional().isString().isLength({ max: 500 }).withMessage('Announcement max 500 chars'),
    body('whatsapp_number').optional().isString().isLength({ max: 20 }).withMessage('Invalid WhatsApp number'),
    body('instagram_handle').optional().isString().isLength({ max: 100 }).withMessage('Instagram handle max 100 chars'),
    body('website_url').optional().isURL().withMessage('Invalid website URL'),
    body('cover_image_url').optional().isString(),
    body('accent_color').optional().matches(/^#[0-9A-Fa-f]{6}$/).withMessage('Accent color must be hex (e.g. #6366F1)'),
    body('show_rating').optional().isBoolean().withMessage('show_rating must be boolean'),
    body('return_policy').optional().isString().isLength({ max: 2000 }).withMessage('Return policy max 2000 chars'),
    body('operating_hours').optional().isString().isLength({ max: 500 }).withMessage('Operating hours max 500 chars'),
    body('operating_days').optional().isString().isLength({ max: 200 }).withMessage('Operating days max 200 chars'),
  ]),
  updateStorefront
);

module.exports = router;
