const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const {
  getStorefront, updateStorefront,
  addMedia, deleteMedia, getMedia,
  updateTheme,
  getPackages, addPackage, deletePackage,
} = require('../controllers/storefrontController');

const router = Router();

// Public — get aggregated storefront data
router.get('/:id', getStorefront);

// Public — list storefront media
router.get('/:id/media', getMedia);

// Public — list service packages
router.get('/:id/packages', getPackages);

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
    body('tagline').optional().isString().isLength({ max: 200 }).withMessage('Tagline max 200 chars'),
    body('intro_video_url').optional().isString(),
  ]),
  updateStorefront
);

// Auth — add media to storefront
router.post(
  '/:id/media',
  authenticate,
  authorize('professional'),
  validate([
    body('media_url').notEmpty().withMessage('media_url is required'),
    body('type').optional().isIn(['reel', 'before_after', 'highlight', 'testimonial', 'gallery']).withMessage('Invalid media type'),
    body('caption').optional().isString().isLength({ max: 500 }),
    body('before_url').optional().isString(),
    body('sort_order').optional().isInt(),
  ]),
  addMedia
);

// Auth — delete media from storefront
router.delete('/:id/media/:mediaId', authenticate, authorize('professional'), deleteMedia);

// Auth — update storefront theme
router.put(
  '/:id/theme',
  authenticate,
  authorize('professional'),
  validate([
    body('theme_name').optional().isIn(['modern', 'classic', 'bold', 'minimal', 'elegant', 'vibrant', 'dark', 'professional']).withMessage('Invalid theme'),
    body('primary_color').optional().matches(/^#[0-9A-Fa-f]{6}$/).withMessage('Invalid primary color'),
    body('accent_color').optional().matches(/^#[0-9A-Fa-f]{6}$/).withMessage('Invalid accent color'),
    body('layout').optional().isIn(['centered', 'left', 'split', 'hero']).withMessage('Invalid layout'),
    body('section_order').optional().isArray(),
    body('custom_intro').optional().isString().isLength({ max: 2000 }),
  ]),
  updateTheme
);

// Auth — add service package
router.post(
  '/:id/packages',
  authenticate,
  authorize('professional'),
  validate([
    body('name').notEmpty().isString().isLength({ max: 100 }).withMessage('Package name required (max 100 chars)'),
    body('tier').optional().isIn(['basic', 'standard', 'premium']).withMessage('Tier must be basic, standard, or premium'),
    body('price').optional().isFloat({ min: 0 }).withMessage('Price must be a positive number'),
    body('description').optional().isString().isLength({ max: 1000 }),
    body('features').optional().isArray(),
    body('is_popular').optional().isBoolean(),
  ]),
  addPackage
);

// Auth — delete service package
router.delete('/:id/packages/:packageId', authenticate, authorize('professional'), deletePackage);

module.exports = router;
