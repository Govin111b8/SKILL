BEGIN;

-- Migration: Add provider_type to professionals table
-- Supports both individual freelancers and organization/company profiles

-- Add provider_type enum
CREATE TYPE provider_type AS ENUM ('individual', 'organization');

-- Add provider_type column to professionals table (default to individual for existing records)
ALTER TABLE professionals
  ADD COLUMN provider_type provider_type NOT NULL DEFAULT 'individual';

-- Add organization-specific fields
ALTER TABLE professionals
  ADD COLUMN company_name VARCHAR(255),
  ADD COLUMN company_registration_number VARCHAR(100),
  ADD COLUMN team_size INTEGER,
  ADD COLUMN services_offered TEXT[];

-- Index for filtering by provider_type
CREATE INDEX idx_professionals_provider_type ON professionals(provider_type);

COMMIT;
