const { Router } = require('express');
const { getCategories, getCategory, getCategoryProfessionals } = require('../controllers/categoryController');
const { cacheMiddleware } = require('../middleware/cache');

const router = Router();

// Categories rarely change — cache for 10 minutes
router.get('/', cacheMiddleware('category', 600), getCategories);
router.get('/:id', cacheMiddleware('category', 600), getCategory);
router.get('/:id/professionals', cacheMiddleware('provider', 120), getCategoryProfessionals);

module.exports = router;
