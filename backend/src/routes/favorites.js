const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const { listFavorites, toggleFavorite, checkFavorite } = require('../controllers/favoriteController');

const router = Router();

router.get('/', authenticate, listFavorites);
router.post('/toggle', authenticate, toggleFavorite);
router.get('/check/:professionalId', authenticate, checkFavorite);

module.exports = router;
