const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const {
  createContact,
  getContacts,
  updateContactStatus,
} = require('../controllers/contactController');

const router = Router();

router.post(
  '/',
  authenticate,
  authorize('customer'),
  validate([
    body('professional_id').trim().notEmpty().withMessage('Professional ID is required'),
    body('contact_type')
      .isIn(['call', 'message', 'quote_request'])
      .withMessage('Contact type must be call, message, or quote_request'),
    body('message').trim().notEmpty().withMessage('Message is required'),
  ]),
  createContact
);

router.get('/', authenticate, getContacts);

router.put(
  '/:id/status',
  authenticate,
  authorize('professional'),
  validate([
    body('status')
      .isIn(['accepted', 'declined'])
      .withMessage('Status must be accepted or declined'),
  ]),
  updateContactStatus
);

module.exports = router;
