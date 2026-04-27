const crypto = require('crypto');
const { query } = require('../config/database');

const fileComplaint = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { reported_user_id, complaint_type, description } = req.body;

    // Verify reported user exists
    const user = await query('SELECT id FROM users WHERE id = $1', [reported_user_id]);
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

    // Check complaint count for reported user - if >= 3, mark latest as banned
    const complaintCount = await query(
      'SELECT COUNT(*) FROM complaints WHERE reported_user_id = $1',
      [reported_user_id]
    );

    if (parseInt(complaintCount.rows[0].count) >= 3) {
      await query(
        "UPDATE complaints SET status = 'banned' WHERE reported_user_id = $1 AND status = 'pending'",
        [reported_user_id]
      );
    }

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
    const offset = (parseInt(page) - 1) * parseInt(limit);

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
      [parseInt(limit), offset]
    );

    res.status(200).json({
      success: true,
      data: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { fileComplaint, getComplaints };
