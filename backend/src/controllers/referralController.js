const { pool } = require('../config/database');
const crypto = require('crypto');

// Generate referral code for user
async function generateCode(req, res, next) {
  try {
    const userId = req.user.id;

    // Check if user already has an active code
    const existing = await pool.query(
      'SELECT * FROM referral_codes WHERE user_id = $1 AND is_active = TRUE', [userId]
    );
    if (existing.rows.length > 0) {
      return res.json({ referral_code: existing.rows[0] });
    }

    const code = `SK${crypto.randomBytes(4).toString('hex').toUpperCase()}`;

    const result = await pool.query(
      `INSERT INTO referral_codes (user_id, code, reward_amount) VALUES ($1, $2, 200) RETURNING *`,
      [userId, code]
    );

    // Also store code on user record
    await pool.query('UPDATE users SET referral_code = $1 WHERE id = $2', [code, userId]);

    res.status(201).json({ referral_code: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

// Apply referral code during/after registration
async function applyCode(req, res, next) {
  try {
    const { code } = req.body;
    const referredId = req.user.id;

    // Check if user already used a referral
    const existingRef = await pool.query(
      'SELECT 1 FROM referrals WHERE referred_id = $1', [referredId]
    );
    if (existingRef.rows.length > 0) {
      return res.status(400).json({ error: 'You have already used a referral code' });
    }

    // Validate code
    const codeRes = await pool.query(
      `SELECT * FROM referral_codes WHERE code = $1 AND is_active = TRUE AND (max_uses IS NULL OR uses_count < max_uses)`,
      [code]
    );
    if (codeRes.rows.length === 0) {
      return res.status(404).json({ error: 'Invalid or expired referral code' });
    }

    const referralCode = codeRes.rows[0];

    if (referralCode.user_id === referredId) {
      return res.status(400).json({ error: 'Cannot use your own referral code' });
    }

    // Create referral record
    const result = await pool.query(
      `INSERT INTO referrals (referrer_id, referred_id, referral_code_id, reward_amount) 
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [referralCode.user_id, referredId, referralCode.id, referralCode.reward_amount]
    );

    // Update uses count
    await pool.query(
      'UPDATE referral_codes SET uses_count = uses_count + 1 WHERE id = $1',
      [referralCode.id]
    );

    // Update user's referred_by
    await pool.query('UPDATE users SET referred_by = $1 WHERE id = $2', [referralCode.user_id, referredId]);

    res.json({ referral: result.rows[0], message: 'Referral code applied! Reward will be credited after first completed booking.' });
  } catch (err) {
    next(err);
  }
}

// Complete referral (trigger reward after first booking completes)
async function completeReferral(userId) {
  try {
    const referral = await pool.query(
      `UPDATE referrals SET status = 'completed', rewarded_at = NOW() 
       WHERE referred_id = $1 AND status = 'pending' RETURNING *`,
      [userId]
    );

    if (referral.rows.length > 0) {
      const { referrer_id, reward_amount } = referral.rows[0];

      // Add loyalty points to referrer
      await pool.query(
        `INSERT INTO loyalty_points (user_id, points, reason) VALUES ($1, $2, 'Referral reward')`,
        [referrer_id, Math.round(reward_amount)]
      );

      await pool.query(
        'UPDATE users SET loyalty_balance = loyalty_balance + $1 WHERE id = $2',
        [Math.round(reward_amount), referrer_id]
      );

      // Notify referrer
      await pool.query(
        `INSERT INTO notifications (user_id, type, title, body) 
         VALUES ($1, 'system', '🎉 Referral Reward!', $2)`,
        [referrer_id, `You earned ₹${reward_amount} in loyalty points from your referral!`]
      );
    }
  } catch (err) {
    console.error('Error completing referral:', err);
  }
}

// Get referral stats
async function getReferralStats(req, res, next) {
  try {
    const userId = req.user.id;

    const code = await pool.query(
      'SELECT * FROM referral_codes WHERE user_id = $1 AND is_active = TRUE', [userId]
    );

    const referrals = await pool.query(
      `SELECT r.*, u.name as referred_name FROM referrals r JOIN users u ON r.referred_id = u.id WHERE r.referrer_id = $1 ORDER BY r.created_at DESC`,
      [userId]
    );

    const loyaltyBalance = await pool.query(
      'SELECT loyalty_balance FROM users WHERE id = $1', [userId]
    );

    res.json({
      referral_code: code.rows[0] || null,
      referrals: referrals.rows,
      total_referrals: referrals.rows.length,
      completed_referrals: referrals.rows.filter(r => r.status === 'completed').length,
      loyalty_balance: loyaltyBalance.rows[0]?.loyalty_balance || 0
    });
  } catch (err) {
    next(err);
  }
}

// Get loyalty points history
async function getLoyaltyHistory(req, res, next) {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const result = await pool.query(
      'SELECT * FROM loyalty_points WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
      [userId, limit, offset]
    );

    const balance = await pool.query(
      'SELECT loyalty_balance FROM users WHERE id = $1', [userId]
    );

    res.json({
      points: result.rows,
      balance: balance.rows[0]?.loyalty_balance || 0
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { generateCode, applyCode, completeReferral, getReferralStats, getLoyaltyHistory };
