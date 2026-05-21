-- Seed data for Global Ecosystem tables (migration 018)
-- Run AFTER 018_global_ecosystem.sql migration

BEGIN;

-- ============================================================
-- COUNTRY TENANTS — Initial launch countries
-- ============================================================

INSERT INTO country_tenants (country_code, country_name, tenant_type, status, default_language, supported_languages, currency_code, currency_symbol, timezone, payment_gateways, commission_rate, tax_rate, tax_name, payout_cycle_days, enabled_engines, operational_cities, launch_date)
VALUES
  -- Phase 1: India (Company Operated)
  ('IN', 'India', 'company_operated', 'active', 'en', ARRAY['en','hi','te','ta','kn','ml','mr','bn'], 'INR', '₹', 'Asia/Kolkata', ARRAY['razorpay','upi','paytm'], 15.00, 18.00, 'GST', 7, ARRAY['booking','subscription','marketplace']::service_engine[], ARRAY['Hyderabad','Vizag','Bangalore','Mumbai','Delhi','Chennai','Pune','Kolkata'], '2025-01-01'),

  -- Phase 4: Middle East
  ('AE', 'United Arab Emirates', 'partner', 'planned', 'en', ARRAY['en','ar'], 'AED', 'د.إ', 'Asia/Dubai', ARRAY['stripe','tap'], 12.00, 5.00, 'VAT', 14, ARRAY['booking','subscription','marketplace']::service_engine[], ARRAY['Dubai','Abu Dhabi','Sharjah'], NULL),

  ('SA', 'Saudi Arabia', 'partner', 'planned', 'ar', ARRAY['ar','en'], 'SAR', '﷼', 'Asia/Riyadh', ARRAY['stripe','mada'], 12.00, 15.00, 'VAT', 14, ARRAY['booking','subscription']::service_engine[], ARRAY['Riyadh','Jeddah','Dammam'], NULL),

  -- Phase 4: Southeast Asia
  ('SG', 'Singapore', 'franchise', 'planned', 'en', ARRAY['en','zh','ms','ta'], 'SGD', 'S$', 'Asia/Singapore', ARRAY['stripe','grabpay'], 10.00, 9.00, 'GST', 7, ARRAY['booking','marketplace']::service_engine[], ARRAY['Singapore'], NULL),

  ('MY', 'Malaysia', 'partner', 'planned', 'ms', ARRAY['ms','en','zh'], 'MYR', 'RM', 'Asia/Kuala_Lumpur', ARRAY['stripe','fpx'], 12.00, 8.00, 'SST', 14, ARRAY['booking','subscription']::service_engine[], ARRAY['Kuala Lumpur','Penang','Johor Bahru'], NULL),

  ('ID', 'Indonesia', 'partner', 'planned', 'id', ARRAY['id','en'], 'IDR', 'Rp', 'Asia/Jakarta', ARRAY['xendit','gopay'], 15.00, 11.00, 'PPN', 14, ARRAY['booking','subscription']::service_engine[], ARRAY['Jakarta','Surabaya','Bali'], NULL),

  -- Phase 4: Africa
  ('KE', 'Kenya', 'partner', 'planned', 'en', ARRAY['en','sw'], 'KES', 'KSh', 'Africa/Nairobi', ARRAY['mpesa','stripe'], 15.00, 16.00, 'VAT', 14, ARRAY['booking','subscription']::service_engine[], ARRAY['Nairobi','Mombasa'], NULL),

  -- Future: Europe
  ('GB', 'United Kingdom', 'company_operated', 'planned', 'en', ARRAY['en'], 'GBP', '£', 'Europe/London', ARRAY['stripe'], 10.00, 20.00, 'VAT', 7, ARRAY['booking','marketplace']::service_engine[], ARRAY['London','Manchester','Birmingham'], NULL),

  -- Future: North America
  ('US', 'United States', 'franchise', 'planned', 'en', ARRAY['en','es'], 'USD', '$', 'America/New_York', ARRAY['stripe'], 10.00, 0.00, 'Sales Tax', 7, ARRAY['booking','marketplace']::service_engine[], ARRAY[], NULL)

ON CONFLICT (country_code) DO NOTHING;

-- ============================================================
-- UPDATE CATEGORIES — Tag with engine type and subscription eligibility
-- ============================================================

-- Booking engine categories (existing home services)
UPDATE categories SET engine = 'booking' WHERE name IN (
  'Plumbing', 'Electrical', 'Carpentry', 'Painting', 'Cleaning',
  'Pest Control', 'HVAC', 'Roofing', 'Appliance Repair',
  'Beauty & Makeup', 'Hair Styling', 'Massage Therapy'
);

-- Marketplace engine categories (project/quote based)
UPDATE categories SET engine = 'marketplace' WHERE name IN (
  'Photography', 'Videography', 'Event Planning', 'Decoration',
  'Tutoring', 'Web Development', 'Mobile Development', 'Graphic Design',
  'Interior Design', 'Life Coaching', 'Fitness Training',
  'Catering', 'DJ & Music', 'MC & Hosting', 'Venue Rental'
);

-- Subscription-eligible categories
UPDATE categories SET is_subscription_eligible = TRUE WHERE name IN (
  'Cleaning', 'Pest Control', 'HVAC', 'Landscaping',
  'Pet Care', 'Appliance Repair'
);

-- Set all categories available in India
UPDATE categories SET country_availability = ARRAY['IN'];

COMMIT;
