-- Migration 017: Professional Services Catalog
-- Enables professionals to define specific services with pricing and duration
-- Supports service-level search and booking

BEGIN;

-- Professional services: individual services offered by a professional
CREATE TABLE IF NOT EXISTS professional_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price_min DECIMAL(10,2),
    price_max DECIMAL(10,2),
    duration_minutes INTEGER,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prof_services_professional ON professional_services(professional_id);
CREATE INDEX IF NOT EXISTS idx_prof_services_category ON professional_services(category_id);
CREATE INDEX IF NOT EXISTS idx_prof_services_name ON professional_services USING gin(to_tsvector('english', name));
CREATE INDEX IF NOT EXISTS idx_prof_services_active ON professional_services(is_active) WHERE is_active = true;

COMMIT;
