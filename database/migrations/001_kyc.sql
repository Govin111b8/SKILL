-- ============================================================
-- KYC / Identity Verification — production migration
-- Supports multiple ID types per user with role-aware validation.
-- Idempotent: safe to run multiple times.
-- ============================================================

-- Document type enum (Indian-first, extensible)
DO $$ BEGIN
  CREATE TYPE kyc_doc_type AS ENUM (
    -- Customer / individual
    'aadhaar',          -- 12-digit Aadhaar
    'pan',              -- PAN card (10 char)
    'voter_id',         -- EPIC number
    'driving_license',  -- DL number
    'passport',         -- Passport number
    'uan',              -- Universal Account Number (PF)
    'pf_number',        -- Provident Fund member ID
    -- Business / employer
    'gstin',            -- 15-char GST number
    'cin',              -- Company Identification Number (21 char)
    'tan',              -- Tax Deduction Account Number (10 char)
    -- Professional credentials
    'icai_membership',  -- Chartered Accountant (ICAI) membership number
    'bar_council',      -- Lawyer / Advocate Bar Council ID
    'mci_registration', -- Doctor / MCI registration
    'coa_registration', -- Architect / Council of Architecture
    'iei_membership',   -- Engineer / IEI membership
    'fssai',            -- Food business license
    'shop_act',         -- Shop & Establishment Act license
    'msme_udyam',       -- MSME/Udyam registration
    'trade_license',    -- Municipal trade license
    'electrical_license', -- State electrical contractor license
    'plumbing_license',   -- State plumbing license
    'iso_cert',         -- ISO certification
    'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE kyc_status AS ENUM ('pending', 'verified', 'rejected', 'expired');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Main verifications table — one user can have many KYC docs
CREATE TABLE IF NOT EXISTS verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    doc_type kyc_doc_type NOT NULL,
    doc_number VARCHAR(64) NOT NULL,         -- raw id (will be masked on display)
    doc_number_hash VARCHAR(128) NOT NULL,   -- SHA-256 hash for dedupe across users
    holder_name VARCHAR(255),                -- name as on document
    issuing_authority VARCHAR(255),          -- e.g. UIDAI, ICAI, GST Dept
    issue_date DATE,
    expiry_date DATE,
    document_url TEXT,                       -- optional uploaded scan
    selfie_url TEXT,                         -- liveness selfie
    status kyc_status NOT NULL DEFAULT 'pending',
    verification_method VARCHAR(50),         -- 'manual' | 'digilocker' | 'gstn_api' | 'icai_api'
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ,
    rejection_reason TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, doc_type)
);

CREATE INDEX IF NOT EXISTS idx_verifications_user ON verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_verifications_status ON verifications(status);
CREATE INDEX IF NOT EXISTS idx_verifications_doc_hash ON verifications(doc_number_hash);
CREATE INDEX IF NOT EXISTS idx_verifications_doc_type ON verifications(doc_type);

-- Add aggregate flags to users for fast read paths
ALTER TABLE users ADD COLUMN IF NOT EXISTS kyc_level SMALLINT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS kyc_completed_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS trust_score SMALLINT NOT NULL DEFAULT 0;
COMMENT ON COLUMN users.kyc_level IS '0=none, 1=phone+email, 2=govt_id, 3=full(id+selfie+credential)';

-- Audit trail
CREATE TABLE IF NOT EXISTS verification_audit (
    id BIGSERIAL PRIMARY KEY,
    verification_id UUID REFERENCES verifications(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,             -- submitted | reviewed | approved | rejected | expired
    note TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_verification_audit_v ON verification_audit(verification_id);

-- Trigger to keep updated_at fresh
CREATE OR REPLACE FUNCTION touch_updated_at() RETURNS trigger AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS verifications_touch ON verifications;
CREATE TRIGGER verifications_touch
  BEFORE UPDATE ON verifications
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- View for non-PII summary
CREATE OR REPLACE VIEW v_user_kyc_summary AS
SELECT
  u.id AS user_id,
  u.kyc_level,
  u.trust_score,
  COUNT(v.id) FILTER (WHERE v.status = 'verified') AS verified_docs,
  COUNT(v.id) FILTER (WHERE v.status = 'pending')  AS pending_docs,
  ARRAY_AGG(DISTINCT v.doc_type) FILTER (WHERE v.status = 'verified') AS verified_types
FROM users u
LEFT JOIN verifications v ON v.user_id = u.id
GROUP BY u.id;
