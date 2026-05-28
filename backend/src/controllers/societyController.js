/**
 * Society & B2B Controller
 *
 * Handles housing societies, corporate clients, bulk service requests, and B2B enquiries.
 *
 * Endpoints:
 *   POST   /api/societies                         — create society (admin)
 *   GET    /api/societies                         — list societies
 *   GET    /api/societies/:id                     — get society details
 *   PUT    /api/societies/:id/verify              — verify society (admin)
 *   POST   /api/societies/:id/members             — add member to society
 *
 *   POST   /api/societies/:id/requests            — post service request (society admin)
 *   GET    /api/societies/requests                — list open requests (professionals browse)
 *   GET    /api/societies/:id/requests            — society's own requests
 *   PUT    /api/societies/requests/:rid/status    — update request status
 *
 *   POST   /api/societies/requests/:rid/bids      — professional submits bid
 *   GET    /api/societies/requests/:rid/bids      — list bids (society admin / request owner)
 *   PUT    /api/societies/bids/:bid_id/award      — award bid to professional
 *
 *   POST   /api/societies/b2b-enquiry             — submit B2B enquiry (public)
 *   GET    /api/societies/b2b-enquiries           — list B2B enquiries (admin)
 *   PUT    /api/societies/b2b-enquiries/:id       — update enquiry status (admin)
 */

const { pool } = require('../config/database');
const logger = require('../config/logger');

// ─── Societies ────────────────────────────────────────────────────────────────

async function createSociety(req, res, next) {
  try {
    const { name, type = 'housing', address, city, pincode, total_units, contact_name, contact_phone, contact_email, gstin } = req.body;

    if (!name || !address || !city || !contact_name || !contact_phone) {
      return res.status(400).json({ error: 'name, address, city, contact_name, and contact_phone are required' });
    }

    const result = await pool.query(
      `INSERT INTO societies (name, type, address, city, pincode, total_units, contact_name, contact_phone, contact_email, gstin, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
       RETURNING *`,
      [name, type, address, city, pincode || null, total_units || null, contact_name, contact_phone, contact_email || null, gstin || null, req.user.id]
    );

    logger.info({ societyId: result.rows[0].id }, 'Society created');
    res.status(201).json({ success: true, society: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function listSocieties(req, res, next) {
  try {
    const { city, type, status = 'active', page = 1, limit = 20 } = req.query;
    const offset = (Math.max(1, parseInt(page, 10)) - 1) * Math.min(100, parseInt(limit, 10));

    const params = [];
    const conditions = [];

    if (city) { params.push(`%${city}%`); conditions.push(`s.city ILIKE $${params.length}`); }
    if (type) { params.push(type); conditions.push(`s.type = $${params.length}`); }
    if (status) { params.push(status); conditions.push(`s.status = $${params.length}`); }

    const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    params.push(Math.min(100, parseInt(limit, 10)), offset);
    const result = await pool.query(
      `SELECT s.*, COUNT(sm.id) AS member_count
       FROM societies s
       LEFT JOIN society_members sm ON sm.society_id = s.id
       ${where}
       GROUP BY s.id
       ORDER BY s.created_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    res.json({ success: true, societies: result.rows });
  } catch (err) {
    next(err);
  }
}

async function getSociety(req, res, next) {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT s.*,
              (SELECT COUNT(*) FROM society_members sm WHERE sm.society_id = s.id) AS member_count,
              (SELECT COUNT(*) FROM society_service_requests r WHERE r.society_id = s.id AND r.status = 'open') AS open_requests
       FROM societies s WHERE s.id = $1`,
      [id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Society not found' });
    res.json({ success: true, society: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function verifySociety(req, res, next) {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `UPDATE societies SET status = 'active', verified_at = NOW(), verified_by = $2, updated_at = NOW()
       WHERE id = $1 AND status = 'pending' RETURNING *`,
      [id, req.user.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Society not found or already verified' });
    res.json({ success: true, society: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function addSocietyMember(req, res, next) {
  try {
    const { id: society_id } = req.params;
    const { user_id, role = 'resident', unit_number } = req.body;

    if (!user_id) return res.status(400).json({ error: 'user_id is required' });

    const result = await pool.query(
      `INSERT INTO society_members (society_id, user_id, role, unit_number)
       VALUES ($1,$2,$3,$4)
       ON CONFLICT (society_id, user_id) DO UPDATE SET role = EXCLUDED.role, unit_number = EXCLUDED.unit_number
       RETURNING *`,
      [society_id, user_id, role, unit_number || null]
    );
    res.status(201).json({ success: true, member: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

// ─── Service Requests ─────────────────────────────────────────────────────────

async function createServiceRequest(req, res, next) {
  try {
    const { id: society_id } = req.params;
    const { category_id, title, description, preferred_date, preferred_time, units_covered, frequency, budget_range } = req.body;

    if (!title || !description) {
      return res.status(400).json({ error: 'title and description are required' });
    }

    // Validate society exists and user has admin rights (member with admin/manager role or platform admin)
    const memberRes = await pool.query(
      `SELECT role FROM society_members WHERE society_id = $1 AND user_id = $2`,
      [society_id, req.user.id]
    );
    const isAdmin = req.user.role === 'admin';
    const isSocietyAdmin = memberRes.rows.length > 0 && ['admin', 'manager'].includes(memberRes.rows[0].role);

    if (!isAdmin && !isSocietyAdmin) {
      return res.status(403).json({ error: 'Only society admins or platform admins can post service requests' });
    }

    const result = await pool.query(
      `INSERT INTO society_service_requests
         (society_id, category_id, title, description, preferred_date, preferred_time, units_covered, frequency, budget_range, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
       RETURNING *`,
      [society_id, category_id || null, title, description, preferred_date || null, preferred_time || null,
       units_covered || null, frequency || 'one_time', budget_range || null, req.user.id]
    );

    logger.info({ requestId: result.rows[0].id, society_id }, 'Society service request created');
    res.status(201).json({ success: true, request: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function listOpenRequests(req, res, next) {
  try {
    const { city, category_id, page = 1, limit = 20 } = req.query;
    const offset = (Math.max(1, parseInt(page, 10)) - 1) * Math.min(100, parseInt(limit, 10));

    const params = [];
    const conditions = [`r.status = 'open'`];

    if (city) { params.push(`%${city}%`); conditions.push(`s.city ILIKE $${params.length}`); }
    if (category_id) { params.push(category_id); conditions.push(`r.category_id = $${params.length}`); }

    params.push(Math.min(100, parseInt(limit, 10)), offset);

    const result = await pool.query(
      `SELECT r.*, s.name AS society_name, s.city, s.type AS society_type, c.name AS category_name,
              (SELECT COUNT(*) FROM society_bids b WHERE b.request_id = r.id) AS bid_count
       FROM society_service_requests r
       JOIN societies s ON s.id = r.society_id
       LEFT JOIN categories c ON c.id = r.category_id
       WHERE ${conditions.join(' AND ')}
       ORDER BY r.created_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    res.json({ success: true, requests: result.rows });
  } catch (err) {
    next(err);
  }
}

async function getSocietyRequests(req, res, next) {
  try {
    const { id: society_id } = req.params;
    const { status } = req.query;

    const params = [society_id];
    let statusClause = '';
    if (status) { params.push(status); statusClause = `AND r.status = $${params.length}`; }

    const result = await pool.query(
      `SELECT r.*, c.name AS category_name,
              (SELECT COUNT(*) FROM society_bids b WHERE b.request_id = r.id) AS bid_count
       FROM society_service_requests r
       LEFT JOIN categories c ON c.id = r.category_id
       WHERE r.society_id = $1 ${statusClause}
       ORDER BY r.created_at DESC`,
      params
    );

    res.json({ success: true, requests: result.rows });
  } catch (err) {
    next(err);
  }
}

// ─── Bids ─────────────────────────────────────────────────────────────────────

async function submitBid(req, res, next) {
  try {
    const { rid: request_id } = req.params;
    const { amount, per_unit_amount, proposal, timeline_days } = req.body;

    if (!amount || !proposal) {
      return res.status(400).json({ error: 'amount and proposal are required' });
    }

    const proRes = await pool.query('SELECT id FROM professionals WHERE user_id = $1', [req.user.id]);
    if (proRes.rows.length === 0) {
      return res.status(403).json({ error: 'Only professionals can submit bids' });
    }
    const professional_id = proRes.rows[0].id;

    const result = await pool.query(
      `INSERT INTO society_bids (request_id, professional_id, amount, per_unit_amount, proposal, timeline_days)
       VALUES ($1,$2,$3,$4,$5,$6)
       ON CONFLICT (request_id, professional_id) DO UPDATE
         SET amount = EXCLUDED.amount, per_unit_amount = EXCLUDED.per_unit_amount,
             proposal = EXCLUDED.proposal, timeline_days = EXCLUDED.timeline_days,
             updated_at = NOW()
       RETURNING *`,
      [request_id, professional_id, amount, per_unit_amount || null, proposal, timeline_days || null]
    );

    res.status(201).json({ success: true, bid: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

async function listBids(req, res, next) {
  try {
    const { rid: request_id } = req.params;

    const result = await pool.query(
      `SELECT b.*, u.name AS pro_name, u.avatar_url AS pro_avatar,
              p.city AS pro_city, p.rating_avg, p.review_count
       FROM society_bids b
       JOIN professionals p ON p.id = b.professional_id
       JOIN users u ON u.id = p.user_id
       WHERE b.request_id = $1
       ORDER BY b.amount ASC, b.created_at ASC`,
      [request_id]
    );

    res.json({ success: true, bids: result.rows });
  } catch (err) {
    next(err);
  }
}

async function awardBid(req, res, next) {
  try {
    const { bid_id } = req.params;

    const bidRes = await pool.query(
      `SELECT b.*, r.society_id, r.created_by
       FROM society_bids b
       JOIN society_service_requests r ON r.id = b.request_id
       WHERE b.id = $1`,
      [bid_id]
    );
    if (bidRes.rows.length === 0) return res.status(404).json({ error: 'Bid not found' });

    const bid = bidRes.rows[0];

    // Authorise: platform admin or society request creator
    const memberRes = await pool.query(
      `SELECT role FROM society_members WHERE society_id = $1 AND user_id = $2`,
      [bid.society_id, req.user.id]
    );
    const isAdmin = req.user.role === 'admin';
    const isSocietyAdmin = memberRes.rows.length > 0 && ['admin', 'manager'].includes(memberRes.rows[0].role);
    const isCreator = bid.created_by === req.user.id;

    if (!isAdmin && !isSocietyAdmin && !isCreator) {
      return res.status(403).json({ error: 'Not authorised to award this bid' });
    }

    // Update bid and request in a transaction
    await pool.query('BEGIN');
    await pool.query(
      `UPDATE society_bids SET status = 'awarded', updated_at = NOW() WHERE id = $1`,
      [bid_id]
    );
    await pool.query(
      `UPDATE society_bids SET status = 'rejected', updated_at = NOW()
       WHERE request_id = $1 AND id != $2 AND status = 'pending'`,
      [bid.request_id, bid_id]
    );
    const updated = await pool.query(
      `UPDATE society_service_requests
       SET status = 'awarded', awarded_to = $2, awarded_at = NOW(), updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [bid.request_id, bid.professional_id]
    );
    await pool.query('COMMIT');

    logger.info({ bidId: bid_id, requestId: bid.request_id }, 'Society bid awarded');
    res.json({ success: true, request: updated.rows[0], awarded_bid: bid_id });
  } catch (err) {
    await pool.query('ROLLBACK').catch(() => {});
    next(err);
  }
}

// ─── B2B Enquiries ────────────────────────────────────────────────────────────

async function submitB2BEnquiry(req, res, next) {
  try {
    const { company_name, contact_name, contact_email, phone, service_type, employee_count, frequency, city, budget, additional_info } = req.body;

    if (!company_name || !contact_name || !contact_email || !phone) {
      return res.status(400).json({ error: 'company_name, contact_name, contact_email, and phone are required' });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(contact_email)) {
      return res.status(400).json({ error: 'Invalid email address' });
    }

    const result = await pool.query(
      `INSERT INTO b2b_enquiries (company_name, contact_name, contact_email, phone, service_type, employee_count, frequency, city, budget, additional_info)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
       RETURNING id, company_name, contact_name, status, created_at`,
      [company_name, contact_name, contact_email, phone, service_type || null, employee_count || null,
       frequency || null, city || null, budget || null, additional_info || null]
    );

    logger.info({ enquiryId: result.rows[0].id, company: company_name }, 'B2B enquiry submitted');
    res.status(201).json({
      success: true,
      message: "Thank you for your enquiry! Our team will contact you within 24 hours.",
      enquiry_id: result.rows[0].id,
    });
  } catch (err) {
    next(err);
  }
}

async function listB2BEnquiries(req, res, next) {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (Math.max(1, parseInt(page, 10)) - 1) * Math.min(100, parseInt(limit, 10));

    const params = [];
    let statusClause = '';
    if (status) { params.push(status); statusClause = `WHERE e.status = $${params.length}`; }

    params.push(Math.min(100, parseInt(limit, 10)), offset);

    const result = await pool.query(
      `SELECT e.*, u.name AS assigned_to_name
       FROM b2b_enquiries e
       LEFT JOIN users u ON u.id = e.assigned_to
       ${statusClause}
       ORDER BY e.created_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    res.json({ success: true, enquiries: result.rows });
  } catch (err) {
    next(err);
  }
}

async function updateB2BEnquiry(req, res, next) {
  try {
    const { id } = req.params;
    const { status, assigned_to, notes } = req.body;

    const validStatuses = ['new', 'contacted', 'converted', 'closed'];
    if (status && !validStatuses.includes(status)) {
      return res.status(400).json({ error: `status must be one of: ${validStatuses.join(', ')}` });
    }

    const result = await pool.query(
      `UPDATE b2b_enquiries
       SET status = COALESCE($2, status),
           assigned_to = COALESCE($3, assigned_to),
           notes = COALESCE($4, notes),
           updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [id, status || null, assigned_to || null, notes || null]
    );

    if (result.rows.length === 0) return res.status(404).json({ error: 'Enquiry not found' });
    res.json({ success: true, enquiry: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createSociety,
  listSocieties,
  getSociety,
  verifySociety,
  addSocietyMember,
  createServiceRequest,
  listOpenRequests,
  getSocietyRequests,
  submitBid,
  listBids,
  awardBid,
  submitB2BEnquiry,
  listB2BEnquiries,
  updateB2BEnquiry,
};
