const { query } = require('../config/database');
const logger = require('../config/logger');

// ============================================================
// COUNTRY TENANT CONTROLLER
// Multi-tenant global architecture management
// ============================================================

/**
 * List all active countries/tenants (public)
 */
exports.listCountries = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT country_code, country_name, status, default_language, 
              supported_languages, currency_code, currency_symbol, 
              enabled_engines, operational_cities, launch_date
       FROM country_tenants 
       WHERE status IN ('active', 'onboarding')
       ORDER BY country_name`
    );

    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
};

/**
 * Get country configuration (public)
 */
exports.getCountryConfig = async (req, res, next) => {
  try {
    const { code } = req.params;

    const result = await query(
      `SELECT * FROM country_tenants WHERE country_code = $1`,
      [code.toUpperCase()]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Country not found or not available' });
    }

    // Get available categories for this country
    const categories = await query(
      `SELECT id, name, description, icon, parent_id, engine, is_subscription_eligible
       FROM categories 
       WHERE $1 = ANY(country_availability) OR country_availability IS NULL
       ORDER BY name`,
      [code.toUpperCase()]
    );

    res.json({
      success: true,
      data: {
        ...result.rows[0],
        categories: categories.rows
      }
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Admin: Create a new country tenant
 */
exports.createTenant = async (req, res, next) => {
  try {
    const {
      country_code, country_name, tenant_type, default_language,
      supported_languages, currency_code, currency_symbol, timezone,
      payment_gateways, commission_rate, tax_rate, tax_name,
      payout_cycle_days, kyc_requirements, enabled_engines,
      partner_name, partner_contact_email, operational_cities, launch_date
    } = req.body;

    if (!country_code || !country_name) {
      return res.status(400).json({ success: false, message: 'country_code and country_name are required' });
    }

    const result = await query(
      `INSERT INTO country_tenants 
       (country_code, country_name, tenant_type, default_language, supported_languages,
        currency_code, currency_symbol, timezone, payment_gateways, commission_rate,
        tax_rate, tax_name, payout_cycle_days, kyc_requirements, enabled_engines,
        partner_name, partner_contact_email, operational_cities, launch_date)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)
       RETURNING *`,
      [
        country_code.toUpperCase(), country_name, tenant_type || 'company_operated',
        default_language || 'en', supported_languages || ['en'],
        currency_code || 'INR', currency_symbol || '₹', timezone || 'UTC',
        payment_gateways || ['razorpay'], commission_rate || 15.00,
        tax_rate || 18.00, tax_name || 'VAT', payout_cycle_days || 7,
        JSON.stringify(kyc_requirements || { basic: ['phone', 'email'], identity: ['government_id'] }),
        enabled_engines || ['booking', 'subscription', 'marketplace'],
        partner_name || null, partner_contact_email || null,
        operational_cities || [], launch_date || null
      ]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ success: false, message: 'Country tenant already exists' });
    }
    next(err);
  }
};

/**
 * Admin: Update country tenant configuration
 */
exports.updateTenant = async (req, res, next) => {
  try {
    const { code } = req.params;
    const {
      status, commission_rate, tax_rate, tax_name, payout_cycle_days,
      payment_gateways, enabled_engines, operational_cities, 
      supported_languages, kyc_requirements, partner_name, partner_contact_email
    } = req.body;

    const result = await query(
      `UPDATE country_tenants SET
        status = COALESCE($1, status),
        commission_rate = COALESCE($2, commission_rate),
        tax_rate = COALESCE($3, tax_rate),
        tax_name = COALESCE($4, tax_name),
        payout_cycle_days = COALESCE($5, payout_cycle_days),
        payment_gateways = COALESCE($6, payment_gateways),
        enabled_engines = COALESCE($7, enabled_engines),
        operational_cities = COALESCE($8, operational_cities),
        supported_languages = COALESCE($9, supported_languages),
        kyc_requirements = COALESCE($10, kyc_requirements),
        partner_name = COALESCE($11, partner_name),
        partner_contact_email = COALESCE($12, partner_contact_email),
        updated_at = NOW()
       WHERE country_code = $13
       RETURNING *`,
      [
        status || null, commission_rate || null, tax_rate || null,
        tax_name || null, payout_cycle_days || null,
        payment_gateways || null, enabled_engines || null,
        operational_cities || null, supported_languages || null,
        kyc_requirements ? JSON.stringify(kyc_requirements) : null,
        partner_name || null, partner_contact_email || null,
        code.toUpperCase()
      ]
    );

    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Country tenant not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * Admin: List all tenants (including planned/suspended)
 */
exports.listAllTenants = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT * FROM country_tenants ORDER BY status, country_name`
    );

    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
};

/**
 * Get supported currencies and payment methods
 */
exports.getSupportedCurrencies = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT country_code, country_name, currency_code, currency_symbol, payment_gateways
       FROM country_tenants WHERE status = 'active'
       ORDER BY country_name`
    );

    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
};
