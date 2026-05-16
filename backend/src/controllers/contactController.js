const crypto = require('crypto');
const { query } = require('../config/database');
const { notify } = require('../utils/notifier');
const smsService = require('../services/sms');
const pushService = require('../services/pushNotification');
const logger = require('../config/logger');

const createContact = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { professional_id, contact_type, message } = req.body;

    // Verify professional exists
    const prof = await query(
      `SELECT p.id, u.id as user_id, u.name, u.phone FROM professionals p
       JOIN users u ON u.id = p.user_id
       WHERE p.id = $1`,
      [professional_id]
    );
    if (prof.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Professional not found.' });
    }
    const profRow = prof.rows[0];

    // Check if customer is blocked by this professional
    const blocked = await query(
      `SELECT id FROM blocked_users
       WHERE blocker_id = $1 AND blocked_id = $2`,
      [profRow.user_id, userId]
    ).catch(() => ({ rows: [] }));
    if (blocked.rows.length > 0) {
      return res.status(403).json({ success: false, message: 'Professional is not accepting contacts at this time.' });
    }

    // PRD §6.7: Customer duplicate contact limit — max 3 contacts per professional in 30 days
    const recentContacts = await query(
      `SELECT COUNT(*) FROM contacts
       WHERE customer_id = $1 AND professional_id = $2
         AND created_at >= NOW() - INTERVAL '30 days'`,
      [userId, professional_id]
    );
    if (parseInt(recentContacts.rows[0].count) >= 3) {
      // Return alternatives
      const similar = await query(
        `SELECT p.id, u.name, u.avatar_url, p.avg_rating, p.trust_index,
                p.subscription_plan
         FROM professionals p
         JOIN users u ON u.id = p.user_id
         JOIN professional_categories pc ON pc.professional_id = p.id
         WHERE pc.category_id IN (
           SELECT category_id FROM professional_categories WHERE professional_id = $1
         )
         AND p.id != $1
         AND u.government_id_verified = TRUE
         ORDER BY p.trust_index DESC NULLS LAST
         LIMIT 5`,
        [professional_id]
      ).catch(() => ({ rows: [] }));

      return res.status(429).json({
        success: false,
        message: "You've recently contacted this professional. Here are similar professionals you might like.",
        similar_professionals: similar.rows,
      });
    }

    const id = crypto.randomUUID();
    const result = await query(
      `INSERT INTO contacts (id, customer_id, professional_id, contact_type, message, status, created_at)
       VALUES ($1, $2, $3, $4, $5, 'pending', NOW())
       RETURNING *`,
      [id, userId, professional_id, contact_type, message]
    );

    // Notify professional of contact/quote request
    try {
      const customerRow = await query('SELECT name FROM users WHERE id = $1', [userId]);
      const customerName = customerRow.rows[0]?.name || 'A customer';

      if (contact_type === 'quote_request') {
        // FCM push notification
        const tokens = await query(
          `SELECT token FROM device_tokens WHERE user_id = $1 AND is_active = TRUE`,
          [profRow.user_id]
        ).catch(() => ({ rows: [] }));
        for (const t of tokens.rows) {
          pushService.sendToDevice(t.token, {
            title: 'New Quote Request',
            body: `${customerName} sent you a quote request`,
          }).catch((err) => logger.error({ err }, 'Failed to send push notification for quote request'));
        }

        // SMS notification
        if (profRow.phone) {
          smsService.send({
            to: profRow.phone,
            message: `SkillConnect: New quote request from ${customerName}. Login to respond: https://app.skillconnect.in`,
          }).catch((err) => logger.error({ err }, 'Failed to send SMS notification for contact request'));
        }
      }

      // In-app notification
      await notify(profRow.user_id, {
        type: 'new_contact',
        title: contact_type === 'quote_request' ? 'New Quote Request' : 'Someone contacted you',
        body: `${customerName} wants to ${contact_type === 'quote_request' ? 'get a quote for' : 'contact you about'} your services`,
        related_id: id,
      });
    } catch (err) { logger.error({ err }, 'Failed to send contact notification'); }

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
