const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { query } = require('../config/database');
const { config } = require('../config');
const logger = require('../config/logger');
const emailService = require('../services/email');
const smsService = require('../services/sms');

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

// ============================================================
// EMAIL VERIFICATION
// ============================================================

const sendVerificationEmail = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const userRes = await query('SELECT email, email_verified FROM users WHERE id = $1', [userId]);
    if (userRes.rows.length === 0) return res.status(404).json({ success: false, message: 'User not found.' });

    const user = userRes.rows[0];
    if (user.email_verified) {
      return res.status(400).json({ success: false, message: 'Email already verified.' });
    }

    const token = emailService.generateToken();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    await query(
      `INSERT INTO email_verifications (user_id, token, expires_at) VALUES ($1, $2, $3)`,
      [userId, token, expiresAt]
    );

    await emailService.sendVerificationEmail(user.email, token);
    res.json({ success: true, message: 'Verification email sent.' });
  } catch (error) { next(error); }
};

const verifyEmail = async (req, res, next) => {
  try {
    const { token } = req.body;
    if (!token) return res.status(400).json({ success: false, message: 'Token is required.' });

    const result = await query(
      `SELECT * FROM email_verifications WHERE token = $1 AND expires_at > NOW() AND verified_at IS NULL`,
      [token]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ success: false, message: 'Invalid or expired verification token.' });
    }

    const verification = result.rows[0];

    await query(`UPDATE email_verifications SET verified_at = NOW() WHERE id = $1`, [verification.id]);
    await query(`UPDATE users SET email_verified = TRUE, email_verified_at = NOW() WHERE id = $1`, [verification.user_id]);

    logger.info({ userId: verification.user_id }, 'Email verified');
    res.json({ success: true, message: 'Email verified successfully.' });
  } catch (error) { next(error); }
};

// ============================================================
// PASSWORD RESET
// ============================================================

const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ success: false, message: 'Email is required.' });

    const userRes = await query('SELECT id, email FROM users WHERE email = $1', [email]);

    // Always return success to prevent email enumeration
    if (userRes.rows.length === 0) {
      return res.json({ success: true, message: 'If an account exists with this email, a reset link has been sent.' });
    }

    const user = userRes.rows[0];
    const token = emailService.generateToken();
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    // Invalidate previous reset tokens
    await query(`UPDATE password_resets SET used_at = NOW() WHERE user_id = $1 AND used_at IS NULL`, [user.id]);

    await query(
      `INSERT INTO password_resets (user_id, token, expires_at) VALUES ($1, $2, $3)`,
      [user.id, token, expiresAt]
    );

    await emailService.sendPasswordResetEmail(user.email, token);
    logger.info({ userId: user.id }, 'Password reset requested');
    res.json({ success: true, message: 'If an account exists with this email, a reset link has been sent.' });
  } catch (error) { next(error); }
};

const resetPassword = async (req, res, next) => {
  try {
    const { token, password } = req.body;
    if (!token || !password) {
      return res.status(400).json({ success: false, message: 'Token and new password are required.' });
    }

    if (password.length < 8) {
      return res.status(400).json({ success: false, message: 'Password must be at least 8 characters.' });
    }

    const result = await query(
      `SELECT * FROM password_resets WHERE token = $1 AND expires_at > NOW() AND used_at IS NULL`,
      [token]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ success: false, message: 'Invalid or expired reset token.' });
    }

    const resetRecord = result.rows[0];
    const salt = await bcrypt.genSalt(config.isProduction ? 12 : 10);
    const hashedPassword = await bcrypt.hash(password, salt);

    await query(`UPDATE users SET password_hash = $1 WHERE id = $2`, [hashedPassword, resetRecord.user_id]);
    await query(`UPDATE password_resets SET used_at = NOW() WHERE id = $1`, [resetRecord.id]);

    // Blacklist all existing refresh tokens for this user (force re-login)
    const tokenHash = crypto.createHash('sha256').update(`all_${resetRecord.user_id}_${Date.now()}`).digest('hex');
    await query(
      `INSERT INTO refresh_token_blacklist (token_hash, user_id, reason, expires_at) VALUES ($1, $2, 'password_reset', NOW() + INTERVAL '7 days')`,
      [tokenHash, resetRecord.user_id]
    );

    logger.info({ userId: resetRecord.user_id }, 'Password reset completed');
    res.json({ success: true, message: 'Password reset successfully. Please login with your new password.' });
  } catch (error) { next(error); }
};

// ============================================================
// PHONE VERIFICATION (OTP)
// ============================================================

const sendPhoneOTP = async (req, res, next) => {
  try {
    const { phone } = req.body;
    if (!phone) return res.status(400).json({ success: false, message: 'Phone number is required.' });

    const result = await smsService.sendOTP(phone, 'phone_verification');
    if (!result.success) {
      return res.status(429).json({ success: false, message: result.error });
    }

    res.json({ success: true, message: 'OTP sent.', expiresIn: result.expiresIn });
  } catch (error) { next(error); }
};

const verifyPhoneOTP = async (req, res, next) => {
  try {
    const { phone, otp } = req.body;
    if (!phone || !otp) return res.status(400).json({ success: false, message: 'Phone and OTP are required.' });

    const result = smsService.verifyOTP(phone, otp, 'phone_verification');
    if (!result.success) {
      return res.status(400).json({ success: false, message: result.error });
    }

    // Mark phone as verified for the current user
    if (req.user) {
      await query(`UPDATE users SET phone_verified = TRUE WHERE id = $1`, [req.user.id]);
    }

    res.json({ success: true, message: 'Phone verified successfully.' });
  } catch (error) { next(error); }
};

// ============================================================
// LOGOUT (token revocation)
// ============================================================

const logout = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
      await query(
        `INSERT INTO refresh_token_blacklist (token_hash, user_id, reason, expires_at)
         VALUES ($1, $2, 'logout', NOW() + INTERVAL '7 days')
         ON CONFLICT (token_hash) DO NOTHING`,
        [tokenHash, req.user.id]
      );
    }
    res.json({ success: true, message: 'Logged out successfully.' });
  } catch (error) { next(error); }
};

module.exports = {
  register,
  login,
  getMe,
  refreshTokenHandler,
  sendVerificationEmail,
  verifyEmail,
  forgotPassword,
  resetPassword,
  sendPhoneOTP,
  verifyPhoneOTP,
  logout,
};
