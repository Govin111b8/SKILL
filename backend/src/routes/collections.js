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
/**
 * @swagger
 * /collections:
 *   post:
 *     summary: Create a new collection
 *     tags: [Collections]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name]
 *             properties:
 *               name:
 *                 type: string
 *               is_public:
 *                 type: boolean
 *     responses:
 *       201:
 *         description: Collection created successfully
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 */
router.post(
  '/',
  validate([
    body('name').notEmpty().isString().isLength({ max: 100 }).withMessage('Collection name required (max 100 chars)'),
    body('is_public').optional().isBoolean(),
  ]),
  createCollection
);
/**
 * @swagger
 * /collections:
 *   get:
 *     summary: List collections for the current user
 *     tags: [Collections]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Collections retrieved successfully
 *       401:
 *         description: Unauthorized
 */
router.get('/', getCollections);
/**
 * @swagger
 * /collections/{id}:
 *   get:
 *     summary: Get a collection by id
 *     tags: [Collections]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Collection retrieved successfully
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Collection not found
 */
router.get('/:id', getCollection);
/**
 * @swagger
 * /collections/{id}:
 *   delete:
 *     summary: Delete a collection
 *     tags: [Collections]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Collection deleted successfully
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Collection not found
 */
router.delete('/:id', deleteCollection);

// Items
/**
 * @swagger
 * /collections/{id}/items:
 *   post:
 *     summary: Add an item to a collection
 *     tags: [Collections]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [item_type, item_id]
 *             properties:
 *               item_type:
 *                 type: string
 *                 enum: [professional, service, post]
 *               item_id:
 *                 type: string
 *     responses:
 *       201:
 *         description: Item added to collection
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Collection not found
 */
router.post(
  '/:id/items',
  validate([
    body('item_type').isIn(['professional', 'service', 'post']).withMessage('item_type must be professional, service, or post'),
    body('item_id').isUUID().withMessage('item_id must be a UUID'),
  ]),
  addItem
);
/**
 * @swagger
 * /collections/{id}/items/{itemId}:
 *   delete:
 *     summary: Remove an item from a collection
 *     tags: [Collections]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: itemId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Item removed from collection
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Collection or item not found
 */
router.delete('/:id/items/:itemId', removeItem);

module.exports = router;
