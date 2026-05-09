const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const {
  createCollection,
  getCollections,
  getCollection,
  addItem,
  removeItem,
  deleteCollection,
} = require('../controllers/collectionsController');

const router = Router();

// All collections routes require authentication
router.use(authenticate);

// CRUD
router.post(
  '/',
  validate([
    body('name').notEmpty().isString().isLength({ max: 100 }).withMessage('Collection name required (max 100 chars)'),
    body('is_public').optional().isBoolean(),
  ]),
  createCollection
);
router.get('/', getCollections);
router.get('/:id', getCollection);
router.delete('/:id', deleteCollection);

// Items
router.post(
  '/:id/items',
  validate([
    body('item_type').isIn(['professional', 'service', 'post']).withMessage('item_type must be professional, service, or post'),
    body('item_id').isUUID().withMessage('item_id must be a UUID'),
  ]),
  addItem
);
router.delete('/:id/items/:itemId', removeItem);

module.exports = router;
