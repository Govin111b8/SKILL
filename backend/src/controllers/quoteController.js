/**
 * Quote Request Controller
 *
 * Handles the quote_request service mode:
 *   - Customers submit requirements with photos, area, and budget
 *   - Up to 3 nearby professionals bid with their price + message
 *   - Customer compares bids and accepts one (20% advance via escrow)
 *   - Milestone-based payment release (reuses marketplace milestones)
 */

const { query } = require('../config/database');
const { sendEmail } = require('../services/email');
const { sendSMS } = require('../services/sms');
const { sendWhatsApp } = require('../services/whatsapp');
const logger = require('../config/logger');

// ── Helpers ─────────────────────────────────────────────────────────────────

function validateStatus(status, allowed) {
  if (!allowed.includes(status)) {
    const err = new Error(`Invalid status transition to '${status}'.`);
    err.statusCode = 400;
    throw err;
  }
}

// ── Customer: submit a quote request ────────────────────────────────────────

const createQuoteRequest = async (req, res, next) => {
  try {
    const customerId = req.user.id;
    const {
      category_id, title, description,
      area_sqft, budget_min, budget_max,
      location_text, latitude, longitude, pincode,
      preferred_date, preferred_time,
      photos,
    } = req.body;

    if (!category_id) return res.status(400).json({ success: false, message: 'category_id is required.' });
    if (!title || !title.trim()) return res.status(400).json({ success: false, message: 'title is required.' });
    if (!description || !description.trim()) return res.status(400).json({ success: false, message: 'description is required.' });

    // Verify category supports quote_request mode
    const catRes = await query(
      `SELECT id, name, service_mode FROM categories WHERE id = $1`,
      [category_id]
    );
    if (catRes.rows.length === 0) return res.status(404).json({ success: false, message: 'Category not found.' });
    const cat = catRes.rows[0];
    if (cat.service_mode !== 'quote_request') {
      return res.status(400).json({
        success: false,
        message: `Category '${cat.name}' uses '${cat.service_mode}' mode, not quote_request.`,
      });
    }

    const result = await query(
      `INSERT INTO quote_requests
         (customer_id, category_id, title, description, area_sqft,
          budget_min, budget_max, location_text, latitude, longitude, pincode,
          preferred_date, preferred_time, photos)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
       RETURNING *`,
      [
        customerId, category_id, title.trim(), description.trim(),
        area_sqft || null, budget_min || null, budget_max || null,
        location_text || null, latitude || null, longitude || null, pincode || null,
        preferred_date || null, preferred_time || null,
        photos && photos.length ? photos : null,
      ]
    );

    const qr = result.rows[0];

    // Notify nearby professionals via push / WhatsApp (fire-and-forget)
    notifyNearbyProfessionals(qr, cat.name).catch((err) =>
      logger.error({ err, quoteId: qr.id }, 'Failed to notify pros for quote request')
    );

    res.status(201).json({ success: true, data: qr, message: 'Quote request submitted. Professionals will respond within 24 hours.' });
  } catch (error) {
    next(error);
  }
};

// ── Customer: list own quote requests ────────────────────────────────────────

const listMyQuoteRequests = async (req, res, next) => {
  try {
    const customerId = req.user.id;
    const status = req.query.status || null;
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit) || 10));
    const offset = (page - 1) * limit;

    const conditions = ['qr.customer_id = $1'];
    const values = [customerId];
    let idx = 2;

    if (status) {
      conditions.push(`qr.status = $${idx}`);
      values.push(status);
      idx++;
    }

    const whereClause = `WHERE ${conditions.join(' AND ')}`;

    const [countRes, dataRes] = await Promise.all([
      query(`SELECT COUNT(*)::int AS total FROM quote_requests qr ${whereClause}`, values),
      query(
        `SELECT qr.*, c.name AS category_name, c.icon AS category_icon,
                COUNT(qb.id)::int AS bid_count
         FROM quote_requests qr
         LEFT JOIN categories c ON qr.category_id = c.id
         LEFT JOIN quote_bids qb ON qb.quote_request_id = qr.id
         ${whereClause}
         GROUP BY qr.id, c.name, c.icon
         ORDER BY qr.created_at DESC
         LIMIT $${idx} OFFSET $${idx + 1}`,
        [...values, limit, offset]
      ),
    ]);

    res.json({
      success: true,
      data: dataRes.rows,
      pagination: { page, limit, total_count: countRes.rows[0].total, total_pages: Math.ceil(countRes.rows[0].total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

// ── Customer/Pro: get single quote request with bids ─────────────────────────

const getQuoteRequest = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const qrRes = await query(
      `SELECT qr.*, c.name AS category_name, c.icon AS category_icon,
              u.full_name AS customer_name, u.phone AS customer_phone
       FROM quote_requests qr
       LEFT JOIN categories c ON qr.category_id = c.id
       LEFT JOIN users u ON qr.customer_id = u.id
       WHERE qr.id = $1`,
      [id]
    );
    if (qrRes.rows.length === 0) return res.status(404).json({ success: false, message: 'Quote request not found.' });

    const qr = qrRes.rows[0];
    const isOwner = qr.customer_id === userId;

    // Fetch bids — hide other pros' contact info from customer until accepted
    const bidsRes = await query(
      `SELECT qb.*, p.business_name, p.avg_rating, p.total_reviews,
              p.trust_level, p.city,
              u.full_name AS pro_name, u.profile_photo,
              u.phone AS pro_phone
       FROM quote_bids qb
       JOIN professionals p ON qb.professional_id = p.id
       JOIN users u ON p.user_id = u.id
       WHERE qb.quote_request_id = $1
       ORDER BY qb.amount ASC`,
      [id]
    );

    const bids = bidsRes.rows.map((b) => {
      // Hide phone until bid is accepted (GDPR-style privacy)
      if (!isOwner || (qr.accepted_bid_id && qr.accepted_bid_id !== b.id)) {
        delete b.pro_phone;
      }
      return b;
    });

    res.json({ success: true, data: { ...qr, bids } });
  } catch (error) {
    next(error);
  }
};

// ── Professional: submit a bid on a quote request ────────────────────────────

const submitBid = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id: quoteRequestId } = req.params;
    const { amount, includes_materials, estimated_days, message, site_visit_date } = req.body;

    if (!amount || Number(amount) <= 0) return res.status(400).json({ success: false, message: 'amount must be a positive number.' });

    // Get professional profile
    const profRes = await query('SELECT id, city FROM professionals WHERE user_id = $1', [userId]);
    if (profRes.rows.length === 0) return res.status(403).json({ success: false, message: 'Professional profile required to bid.' });
    const professional_id = profRes.rows[0].id;

    // Validate quote request is open
    const qrRes = await query('SELECT id, status, max_bids, customer_id FROM quote_requests WHERE id = $1', [quoteRequestId]);
    if (qrRes.rows.length === 0) return res.status(404).json({ success: false, message: 'Quote request not found.' });
    const qr = qrRes.rows[0];
    if (!['open', 'bidding'].includes(qr.status)) {
      return res.status(400).json({ success: false, message: `Quote request is '${qr.status}' and no longer accepting bids.` });
    }

    // Check max bids
    const bidCount = await query('SELECT COUNT(*)::int AS cnt FROM quote_bids WHERE quote_request_id = $1', [quoteRequestId]);
    if (bidCount.rows[0].cnt >= qr.max_bids) {
      return res.status(400).json({ success: false, message: `Maximum bids (${qr.max_bids}) reached for this request.` });
    }

    // Upsert bid (pro can update their bid while still submitted)
    const bidRes = await query(
      `INSERT INTO quote_bids
         (quote_request_id, professional_id, amount, includes_materials, estimated_days, message, site_visit_date)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       ON CONFLICT (quote_request_id, professional_id) DO UPDATE SET
         amount = EXCLUDED.amount,
         includes_materials = EXCLUDED.includes_materials,
         estimated_days = EXCLUDED.estimated_days,
         message = EXCLUDED.message,
         site_visit_date = EXCLUDED.site_visit_date,
         updated_at = NOW()
       RETURNING *`,
      [quoteRequestId, professional_id, amount, includes_materials || false, estimated_days || null, message || null, site_visit_date || null]
    );

    // Move request to 'bidding' state if still 'open'
    if (qr.status === 'open') {
      await query(`UPDATE quote_requests SET status = 'bidding', updated_at = NOW() WHERE id = $1`, [quoteRequestId]);
    }

    // Notify customer (fire-and-forget)
    notifyCustomerNewBid(qr.customer_id, quoteRequestId, profRes.rows[0]).catch((err) =>
      logger.error({ err, quoteId: quoteRequestId }, 'Failed to notify customer of new bid')
    );

    res.status(201).json({ success: true, data: bidRes.rows[0], message: 'Bid submitted successfully.' });
  } catch (error) {
    next(error);
  }
};

// ── Customer: accept a bid ───────────────────────────────────────────────────

const acceptBid = async (req, res, next) => {
  try {
    const customerId = req.user.id;
    const { id: quoteRequestId, bidId } = req.params;

    // Verify ownership
    const qrRes = await query('SELECT * FROM quote_requests WHERE id = $1 AND customer_id = $2', [quoteRequestId, customerId]);
    if (qrRes.rows.length === 0) return res.status(404).json({ success: false, message: 'Quote request not found or not yours.' });
    const qr = qrRes.rows[0];

    if (!['open', 'bidding'].includes(qr.status)) {
      return res.status(400).json({ success: false, message: `Cannot accept bid — request is '${qr.status}'.` });
    }

    // Verify bid exists
    const bidRes = await query('SELECT * FROM quote_bids WHERE id = $1 AND quote_request_id = $2', [bidId, quoteRequestId]);
    if (bidRes.rows.length === 0) return res.status(404).json({ success: false, message: 'Bid not found.' });

    // Accept bid, reject others
    await query(
      `UPDATE quote_bids SET status = 'rejected', updated_at = NOW()
       WHERE quote_request_id = $1 AND id != $2 AND status = 'submitted'`,
      [quoteRequestId, bidId]
    );
    await query(`UPDATE quote_bids SET status = 'accepted', updated_at = NOW() WHERE id = $1`, [bidId]);
    await query(
      `UPDATE quote_requests SET status = 'accepted', accepted_bid_id = $1, updated_at = NOW() WHERE id = $2`,
      [bidId, quoteRequestId]
    );

    res.json({ success: true, message: 'Bid accepted. Proceed to pay 20% advance to confirm booking.' });
  } catch (error) {
    next(error);
  }
};

// ── Professional: list open quote requests near their area ───────────────────

const listOpenQuoteRequests = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const profRes = await query('SELECT id, city FROM professionals WHERE user_id = $1', [userId]);
    if (profRes.rows.length === 0) return res.status(403).json({ success: false, message: 'Professional profile required.' });
    const professional_id = profRes.rows[0].id;

    const { category_id, pincode, page: rawPage, limit: rawLimit } = req.query;
    const page = Math.max(1, parseInt(rawPage) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(rawLimit) || 10));
    const offset = (page - 1) * limit;

    const conditions = [`qr.status IN ('open','bidding')`, `qr.expires_at > NOW()`];
    const values = [];
    let idx = 1;

    if (category_id) {
      conditions.push(`qr.category_id = $${idx++}`);
      values.push(category_id);
    }
    if (pincode) {
      conditions.push(`qr.pincode = $${idx++}`);
      values.push(pincode);
    }

    const whereClause = `WHERE ${conditions.join(' AND ')}`;

    const [countRes, dataRes] = await Promise.all([
      query(`SELECT COUNT(*)::int AS total FROM quote_requests qr ${whereClause}`, values),
      query(
        `SELECT qr.id, qr.title, qr.description, qr.category_id, qr.area_sqft,
                qr.budget_min, qr.budget_max, qr.location_text, qr.pincode,
                qr.preferred_date, qr.preferred_time, qr.status, qr.expires_at, qr.created_at,
                c.name AS category_name,
                COUNT(qb.id)::int AS bid_count,
                EXISTS(SELECT 1 FROM quote_bids WHERE quote_request_id=qr.id AND professional_id=$${idx}) AS already_bid
         FROM quote_requests qr
         LEFT JOIN categories c ON qr.category_id = c.id
         LEFT JOIN quote_bids qb ON qb.quote_request_id = qr.id
         ${whereClause}
         GROUP BY qr.id, c.name
         ORDER BY qr.created_at DESC
         LIMIT $${idx + 1} OFFSET $${idx + 2}`,
        [...values, professional_id, limit, offset]
      ),
    ]);

    res.json({
      success: true,
      data: dataRes.rows,
      pagination: { page, limit, total_count: countRes.rows[0].total, total_pages: Math.ceil(countRes.rows[0].total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

// ── Internal: notify nearby professionals of new quote request ───────────────

async function notifyNearbyProfessionals(quoteRequest, categoryName) {
  // Find professionals who serve this pincode / category
  const profRes = await query(
    `SELECT p.id, u.phone, u.full_name, u.email
     FROM professionals p
     JOIN users u ON p.user_id = u.id
     JOIN professional_categories pc ON pc.professional_id = p.id
     WHERE pc.category_id = $1
       AND p.is_verified = true
     LIMIT 20`,
    [quoteRequest.category_id]
  );

  for (const pro of profRes.rows) {
    const msg = `New ${categoryName} quote request near ${quoteRequest.pincode || 'your area'}. Budget: ₹${quoteRequest.budget_min || 'Open'}–₹${quoteRequest.budget_max || 'Open'}. View on SkillConnect app.`;
    try {
      await sendWhatsApp({ to: pro.phone, message: msg });
    } catch (err) {
      // WhatsApp optional — fall back gracefully
      logger.warn({ err, proId: pro.id }, 'WhatsApp notify failed');
    }
  }
}

async function notifyCustomerNewBid(customerId, quoteRequestId, professional) {
  const userRes = await query('SELECT phone, email, full_name FROM users WHERE id = $1', [customerId]);
  if (!userRes.rows.length) return;
  const customer = userRes.rows[0];

  const msg = `A professional has placed a bid on your quote request. Log in to SkillConnect to compare bids.`;
  await sendWhatsApp({ to: customer.phone, message: msg }).catch(() => {});
  await sendEmail({
    to: customer.email,
    subject: 'New bid on your SkillConnect quote request',
    html: `<p>Hi ${customer.full_name},</p><p>A new bid has been submitted for your quote request. <a href="${process.env.APP_URL || 'https://skillconnect.in'}/quotes/${quoteRequestId}">View bids</a></p>`,
  }).catch(() => {});
}

module.exports = {
  createQuoteRequest,
  listMyQuoteRequests,
  getQuoteRequest,
  submitBid,
  acceptBid,
  listOpenQuoteRequests,
};
