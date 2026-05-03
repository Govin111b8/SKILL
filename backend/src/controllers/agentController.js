const { pool } = require('../config/database');
const crypto = require('crypto');

// Register as agent (any authenticated user can become an agent)
async function becomeAgent(req, res, next) {
  try {
    const userId = req.user.id;
    const { zone } = req.body;

    // Check if already an agent
    const existing = await pool.query(
      'SELECT id FROM agents WHERE user_id = $1', [userId]
    );
    if (existing.rows.length > 0) {
      return res.status(400).json({ error: 'You are already registered as an agent' });
    }

    // Generate unique agent code
    const agentCode = `AG${crypto.randomBytes(4).toString('hex').toUpperCase()}`;

    const result = await pool.query(
      `INSERT INTO agents (user_id, agent_code, zone)
       VALUES ($1, $2, $3) RETURNING *`,
      [userId, agentCode, zone || null]
    );

    // Update user role to agent if they were customer
    await pool.query(
      `UPDATE users SET role = 'agent' WHERE id = $1 AND role = 'customer'`,
      [userId]
    );

    res.status(201).json({ success: true, agent: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

// Get agent profile/dashboard data
async function getAgentDashboard(req, res, next) {
  try {
    const userId = req.user.id;

    const agentRes = await pool.query(
      'SELECT * FROM agents WHERE user_id = $1', [userId]
    );
    if (agentRes.rows.length === 0) {
      return res.status(404).json({ error: 'Agent profile not found' });
    }
    const agent = agentRes.rows[0];

    // Get recent onboarded users
    const onboarded = await pool.query(
      `SELECT aou.*, u.name, u.email, u.role, u.created_at as user_joined
       FROM agent_onboarded_users aou
       JOIN users u ON u.id = aou.user_id
       WHERE aou.agent_id = $1
       ORDER BY aou.created_at DESC LIMIT 20`,
      [agent.id]
    );

    // Get reward summary
    const rewardSummary = await pool.query(
      `SELECT action, COUNT(*) as count, SUM(amount) as total_amount, SUM(points) as total_points
       FROM agent_rewards
       WHERE agent_id = $1
       GROUP BY action`,
      [agent.id]
    );

    // Get pending vs unlocked rewards
    const rewardStatus = await pool.query(
      `SELECT status, COUNT(*) as count, SUM(amount) as total
       FROM agent_rewards WHERE agent_id = $1 GROUP BY status`,
      [agent.id]
    );

    // Get recent wallet transactions
    const transactions = await pool.query(
      `SELECT * FROM agent_wallet_transactions
       WHERE agent_id = $1 ORDER BY created_at DESC LIMIT 10`,
      [agent.id]
    );

    res.json({
      success: true,
      agent,
      onboarded_users: onboarded.rows,
      reward_summary: rewardSummary.rows,
      reward_status: rewardStatus.rows,
      recent_transactions: transactions.rows
    });
  } catch (err) {
    next(err);
  }
}

// Agent onboards a new provider
async function onboardProvider(req, res, next) {
  try {
    const userId = req.user.id;
    const { name, email, password, phone, location, zone } = req.body;

    // Get agent
    const agentRes = await pool.query(
      'SELECT * FROM agents WHERE user_id = $1 AND is_active = TRUE', [userId]
    );
    if (agentRes.rows.length === 0) {
      return res.status(403).json({ error: 'Not an active agent' });
    }
    const agent = agentRes.rows[0];

    // Check KYC requirement
    if (!agent.kyc_verified) {
      return res.status(403).json({ error: 'Agent KYC verification required before onboarding' });
    }

    // Check if email already exists
    const emailCheck = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (emailCheck.rows.length > 0) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    // Hash password
    const bcrypt = require('bcryptjs');
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Create provider user
    const userResult = await pool.query(
      `INSERT INTO users (name, email, password_hash, phone, role, location, onboarded_by_agent)
       VALUES ($1, $2, $3, $4, 'professional', $5, $6) RETURNING id, name, email, role`,
      [name, email, passwordHash, phone, location || zone || agent.zone, agent.id]
    );
    const newUser = userResult.rows[0];

    // Create professional profile
    await pool.query(
      `INSERT INTO professionals (user_id, provider_type) VALUES ($1, 'individual')`,
      [newUser.id]
    );

    // Track onboarding
    await pool.query(
      `INSERT INTO agent_onboarded_users (agent_id, user_id, user_role)
       VALUES ($1, $2, 'professional')`,
      [agent.id, newUser.id]
    );

    // Update agent stats
    await pool.query(
      `UPDATE agents SET providers_onboarded = providers_onboarded + 1, updated_at = NOW()
       WHERE id = $1`,
      [agent.id]
    );

    // Create pending reward
    const rewardConfig = await pool.query(
      `SELECT * FROM reward_config WHERE action = 'provider_onboarded' AND is_active = TRUE`
    );
    if (rewardConfig.rows.length > 0) {
      const rc = rewardConfig.rows[0];
      await pool.query(
        `INSERT INTO agent_rewards (agent_id, action, target_user_id, points, amount, status)
         VALUES ($1, 'provider_onboarded', $2, $3, $4, 'pending')`,
        [agent.id, newUser.id, rc.points, rc.amount]
      );
    }

    res.status(201).json({
      success: true,
      message: 'Provider onboarded successfully',
      user: newUser
    });
  } catch (err) {
    next(err);
  }
}

// Agent onboards a new customer
async function onboardCustomer(req, res, next) {
  try {
    const userId = req.user.id;
    const { name, email, password, phone, location } = req.body;

    // Get agent
    const agentRes = await pool.query(
      'SELECT * FROM agents WHERE user_id = $1 AND is_active = TRUE', [userId]
    );
    if (agentRes.rows.length === 0) {
      return res.status(403).json({ error: 'Not an active agent' });
    }
    const agent = agentRes.rows[0];

    if (!agent.kyc_verified) {
      return res.status(403).json({ error: 'Agent KYC verification required before onboarding' });
    }

    // Check if email already exists
    const emailCheck = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (emailCheck.rows.length > 0) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    const bcrypt = require('bcryptjs');
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const userResult = await pool.query(
      `INSERT INTO users (name, email, password_hash, phone, role, location, onboarded_by_agent)
       VALUES ($1, $2, $3, $4, 'customer', $5, $6) RETURNING id, name, email, role`,
      [name, email, passwordHash, phone, location || agent.zone, agent.id]
    );
    const newUser = userResult.rows[0];

    // Track onboarding
    await pool.query(
      `INSERT INTO agent_onboarded_users (agent_id, user_id, user_role)
       VALUES ($1, $2, 'customer')`,
      [agent.id, newUser.id]
    );

    // Update agent stats
    await pool.query(
      `UPDATE agents SET customers_onboarded = customers_onboarded + 1, updated_at = NOW()
       WHERE id = $1`,
      [agent.id]
    );

    // Create pending reward
    const rewardConfig = await pool.query(
      `SELECT * FROM reward_config WHERE action = 'customer_onboarded' AND is_active = TRUE`
    );
    if (rewardConfig.rows.length > 0) {
      const rc = rewardConfig.rows[0];
      await pool.query(
        `INSERT INTO agent_rewards (agent_id, action, target_user_id, points, amount, status)
         VALUES ($1, 'customer_onboarded', $2, $3, $4, 'pending')`,
        [agent.id, newUser.id, rc.points, rc.amount]
      );
    }

    res.status(201).json({
      success: true,
      message: 'Customer onboarded successfully',
      user: newUser
    });
  } catch (err) {
    next(err);
  }
}

// Unlock pending rewards (called by system/admin when conditions met)
async function unlockReward(req, res, next) {
  try {
    const { reward_id } = req.params;

    const reward = await pool.query(
      'SELECT * FROM agent_rewards WHERE id = $1 AND status = $2',
      [reward_id, 'pending']
    );
    if (reward.rows.length === 0) {
      return res.status(404).json({ error: 'Pending reward not found' });
    }

    const r = reward.rows[0];

    // Update reward status
    await pool.query(
      `UPDATE agent_rewards SET status = 'unlocked', unlocked_at = NOW() WHERE id = $1`,
      [reward_id]
    );

    // Credit wallet
    const agentRes = await pool.query('SELECT * FROM agents WHERE id = $1', [r.agent_id]);
    const agent = agentRes.rows[0];
    const newBalance = parseFloat(agent.wallet_balance) + parseFloat(r.amount);

    await pool.query(
      `UPDATE agents SET wallet_balance = $1, total_earned = total_earned + $2, updated_at = NOW()
       WHERE id = $3`,
      [newBalance, r.amount, r.agent_id]
    );

    // Log wallet transaction
    await pool.query(
      `INSERT INTO agent_wallet_transactions (agent_id, type, amount, balance_after, description, reference_id)
       VALUES ($1, 'credit', $2, $3, $4, $5)`,
      [r.agent_id, r.amount, newBalance, `Reward: ${r.action}`, reward_id]
    );

    res.json({ success: true, message: 'Reward unlocked and credited to wallet' });
  } catch (err) {
    next(err);
  }
}

// Get agent wallet & transactions
async function getWallet(req, res, next) {
  try {
    const userId = req.user.id;

    const agentRes = await pool.query(
      'SELECT id, wallet_balance, total_earned FROM agents WHERE user_id = $1', [userId]
    );
    if (agentRes.rows.length === 0) {
      return res.status(404).json({ error: 'Agent not found' });
    }
    const agent = agentRes.rows[0];

    const transactions = await pool.query(
      `SELECT * FROM agent_wallet_transactions
       WHERE agent_id = $1 ORDER BY created_at DESC LIMIT 50`,
      [agent.id]
    );

    res.json({
      success: true,
      wallet: {
        balance: agent.wallet_balance,
        total_earned: agent.total_earned
      },
      transactions: transactions.rows
    });
  } catch (err) {
    next(err);
  }
}

// Get reward config (public - shows what agents can earn)
async function getRewardConfig(req, res, next) {
  try {
    const result = await pool.query(
      'SELECT action, points, amount, description FROM reward_config WHERE is_active = TRUE ORDER BY amount DESC'
    );
    res.json({ success: true, rewards: result.rows });
  } catch (err) {
    next(err);
  }
}

// Get agent leaderboard
async function getLeaderboard(req, res, next) {
  try {
    const { zone } = req.query;

    let query = `
      SELECT a.agent_code, a.zone, a.level, a.providers_onboarded, a.customers_onboarded,
             a.total_earned, u.name, u.avatar_url
      FROM agents a
      JOIN users u ON u.id = a.user_id
      WHERE a.is_active = TRUE
    `;
    const params = [];

    if (zone) {
      params.push(zone);
      query += ` AND a.zone = $${params.length}`;
    }

    query += ` ORDER BY a.total_earned DESC LIMIT 50`;

    const result = await pool.query(query, params);
    res.json({ success: true, leaderboard: result.rows });
  } catch (err) {
    next(err);
  }
}

// Get all zones
async function getZones(req, res, next) {
  try {
    const result = await pool.query(
      'SELECT * FROM zones WHERE is_active = TRUE ORDER BY phase, name'
    );
    res.json({ success: true, zones: result.rows });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  becomeAgent,
  getAgentDashboard,
  onboardProvider,
  onboardCustomer,
  unlockReward,
  getWallet,
  getRewardConfig,
  getLeaderboard,
  getZones
};
