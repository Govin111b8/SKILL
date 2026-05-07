const { Router } = require('express');
const crypto = require('crypto');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const { query } = require('../config/database');
const { getCategories, getCategory, getCategoryProfessionals } = require('../controllers/categoryController');
const { cacheMiddleware } = require('../middleware/cache');

const router = Router();

// Categories rarely change — cache for 10 minutes
router.get('/', cacheMiddleware('category', 600), getCategories);
router.get('/:id', cacheMiddleware('category', 600), getCategory);
router.get('/:id/professionals', cacheMiddleware('provider', 120), getCategoryProfessionals);

// POST /api/categories/request — User/pro submits new category suggestion
router.post('/request', authenticate,
  validate([
    body('category_name').trim().notEmpty().withMessage('category_name is required'),
    body('description').optional().isString(),
    body('parent_id').optional({ nullable: true }).isInt(),
  ]),
  async (req, res, next) => {
    try {
      const { category_name, description, parent_id } = req.body;
      await query(
        `INSERT INTO category_requests (id, user_id, category_name, description, parent_id, created_at)
         VALUES ($1, $2, $3, $4, $5, NOW())`,
        [crypto.randomUUID(), req.user.id, category_name.trim(), description || null, parent_id || null]
      );
      res.status(201).json({ success: true, message: 'Category suggestion submitted. We\'ll review it within 5 business days.' });
    } catch (err) { next(err); }
  }
);

module.exports = router;

