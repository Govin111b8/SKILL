-- Migration 023: Home Services Platform Expansion
-- Adds: rich home services taxonomy, service_mode, flexible pricing models,
--       quote requests, home profiles, GPS job tracking, AMC plans, bundle packages

BEGIN;

-- ============================================================
-- ENUMS
-- ============================================================

DO $$ BEGIN
  CREATE TYPE service_mode AS ENUM ('instant_book', 'quote_request', 'subscription');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE pricing_type AS ENUM ('fixed', 'hourly', 'per_sqft', 'custom_quote', 'amc', 'package');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE quote_status AS ENUM ('open', 'bidding', 'accepted', 'in_progress', 'completed', 'cancelled', 'expired');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE bid_status AS ENUM ('submitted', 'shortlisted', 'accepted', 'rejected', 'withdrawn');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE tracking_status AS ENUM ('assigned', 'en_route', 'arrived', 'in_progress', 'completed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- ALTER CATEGORIES — add service_mode + pricing metadata
-- ============================================================

ALTER TABLE categories
  ADD COLUMN IF NOT EXISTS service_mode service_mode NOT NULL DEFAULT 'instant_book',
  ADD COLUMN IF NOT EXISTS default_pricing_type pricing_type NOT NULL DEFAULT 'fixed',
  ADD COLUMN IF NOT EXISTS hsn_code VARCHAR(20),          -- GST HSN/SAC code for this service type
  ADD COLUMN IF NOT EXISTS women_only_option BOOLEAN NOT NULL DEFAULT false,  -- allow filter for female pros
  ADD COLUMN IF NOT EXISTS requires_site_visit BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS typical_duration_hours DECIMAL(4,1),
  ADD COLUMN IF NOT EXISTS sort_priority INTEGER NOT NULL DEFAULT 0;  -- for homepage ordering

-- ============================================================
-- ALTER PROFESSIONAL_SERVICES — richer pricing support
-- ============================================================

ALTER TABLE professional_services
  ADD COLUMN IF NOT EXISTS pricing_type pricing_type NOT NULL DEFAULT 'fixed',
  ADD COLUMN IF NOT EXISTS price_per_unit DECIMAL(10,2),    -- price per sqft / per hour
  ADD COLUMN IF NOT EXISTS price_unit VARCHAR(30),          -- 'sqft', 'hour', 'visit', 'room', 'piece'
  ADD COLUMN IF NOT EXISTS amc_price_annual DECIMAL(10,2),  -- AMC annual price
  ADD COLUMN IF NOT EXISTS includes_materials BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS service_mode service_mode;       -- override category default if needed

-- ============================================================
-- EXPAND HOME SERVICES CATEGORIES
-- ============================================================

-- Top-level parent already exists ('Home Services').
-- We add richer subcategory groups (level-2) and leaf services (level-3).

-- ---- Level-2: Home Maintenance & Repair ----
INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, sort_priority)
SELECT 'Home Maintenance & Repair',
       (SELECT id FROM categories WHERE name = 'Home Services' AND parent_id IS NULL LIMIT 1),
       'Repair and maintenance of home appliances and systems',
       'build', 'instant_book', 'fixed', 10
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Home Maintenance & Repair');

-- Level-3 under Home Maintenance & Repair
INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, hsn_code, sort_priority)
SELECT unnest(ARRAY[
  'AC Repair & Servicing',
  'Water Purifier / RO Service',
  'Appliance Repair',
  'Geyser / Water Heater Repair',
  'CCTV & Security System Installation'
]),
(SELECT id FROM categories WHERE name = 'Home Maintenance & Repair' LIMIT 1),
unnest(ARRAY[
  'Split AC, window AC, cassette AC repair and annual servicing',
  'RO/UV purifier repair, filter change, and AMC plans',
  'Washing machine, refrigerator, microwave, geyser, and TV repair',
  'Electric and gas geyser, instant and storage water heater repair',
  'CCTV camera installation, DVR setup, and security alarm systems'
]),
unnest(ARRAY['ac_unit','water_drop','kitchen','hot_tub','security']),
'instant_book',
unnest(ARRAY['fixed'::pricing_type,'fixed'::pricing_type,'fixed'::pricing_type,'fixed'::pricing_type,'fixed'::pricing_type]),
unnest(ARRAY['998714','998714','998714','998714','998314']),
unnest(ARRAY[1,2,3,4,5])
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'AC Repair & Servicing');

-- ---- Level-2: Home Cleaning ----
INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, sort_priority)
SELECT 'Home Cleaning',
       (SELECT id FROM categories WHERE name = 'Home Services' AND parent_id IS NULL LIMIT 1),
       'Professional home, sofa, carpet, and pest control cleaning',
       'cleaning_services', 'instant_book', 'fixed', 9
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Home Cleaning');

INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, hsn_code)
SELECT unnest(ARRAY[
  'Deep Home Cleaning',
  'Kitchen Cleaning',
  'Bathroom Cleaning',
  'Sofa & Carpet Cleaning',
  'Pest Control',
  'Water Tank Cleaning'
]),
(SELECT id FROM categories WHERE name = 'Home Cleaning' LIMIT 1),
unnest(ARRAY[
  'Full home deep cleaning — per room or full home packages',
  'Chimney, stove, tiles, and cabinet degreasing',
  'Tiles, fixtures, and full bathroom sanitization',
  'Dry and wet cleaning for sofas, carpets, and mattresses',
  'Cockroach, termite, bed bugs, mosquito, and rat treatment',
  'Underground and overhead water tank disinfection'
]),
unnest(ARRAY['home','restaurant_menu','bathtub','chair','pest_control','water']),
'instant_book',
'fixed',
unnest(ARRAY['998531','998531','998531','998531','998531','998531'])
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Deep Home Cleaning');

-- ---- Level-2: Plumbing (already exists — enrich) ----
UPDATE categories SET
  service_mode = 'instant_book',
  default_pricing_type = 'fixed',
  hsn_code = '995422',
  sort_priority = 8
WHERE name = 'Plumbing';

INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, hsn_code)
SELECT unnest(ARRAY[
  'Tap & Pipe Leak Repair',
  'Toilet & WC Repair',
  'Drainage & Pipeline Cleaning',
  'Water Tank Installation',
  'Bathroom Fitting'
]),
(SELECT id FROM categories WHERE name = 'Plumbing' LIMIT 1),
unnest(ARRAY[
  'Tap washer replacement, pipe joint sealing, and leak fixing',
  'Flush tank, WC seat, and toilet repair',
  'Drain jetting, blockage removal, and sewer cleaning',
  'Overhead and underground water tank supply and fitting',
  'Complete bathroom fitting — taps, showers, and accessories'
]),
unnest(ARRAY['plumbing','wc','pipe','water_damage','bathtub']),
'instant_book',
'fixed',
'995422'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Tap & Pipe Leak Repair');

-- ---- Level-2: Electrical (already exists — enrich) ----
UPDATE categories SET
  service_mode = 'instant_book',
  default_pricing_type = 'fixed',
  hsn_code = '995423',
  sort_priority = 7
WHERE name = 'Electrical';

INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, hsn_code)
SELECT unnest(ARRAY[
  'Wiring & Rewiring',
  'Switch, Socket & Fan Installation',
  'Inverter & UPS Installation',
  'MCB & Fuse Box Repair',
  'CCTV Wiring'
]),
(SELECT id FROM categories WHERE name = 'Electrical' LIMIT 1),
unnest(ARRAY[
  'Full home rewiring, conduit fitting, and cable laying',
  'Modular switch, socket, ceiling fan, and exhaust fan installation',
  'Home inverter, UPS, and battery connection and setup',
  'MCB box repair, fuse replacement, and load balancing',
  'Structured cabling for CCTV and network points'
]),
unnest(ARRAY['electrical_services','toggle_on','battery_charging_full','electrical_services_2','cable']),
'instant_book',
'fixed',
'995423'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Wiring & Rewiring');

-- ---- Level-2: Carpentry (already exists — enrich) ----
UPDATE categories SET
  service_mode = 'instant_book',
  default_pricing_type = 'fixed',
  hsn_code = '995424',
  sort_priority = 6
WHERE name = 'Carpentry';

INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, hsn_code)
SELECT unnest(ARRAY[
  'Furniture Assembly & Repair',
  'Door & Window Repair',
  'Custom Wardrobe & Shelf',
  'Bed & Sofa Repair'
]),
(SELECT id FROM categories WHERE name = 'Carpentry' LIMIT 1),
unnest(ARRAY[
  'Flat-pack furniture assembly, chair repair, and table fixing',
  'Door hinge, lock, frame repair, and window fitting',
  'Custom wardrobe, bookshelf, and storage unit fabrication',
  'Bed frame, sofa frame, and recliner repair'
]),
unnest(ARRAY['chair','door_front','wardrobe','weekend']),
'instant_book',
'fixed',
'995424'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Furniture Assembly & Repair');

-- ---- Level-2: Painting ----
INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, requires_site_visit, sort_priority)
SELECT 'Painting',
       (SELECT id FROM categories WHERE name = 'Home Services' AND parent_id IS NULL LIMIT 1),
       'Interior, exterior, and decorative painting services',
       'format_paint', 'quote_request', 'per_sqft', true, 5
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Painting');

INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, hsn_code, requires_site_visit)
SELECT unnest(ARRAY[
  'Interior Wall Painting',
  'Exterior Painting',
  'Waterproofing',
  'Texture & Design Painting',
  'Wood Polish & Painting'
]),
(SELECT id FROM categories WHERE name = 'Painting' LIMIT 1),
unnest(ARRAY[
  'Full room and home interior painting — emulsion, distemper, POP',
  'Exterior wall and terrace painting with weather-resistant coats',
  'Bathroom, terrace, and wall waterproofing treatment',
  'Texture, stone, and stencil decorative wall finish',
  'Wood polish, enamel paint for doors, windows, and furniture'
]),
unnest(ARRAY['format_paint','home_repair_service','water_damage','brush','chair']),
'quote_request',
'per_sqft',
unnest(ARRAY['995425','995425','995425','995425','995425']),
true
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Interior Wall Painting');

-- ---- Level-2: Maid / Domestic Help ----
INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, women_only_option, sort_priority)
SELECT 'Maid & Domestic Help',
       (SELECT id FROM categories WHERE name = 'Home Services' AND parent_id IS NULL LIMIT 1),
       'Daily maid, cook, nanny, and domestic help subscription services',
       'cleaning_services', 'subscription', 'hourly', true, 11
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Maid & Domestic Help');

INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, women_only_option, hsn_code)
SELECT unnest(ARRAY[
  'Daily Maid (Cook + Clean)',
  'Part-time Maid',
  'Full-time Live-in Maid',
  'Cook',
  'Baby Care & Nanny',
  'Elder & Patient Care',
  'Driver'
]),
(SELECT id FROM categories WHERE name = 'Maid & Domestic Help' LIMIT 1),
unnest(ARRAY[
  'Full-time maid for cooking and cleaning duties',
  'Part-time hourly maid for cleaning or cooking',
  'Resident live-in maid for full household management',
  'Dedicated cook — vegetarian, non-veg, or regional cuisines',
  'Newborn, infant, and toddler care and supervision',
  'Companionship and care for elderly or post-surgery patients',
  'Personal or family driver for daily commute or errands'
]),
unnest(ARRAY['cleaning_services','schedule','home','restaurant','child_care','elderly','drive_eta']),
'subscription',
'hourly',
unnest(ARRAY[true,true,true,true,true,true,false]),
'997212'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Daily Maid (Cook + Clean)');

-- ---- Level-2: Interior Design ----
UPDATE categories SET
  service_mode = 'quote_request',
  default_pricing_type = 'custom_quote',
  requires_site_visit = true,
  sort_priority = 12
WHERE name = 'Interior Design';

INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, requires_site_visit, hsn_code)
SELECT unnest(ARRAY[
  'Full Home Interior Design',
  'Modular Kitchen Design',
  'Bedroom Interior Design',
  'False Ceiling & POP',
  'Wallpaper & Wall Décor',
  'Vastu Consultation'
]),
(SELECT id FROM categories WHERE name = 'Interior Design' LIMIT 1),
unnest(ARRAY[
  'End-to-end home interior design, 3D visualisation, and execution',
  'Modular kitchen with laminates, shutters, and accessories',
  'Bedroom furniture, wardrobe, and décor design and fit-out',
  'POP false ceiling, gypsum board, and cove lighting design',
  'Wallpaper installation, wall art, and feature wall design',
  'Vastu shastra consultation and correction recommendations'
]),
unnest(ARRAY['design_services','kitchen','bed','ceiling','wallpaper','star']),
'quote_request',
'custom_quote',
true,
unnest(ARRAY['998311','998311','998311','998311','998311','998311'])
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Full Home Interior Design');

-- ---- Level-2: Renovation & Construction ----
INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, requires_site_visit, sort_priority)
SELECT 'Renovation & Construction',
       (SELECT id FROM categories WHERE name = 'Home Services' AND parent_id IS NULL LIMIT 1),
       'Home renovation, flooring, civil work, and construction services',
       'construction', 'quote_request', 'custom_quote', true, 13
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Renovation & Construction');

INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, requires_site_visit, hsn_code)
SELECT unnest(ARRAY[
  'Home Renovation',
  'Bathroom Renovation',
  'Kitchen Renovation',
  'Flooring',
  'Civil Work & Masonry',
  'Waterproofing & Terrace Work'
]),
(SELECT id FROM categories WHERE name = 'Renovation & Construction' LIMIT 1),
unnest(ARRAY[
  'Full or partial home renovation with design and execution',
  'Complete bathroom makeover — tiles, fixtures, and plumbing',
  'Kitchen renovation — layout, tiles, counters, and cabinets',
  'Tile, marble, vitrified, wooden, and vinyl flooring installation',
  'Brick, concrete, plastering, and masonry construction work',
  'Terrace, basement, and wall waterproofing treatment'
]),
unnest(ARRAY['home_repair_service','bathtub','kitchen','floor','construction','water_damage']),
'quote_request',
'custom_quote',
true,
'995428'
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Home Renovation');

-- ---- Level-2: Other Home Services ----
INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, sort_priority)
SELECT 'Other Home Services',
       (SELECT id FROM categories WHERE name = 'Home Services' AND parent_id IS NULL LIMIT 1),
       'Packers, laundry, gardening, pool, and generator services',
       'more_horiz', 'instant_book', 'fixed', 3
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Other Home Services');

INSERT INTO categories (name, parent_id, description, icon, service_mode, default_pricing_type, requires_site_visit, hsn_code)
SELECT unnest(ARRAY[
  'Packers & Movers',
  'Laundry Service',
  'Gardening & Landscaping',
  'Swimming Pool Maintenance',
  'Generator & DG Set Service'
]),
(SELECT id FROM categories WHERE name = 'Other Home Services' LIMIT 1),
unnest(ARRAY[
  'Local and intercity household moving with packing and unpacking',
  'Pickup and drop laundry — wash, fold, iron, and dry cleaning',
  'Garden design, lawn maintenance, plant care, and landscaping',
  'Pool cleaning, chemical treatment, and pump maintenance',
  'DG set service, alternator repair, and AMC for generators'
]),
unnest(ARRAY['local_shipping','local_laundry_service','yard','pool','power']),
'quote_request',
unnest(ARRAY['custom_quote'::pricing_type,'fixed'::pricing_type,'custom_quote'::pricing_type,'fixed'::pricing_type,'fixed'::pricing_type]),
unnest(ARRAY[true,false,true,false,false]),
unnest(ARRAY['996713','998532','998534','998543','998714'])
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Packers & Movers');

-- ============================================================
-- QUOTE REQUESTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS quote_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id     INTEGER NOT NULL REFERENCES categories(id),
    title           VARCHAR(300) NOT NULL,
    description     TEXT NOT NULL,
    area_sqft       DECIMAL(10,2),               -- for painting/flooring
    budget_min      DECIMAL(12,2),
    budget_max      DECIMAL(12,2),
    location_text   TEXT,                        -- human-readable address
    latitude        DECIMAL(9,6),
    longitude       DECIMAL(9,6),
    pincode         VARCHAR(10),
    preferred_date  DATE,
    preferred_time  VARCHAR(20),                 -- 'morning','afternoon','evening'
    photos          TEXT[],                      -- S3 URLs of requirement photos
    status          quote_status NOT NULL DEFAULT 'open',
    max_bids        SMALLINT NOT NULL DEFAULT 3,
    accepted_bid_id UUID,                        -- set when customer accepts a bid
    expires_at      TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '48 hours',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quote_requests_customer ON quote_requests(customer_id);
CREATE INDEX IF NOT EXISTS idx_quote_requests_category ON quote_requests(category_id);
CREATE INDEX IF NOT EXISTS idx_quote_requests_status ON quote_requests(status);
CREATE INDEX IF NOT EXISTS idx_quote_requests_pincode ON quote_requests(pincode);
CREATE INDEX IF NOT EXISTS idx_quote_requests_created ON quote_requests(created_at DESC);

-- ============================================================
-- QUOTE BIDS TABLE (professionals submit bids)
-- ============================================================

CREATE TABLE IF NOT EXISTS quote_bids (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_request_id    UUID NOT NULL REFERENCES quote_requests(id) ON DELETE CASCADE,
    professional_id     UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
    amount              DECIMAL(12,2) NOT NULL,
    includes_materials  BOOLEAN NOT NULL DEFAULT false,
    estimated_days      SMALLINT,
    message             TEXT,
    site_visit_date     DATE,                     -- proposed site visit
    status              bid_status NOT NULL DEFAULT 'submitted',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (quote_request_id, professional_id)   -- one bid per pro per request
);

CREATE INDEX IF NOT EXISTS idx_quote_bids_request ON quote_bids(quote_request_id);
CREATE INDEX IF NOT EXISTS idx_quote_bids_professional ON quote_bids(professional_id);
CREATE INDEX IF NOT EXISTS idx_quote_bids_status ON quote_bids(status);

-- Link accepted_bid_id FK after bid table exists
ALTER TABLE quote_requests
  ADD CONSTRAINT fk_accepted_bid FOREIGN KEY (accepted_bid_id)
  REFERENCES quote_bids(id) ON DELETE SET NULL
  NOT VALID;

-- ============================================================
-- HOME PROFILES TABLE (customer saves home details)
-- ============================================================

CREATE TABLE IF NOT EXISTS home_profiles (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    nickname        VARCHAR(100) NOT NULL DEFAULT 'My Home',       -- "Main Home", "Office"
    bhk_type        VARCHAR(20),                                    -- '1BHK','2BHK','3BHK','4BHK','Villa'
    area_sqft       DECIMAL(10,2),
    floor_number    SMALLINT,
    building_name   VARCHAR(200),
    address_line1   TEXT,
    address_line2   TEXT,
    locality        VARCHAR(100),
    city            VARCHAR(100),
    pincode         VARCHAR(10),
    state           VARCHAR(100),
    latitude        DECIMAL(9,6),
    longitude       DECIMAL(9,6),
    appliances      JSONB NOT NULL DEFAULT '[]',   -- [{type:'AC', brand:'Daikin', model:'1.5T', year:2021}]
    notes           TEXT,
    is_default      BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_home_profiles_user_default
  ON home_profiles(user_id) WHERE is_default = true;
CREATE INDEX IF NOT EXISTS idx_home_profiles_user ON home_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_home_profiles_pincode ON home_profiles(pincode);

-- ============================================================
-- JOB TRACKING TABLE (real-time GPS tracking during active jobs)
-- ============================================================

CREATE TABLE IF NOT EXISTS job_tracking (
    id              SERIAL PRIMARY KEY,
    booking_id      UUID NOT NULL,                   -- references bookings(id) — not FK to avoid circular dep
    professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
    customer_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status          tracking_status NOT NULL DEFAULT 'assigned',
    latitude        DECIMAL(9,6),
    longitude       DECIMAL(9,6),
    accuracy_meters DECIMAL(8,2),
    heading_degrees DECIMAL(5,2),
    speed_kmh       DECIMAL(6,2),
    eta_minutes     SMALLINT,
    started_at      TIMESTAMPTZ,
    arrived_at      TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    last_location_at TIMESTAMPTZ,
    before_photos   TEXT[],                          -- S3 URLs of before photos
    after_photos    TEXT[],                          -- S3 URLs of after photos
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_job_tracking_booking ON job_tracking(booking_id);
CREATE INDEX IF NOT EXISTS idx_job_tracking_professional ON job_tracking(professional_id);
CREATE INDEX IF NOT EXISTS idx_job_tracking_status ON job_tracking(status);

-- ============================================================
-- AMC PLANS (Annual Maintenance Contracts)
-- ============================================================

CREATE TABLE IF NOT EXISTS amc_plans (
    id              SERIAL PRIMARY KEY,
    category_id     INTEGER NOT NULL REFERENCES categories(id),
    name            VARCHAR(200) NOT NULL,
    description     TEXT,
    appliance_type  VARCHAR(100),                    -- 'AC','RO','Geyser','Washing Machine'
    services_per_year SMALLINT NOT NULL DEFAULT 2,   -- number of visits
    price_annual    DECIMAL(10,2) NOT NULL,
    price_monthly   DECIMAL(10,2),                   -- for monthly billing option
    covers_labour   BOOLEAN NOT NULL DEFAULT true,
    covers_spares   BOOLEAN NOT NULL DEFAULT false,
    max_appliances  SMALLINT NOT NULL DEFAULT 1,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_amc_plans_category ON amc_plans(category_id);
CREATE INDEX IF NOT EXISTS idx_amc_plans_active ON amc_plans(is_active) WHERE is_active = true;

-- Customer AMC subscriptions
CREATE TABLE IF NOT EXISTS amc_subscriptions (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amc_plan_id     INTEGER NOT NULL REFERENCES amc_plans(id),
    home_profile_id INTEGER REFERENCES home_profiles(id) ON DELETE SET NULL,
    appliance_details JSONB NOT NULL DEFAULT '{}',   -- {brand, model, year}
    start_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date        DATE NOT NULL,
    next_service_date DATE,
    services_used   SMALLINT NOT NULL DEFAULT 0,
    status          VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','expired','cancelled')),
    payment_mode    VARCHAR(20) NOT NULL DEFAULT 'annual' CHECK (payment_mode IN ('annual','monthly')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_amc_subs_user ON amc_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_amc_subs_plan ON amc_subscriptions(amc_plan_id);
CREATE INDEX IF NOT EXISTS idx_amc_subs_next_service ON amc_subscriptions(next_service_date);

-- ============================================================
-- BUNDLE PACKAGES
-- ============================================================

CREATE TABLE IF NOT EXISTS bundle_packages (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(200) NOT NULL,
    description     TEXT,
    city            VARCHAR(100),                    -- NULL = all cities
    categories      INTEGER[],                       -- category IDs included
    original_price  DECIMAL(10,2) NOT NULL,
    bundle_price    DECIMAL(10,2) NOT NULL,
    validity_days   SMALLINT NOT NULL DEFAULT 90,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SEED: AMC Plans for common appliances
-- ============================================================

INSERT INTO amc_plans (category_id, name, description, appliance_type, services_per_year, price_annual, price_monthly, covers_labour, covers_spares)
SELECT
  (SELECT id FROM categories WHERE name = 'AC Repair & Servicing' LIMIT 1),
  unnest(ARRAY['AC Basic AMC', 'AC Comprehensive AMC']),
  unnest(ARRAY[
    '2 services per year — cleaning, gas top-up check, and labour',
    '4 services per year — cleaning, gas top-up, and up to ₹2000 spare parts'
  ]),
  'AC',
  unnest(ARRAY[2::SMALLINT, 4::SMALLINT]),
  unnest(ARRAY[1499.00, 2999.00]),
  unnest(ARRAY[NULL::DECIMAL, 299.00]),
  true,
  unnest(ARRAY[false, true])
WHERE EXISTS (SELECT 1 FROM categories WHERE name = 'AC Repair & Servicing')
  AND NOT EXISTS (SELECT 1 FROM amc_plans WHERE appliance_type = 'AC');

INSERT INTO amc_plans (category_id, name, description, appliance_type, services_per_year, price_annual, covers_labour, covers_spares)
SELECT
  (SELECT id FROM categories WHERE name = 'Water Purifier / RO Service' LIMIT 1),
  'RO Purifier AMC',
  '3 services per year — filter change, membrane check, and sanitization',
  'RO Purifier',
  3,
  1999.00,
  true,
  false
WHERE EXISTS (SELECT 1 FROM categories WHERE name = 'Water Purifier / RO Service')
  AND NOT EXISTS (SELECT 1 FROM amc_plans WHERE appliance_type = 'RO Purifier');

-- ============================================================
-- SEED: Bundle Packages
-- ============================================================

INSERT INTO bundle_packages (name, description, original_price, bundle_price, validity_days, sort_order)
SELECT unnest(ARRAY[
  'Home Care Essential Pack',
  'New Home Setup Pack',
  'Summer Home Care Pack'
]),
unnest(ARRAY[
  'AC Service + Deep Home Cleaning + Pest Control — quarterly bundle',
  'Painting estimate + Carpentry + Electrical checkup for new homes',
  'AC service + Fan cleaning + Cooler servicing — pre-summer combo'
]),
unnest(ARRAY[3497.00, 2999.00, 1999.00]),
unnest(ARRAY[2499.00, 1999.00, 1299.00]),
unnest(ARRAY[90::SMALLINT, 60::SMALLINT, 60::SMALLINT]),
unnest(ARRAY[1,2,3])
WHERE NOT EXISTS (SELECT 1 FROM bundle_packages WHERE name = 'Home Care Essential Pack');

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_categories_service_mode ON categories(service_mode);
CREATE INDEX IF NOT EXISTS idx_categories_parent_sort ON categories(parent_id, sort_priority DESC);
CREATE INDEX IF NOT EXISTS idx_prof_services_pricing_type ON professional_services(pricing_type);

COMMIT;
