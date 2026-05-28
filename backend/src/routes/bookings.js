const router = require('express').Router();
const { authenticate } = require('../middleware/auth');
const c = require('../controllers/bookingController');
const { idempotencyCheck, actionRateLimit, detectSuspiciousBooking } = require('../middleware/fraudPrevention');

router.use(authenticate);
/**
 * @swagger
 * /bookings:
 *   get:
 *     summary: List bookings for the current user
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Bookings retrieved successfully
 *       401:
 *         description: Unauthorized
 */
router.get('/', c.list);
/**
 * @swagger
 * /bookings:
 *   post:
 *     summary: Create a new booking
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               professional_id:
 *                 type: string
 *               service_id:
 *                 type: string
 *               preferred_date:
 *                 type: string
 *                 format: date
 *               address:
 *                 type: string
 *     responses:
 *       201:
 *         description: Booking created successfully
 *       400:
 *         description: Invalid booking request
 *       401:
 *         description: Unauthorized
 */
router.post('/', idempotencyCheck, actionRateLimit('booking_create', 10, 60000), detectSuspiciousBooking, c.create);
/**
 * @swagger
 * /bookings/{id}:
 *   get:
 *     summary: Get booking details by id
 *     tags: [Bookings]
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
 *         description: Booking retrieved successfully
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Booking not found
 */
router.get('/:id', c.get);
/**
 * @swagger
 * /bookings/{id}/transition:
 *   post:
 *     summary: Transition a booking to a new status
 *     tags: [Bookings]
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
 *             required: [status]
 *             properties:
 *               status:
 *                 type: string
 *               note:
 *                 type: string
 *     responses:
 *       200:
 *         description: Booking status updated
 *       400:
 *         description: Invalid transition request
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Booking not found
 */
router.post('/:id/transition', c.transition);

module.exports = router;
