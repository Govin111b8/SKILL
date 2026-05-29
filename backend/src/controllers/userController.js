const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const { pool, query } = require('../config/database');

const getProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const result = await query(
      `SELECT id, name, email, phone, role, location, avatar_url,
              phone_verified, government_id_verified, selfie_verified, created_at
       FROM users WHERE id = $1`,
      [userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }
    res.status(200).json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { name, phone, location, avatar_url } = req.body;

    const result = await query(
      `UPDATE users
       SET name = COALESCE($1, name),
           phone = COALESCE($2, phone),
           location = COALESCE($3, location),
           avatar_url = COALESCE($4, avatar_url),
           updated_at = NOW()
       WHERE id = $5
       RETURNING id, name, email, phone, role, location, avatar_url, created_at`,
      [name, phone, location, avatar_url, userId]
    );

    res.status(200).json({ success: true, data: result.rows[0], message: 'Profile updated.' });
  } catch (error) {
    next(error);
  }
};

const changePassword = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { current_password, new_password } = req.body;

    if (!new_password || new_password.length < 8) {
      return res.status(400).json({ success: false, message: 'New password must be at least 8 characters.' });
    }
    if (!/[A-Z]/.test(new_password)) {
      return res.status(400).json({ success: false, message: 'New password must contain at least one uppercase letter.' });
    }
    if (!/\d/.test(new_password)) {
      return res.status(400).json({ success: false, message: 'New password must contain at least one number.' });
    }

    const userResult = await query('SELECT password_hash FROM users WHERE id = $1', [userId]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    const isMatch = await bcrypt.compare(current_password, userResult.rows[0].password_hash);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Current password is incorrect.' });
    }

    const salt = await bcrypt.genSalt(12);
    const hash = await bcrypt.hash(new_password, salt);
    await query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2', [hash, userId]);

    res.status(200).json({ success: true, message: 'Password changed successfully.' });
  } catch (error) {
    next(error);
  }
};

const deleteAccount = async (req, res, next) => {
  const client = await pool.connect();
  try {
    const userId = req.user.id;
    const deletedEmail = `deleted+${crypto.randomUUID()}@deleted.skillconnect.invalid`;
    const deletedPhone = `deleted${Date.now().toString().slice(-10)}`;
    const disabledPasswordHash = crypto.randomBytes(32).toString('hex');

    await client.query('BEGIN');
    const result = await client.query(
      `UPDATE users
       SET name = 'Deleted User',
           email = $2,
           phone = $3,
           password_hash = $4,
           avatar_url = NULL,
           location = NULL,
           phone_verified = FALSE,
           government_id_verified = FALSE,
           selfie_verified = FALSE,
           is_active = FALSE,
           deleted_at = NOW(),
           updated_at = NOW()
       WHERE id = $1
       RETURNING id`,
      [userId, deletedEmail, deletedPhone, disabledPasswordHash]
    );

    if (result.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    try {
      await client.query('DELETE FROM refresh_tokens WHERE user_id = $1', [userId]);
    } catch (refreshErr) {
      if (refreshErr.code !== '42P01') throw refreshErr;
    }

    await client.query('COMMIT');
    res.status(200).json({ success: true, message: 'Account anonymized successfully.' });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    next(error);
  } finally {
    client.release();
  }
};

module.exports = { getProfile, updateProfile, changePassword, deleteAccount };
