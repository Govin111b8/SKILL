const crypto = require('crypto');
const { query } = require('../config/database');
const { notify } = require('../utils/notifier');
const emailService = require('../services/email');
const logger = require('../config/logger');

const fileComplaint = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { reported_user_id, complaint_type, description } = req.body;

    // Verify reported user exists
    const user = await query('SELECT id, email, name FROM users WHERE id = $1', [reported_user_id]);
    if (user.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Reported user not found.',
      });
    }

    const id = crypto.randomUUID();
    await query(
      `INSERT INTO complaints (id, reporter_id, reported_user_id, complaint_type, description, status, created_at)
       VALUES ($1, $2, $3, $4, $5, 'pending', NOW())`,
      [id, userId, reported_user_id, complaint_type, description]
    );

    // Check complaint count — escalate status based on count
    const complaintCount = await query(
      'SELECT COUNT(*) FROM complaints WHERE reported_user_id = $1',
      [reported_user_id]
    );

    const count = parseInt(complaintCount.rows[0].count);
    if (count >= 3) {
      await query(
        "UPDATE complaints SET status = 'flagged' WHERE reported_user_id = $1 AND status = 'pending'",
        [reported_user_id]
      );
    }

    // Notify the reported user via in-app + email
    try {
      await notify(reported_user_id, {
        type: 'complaint_received',
        title: 'A complaint has been filed about your account',
        body: 'SkillConnect has received a complaint. Our team will review it and notify you of the outcome.',
        related_id: id,
      });

      const reportedUser = user.rows[0];
      if (reportedUser.email) {
        emailService.sendEmail({
          to: reportedUser.email,
          subject: 'SkillConnect: A complaint has been filed against your account',
          text: `Hi ${reportedUser.name},\n\nA complaint has been filed against your SkillConnect account. Our trust & safety team will review it within 48 hours.\n\nIf you believe this complaint is unfair, you may submit an appeal after receiving our decision.\n\nThe SkillConnect Trust & Safety Team`,
        }).catch((err) => logger.error({ err }, 'Failed to send complaint notification email'));
      }
    } catch (err) { logger.error({ err }, 'Failed to notify reported user about complaint'); }

    const result = await query('SELECT * FROM complaints WHERE id = $1', [id]);

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'Complaint filed successfully.',
    });
  } catch (error) {
    next(error);
  }
};


const getComplaints = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const safePage = Math.max(1, parseInt(page) || 1);
    const safeLimit = Math.min(100, Math.max(1, parseInt(limit) || 20));
    const offset = (safePage - 1) * safeLimit;

    const countResult = await query('SELECT COUNT(*) FROM complaints');
    const total = parseInt(countResult.rows[0].count);

    const result = await query(
      `SELECT c.*, 
              reporter.name as reporter_name,
              reported.name as reported_user_name
       FROM complaints c
       JOIN users reporter ON c.reporter_id = reporter.id
       JOIN users reported ON c.reported_user_id = reported.id
       ORDER BY c.created_at DESC
       LIMIT $1 OFFSET $2`,
      [safeLimit, offset]
    );

    res.status(200).json({
      success: true,
      data: result.rows,
      pagination: {
        page: safePage,
        limit: safeLimit,
        total,
        pages: Math.ceil(total / safeLimit),
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { fileComplaint, getComplaints };
