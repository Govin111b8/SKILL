/**
 * Home Profile Controller
 *
 * Customers save their home details (BHK type, area, appliances, address)
 * so repeat bookings are faster and professionals get context upfront.
 */

const { query } = require('../config/database');

// ── List home profiles for authenticated user ─────────────────────────────────

const listHomeProfiles = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const result = await query(
      `SELECT * FROM home_profiles WHERE user_id = $1 ORDER BY is_default DESC, created_at ASC`,
      [userId]
    );
    res.json({ success: true, data: result.rows });
  } catch (error) {
    next(error);
  }
};

// ── Get single home profile ───────────────────────────────────────────────────

const getHomeProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const result = await query(
      `SELECT * FROM home_profiles WHERE id = $1 AND user_id = $2`,
      [id, userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Home profile not found.' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

// ── Create home profile ───────────────────────────────────────────────────────

const createHomeProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const {
      nickname, bhk_type, area_sqft, floor_number, building_name,
      address_line1, address_line2, locality, city, pincode, state,
      latitude, longitude, appliances, notes, is_default,
    } = req.body;

    if (!address_line1 || !address_line1.trim()) {
      return res.status(400).json({ success: false, message: 'address_line1 is required.' });
    }
    if (!pincode || !/^\d{6}$/.test(pincode)) {
      return res.status(400).json({ success: false, message: 'Valid 6-digit pincode is required.' });
    }

    // If marking as default, unset current default first
    if (is_default) {
      await query(`UPDATE home_profiles SET is_default = false WHERE user_id = $1 AND is_default = true`, [userId]);
    }

    const result = await query(
      `INSERT INTO home_profiles
         (user_id, nickname, bhk_type, area_sqft, floor_number, building_name,
          address_line1, address_line2, locality, city, pincode, state,
          latitude, longitude, appliances, notes, is_default)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)
       RETURNING *`,
      [
        userId,
        nickname || 'My Home',
        bhk_type || null,
        area_sqft || null,
        floor_number || null,
        building_name || null,
        address_line1.trim(),
        address_line2 || null,
        locality || null,
        city || null,
        pincode,
        state || null,
        latitude || null,
        longitude || null,
        appliances ? JSON.stringify(appliances) : '[]',
        notes || null,
        is_default || false,
      ]
    );

    res.status(201).json({ success: true, data: result.rows[0], message: 'Home profile created.' });
  } catch (error) {
    next(error);
  }
};

// ── Update home profile ───────────────────────────────────────────────────────

const updateHomeProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    // Verify ownership
    const existing = await query(`SELECT id FROM home_profiles WHERE id = $1 AND user_id = $2`, [id, userId]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Home profile not found.' });
    }

    const {
      nickname, bhk_type, area_sqft, floor_number, building_name,
      address_line1, address_line2, locality, city, pincode, state,
      latitude, longitude, appliances, notes, is_default,
    } = req.body;

    if (pincode && !/^\d{6}$/.test(pincode)) {
      return res.status(400).json({ success: false, message: 'Valid 6-digit pincode is required.' });
    }

    // If marking as default, unset current default first
    if (is_default === true) {
      await query(`UPDATE home_profiles SET is_default = false WHERE user_id = $1 AND is_default = true AND id != $2`, [userId, id]);
    }

    const fields = [];
    const values = [];
    let idx = 1;

    const addField = (col, val) => { fields.push(`${col} = $${idx++}`); values.push(val); };

    if (nickname !== undefined) addField('nickname', nickname);
    if (bhk_type !== undefined) addField('bhk_type', bhk_type);
    if (area_sqft !== undefined) addField('area_sqft', area_sqft);
    if (floor_number !== undefined) addField('floor_number', floor_number);
    if (building_name !== undefined) addField('building_name', building_name);
    if (address_line1 !== undefined) addField('address_line1', address_line1.trim());
    if (address_line2 !== undefined) addField('address_line2', address_line2);
    if (locality !== undefined) addField('locality', locality);
    if (city !== undefined) addField('city', city);
    if (pincode !== undefined) addField('pincode', pincode);
    if (state !== undefined) addField('state', state);
    if (latitude !== undefined) addField('latitude', latitude);
    if (longitude !== undefined) addField('longitude', longitude);
    if (appliances !== undefined) addField('appliances', JSON.stringify(appliances));
    if (notes !== undefined) addField('notes', notes);
    if (is_default !== undefined) addField('is_default', is_default);

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields to update.' });
    }

    fields.push(`updated_at = NOW()`);
    values.push(id);

    const result = await query(
      `UPDATE home_profiles SET ${fields.join(', ')} WHERE id = $${idx} RETURNING *`,
      values
    );

    res.json({ success: true, data: result.rows[0], message: 'Home profile updated.' });
  } catch (error) {
    next(error);
  }
};

// ── Delete home profile ───────────────────────────────────────────────────────

const deleteHomeProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const result = await query(
      `DELETE FROM home_profiles WHERE id = $1 AND user_id = $2 RETURNING id`,
      [id, userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Home profile not found.' });
    }
    res.json({ success: true, message: 'Home profile deleted.' });
  } catch (error) {
    next(error);
  }
};

// ── Set default home profile ──────────────────────────────────────────────────

const setDefaultHomeProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    // Verify ownership
    const existing = await query(`SELECT id FROM home_profiles WHERE id = $1 AND user_id = $2`, [id, userId]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Home profile not found.' });
    }

    await query(`UPDATE home_profiles SET is_default = false WHERE user_id = $1`, [userId]);
    await query(`UPDATE home_profiles SET is_default = true, updated_at = NOW() WHERE id = $1`, [id]);

    res.json({ success: true, message: 'Default home profile updated.' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  listHomeProfiles,
  getHomeProfile,
  createHomeProfile,
  updateHomeProfile,
  deleteHomeProfile,
  setDefaultHomeProfile,
};
