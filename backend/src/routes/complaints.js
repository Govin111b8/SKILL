const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const { fileComplaint, getComplaints } = require('../controllers/complaintController');

const router = Router();

router.post(
  '/',
  authenticate,
  validate([
    body('reported_user_id').trim().notEmpty().withMessage('Reported user ID is required'),
    body('complaint_type')
      .trim()
      .notEmpty()
      .withMessage('Complaint type is required'),
    body('description')
      .trim()
      .isLength({ min: 10 })
      .withMessage('Description must be at least 10 characters'),
  ]),
  fileComplaint
);

router.get('/', authenticate, authorize('admin'), getComplaints);

module.exports = router;
