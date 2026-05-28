const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const {
  getServices,
  addService,
  addOwnService,
  updateService,
  deleteService,
  searchServices,
} = require('../controllers/serviceController');

const router = Router();

/**
 * @swagger
 * /services/search:
 *   get:
 *     summary: Search services across professionals
 *     tags: [Services]
 *     security: []
 *     parameters:
 *       - in: query
 *         name: q
 *         schema:
 *           type: string
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Services search results
 *       400:
 *         description: Invalid search query
 */
router.get('/search', searchServices);
/**
 * @swagger
 * /services/me:
 *   post:
 *     summary: Add a service to the authenticated professional profile
 *     tags: [Services]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               price:
 *                 type: number
 *     responses:
 *       201:
 *         description: Service added successfully
 *       400:
 *         description: Invalid request
 *       401:
 *         description: Unauthorized
 */
router.post('/me', authenticate, addOwnService);
/**
 * @swagger
 * /services/{professionalId}:
 *   get:
 *     summary: List services offered by a professional
 *     tags: [Services]
 *     security: []
 *     parameters:
 *       - in: path
 *         name: professionalId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Services retrieved successfully
 *       404:
 *         description: Professional not found
 */
router.get('/:professionalId', getServices);
/**
 * @swagger
 * /services/{professionalId}:
 *   post:
 *     summary: Add a service for a professional
 *     tags: [Services]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: professionalId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               price:
 *                 type: number
 *     responses:
 *       201:
 *         description: Service created successfully
 *       400:
 *         description: Invalid request
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Professional not found
 */
router.post('/:professionalId', authenticate, addService);
/**
 * @swagger
 * /services/item/{serviceId}:
 *   put:
 *     summary: Update a professional service
 *     tags: [Services]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: serviceId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               price:
 *                 type: number
 *     responses:
 *       200:
 *         description: Service updated successfully
 *       400:
 *         description: Invalid request
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Service not found
 */
router.put('/item/:serviceId', authenticate, updateService);
/**
 * @swagger
 * /services/item/{serviceId}:
 *   delete:
 *     summary: Delete a professional service
 *     tags: [Services]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: serviceId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Service deleted successfully
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Service not found
 */
router.delete('/item/:serviceId', authenticate, deleteService);

module.exports = router;
