const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const { authenticate, authorize, optionalAuth } = require('../middleware/auth');
const {
  createPost,
  getPosts,
  getPost,
  toggleLike,
  deletePost,
} = require('../controllers/communityController');

const router = Router();

// Public — list posts
router.get('/posts', getPosts);

// Public — get single post (optionalAuth to detect liked status)
router.get('/posts/:id', optionalAuth, getPost);

// Auth — create post (professionals only)
router.post(
  '/posts',
  authenticate,
  authorize('professional'),
  validate([
    body('title').notEmpty().isString().isLength({ max: 200 }).withMessage('Title required (max 200 chars)'),
    body('content').notEmpty().isString().isLength({ max: 5000 }).withMessage('Content required (max 5000 chars)'),
    body('category').optional().isString().isLength({ max: 50 }),
    body('media_urls').optional().isArray(),
  ]),
  createPost
);

// Auth — like/unlike a post
router.post('/posts/:id/like', authenticate, toggleLike);

// Auth — delete own post
router.delete('/posts/:id', authenticate, deletePost);

module.exports = router;
