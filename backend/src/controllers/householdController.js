const { query } = require('../config/database');
const logger = require('../config/logger');

// ============================================================
// HOUSEHOLD & FAMILY CONTROLLER
// Manages family accounts, household profiles, and shared services
// ============================================================

/**
 * Create a new household
 */
exports.createHousehold = async (req, res, next) => {
  try {
    const { name, address, city, state, country_code, latitude, longitude,
            property_type, size_sqft, preferred_language, pets, appliances } = req.body;

    if (!name) {
      return res.status(400).json({ success: false, message: 'Household name is required' });
    }

    const result = await query(
      `INSERT INTO households 
       (name, owner_id, address, city, state, country_code, latitude, longitude,
        property_type, size_sqft, preferred_language, pets, appliances)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
       RETURNING *`,
      [
        name, req.user.id, address || null, city || null, state || null,
        country_code || 'IN', latitude || null, longitude || null,
        property_type || null, size_sqft || null, preferred_language || 'en',
        JSON.stringify(pets || []), JSON.stringify(appliances || [])
      ]
    );

    // Auto-add owner as household member
    await query(
      `INSERT INTO household_members (household_id, user_id, name, role, can_book, can_manage_subscriptions)
       VALUES ($1, $2, $3, 'owner', TRUE, TRUE)`,
      [result.rows[0].id, req.user.id, req.user.name || 'Owner']
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * List user's households
 */
exports.listHouseholds = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT h.*, 
              (SELECT COUNT(*) FROM household_members WHERE household_id = h.id) as member_count,
              (SELECT COUNT(*) FROM service_subscriptions WHERE household_id = h.id AND status = 'active') as active_subscriptions
       FROM households h
       WHERE h.owner_id = $1
       UNION
       SELECT h.*, 
              (SELECT COUNT(*) FROM household_members WHERE household_id = h.id) as member_count,
              (SELECT COUNT(*) FROM service_subscriptions WHERE household_id = h.id AND status = 'active') as active_subscriptions
       FROM households h
       JOIN household_members hm ON h.id = hm.household_id
       WHERE hm.user_id = $1 AND h.owner_id != $1
       ORDER BY created_at DESC`,
      [req.user.id]
    );

    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
};

/**
 * Get household details
 */
exports.getHousehold = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Verify access
    const access = await query(
      `SELECT 1 FROM household_members WHERE household_id = $1 AND user_id = $2
       UNION SELECT 1 FROM households WHERE id = $1 AND owner_id = $2`,
      [id, req.user.id]
    );

    if (!access.rows.length) {
      return res.status(403).json({ success: false, message: 'Access denied to this household' });
    }

    const household = await query(`SELECT * FROM households WHERE id = $1`, [id]);
    if (!household.rows[0]) {
      return res.status(404).json({ success: false, message: 'Household not found' });
    }

    const members = await query(
      `SELECT hm.*, u.email, u.avatar_url 
       FROM household_members hm 
       LEFT JOIN users u ON hm.user_id = u.id
       WHERE hm.household_id = $1 ORDER BY hm.role, hm.name`,
      [id]
    );

    const subscriptions = await query(
      `SELECT s.*, c.name as category_name
       FROM service_subscriptions s
       LEFT JOIN categories c ON s.category_id = c.id
       WHERE s.household_id = $1 AND s.status IN ('active', 'paused')
       ORDER BY s.next_occurrence`,
      [id]
    );

    res.json({
      success: true,
      data: {
        ...household.rows[0],
        members: members.rows,
        subscriptions: subscriptions.rows
      }
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Update household details
 */
exports.updateHousehold = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, address, city, state, property_type, size_sqft,
            preferred_language, pets, appliances, preferred_providers } = req.body;

    // Only owner can update
    const ownership = await query(
      `SELECT 1 FROM households WHERE id = $1 AND owner_id = $2`,
      [id, req.user.id]
    );

    if (!ownership.rows.length) {
      return res.status(403).json({ success: false, message: 'Only the household owner can update' });
    }

    const result = await query(
      `UPDATE households SET
        name = COALESCE($1, name),
        address = COALESCE($2, address),
        city = COALESCE($3, city),
        state = COALESCE($4, state),
        property_type = COALESCE($5, property_type),
        size_sqft = COALESCE($6, size_sqft),
        preferred_language = COALESCE($7, preferred_language),
        pets = COALESCE($8, pets),
        appliances = COALESCE($9, appliances),
        preferred_providers = COALESCE($10, preferred_providers),
        updated_at = NOW()
       WHERE id = $11
       RETURNING *`,
      [
        name || null, address || null, city || null, state || null,
        property_type || null, size_sqft || null, preferred_language || null,
        pets ? JSON.stringify(pets) : null, appliances ? JSON.stringify(appliances) : null,
        preferred_providers || null, id
      ]
    );

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * Add member to household
 */
exports.addMember = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, role, phone, email, user_id, can_book, can_manage_subscriptions, is_emergency_contact } = req.body;

    if (!name) {
      return res.status(400).json({ success: false, message: 'Member name is required' });
    }

    // Only owner can add members
    const ownership = await query(
      `SELECT 1 FROM households WHERE id = $1 AND owner_id = $2`,
      [id, req.user.id]
    );

    if (!ownership.rows.length) {
      return res.status(403).json({ success: false, message: 'Only the household owner can add members' });
    }

    const validRoles = ['adult', 'child', 'caretaker'];
    const memberRole = validRoles.includes(role) ? role : 'adult';

    const result = await query(
      `INSERT INTO household_members 
       (household_id, user_id, name, role, phone, email, can_book, can_manage_subscriptions, is_emergency_contact)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        id, user_id || null, name, memberRole, phone || null, email || null,
        can_book !== false, can_manage_subscriptions === true, is_emergency_contact === true
      ]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * Remove member from household
 */
exports.removeMember = async (req, res, next) => {
  try {
    const { id, memberId } = req.params;

    // Only owner can remove members
    const ownership = await query(
      `SELECT 1 FROM households WHERE id = $1 AND owner_id = $2`,
      [id, req.user.id]
    );

    if (!ownership.rows.length) {
      return res.status(403).json({ success: false, message: 'Only the household owner can remove members' });
    }

    // Can't remove owner
    const member = await query(
      `SELECT role FROM household_members WHERE id = $1 AND household_id = $2`,
      [memberId, id]
    );

    if (!member.rows[0]) {
      return res.status(404).json({ success: false, message: 'Member not found' });
    }

    if (member.rows[0].role === 'owner') {
      return res.status(400).json({ success: false, message: 'Cannot remove the household owner' });
    }

    await query(`DELETE FROM household_members WHERE id = $1 AND household_id = $2`, [memberId, id]);

    res.json({ success: true, message: 'Member removed' });
  } catch (err) {
    next(err);
  }
};
