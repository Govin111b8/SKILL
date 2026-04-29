const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const multer = require('multer');
const { query } = require('../config/database');

// Store files in /uploads directory
const UPLOAD_DIR = path.join(__dirname, '../../uploads');
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOAD_DIR),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const name = `${crypto.randomUUID()}${ext}`;
    cb(null, name);
  },
});

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
const MAX_SIZE = 5 * 1024 * 1024; // 5MB

const upload = multer({
  storage,
  limits: { fileSize: MAX_SIZE },
  fileFilter: (req, file, cb) => {
    if (ALLOWED_TYPES.includes(file.mimetype)) cb(null, true);
    else cb(new Error('Only JPEG, PNG, WebP, and GIF images are allowed'));
  },
}).single('file');

exports.uploadFile = (req, res, next) => {
  upload(req, res, (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') return res.status(413).json({ success: false, message: 'File too large. Max 5MB.' });
      return res.status(400).json({ success: false, message: err.message || 'Upload failed' });
    }
    if (!req.file) return res.status(400).json({ success: false, message: 'No file provided' });

    const url = `/uploads/${req.file.filename}`;
    res.json({ success: true, data: { url, filename: req.file.filename, size: req.file.size } });
  });
};

// Update user avatar
exports.updateAvatar = async (req, res, next) => {
  upload(req, res, async (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') return res.status(413).json({ success: false, message: 'File too large. Max 5MB.' });
      return res.status(400).json({ success: false, message: err.message || 'Upload failed' });
    }
    if (!req.file) return res.status(400).json({ success: false, message: 'No file provided' });

    try {
      const url = `/uploads/${req.file.filename}`;
      await query('UPDATE users SET avatar_url = $1 WHERE id = $2', [url, req.user.id]);
      res.json({ success: true, data: { avatar_url: url } });
    } catch (e) { next(e); }
  });
};
