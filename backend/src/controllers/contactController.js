const crypto = require('crypto');
const { query } = require('../config/database');

const createContact = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { professional_id, contact_type, message } = req.body;

    // Verify professional exists
    const prof = await query('SELECT id FROM professionals WHERE id = $1', [professional_id]);
    if (prof.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Professional not found.',
      });
    }

    const id = crypto.randomUUID();
    const result = await query(
      `INSERT INTO contacts (id, customer_id, professional_id, contact_type, message, status, created_at)
       VALUES ($1, $2, $3, $4, $5, 'pending', NOW())
       RETURNING *`,
      [id, userId, professional_id, contact_type, message]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'Contact request created successfully.',
    });
  } catch (error) {
    next(error);
  }
};

const getContacts = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const role = req.user.role;
    const { page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let contactQuery;
    let countQuery;
    const params = [userId, parseInt(limit), offset];

    if (role === 'professional') {
      // Get professional id first
      const profResult = await query(
        'SELECT id FROM professionals WHERE user_id = $1',
        [userId]
      );
      if (profResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Professional profile not found.',
        });
      }
      const professionalId = profResult.rows[0].id;
      params[0] = professionalId;

      countQuery = 'SELECT COUNT(*) FROM contacts WHERE professional_id = $1';
      contactQuery = `
        SELECT c.*, u.name as customer_name, u.email as customer_email
        FROM contacts c
        JOIN users u ON c.customer_id = u.id
        WHERE c.professional_id = $1
        ORDER BY c.created_at DESC
        LIMIT $2 OFFSET $3
      `;
    } else {
      countQuery = 'SELECT COUNT(*) FROM contacts WHERE customer_id = $1';
      contactQuery = `
        SELECT c.*, u.name as professional_name
        FROM contacts c
        JOIN professionals p ON c.professional_id = p.id
        JOIN users u ON p.user_id = u.id
        WHERE c.customer_id = $1
        ORDER BY c.created_at DESC
        LIMIT $2 OFFSET $3
      `;
    }

    const countResult = await query(countQuery, [params[0]]);
    const total = parseInt(countResult.rows[0].count);

    const result = await query(contactQuery, params);

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

const updateContactStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const { status } = req.body;

    // Verify ownership (professional only)
    const profResult = await query(
      'SELECT id FROM professionals WHERE user_id = $1',
      [userId]
    );
    if (profResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Only professionals can update contact status.',
      });
    }

    const professionalId = profResult.rows[0].id;
    const contact = await query(
      'SELECT id FROM contacts WHERE id = $1 AND professional_id = $2',
      [id, professionalId]
    );
    if (contact.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contact not found.',
      });
    }

    const result = await query(
      `UPDATE contacts SET status = $1 WHERE id = $2 RETURNING *`,
      [status, id]
    );

    res.status(200).json({
      success: true,
      data: result.rows[0],
      message: 'Contact status updated successfully.',
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { createContact, getContacts, updateContactStatus };
