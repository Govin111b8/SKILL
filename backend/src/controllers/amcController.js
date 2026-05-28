/**
 * AMC Plans Controller
 *
 * Annual Maintenance Contracts for AC, RO purifier, geyser, etc.
 * Customers subscribe to a plan; platform schedules service visits.
 */

const { query } = require('../config/database');

// ── List available AMC plans ──────────────────────────────────────────────────

const listAmcPlans = async (req, res, next) => {
  try {
    const { category_id, appliance_type } = req.query;

    const conditions = ['ap.is_active = true'];
    const values = [];
    let idx = 1;

    if (category_id) {
      conditions.push(`ap.category_id = $${idx++}`);
      values.push(category_id);
    }
    if (appliance_type) {
      conditions.push(`ap.appliance_type ILIKE $${idx++}`);
      values.push(appliance_type);
    }

    const result = await query(
      `SELECT ap.*, c.name AS category_name
       FROM amc_plans ap
       JOIN categories c ON ap.category_id = c.id
       WHERE ${conditions.join(' AND ')}
       ORDER BY ap.price_annual ASC`,
      values
    );

    res.json({ success: true, data: result.rows });
  } catch (error) {
    next(error);
  }
};

// ── Get single AMC plan ───────────────────────────────────────────────────────

const getAmcPlan = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT ap.*, c.name AS category_name
       FROM amc_plans ap
       JOIN categories c ON ap.category_id = c.id
       WHERE ap.id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'AMC plan not found.' });
    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

// ── Customer: subscribe to an AMC plan ───────────────────────────────────────

const subscribeAmcPlan = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { plan_id, home_profile_id, appliance_details, payment_mode } = req.body;

    if (!plan_id) return res.status(400).json({ success: false, message: 'plan_id is required.' });

    const planRes = await query('SELECT * FROM amc_plans WHERE id = $1 AND is_active = true', [plan_id]);
    if (planRes.rows.length === 0) return res.status(404).json({ success: false, message: 'AMC plan not found.' });
    const plan = planRes.rows[0];

    // Validate home_profile ownership if provided
    if (home_profile_id) {
      const hpRes = await query('SELECT id FROM home_profiles WHERE id = $1 AND user_id = $2', [home_profile_id, userId]);
      if (hpRes.rows.length === 0) return res.status(400).json({ success: false, message: 'Home profile not found or not yours.' });
    }

    const validPaymentMode = ['annual', 'monthly'].includes(payment_mode) ? payment_mode : 'annual';
    const startDate = new Date();
    const endDate = new Date(startDate);
    endDate.setFullYear(endDate.getFullYear() + 1);

    // First service in ~30 days
    const firstService = new Date(startDate);
    firstService.setDate(firstService.getDate() + 30);

    const result = await query(
      `INSERT INTO amc_subscriptions
         (user_id, amc_plan_id, home_profile_id, appliance_details, start_date, end_date, next_service_date, payment_mode)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING *`,
      [
        userId, plan_id,
        home_profile_id || null,
        appliance_details ? JSON.stringify(appliance_details) : '{}',
        startDate.toISOString().split('T')[0],
        endDate.toISOString().split('T')[0],
        firstService.toISOString().split('T')[0],
        validPaymentMode,
      ]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: `AMC subscription activated. Your first service is scheduled around ${firstService.toDateString()}.`,
    });
  } catch (error) {
    next(error);
  }
};

// ── Customer: list own AMC subscriptions ─────────────────────────────────────

const listMyAmcSubscriptions = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT asub.*, ap.name AS plan_name, ap.appliance_type, ap.services_per_year,
              ap.price_annual, c.name AS category_name
       FROM amc_subscriptions asub
       JOIN amc_plans ap ON asub.amc_plan_id = ap.id
       JOIN categories c ON ap.category_id = c.id
       WHERE asub.user_id = $1
       ORDER BY asub.created_at DESC`,
      [userId]
    );

    res.json({ success: true, data: result.rows });
  } catch (error) {
    next(error);
  }
};

// ── Customer: cancel an AMC subscription ─────────────────────────────────────

const cancelAmcSubscription = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const result = await query(
      `UPDATE amc_subscriptions SET status = 'cancelled' WHERE id = $1 AND user_id = $2 AND status = 'active' RETURNING id`,
      [id, userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'AMC subscription not found or already cancelled.' });
    }
    res.json({ success: true, message: 'AMC subscription cancelled.' });
  } catch (error) {
    next(error);
  }
};

// ── Admin: create AMC plan ────────────────────────────────────────────────────

const createAmcPlan = async (req, res, next) => {
  try {
    const {
      category_id, name, description, appliance_type,
      services_per_year, price_annual, price_monthly,
      covers_labour, covers_spares, max_appliances,
    } = req.body;

    if (!category_id || !name || !price_annual) {
      return res.status(400).json({ success: false, message: 'category_id, name, and price_annual are required.' });
    }

    const result = await query(
      `INSERT INTO amc_plans
         (category_id, name, description, appliance_type, services_per_year,
          price_annual, price_monthly, covers_labour, covers_spares, max_appliances)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
       RETURNING *`,
      [
        category_id, name.trim(), description || null, appliance_type || null,
        services_per_year || 2, price_annual,
        price_monthly || null, covers_labour !== false, covers_spares || false,
        max_appliances || 1,
      ]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

// ── List bundle packages ──────────────────────────────────────────────────────

const listBundlePackages = async (req, res, next) => {
  try {
    const { city } = req.query;

    const result = await query(
      `SELECT * FROM bundle_packages
       WHERE is_active = true
         AND (city IS NULL OR city ILIKE $1)
       ORDER BY sort_order ASC`,
      [city || '%']
    );

    res.json({ success: true, data: result.rows });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  listAmcPlans,
  getAmcPlan,
  subscribeAmcPlan,
  listMyAmcSubscriptions,
  cancelAmcSubscription,
  createAmcPlan,
  listBundlePackages,
};
