-- Migration 021: Trust Levels (Bronze/Silver/Gold/Platinum) + Neighborhood Trust
-- Implements tiered trust system and locality-based trust scoring

BEGIN;

-- ============================================================
-- TRUST LEVELS — Tiered provider ranking
-- ============================================================

CREATE TYPE trust_level AS ENUM ('bronze', 'silver', 'gold', 'platinum');

-- Add trust_level column to professionals
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS trust_level trust_level DEFAULT 'bronze';
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS trust_score DECIMAL(5,2) DEFAULT 0.00;
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS trust_calculated_at TIMESTAMPTZ;

-- Trust level thresholds configuration
CREATE TABLE trust_level_config (
    id SERIAL PRIMARY KEY,
    level trust_level NOT NULL UNIQUE,
    min_score DECIMAL(5,2) NOT NULL,
    min_completed_jobs INTEGER NOT NULL DEFAULT 0,
    min_rating DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    min_repeat_rate DECIMAL(5,2) NOT NULL DEFAULT 0.00,  -- percentage
    max_cancellation_rate DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    benefits JSONB NOT NULL DEFAULT '{}',
    badge_color VARCHAR(7) NOT NULL DEFAULT '#CD7F32',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO trust_level_config (level, min_score, min_completed_jobs, min_rating, min_repeat_rate, max_cancellation_rate, benefits, badge_color) VALUES
('bronze', 0, 0, 0.00, 0.00, 100.00, '{"verified_badge": true}', '#CD7F32'),
('silver', 30, 10, 3.50, 10.00, 30.00, '{"verified_badge": true, "priority_support": true, "featured_in_area": true}', '#C0C0C0'),
('gold', 60, 50, 4.20, 30.00, 15.00, '{"verified_badge": true, "priority_support": true, "featured_in_area": true, "premium_leads": true, "reduced_commission": true}', '#FFD700'),
('platinum', 85, 100, 4.70, 50.00, 5.00, '{"verified_badge": true, "priority_support": true, "featured_in_area": true, "premium_leads": true, "reduced_commission": true, "dedicated_manager": true, "early_payouts": true}', '#E5E4E2')
ON CONFLICT (level) DO NOTHING;

-- ============================================================
-- NEIGHBORHOOD TRUST — Locality-based trust scoring
-- ============================================================

CREATE TABLE neighborhood_trust (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
    -- Location context
    locality VARCHAR(255),         -- e.g. "Gachibowli", "Banjara Hills"
    city VARCHAR(100),
    pincode VARCHAR(10),
    -- Trust metrics for this neighborhood
    completed_jobs INTEGER NOT NULL DEFAULT 0,
    repeat_customers INTEGER NOT NULL DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_customers INTEGER NOT NULL DEFAULT 0,
    -- Community endorsements
    community_endorsements INTEGER NOT NULL DEFAULT 0,
    neighbor_bookings INTEGER NOT NULL DEFAULT 0,   -- bookings from same apartment/society
    -- Calculated trust
    neighborhood_score DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    -- Metadata
    last_calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(professional_id, locality, city)
);

CREATE INDEX idx_neighborhood_trust_locality ON neighborhood_trust(locality, city);
CREATE INDEX idx_neighborhood_trust_professional ON neighborhood_trust(professional_id);
CREATE INDEX idx_neighborhood_trust_score ON neighborhood_trust(neighborhood_score DESC);

-- ============================================================
-- TRUST HISTORY — Track trust level changes
-- ============================================================

CREATE TABLE trust_level_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
    previous_level trust_level,
    new_level trust_level NOT NULL,
    previous_score DECIMAL(5,2),
    new_score DECIMAL(5,2) NOT NULL,
    reason TEXT,
    calculated_factors JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trust_history_professional ON trust_level_history(professional_id, created_at DESC);

COMMIT;
