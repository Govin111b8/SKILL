-- Migration 018: Global Trusted Services Ecosystem
-- Adds: subscription engine, country tenants, family/household system, service engines
-- Part of the "Trusted Operating System for Local Services Worldwide" evolution

BEGIN;

-- ============================================================
-- ENUM TYPES
-- ============================================================

CREATE TYPE service_engine AS ENUM ('booking', 'subscription', 'marketplace');
CREATE TYPE subscription_frequency AS ENUM ('daily', 'weekly', 'biweekly', 'monthly', 'quarterly');
CREATE TYPE subscription_status AS ENUM ('active', 'paused', 'cancelled', 'expired');
CREATE TYPE household_member_role AS ENUM ('owner', 'adult', 'child', 'caretaker');
CREATE TYPE country_status AS ENUM ('active', 'onboarding', 'planned', 'suspended');
CREATE TYPE tenant_type AS ENUM ('company_operated', 'franchise', 'partner');

-- ============================================================
-- COUNTRY TENANTS — Multi-tenant global architecture
-- ============================================================

CREATE TABLE country_tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code VARCHAR(3) NOT NULL UNIQUE,       -- ISO 3166-1 alpha-2/3
    country_name VARCHAR(100) NOT NULL,
    tenant_type tenant_type NOT NULL DEFAULT 'company_operated',
    status country_status NOT NULL DEFAULT 'planned',
    -- Localization
    default_language VARCHAR(10) NOT NULL DEFAULT 'en',
    supported_languages TEXT[] NOT NULL DEFAULT ARRAY['en'],
    currency_code VARCHAR(3) NOT NULL DEFAULT 'INR',
    currency_symbol VARCHAR(5) NOT NULL DEFAULT '₹',
    timezone VARCHAR(50) NOT NULL DEFAULT 'Asia/Kolkata',
    -- Operations
    payment_gateways TEXT[] NOT NULL DEFAULT ARRAY['razorpay'],
    commission_rate DECIMAL(5,2) NOT NULL DEFAULT 15.00,
    tax_rate DECIMAL(5,2) NOT NULL DEFAULT 18.00,
    tax_name VARCHAR(50) NOT NULL DEFAULT 'GST',
    payout_cycle_days INTEGER NOT NULL DEFAULT 7,
    -- Verification requirements
    kyc_requirements JSONB NOT NULL DEFAULT '{"basic": ["phone", "email"], "identity": ["government_id"], "professional": ["certification"]}',
    -- Service configuration
    enabled_engines service_engine[] NOT NULL DEFAULT ARRAY['booking', 'subscription', 'marketplace']::service_engine[],
    enabled_categories INTEGER[] NOT NULL DEFAULT '{}',
    -- Partner info
    partner_name VARCHAR(255),
    partner_contact_email VARCHAR(255),
    partner_contract_start DATE,
    partner_contract_end DATE,
    -- Metadata
    operational_cities TEXT[] NOT NULL DEFAULT '{}',
    launch_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SERVICE ENGINE CLASSIFICATION — Tag categories with their engine
-- ============================================================

ALTER TABLE categories ADD COLUMN IF NOT EXISTS engine service_engine DEFAULT 'booking';
ALTER TABLE categories ADD COLUMN IF NOT EXISTS is_subscription_eligible BOOLEAN DEFAULT FALSE;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS country_availability TEXT[] DEFAULT ARRAY['IN'];

-- ============================================================
-- SUBSCRIPTION ENGINE — Recurring household services
-- ============================================================

CREATE TABLE service_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    professional_id UUID REFERENCES professionals(id) ON DELETE SET NULL,
    category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    service_id UUID,  -- references professional_services if applicable
    -- Subscription details
    title VARCHAR(255) NOT NULL,
    description TEXT,
    frequency subscription_frequency NOT NULL,
    preferred_days TEXT[] NOT NULL DEFAULT '{}',     -- e.g. ['monday','wednesday','friday']
    preferred_time_start TIME,
    preferred_time_end TIME,
    -- Pricing
    price_per_occurrence DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    -- Status
    status subscription_status NOT NULL DEFAULT 'active',
    pause_reason TEXT,
    paused_at TIMESTAMPTZ,
    resume_date DATE,
    -- Scheduling
    next_occurrence DATE,
    last_occurrence DATE,
    occurrences_completed INTEGER NOT NULL DEFAULT 0,
    -- Auto-renew
    auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    -- Family sharing
    household_id UUID,
    -- Address
    service_address TEXT,
    service_lat DECIMAL(9,6),
    service_lng DECIMAL(9,6),
    -- Metadata
    notes TEXT,
    country_code VARCHAR(3) NOT NULL DEFAULT 'IN',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Subscription occurrence log (each delivery/visit)
CREATE TABLE subscription_occurrences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID NOT NULL REFERENCES service_subscriptions(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    scheduled_time TIME,
    actual_date DATE,
    actual_time TIME,
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled',  -- scheduled, completed, missed, cancelled, rescheduled
    professional_id UUID REFERENCES professionals(id) ON DELETE SET NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    notes TEXT,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- FAMILY & HOUSEHOLD SYSTEM
-- ============================================================

CREATE TABLE households (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL DEFAULT 'My Home',
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- Address
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country_code VARCHAR(3) NOT NULL DEFAULT 'IN',
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    -- Household info
    property_type VARCHAR(50),  -- apartment, house, villa, office
    size_sqft INTEGER,
    -- Preferences
    preferred_language VARCHAR(10) DEFAULT 'en',
    preferred_providers UUID[] DEFAULT '{}',
    -- Pets & appliances (for service matching)
    pets JSONB DEFAULT '[]',
    appliances JSONB DEFAULT '[]',
    -- Schedules
    recurring_schedules JSONB DEFAULT '[]',
    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE household_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    role household_member_role NOT NULL DEFAULT 'adult',
    phone VARCHAR(20),
    email VARCHAR(255),
    can_book BOOLEAN NOT NULL DEFAULT TRUE,
    can_manage_subscriptions BOOLEAN NOT NULL DEFAULT FALSE,
    is_emergency_contact BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Link subscriptions to households
ALTER TABLE service_subscriptions 
    ADD CONSTRAINT fk_subscription_household 
    FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE SET NULL;

-- ============================================================
-- MARKETPLACE ENGINE ENHANCEMENTS — Quote/project workflow
-- ============================================================

CREATE TABLE marketplace_proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(id),
    -- Project details
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    budget_min DECIMAL(10,2),
    budget_max DECIMAL(10,2),
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    -- Timeline
    estimated_duration_days INTEGER,
    start_date DATE,
    -- Status
    status VARCHAR(30) NOT NULL DEFAULT 'pending',  -- pending, quoted, negotiating, accepted, in_progress, completed, cancelled
    -- Quote from professional
    quoted_amount DECIMAL(10,2),
    quote_notes TEXT,
    quoted_at TIMESTAMPTZ,
    -- Milestones
    milestones JSONB DEFAULT '[]',
    -- Metadata
    attachments TEXT[] DEFAULT '{}',
    country_code VARCHAR(3) NOT NULL DEFAULT 'IN',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PROVIDER BUSINESS OS ENHANCEMENTS
-- ============================================================

-- Provider inventory/equipment tracking
CREATE TABLE provider_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
    item_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_cost DECIMAL(10,2),
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    low_stock_threshold INTEGER DEFAULT 5,
    category VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Provider CRM — customer relationship tracking
CREATE TABLE provider_customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- Relationship data
    first_booking_date DATE,
    last_booking_date DATE,
    total_bookings INTEGER NOT NULL DEFAULT 0,
    total_revenue DECIMAL(12,2) NOT NULL DEFAULT 0,
    -- Tags & notes
    tags TEXT[] DEFAULT '{}',
    notes TEXT,
    is_vip BOOLEAN NOT NULL DEFAULT FALSE,
    -- Preferences
    preferred_time TEXT,
    special_instructions TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(professional_id, customer_id)
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_country_tenants_code ON country_tenants(country_code);
CREATE INDEX idx_country_tenants_status ON country_tenants(status);

CREATE INDEX idx_service_subscriptions_customer ON service_subscriptions(customer_id);
CREATE INDEX idx_service_subscriptions_professional ON service_subscriptions(professional_id);
CREATE INDEX idx_service_subscriptions_status ON service_subscriptions(status);
CREATE INDEX idx_service_subscriptions_next ON service_subscriptions(next_occurrence) WHERE status = 'active';
CREATE INDEX idx_service_subscriptions_household ON service_subscriptions(household_id);

CREATE INDEX idx_subscription_occurrences_sub ON subscription_occurrences(subscription_id);
CREATE INDEX idx_subscription_occurrences_date ON subscription_occurrences(scheduled_date);

CREATE INDEX idx_households_owner ON households(owner_id);
CREATE INDEX idx_household_members_household ON household_members(household_id);
CREATE INDEX idx_household_members_user ON household_members(user_id);

CREATE INDEX idx_marketplace_proposals_customer ON marketplace_proposals(customer_id);
CREATE INDEX idx_marketplace_proposals_professional ON marketplace_proposals(professional_id);
CREATE INDEX idx_marketplace_proposals_status ON marketplace_proposals(status);

CREATE INDEX idx_provider_inventory_professional ON provider_inventory(professional_id);
CREATE INDEX idx_provider_customers_professional ON provider_customers(professional_id);
CREATE INDEX idx_provider_customers_customer ON provider_customers(customer_id);

COMMIT;
