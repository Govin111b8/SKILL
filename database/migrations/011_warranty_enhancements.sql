-- Migration 011: Warranty enhancements and emergency table fixes
-- Adds 'resolved' status to warranty flow so professionals can close out warranty claims

-- Extend warranty_status enum with 'resolved'
DO $$ BEGIN
  ALTER TYPE warranty_status ADD VALUE IF NOT EXISTS 'resolved';
EXCEPTION WHEN others THEN NULL; END $$;

-- Index to make professional warranty claim lookups fast
CREATE INDEX IF NOT EXISTS idx_warranties_pro_status
  ON service_warranties(professional_id, status);
