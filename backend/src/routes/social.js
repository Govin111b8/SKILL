const { Router } = require('express');
const { authenticate } = require('../middleware/auth');
const {
  followProfessional,
  unfollowProfessional,
  getFollowing,
  checkFollow,
  getFeed,
} = require('../controllers/socialController');

const router = Router();

// All social routes require authentication
router.use(authenticate);

// Follow / unfollow a professional
router.post('/follow/:professionalId', followProfessional);
router.delete('/unfollow/:professionalId', unfollowProfessional);

// Check if following a professional
router.get('/check/:professionalId', checkFollow);

// List followed professionals
router.get('/following', getFollowing);

// Aggregated feed from followed professionals
router.get('/feed', getFeed);

module.exports = router;
