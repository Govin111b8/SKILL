const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { query } = require('../config/database');
const { config } = require('../config');
const logger = require('../config/logger');

// In-memory login attempt tracking (use Redis in production for multi-instance)
const loginAttempts = new Map();

function getAttemptKey(email) {
  return email.toLowerCase().trim();
}

function recordFailedAttempt(email) {
  const key = getAttemptKey(email);
  const now = Date.now();
  const record = loginAttempts.get(key) || { count: 0, firstAttempt: now, lockedUntil: 0 };
  record.count++;
  record.lastAttempt = now;
  if (record.count >= config.security.maxLoginAttempts) {
    record.lockedUntil = now + config.security.lockoutDurationMinutes * 60 * 1000;
  }
  loginAttempts.set(key, record);
}

function isAccountLocked(email) {
  const key = getAttemptKey(email);
  const record = loginAttempts.get(key);
  if (!record) return false;
  if (record.lockedUntil > Date.now()) return true;
  // Reset if lockout expired
  if (record.lockedUntil > 0 && record.lockedUntil <= Date.now()) {
    loginAttempts.delete(key);
  }
  return false;
}

function clearAttempts(email) {
  loginAttempts.delete(getAttemptKey(email));
}

const generateAccessToken = (user) => {
  return jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    config.jwt.secret,
    { expiresIn: config.jwt.expiresIn }
  );
};

const generateRefreshToken = (user) => {
  return jwt.sign(
    { id: user.id, type: 'refresh' },
    config.jwt.secret,
    { expiresIn: config.jwt.refreshExpiresIn }
  );
};

const register = async (req, res, next) => {
  try {
    const { name, email, password, role, location } = req.body;
    const phone = req.body.phone || '';

    // Check if user already exists
    const existingUser = await query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );
    if (existingUser.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists.',
      });
    }

    // Hash password
    const salt = await bcrypt.genSalt(config.isProduction ? 12 : 10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const id = crypto.randomUUID();
    const result = await query(
      `INSERT INTO users (id, name, email, password_hash, phone, role, location, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
       RETURNING id, name, email, phone, role, location, created_at`,
      [id, name, email, hashedPassword, phone, role, location]
    );

    const user = result.rows[0];
    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    logger.info({ userId: user.id, role: user.role }, 'User registered');

    res.status(201).json({
      success: true,
      data: { user, token: accessToken, refreshToken },
      message: 'User registered successfully.',
    });
  } catch (error) {
    next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Account lockout check
    if (isAccountLocked(email)) {
      logger.warn({ email }, 'Login attempt on locked account');
      return res.status(429).json({
        success: false,
        message: `Account temporarily locked due to too many failed attempts. Try again in ${config.security.lockoutDurationMinutes} minutes.`,
      });
    }

    const result = await query(
      'SELECT id, name, email, password_hash, phone, role, location FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      recordFailedAttempt(email);
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.',
      });
    }

    const user = result.rows[0];

    // Check if user is banned (3+ complaints with 'banned' status)
    const banCheck = await query(
      "SELECT COUNT(*) FROM complaints WHERE reported_user_id = $1 AND status = 'banned'",
      [user.id]
    );
    if (parseInt(banCheck.rows[0].count) > 0) {
      return res.status(403).json({
        success: false,
        message: 'Your account has been banned.',
      });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      recordFailedAttempt(email);
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.',
      });
    }

    // Successful login — clear lockout
    clearAttempts(email);

    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    const { password_hash: _, ...userWithoutPassword } = user;

    logger.info({ userId: user.id }, 'User logged in');

    res.status(200).json({
      success: true,
      data: { user: userWithoutPassword, token: accessToken, refreshToken },
      message: 'Login successful.',
    });
  } catch (error) {
    next(error);
  }
};

const refreshTokenHandler = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ success: false, message: 'Refresh token is required.' });
    }

    let decoded;
    try {
      decoded = jwt.verify(refreshToken, config.jwt.secret);
    } catch (err) {
      return res.status(401).json({ success: false, message: 'Invalid or expired refresh token.' });
    }

    if (decoded.type !== 'refresh') {
      return res.status(401).json({ success: false, message: 'Invalid token type.' });
    }

    const result = await query(
      'SELECT id, name, email, phone, role, location FROM users WHERE id = $1',
      [decoded.id]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, message: 'User not found.' });
    }

    const user = result.rows[0];
    const newAccessToken = generateAccessToken(user);
    const newRefreshToken = generateRefreshToken(user);

    res.status(200).json({
      success: true,
      data: { token: newAccessToken, refreshToken: newRefreshToken },
      message: 'Token refreshed successfully.',
    });
  } catch (error) {
    next(error);
  }
};

const getMe = async (req, res, next) => {
  try {
    const result = await query(
      'SELECT id, name, email, phone, role, location, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found.',
      });
    }

    res.status(200).json({
      success: true,
      data: { user: result.rows[0] },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { register, login, getMe, refreshTokenHandler };
