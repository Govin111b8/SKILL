/**
 * Admin Controller — Platform administration endpoints
 * Manages users, KYC queue, disputes, analytics, and categories.
 */

const { pool } = require('../config/database');
const logger = require('../config/logger');

/**
 * Log an admin action for audit trail
 */
async function auditLog(adminId, action, targetType, targetId, details = {}, ip = null) {
  await pool.query(
    `INSERT INTO admin_audit_log (admin_id, action, target_type, target_id, details, ip_address)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [adminId, action, targetType, targetId, JSON.stringify(details), ip]
  );
}

// ============================================================
// DASHBOARD & ANALYTICS
// ============================================================

exports.getDashboard = async (req, res, next) => {
  try {
    const stats = await pool.query(`
      SELECT
        (SELECT COUNT(*) FROM users) as total_users,
        (SELECT COUNT(*) FROM users WHERE created_at >= NOW() - INTERVAL '7 days') as new_users_7d,
        (SELECT COUNT(*) FROM professionals) as total_professionals,
        (SELECT COUNT(*) FROM bookings) as total_bookings,
        (SELECT COUNT(*) FROM bookings WHERE status = 'in_progress') as active_bookings,
        (SELECT COUNT(*) FROM bookings WHERE created_at >= NOW() - INTERVAL '7 days') as new_bookings_7d,
        (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE status = 'released') as total_revenue,
        (SELECT COALESCE(SUM(platform_fee), 0) FROM payments WHERE status = 'released') as platform_earnings,
        (SELECT COUNT(*) FROM disputes WHERE status = 'open') as open_disputes,
        (SELECT COUNT(*) FROM verifications WHERE status = 'pending') as pending_kyc,
        (SELECT COUNT(*) FROM complaints WHERE status = 'pending') as pending_complaints
    `);

    res.json({ success: true, data: stats.rows[0] });
  } catch (err) { next(err); }
};

exports.getAnalytics = async (req, res, next) => {
  try {
    const { period = '30d' } = req.query;
    const intervalMap = { '7d': '7 days', '90d': '90 days' };
    const interval = intervalMap[period] || '30 days';

    const [revenue, bookings, userGrowth] = await Promise.all([
      pool.query(`
        SELECT DATE_TRUNC('day', created_at) as date, 
               SUM(amount) as total, SUM(platform_fee) as fees, COUNT(*) as count
        FROM payments WHERE status IN ('released', 'held_in_escrow') AND created_at >= NOW() - $1::interval
        GROUP BY DATE_TRUNC('day', created_at) ORDER BY date
      `, [interval]),
      pool.query(`
        SELECT DATE_TRUNC('day', created_at) as date, status, COUNT(*) as count
        FROM bookings WHERE created_at >= NOW() - $1::interval
        GROUP BY DATE_TRUNC('day', created_at), status ORDER BY date
      `, [interval]),
      pool.query(`
        SELECT DATE_TRUNC('day', created_at) as date, role, COUNT(*) as count
        FROM users WHERE created_at >= NOW() - $1::interval
        GROUP BY DATE_TRUNC('day', created_at), role ORDER BY date
      `, [interval]),
    ]);

    res.json({
      success: true,
      data: {
        revenue: revenue.rows,
        bookings: bookings.rows,
        userGrowth: userGrowth.rows,
      },
    });
  } catch (err) { next(err); }
};

// ============================================================
// USER MANAGEMENT
// ============================================================

exports.listUsers = async (req, res, next) => {
  try {
    const { page = 1, limit = 25, role, search, status } = req.query;
    const offset = (page - 1) * limit;
    const params = [];
    let where = '1=1';

    if (role) {
      params.push(role);
      where += ` AND u.role = $${params.length}`;
    }
    if (search) {
      params.push(`%${search}%`);
      where += ` AND (u.name ILIKE $${params.length} OR u.email ILIKE $${params.length})`;
    }
    if (status === 'banned') {
      where += ` AND EXISTS (SELECT 1 FROM complaints c WHERE c.reported_user_id = u.id AND c.status = 'banned')`;
    }

    params.push(limit, offset);
    const result = await pool.query(
      `SELECT u.id, u.name, u.email, u.phone, u.role, u.location, u.email_verified,
              u.is_admin, u.created_at,
              (SELECT COUNT(*) FROM bookings b WHERE b.customer_id = u.id OR EXISTS (
                SELECT 1 FROM professionals p WHERE p.user_id = u.id AND b.professional_id = p.id
              )) as booking_count
       FROM users u WHERE ${where}
       ORDER BY u.created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    const countRes = await pool.query(`SELECT COUNT(*) FROM users u WHERE ${where}`, params.slice(0, -2));

    res.json({
      success: true,
      data: { users: result.rows, total: parseInt(countRes.rows[0].count), page: Number(page), limit: Number(limit) },
    });
  } catch (err) { next(err); }
};

exports.getUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    const user = await pool.query(
      `SELECT u.*, 
        (SELECT row_to_json(p) FROM professionals p WHERE p.user_id = u.id) as professional_profile
       FROM users u WHERE u.id = $1`,
      [id]
    );
    if (user.rows.length === 0) return res.status(404).json({ success: false, message: 'User not found' });

    const [bookings, payments, complaints] = await Promise.all([
      pool.query(`SELECT id, title, status, created_at FROM bookings WHERE customer_id = $1 ORDER BY created_at DESC LIMIT 10`, [id]),
      pool.query(`SELECT id, amount, status, created_at FROM payments WHERE payer_id = $1 OR payee_id = $1 ORDER BY created_at DESC LIMIT 10`, [id]),
      pool.query(`SELECT id, type, status, created_at FROM complaints WHERE reported_user_id = $1 ORDER BY created_at DESC`, [id]),
    ]);

    const { password_hash, ...userData } = user.rows[0];
    res.json({
      success: true,
      data: { user: userData, bookings: bookings.rows, payments: payments.rows, complaints: complaints.rows },
    });
  } catch (err) { next(err); }
};

exports.banUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    await pool.query(
      `INSERT INTO complaints (reporter_id, reported_user_id, type, description, status)
       VALUES ($1, $2, 'fraud', $3, 'banned')`,
      [req.user.id, id, reason || 'Banned by admin']
    );

    await auditLog(req.user.id, 'ban_user', 'user', id, { reason }, req.ip);
    logger.info({ adminId: req.user.id, targetId: id }, 'User banned by admin');
    res.json({ success: true, message: 'User banned' });
  } catch (err) { next(err); }
};

exports.unbanUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    await pool.query(`UPDATE complaints SET status = 'resolved' WHERE reported_user_id = $1 AND status = 'banned'`, [id]);
    await auditLog(req.user.id, 'unban_user', 'user', id, {}, req.ip);
    res.json({ success: true, message: 'User unbanned' });
  } catch (err) { next(err); }
};

// ============================================================
// KYC MANAGEMENT
// ============================================================

exports.getKYCQueue = async (req, res, next) => {
  try {
    const { status = 'pending', page = 1, limit = 25 } = req.query;
    const offset = (page - 1) * limit;

    const result = await pool.query(
      `SELECT v.*, u.name as user_name, u.email as user_email, u.phone as user_phone
       FROM verifications v
       JOIN users u ON v.user_id = u.id
       WHERE v.status = $1
       ORDER BY v.created_at ASC
       LIMIT $2 OFFSET $3`,
      [status, limit, offset]
    );

    const countRes = await pool.query(`SELECT COUNT(*) FROM verifications WHERE status = $1`, [status]);

    res.json({
      success: true,
      data: { verifications: result.rows, total: parseInt(countRes.rows[0].count), page: Number(page) },
    });
  } catch (err) { next(err); }
};

exports.approveKYC = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `UPDATE verifications SET status = 'verified', verified_at = NOW(), verification_method = 'manual_admin', updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [id]
    );
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Verification not found' });

    await auditLog(req.user.id, 'approve_kyc', 'verification', id, {}, req.ip);

    // Notify user
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, related_id)
       VALUES ($1, 'system', 'KYC Approved', 'Your document has been verified successfully!', $2)`,
      [result.rows[0].user_id, id]
    );

    res.json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
};

exports.rejectKYC = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    const result = await pool.query(
      `UPDATE verifications SET status = 'rejected', rejection_reason = $2, updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [id, reason]
    );
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Verification not found' });

    await auditLog(req.user.id, 'reject_kyc', 'verification', id, { reason }, req.ip);

    await pool.query(
      `INSERT INTO notifications (user_id, type, title, body, related_id)
       VALUES ($1, 'system', 'KYC Rejected', $2, $3)`,
      [result.rows[0].user_id, `Your document was rejected: ${reason}`, id]
    );

    res.json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
};

// ============================================================
// DISPUTE MANAGEMENT
// ============================================================

exports.listDisputes = async (req, res, next) => {
  try {
    const { status = 'open', page = 1, limit = 25 } = req.query;
    const offset = (page - 1) * limit;

    const result = await pool.query(
      `SELECT d.*, 
        u1.name as raised_by_name, u1.email as raised_by_email,
        u2.name as against_name, u2.email as against_email,
        b.title as booking_title
       FROM disputes d
       JOIN users u1 ON d.raised_by = u1.id
       JOIN users u2 ON d.against_user = u2.id
       JOIN bookings b ON d.booking_id = b.id
       WHERE d.status = $1
       ORDER BY d.created_at ASC
       LIMIT $2 OFFSET $3`,
      [status, limit, offset]
    );

    res.json({ success: true, data: { disputes: result.rows, page: Number(page) } });
  } catch (err) { next(err); }
};

exports.resolveDispute = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { resolution, status, refund } = req.body;

    const result = await pool.query(
      `UPDATE disputes SET status = $2, admin_resolution = $3, resolved_at = NOW(), resolved_by = $4, updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [id, status || 'closed', resolution, req.user.id]
    );

    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Dispute not found' });

    // If refund requested, process it
    if (refund) {
      await pool.query(
        `UPDATE payments SET status = 'refunded', refund_reason = $2, updated_at = NOW()
         WHERE booking_id = $1 AND status = 'held_in_escrow'`,
        [result.rows[0].booking_id, `Dispute resolved: ${resolution}`]
      );
    }

    await auditLog(req.user.id, 'resolve_dispute', 'dispute', id, { resolution, status, refund }, req.ip);
    res.json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
};

// ============================================================
// CATEGORY MANAGEMENT
// ============================================================

exports.createCategory = async (req, res, next) => {
  try {
    const { name, description, parent_id, icon } = req.body;
    const result = await pool.query(
      `INSERT INTO categories (name, description, parent_id, icon) VALUES ($1, $2, $3, $4) RETURNING *`,
      [name, description, parent_id || null, icon]
    );
    await auditLog(req.user.id, 'create_category', 'category', result.rows[0].id, { name }, req.ip);
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
};

exports.updateCategory = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, description, icon } = req.body;
    const result = await pool.query(
      `UPDATE categories SET name = COALESCE($2, name), description = COALESCE($3, description), icon = COALESCE($4, icon) WHERE id = $1 RETURNING *`,
      [id, name, description, icon]
    );
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Category not found' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
};

exports.deleteCategory = async (req, res, next) => {
  try {
    const { id } = req.params;
    await pool.query(`DELETE FROM categories WHERE id = $1`, [id]);
    await auditLog(req.user.id, 'delete_category', 'category', id, {}, req.ip);
    res.json({ success: true, message: 'Category deleted' });
  } catch (err) { next(err); }
};

// ============================================================
// COMPLAINTS MANAGEMENT
// ============================================================

exports.listComplaints = async (req, res, next) => {
  try {
    const { status = 'pending', page = 1, limit = 25 } = req.query;
    const offset = (page - 1) * limit;

    const result = await pool.query(
      `SELECT c.*, 
        u1.name as reporter_name, u2.name as reported_name
       FROM complaints c
       JOIN users u1 ON c.reporter_id = u1.id
       JOIN users u2 ON c.reported_user_id = u2.id
       WHERE c.status = $1
       ORDER BY c.created_at ASC LIMIT $2 OFFSET $3`,
      [status, limit, offset]
    );

    res.json({ success: true, data: { complaints: result.rows, page: Number(page) } });
  } catch (err) { next(err); }
};

exports.resolveComplaint = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, admin_note } = req.body;

    const result = await pool.query(
      `UPDATE complaints SET status = $2, admin_note = $3, resolved_at = NOW(), resolved_by = $4, updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [id, status, admin_note, req.user.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Complaint not found' });

    await auditLog(req.user.id, 'resolve_complaint', 'complaint', id, { status, admin_note }, req.ip);
    res.json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
};

// ============================================================
// PLATFORM SETTINGS
// ============================================================

exports.getAuditLog = async (req, res, next) => {
  try {
    const { page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;

    const result = await pool.query(
      `SELECT a.*, u.name as admin_name
       FROM admin_audit_log a JOIN users u ON a.admin_id = u.id
       ORDER BY a.created_at DESC LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    res.json({ success: true, data: { logs: result.rows, page: Number(page) } });
  } catch (err) { next(err); }
};
