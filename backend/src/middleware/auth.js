const jwt = require('jsonwebtoken');
const { config } = require('../config');
const { query } = require('../config/database');

const authenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Access denied. No token provided.',
    });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, config.jwt.secret);
    // Reject refresh tokens used as access tokens
    if (decoded.type === 'refresh') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token type.',
      });
    }

    // Enrich with is_admin flag from database (best-effort, doesn't fail auth)
    if (decoded.id) {
      try {
        const userRes = await query('SELECT is_admin FROM users WHERE id = $1', [decoded.id]);
        if (userRes.rows.length > 0) {
          decoded.is_admin = userRes.rows[0].is_admin;
        }
      } catch (_) {
        // DB lookup failed — continue without admin flag (non-critical)
        decoded.is_admin = false;
      }
    }

    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token.',
    });
  }
};

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required.',
      });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to perform this action.',
      });
    }
    next();
  };
};

// Like authenticate but doesn't reject — just sets req.user if token present
const optionalAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    try {
      const decoded = jwt.verify(token, config.jwt.secret);
      if (decoded.type !== 'refresh') {
        req.user = decoded;
      }
    } catch (_) {}
  }
  next();
};

module.exports = { authenticate, authorize, optionalAuth };
