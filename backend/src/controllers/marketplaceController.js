const { query } = require('../config/database');
const logger = require('../config/logger');

// ============================================================
// MARKETPLACE PROPOSALS CONTROLLER
// Quote/project-based workflow for professional services
// ============================================================

/**
 * Create a new project proposal request
 */
exports.createProposal = async (req, res, next) => {
  try {
    if (req.user.role !== 'customer') {
      return res.status(403).json({ success: false, message: 'Only customers can create proposals' });
    }

    const {
      professional_id, category_id, title, description,
      budget_min, budget_max, currency, estimated_duration_days,
      start_date, attachments
    } = req.body;

    if (!professional_id || !title || !description) {
      return res.status(400).json({
        success: false,
        message: 'professional_id, title, and description are required'
      });
    }

    if (budget_min && budget_max && parseFloat(budget_min) > parseFloat(budget_max)) {
      return res.status(400).json({ success: false, message: 'budget_min cannot exceed budget_max' });
    }

    const result = await query(
      `INSERT INTO marketplace_proposals 
       (customer_id, professional_id, category_id, title, description,
        budget_min, budget_max, currency, estimated_duration_days, start_date, attachments)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       RETURNING *`,
      [
        req.user.id, professional_id, category_id || null,
        title, description, budget_min || null, budget_max || null,
        currency || 'INR', estimated_duration_days || null,
        start_date || null, attachments || []
      ]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * List proposals for customer
 */
exports.listCustomerProposals = async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 20));
    const offset = (page - 1) * limit;
    const status = req.query.status || null;

    let whereClause = 'WHERE mp.customer_id = $1';
    const params = [req.user.id];
    let idx = 2;

    if (status) {
      whereClause += ` AND mp.status = $${idx}`;
      params.push(status);
      idx++;
    }

    params.push(limit, offset);

    const result = await query(
      `SELECT mp.*, u.name as professional_name, c.name as category_name
       FROM marketplace_proposals mp
       LEFT JOIN professionals p ON mp.professional_id = p.id
       LEFT JOIN users u ON p.user_id = u.id
       LEFT JOIN categories c ON mp.category_id = c.id
       ${whereClause}
       ORDER BY mp.created_at DESC
       LIMIT $${idx} OFFSET $${idx + 1}`,
      params
    );

    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
};

/**
 * List proposals for professional
 */
exports.listProfessionalProposals = async (req, res, next) => {
  try {
    const pro = await query(`SELECT id FROM professionals WHERE user_id = $1`, [req.user.id]);
    if (!pro.rows[0]) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 20));
    const offset = (page - 1) * limit;

    const result = await query(
      `SELECT mp.*, u.name as customer_name, c.name as category_name
       FROM marketplace_proposals mp
       LEFT JOIN users u ON mp.customer_id = u.id
       LEFT JOIN categories c ON mp.category_id = c.id
       WHERE mp.professional_id = $1
       ORDER BY mp.created_at DESC
       LIMIT $2 OFFSET $3`,
      [pro.rows[0].id, limit, offset]
    );

    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
};

/**
 * Professional: Submit a quote for a proposal
 */
exports.submitQuote = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { quoted_amount, quote_notes, milestones } = req.body;

    if (!quoted_amount || quoted_amount <= 0) {
      return res.status(400).json({ success: false, message: 'Valid quoted_amount is required' });
    }

    const pro = await query(`SELECT id FROM professionals WHERE user_id = $1`, [req.user.id]);
    if (!pro.rows[0]) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const result = await query(
      `UPDATE marketplace_proposals SET
        quoted_amount = $1,
        quote_notes = $2,
        quoted_at = NOW(),
        milestones = COALESCE($3, milestones),
        status = 'quoted',
        updated_at = NOW()
       WHERE id = $4 AND professional_id = $5 AND status = 'pending'
       RETURNING *`,
      [quoted_amount, quote_notes || null, milestones ? JSON.stringify(milestones) : null, id, pro.rows[0].id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Proposal not found or already quoted' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * Customer: Accept a quote
 */
exports.acceptQuote = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await query(
      `UPDATE marketplace_proposals SET
        status = 'accepted',
        updated_at = NOW()
       WHERE id = $1 AND customer_id = $2 AND status = 'quoted'
       RETURNING *`,
      [id, req.user.id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Quoted proposal not found' });
    }

    res.json({ success: true, data: result.rows[0], message: 'Quote accepted' });
  } catch (err) {
    next(err);
  }
};

/**
 * Update proposal status (transition)
 */
exports.updateStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const allowedTransitions = {
      pending: ['quoted', 'cancelled'],
      quoted: ['accepted', 'negotiating', 'cancelled'],
      negotiating: ['quoted', 'accepted', 'cancelled'],
      accepted: ['in_progress', 'cancelled'],
      in_progress: ['completed', 'cancelled'],
    };

    // Get current proposal
    const current = await query(
      `SELECT * FROM marketplace_proposals WHERE id = $1 AND (customer_id = $2 OR professional_id IN (SELECT id FROM professionals WHERE user_id = $2))`,
      [id, req.user.id]
    );

    if (!current.rows[0]) {
      return res.status(404).json({ success: false, message: 'Proposal not found' });
    }

    const allowed = allowedTransitions[current.rows[0].status] || [];
    if (!allowed.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot transition from '${current.rows[0].status}' to '${status}'. Allowed: ${allowed.join(', ')}`
      });
    }

    const result = await query(
      `UPDATE marketplace_proposals SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
      [status, id]
    );

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * Get proposal details
 */
exports.getProposal = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT mp.*, 
              cu.name as customer_name, cu.phone as customer_phone,
              pu.name as professional_name, pu.phone as professional_phone,
              c.name as category_name
       FROM marketplace_proposals mp
       LEFT JOIN users cu ON mp.customer_id = cu.id
       LEFT JOIN professionals p ON mp.professional_id = p.id
       LEFT JOIN users pu ON p.user_id = pu.id
       LEFT JOIN categories c ON mp.category_id = c.id
       WHERE mp.id = $1 AND (mp.customer_id = $2 OR p.user_id = $2)`,
      [id, req.user.id]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Proposal not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * Add milestone to a proposal (professional)
 */
exports.addMilestone = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { title, description, amount, due_date } = req.body;

    if (!title || !amount) {
      return res.status(400).json({ success: false, message: 'title and amount are required' });
    }

    const pro = await query(`SELECT id FROM professionals WHERE user_id = $1`, [req.user.id]);
    if (!pro.rows[0]) {
      return res.status(404).json({ success: false, message: 'Professional profile not found' });
    }

    const proposal = await query(
      `SELECT * FROM marketplace_proposals WHERE id = $1 AND professional_id = $2 AND status IN ('quoted', 'negotiating', 'accepted', 'in_progress')`,
      [id, pro.rows[0].id]
    );

    if (!proposal.rows[0]) {
      return res.status(404).json({ success: false, message: 'Proposal not found or not in valid state' });
    }

    const currentMilestones = proposal.rows[0].milestones || [];
    const newMilestone = {
      id: `ms_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`,
      title,
      description: description || null,
      amount: parseFloat(amount),
      due_date: due_date || null,
      status: 'pending',
      created_at: new Date().toISOString(),
    };
    currentMilestones.push(newMilestone);

    const updated = await query(
      `UPDATE marketplace_proposals SET milestones = $1::jsonb, updated_at = NOW() WHERE id = $2 RETURNING *`,
      [JSON.stringify(currentMilestones), id]
    );

    res.status(201).json({ success: true, data: { proposal: updated.rows[0], milestone: newMilestone } });
  } catch (err) {
    next(err);
  }
};

/**
 * Update milestone status
 */
exports.updateMilestone = async (req, res, next) => {
  try {
    const { id, milestoneId } = req.params;
    const { status, notes } = req.body;

    const validStatuses = ['pending', 'in_progress', 'completed', 'paid'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: `status must be one of: ${validStatuses.join(', ')}` });
    }

    const proposal = await query(
      `SELECT mp.* FROM marketplace_proposals mp
       LEFT JOIN professionals p ON mp.professional_id = p.id
       WHERE mp.id = $1 AND (mp.customer_id = $2 OR p.user_id = $2)`,
      [id, req.user.id]
    );

    if (!proposal.rows[0]) {
      return res.status(404).json({ success: false, message: 'Proposal not found' });
    }

    const milestones = proposal.rows[0].milestones || [];
    const msIndex = milestones.findIndex((m) => m.id === milestoneId);
    if (msIndex === -1) {
      return res.status(404).json({ success: false, message: 'Milestone not found' });
    }

    milestones[msIndex].status = status;
    if (notes) milestones[msIndex].notes = notes;
    if (status === 'completed') milestones[msIndex].completed_at = new Date().toISOString();
    if (status === 'paid') milestones[msIndex].paid_at = new Date().toISOString();

    const updated = await query(
      `UPDATE marketplace_proposals SET milestones = $1::jsonb, updated_at = NOW() WHERE id = $2 RETURNING *`,
      [JSON.stringify(milestones), id]
    );

    res.json({ success: true, data: { proposal: updated.rows[0], milestone: milestones[msIndex] } });
  } catch (err) {
    next(err);
  }
};

/**
 * Get milestone progress summary
 */
exports.getMilestones = async (req, res, next) => {
  try {
    const { id } = req.params;

    const proposal = await query(
      `SELECT mp.milestones, mp.quoted_amount, mp.status as proposal_status
       FROM marketplace_proposals mp
       LEFT JOIN professionals p ON mp.professional_id = p.id
       WHERE mp.id = $1 AND (mp.customer_id = $2 OR p.user_id = $2)`,
      [id, req.user.id]
    );

    if (!proposal.rows[0]) {
      return res.status(404).json({ success: false, message: 'Proposal not found' });
    }

    const milestones = proposal.rows[0].milestones || [];
    const totalAmount = milestones.reduce((sum, m) => sum + (parseFloat(m.amount) || 0), 0);
    const paidAmount = milestones.filter((m) => m.status === 'paid').reduce((sum, m) => sum + (parseFloat(m.amount) || 0), 0);
    const completedCount = milestones.filter((m) => m.status === 'completed' || m.status === 'paid').length;

    res.json({
      success: true,
      data: {
        milestones,
        summary: {
          total_milestones: milestones.length,
          completed: completedCount,
          pending: milestones.filter((m) => m.status === 'pending').length,
          in_progress: milestones.filter((m) => m.status === 'in_progress').length,
          total_amount: totalAmount,
          paid_amount: paidAmount,
          remaining_amount: totalAmount - paidAmount,
          progress_percent: milestones.length > 0 ? Math.round((completedCount / milestones.length) * 100) : 0,
        },
      },
    });
  } catch (err) {
    next(err);
  }
};