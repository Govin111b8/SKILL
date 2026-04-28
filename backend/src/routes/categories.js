const { Router } = require('express');
const { getCategories, getCategory, getCategoryProfessionals } = require('../controllers/categoryController');

const router = Router();

router.get('/', getCategories);
router.get('/:id', getCategory);
router.get('/:id/professionals', getCategoryProfessionals);

module.exports = router;
