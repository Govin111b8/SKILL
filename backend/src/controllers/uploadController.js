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

// Allowed file extensions (whitelist)
const ALLOWED_EXTENSIONS = new Set([
  '.jpg', '.jpeg', '.png', '.webp', '.gif', '.mp4', '.mov', '.webm', '.pdf',
]);

// Magic byte signatures for file type verification
const MAGIC_BYTES = {
  'image/jpeg': [Buffer.from([0xFF, 0xD8, 0xFF])],
  'image/png': [Buffer.from([0x89, 0x50, 0x4E, 0x47])],
  'image/gif': [Buffer.from('GIF87a'), Buffer.from('GIF89a')],
  'image/webp': [], // RIFF header checked separately
  'video/mp4': [], // ftyp box checked separately
  'video/quicktime': [], // ftyp box checked separately
  'video/webm': [Buffer.from([0x1A, 0x45, 0xDF, 0xA3])],
  'application/pdf': [Buffer.from('%PDF')],
};

/**
 * Validate file magic bytes match claimed MIME type.
 * Prevents attackers from uploading malicious files with spoofed Content-Type.
 */
function validateMagicBytes(buffer, mimetype) {
  if (!buffer || buffer.length < 4) return false;

  // WebP: RIFF....WEBP
  if (mimetype === 'image/webp') {
    return buffer.slice(0, 4).toString() === 'RIFF' && buffer.slice(8, 12).toString() === 'WEBP';
  }

  // MP4/QuickTime: look for ftyp box
  if (mimetype === 'video/mp4' || mimetype === 'video/quicktime') {
    const ftypStr = buffer.slice(4, 8).toString();
    return ftypStr === 'ftyp';
  }

  const signatures = MAGIC_BYTES[mimetype];
  if (!signatures || signatures.length === 0) return true; // No check available

  return signatures.some((sig) => {
    if (buffer.length < sig.length) return false;
    return buffer.slice(0, sig.length).equals(sig);
  });
}

/**
 * Validate file extension against whitelist.
 */
function validateExtension(filename) {
  const ext = path.extname(filename || '').toLowerCase();
  return ALLOWED_EXTENSIONS.has(ext);
}

const upload = multer({
  storage: memoryStorage,
  limits: { fileSize: MAX_SIZE },
  fileFilter: (req, file, cb) => {
    // Check MIME type
    if (!ALLOWED_TYPES.includes(file.mimetype)) {
      return cb(new Error('Only JPEG, PNG, WebP, GIF images and MP4/WebM/MOV videos are allowed'));
    }
    // Check file extension
    if (!validateExtension(file.originalname)) {
      return cb(new Error('File extension not allowed'));
    }
    cb(null, true);
  },
}).single('file');

const uploadDoc = multer({
  storage: memoryStorage,
  limits: { fileSize: MAX_SIZE },
  fileFilter: (req, file, cb) => {
    if (!ALLOWED_DOC_TYPES.includes(file.mimetype)) {
      return cb(new Error('Only images, videos, and PDF files are allowed'));
    }
    if (!validateExtension(file.originalname)) {
      return cb(new Error('File extension not allowed'));
    }
    cb(null, true);
  },
}).single('file');

exports.uploadFile = (req, res, next) => {
  upload(req, res, async (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') return res.status(413).json({ success: false, message: 'File too large. Max 10MB.' });
      return res.status(400).json({ success: false, message: err.message || 'Upload failed' });
    }
    if (!req.file) return res.status(400).json({ success: false, message: 'No file provided' });

    // Validate magic bytes match claimed MIME type
    if (!validateMagicBytes(req.file.buffer, req.file.mimetype)) {
      return res.status(400).json({ success: false, message: 'File content does not match its type. Upload rejected.' });
    }

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
      if (err.code === 'LIMIT_FILE_SIZE') return res.status(413).json({ success: false, message: 'File too large. Max 10MB.' });
      return res.status(400).json({ success: false, message: err.message || 'Upload failed' });
    }
    if (!req.file) return res.status(400).json({ success: false, message: 'No file provided' });

    // Validate magic bytes match claimed MIME type
    if (!validateMagicBytes(req.file.buffer, req.file.mimetype)) {
      return res.status(400).json({ success: false, message: 'File content does not match its type. Upload rejected.' });
    }

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
