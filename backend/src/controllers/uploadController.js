const path = require('path');
const crypto = require('crypto');
const multer = require('multer');
const { query } = require('../config/database');
const storage = require('../services/storage');

// Use memory storage — we'll pipe to S3/local via storage service
const memoryStorage = multer.memoryStorage();

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'video/quicktime', 'video/webm'];
const ALLOWED_DOC_TYPES = [...ALLOWED_TYPES, 'application/pdf'];
const MAX_SIZE = 10 * 1024 * 1024; // 10MB

const upload = multer({
  storage: memoryStorage,
  limits: { fileSize: MAX_SIZE },
  fileFilter: (req, file, cb) => {
    if (ALLOWED_TYPES.includes(file.mimetype)) cb(null, true);
    else cb(new Error('Only JPEG, PNG, WebP, GIF images and MP4/WebM/MOV videos are allowed'));
  },
}).single('file');

const uploadDoc = multer({
  storage: memoryStorage,
  limits: { fileSize: MAX_SIZE },
  fileFilter: (req, file, cb) => {
    if (ALLOWED_DOC_TYPES.includes(file.mimetype)) cb(null, true);
    else cb(new Error('Only images, videos, and PDF files are allowed'));
  },
}).single('file');

exports.uploadFile = (req, res, next) => {
  upload(req, res, async (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') return res.status(413).json({ success: false, message: 'File too large. Max 5MB.' });
      return res.status(400).json({ success: false, message: err.message || 'Upload failed' });
    }
    if (!req.file) return res.status(400).json({ success: false, message: 'No file provided' });

    try {
      const ALLOWED_FOLDERS = ['uploads', 'avatars', 'kyc', 'portfolio', 'storefront', 'media', 'documents', 'reels'];
      const folder = ALLOWED_FOLDERS.includes(req.query.folder) ? req.query.folder : 'uploads';
      const { url, key } = await storage.uploadFile(
        req.file.buffer,
        req.file.originalname,
        req.file.mimetype,
        folder
      );
      res.json({ success: true, data: { url, key, filename: path.basename(url), size: req.file.size } });
    } catch (e) { next(e); }
  });
};

// Upload KYC/document file (supports PDF)
exports.uploadDocument = (req, res, next) => {
  uploadDoc(req, res, async (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') return res.status(413).json({ success: false, message: 'File too large. Max 5MB.' });
      return res.status(400).json({ success: false, message: err.message || 'Upload failed' });
    }
    if (!req.file) return res.status(400).json({ success: false, message: 'No file provided' });

    try {
      const { url, key } = await storage.uploadFile(
        req.file.buffer,
        req.file.originalname,
        req.file.mimetype,
        'kyc'
      );
      res.json({ success: true, data: { url, key, filename: path.basename(url), size: req.file.size } });
    } catch (e) { next(e); }
  });
};

// Update user avatar
exports.updateAvatar = (req, res, next) => {
  upload(req, res, async (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') return res.status(413).json({ success: false, message: 'File too large. Max 5MB.' });
      return res.status(400).json({ success: false, message: err.message || 'Upload failed' });
    }
    if (!req.file) return res.status(400).json({ success: false, message: 'No file provided' });

    try {
      const { url } = await storage.uploadFile(
        req.file.buffer,
        req.file.originalname,
        req.file.mimetype,
        'avatars'
      );
      await query('UPDATE users SET avatar_url = $1 WHERE id = $2', [url, req.user.id]);
      res.json({ success: true, data: { avatar_url: url } });
    } catch (e) { next(e); }
  });
};
