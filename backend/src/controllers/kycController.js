const crypto = require('crypto');
const { query } = require('../config/database');
const v = require('../utils/kycValidators');

const sha256 = (s) => crypto.createHash('sha256').update(String(s)).digest('hex');

// Refresh user.kyc_level + trust_score from verifications table
async function refreshAggregates(userId) {
  const r = await query(
    `SELECT ARRAY_AGG(doc_type::text) FILTER (WHERE status = 'verified') AS types
     FROM verifications WHERE user_id = $1`,
    [userId]
  );
  let types = r.rows[0]?.types || [];
  // pg may return enum array as a string like '{aadhaar,gstin}' — coerce defensively
  if (typeof types === 'string') {
    types = types.replace(/^\{|\}$/g, '').split(',').filter(Boolean);
  }
  if (!Array.isArray(types)) types = [];
  const u = await query('SELECT phone_verified, government_id_verified, selfie_verified FROM users WHERE id = $1', [userId]);
  const usr = u.rows[0] || {};
  const hasGovId = types.some((t) => ['aadhaar','pan','passport','voter_id','driving_license'].includes(t));
  const hasCredential = types.some((t) => ['icai_membership','bar_council','mci_registration','coa_registration','iei_membership','electrical_license','plumbing_license','gstin','cin','fssai','msme_udyam','shop_act','iso_cert'].includes(t));
  const level = v.computeKycLevel({
    phoneVerified: usr.phone_verified,
    emailVerified: true,
    hasGovId,
    hasSelfie: !!usr.selfie_verified,
    hasCredential,
  });
  const trust = v.computeTrustScore(types);
  await query(
    `UPDATE users SET kyc_level = $1::smallint, trust_score = $2::smallint,
       kyc_completed_at = CASE WHEN $1::smallint >= 3 AND kyc_completed_at IS NULL THEN NOW() ELSE kyc_completed_at END
     WHERE id = $3`,
    [level, trust, userId]
  );
  return { kyc_level: level, trust_score: trust, verified_types: types };
}

exports.listMine = async (req, res, next) => {
  try {
    const r = await query(
      `SELECT id, doc_type, doc_number, status, holder_name, issuing_authority,
              issue_date, expiry_date, verification_method, verified_at, rejection_reason,
              created_at, updated_at
       FROM verifications WHERE user_id = $1 ORDER BY created_at DESC`,
      [req.user.id]
    );
    const data = r.rows.map((row) => ({ ...row, doc_number: v.maskDocNumber(row.doc_number) }));
    const u = await query('SELECT kyc_level, trust_score, kyc_completed_at FROM users WHERE id = $1', [req.user.id]);
    res.json({ success: true, data, user: u.rows[0] || {} });
  } catch (e) { next(e); }
};

exports.allowedTypes = async (req, res) => {
  res.json({ success: true, data: v.ROLE_ALLOWED[req.user.role] || [] });
};

exports.submit = async (req, res, next) => {
  try {
    const { doc_type, doc_number, holder_name, issuing_authority, issue_date, expiry_date, document_url, selfie_url } = req.body;
    if (!doc_type || !doc_number) {
      return res.status(400).json({ success: false, message: 'doc_type and doc_number are required' });
    }
    if (!v.isAllowedForRole(req.user.role, doc_type)) {
      return res.status(403).json({ success: false, message: `Doc type '${doc_type}' not allowed for role '${req.user.role}'` });
    }
    const check = v.validate(doc_type, doc_number);
    if (!check.valid) return res.status(422).json({ success: false, message: check.reason });

    const normalized = check.normalized;
    const hash = sha256(`${doc_type}:${normalized}`);

    // Reject if same doc number is already verified for a DIFFERENT user
    const dup = await query(
      `SELECT user_id FROM verifications WHERE doc_number_hash = $1 AND status = 'verified' AND user_id <> $2 LIMIT 1`,
      [hash, req.user.id]
    );
    if (dup.rows.length) {
      return res.status(409).json({ success: false, message: 'This document is already verified to another account' });
    }

    // Auto-verify in DEV mode (no live gateway). Status = 'pending' in production.
    const autoVerify = process.env.KYC_AUTO_VERIFY === 'true' || process.env.NODE_ENV !== 'production';
    const status = autoVerify ? 'verified' : 'pending';
    const method = autoVerify ? 'sandbox_auto' : 'manual';

    const ins = await query(
      `INSERT INTO verifications
        (user_id, doc_type, doc_number, doc_number_hash, holder_name, issuing_authority,
         issue_date, expiry_date, document_url, selfie_url, status, verification_method, verified_at)
       VALUES ($1, $2::kyc_doc_type, $3, $4, $5, $6, $7::date, $8::date, $9, $10, $11::kyc_status, $12, $13::timestamptz)
       ON CONFLICT (user_id, doc_type) DO UPDATE SET
         doc_number = EXCLUDED.doc_number,
         doc_number_hash = EXCLUDED.doc_number_hash,
         holder_name = EXCLUDED.holder_name,
         issuing_authority = EXCLUDED.issuing_authority,
         issue_date = EXCLUDED.issue_date,
         expiry_date = EXCLUDED.expiry_date,
         document_url = EXCLUDED.document_url,
         selfie_url = EXCLUDED.selfie_url,
         status = EXCLUDED.status,
         verification_method = EXCLUDED.verification_method,
         verified_at = EXCLUDED.verified_at,
         rejection_reason = NULL,
         updated_at = NOW()
       RETURNING id, doc_type, status, verified_at`,
      [req.user.id, doc_type, normalized, hash, holder_name || null, issuing_authority || null,
       issue_date || null, expiry_date || null, document_url || null, selfie_url || null,
       status, method, autoVerify ? new Date() : null]
    );

    await query(
      `INSERT INTO verification_audit (verification_id, actor_id, action, ip_address, user_agent)
       VALUES ($1, $2, $3, $4::inet, $5)`,
      [ins.rows[0].id, req.user.id, autoVerify ? 'approved' : 'submitted',
       req.ip || null, req.headers['user-agent'] || null]
    );

    if (autoVerify) {
      await query(`UPDATE users SET government_id_verified = TRUE WHERE id = $1 AND $2::text IN ('aadhaar','pan','passport','voter_id','driving_license')`,
        [req.user.id, doc_type]);
    }

    const aggregates = await refreshAggregates(req.user.id);
    res.status(201).json({
      success: true,
      message: autoVerify ? 'Document verified' : 'Document submitted for review',
      data: { ...ins.rows[0], doc_number: v.maskDocNumber(normalized) },
      aggregates,
    });
  } catch (e) { next(e); }
};

exports.remove = async (req, res, next) => {
  try {
    const r = await query(
      'DELETE FROM verifications WHERE id = $1 AND user_id = $2 RETURNING id',
      [req.params.id, req.user.id]
    );
    if (!r.rows.length) return res.status(404).json({ success: false, message: 'Not found' });
    const aggregates = await refreshAggregates(req.user.id);
    res.json({ success: true, message: 'Removed', aggregates });
  } catch (e) { next(e); }
};

// Public summary (non-PII) — used in profile/search to render badges
exports.publicSummary = async (req, res, next) => {
  try {
    const r = await query(
      `SELECT u.id, u.kyc_level, u.trust_score,
              ARRAY_AGG(v.doc_type::text) FILTER (WHERE v.status = 'verified') AS verified_types,
              COUNT(v.id) FILTER (WHERE v.status = 'verified') AS verified_count
       FROM users u LEFT JOIN verifications v ON v.user_id = u.id
       WHERE u.id = $1 GROUP BY u.id`,
      [req.params.userId]
    );
    if (!r.rows.length) return res.status(404).json({ success: false, message: 'Not found' });
    let row = r.rows[0];
    if (typeof row.verified_types === 'string') {
      row.verified_types = row.verified_types.replace(/^\{|\}$/g, '').split(',').filter(Boolean);
    }
    if (!Array.isArray(row.verified_types)) row.verified_types = [];
    res.json({ success: true, data: row });
  } catch (e) { next(e); }
};

// Admin endpoint — approve/reject pending docs
exports.adminReview = async (req, res, next) => {
  try {
    const { status, rejection_reason } = req.body;
    if (!['verified', 'rejected'].includes(status)) {
      return res.status(400).json({ success: false, message: 'status must be verified or rejected' });
    }
    const r = await query(
      `UPDATE verifications SET status = $1, rejection_reason = $2, verified_by = $3,
         verified_at = CASE WHEN $1 = 'verified' THEN NOW() ELSE NULL END,
         updated_at = NOW()
       WHERE id = $4 RETURNING user_id`,
      [status, rejection_reason || null, req.user.id, req.params.id]
    );
    if (!r.rows.length) return res.status(404).json({ success: false, message: 'Not found' });
    await query(
      `INSERT INTO verification_audit (verification_id, actor_id, action, note) VALUES ($1, $2, $3, $4)`,
      [req.params.id, req.user.id, status === 'verified' ? 'approved' : 'rejected', rejection_reason || null]
    );
    const aggregates = await refreshAggregates(r.rows[0].user_id);
    res.json({ success: true, message: 'Review saved', aggregates });
  } catch (e) { next(e); }
};
