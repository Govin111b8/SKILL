-- ============================================================
-- Migration 012: Schema Completion per PRD + Tech Supplement
-- ============================================================
-- Adds all missing tables identified in the deep-dive audit:
--   service_areas, certifications, subscriptions, payout_log,
--   gst_invoices, professional_hours, device_tokens
-- Also adds missing columns to existing tables.
-- ============================================================

-- ── ENUMS ──────────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE subscription_status AS ENUM ('active', 'expired', 'cancelled', 'grace');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE invoice_type AS ENUM ('b2b', 'b2c');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE device_platform AS ENUM ('ios', 'android', 'web');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── 1. service_areas ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS service_areas (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id UUID          NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  city            VARCHAR(100)  NOT NULL,
  zone_name       VARCHAR(150),
  lat             DECIMAL(9,6),
  lng             DECIMAL(10,6),
  radius_km       SMALLINT      DEFAULT 10,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_service_areas_professional ON service_areas(professional_id);
CREATE INDEX IF NOT EXISTS idx_service_areas_city ON service_areas(city);

-- ── 2. certifications ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS certifications (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id UUID          NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  title           VARCHAR(255)  NOT NULL,
  doc_url         TEXT,
  issued_by       VARCHAR(255),
  issue_date      DATE,
  expiry_date     DATE,
  is_verified     BOOLEAN       NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_certifications_professional ON certifications(professional_id);

-- ── 3. subscriptions (full lifecycle table) ────────────────
CREATE TABLE IF NOT EXISTS subscriptions (
  id               UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id  UUID                NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  plan             subscription_plan   NOT NULL,
  amount_paid      DECIMAL(10,2)       NOT NULL,
  currency         VARCHAR(3)          NOT NULL DEFAULT 'INR',
  payment_id       VARCHAR(255),
  razorpay_order_id VARCHAR(255),
  start_date       TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
  end_date         TIMESTAMPTZ         NOT NULL,
  grace_period_end TIMESTAMPTZ,
  status           subscription_status NOT NULL DEFAULT 'active',
  gstin            VARCHAR(15),
  created_at       TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_subscriptions_professional ON subscriptions(professional_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_end_date ON subscriptions(end_date);

-- ── 4. payout_log (GST audit trail) ───────────────────────
CREATE TABLE IF NOT EXISTS payout_log (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id UUID          NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  subscription_id UUID          REFERENCES subscriptions(id),
  amount          DECIMAL(10,2) NOT NULL,
  currency        VARCHAR(3)    NOT NULL DEFAULT 'INR',
  gateway_ref     VARCHAR(255),
  status          VARCHAR(50)   NOT NULL DEFAULT 'completed',
  notes           TEXT,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_payout_log_professional ON payout_log(professional_id);

-- ── 5. gst_invoices ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS gst_invoices (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID          NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  professional_id UUID          NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  invoice_number  VARCHAR(50)   NOT NULL UNIQUE,
  invoice_type    invoice_type  NOT NULL DEFAULT 'b2c',
  gstin           VARCHAR(15),
  amount          DECIMAL(10,2) NOT NULL,
  cgst            DECIMAL(10,2) NOT NULL DEFAULT 0,
  sgst            DECIMAL(10,2) NOT NULL DEFAULT 0,
  igst            DECIMAL(10,2) NOT NULL DEFAULT 0,
  total           DECIMAL(10,2) NOT NULL,
  pdf_url         TEXT,
  issued_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_gst_invoices_professional ON gst_invoices(professional_id);
CREATE INDEX IF NOT EXISTS idx_gst_invoices_subscription ON gst_invoices(subscription_id);

-- ── 6. professional_hours (weekly availability schedule) ───
CREATE TABLE IF NOT EXISTS professional_hours (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id UUID          NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  day_of_week     SMALLINT      NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sun, 6=Sat
  open_time       TIME,
  close_time      TIME,
  is_closed       BOOLEAN       NOT NULL DEFAULT FALSE,
  UNIQUE (professional_id, day_of_week)
);
CREATE INDEX IF NOT EXISTS idx_professional_hours_professional ON professional_hours(professional_id);

-- ── 7. device_tokens (FCM push notification tokens) ───────
CREATE TABLE IF NOT EXISTS device_tokens (
  id           UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token        TEXT            NOT NULL,
  platform     device_platform NOT NULL,
  is_active    BOOLEAN         NOT NULL DEFAULT TRUE,
  last_used_at TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
  created_at   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, token)
);
CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_active ON device_tokens(user_id, is_active);

-- ── Missing columns on existing tables ────────────────────

-- users
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10) DEFAULT 'en';
ALTER TABLE users ADD COLUMN IF NOT EXISTS timezone VARCHAR(50) DEFAULT 'Asia/Kolkata';
ALTER TABLE users ADD COLUMN IF NOT EXISTS acquisition_source VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- professionals
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS gender VARCHAR(20);
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS service_radius_km SMALLINT DEFAULT 25;
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ;
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS gstin VARCHAR(15);

-- verifications (KYC) — add face match score column
ALTER TABLE verifications ADD COLUMN IF NOT EXISTS face_match_score SMALLINT;
ALTER TABLE verifications ADD COLUMN IF NOT EXISTS face_match_provider VARCHAR(50);

-- reviews — add moderation and editing support
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS moderation_status VARCHAR(30) DEFAULT 'approved';
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT FALSE;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS edited_at TIMESTAMPTZ;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS helpful_count INTEGER DEFAULT 0;

-- search_history (already created in migration 008, ensure it exists)
CREATE TABLE IF NOT EXISTS search_history (
  id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  query_text  VARCHAR(255)  NOT NULL,
  filters_json JSONB,
  result_count INTEGER,
  created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_search_history_user ON search_history(user_id);
CREATE INDEX IF NOT EXISTS idx_search_history_created ON search_history(created_at);

-- ── search_index materialised view ────────────────────────
-- Refreshed nightly (or on demand after profile update)
CREATE MATERIALIZED VIEW IF NOT EXISTS search_index AS
  SELECT
    p.id                                                          AS professional_id,
    u.name,
    p.headline,
    p.bio,
    p.availability_status,
    p.subscription_plan,
    p.reputation_score,
    p.avg_rating,
    COALESCE((
      SELECT COUNT(*) FROM reviews r WHERE r.professional_id = p.id
    ), 0)                                                         AS review_count,
    p.completed_jobs,
    p.latitude,
    p.longitude,
    p.updated_at,
    u.government_id_verified,
    -- Profile completeness score (0–100)
    (
      CASE WHEN p.headline IS NOT NULL AND p.headline <> '' THEN 10 ELSE 0 END +
      CASE WHEN p.bio IS NOT NULL AND p.bio <> '' THEN 10 ELSE 0 END +
      CASE WHEN p.latitude IS NOT NULL THEN 10 ELSE 0 END +
      CASE WHEN p.cover_image_url IS NOT NULL THEN 5 ELSE 0 END +
      CASE WHEN u.avatar_url IS NOT NULL THEN 5 ELSE 0 END +
      CASE WHEN u.government_id_verified THEN 20 ELSE 0 END +
      CASE WHEN (SELECT COUNT(*) FROM portfolio_items pi WHERE pi.professional_id = p.id) > 0 THEN 20 ELSE 0 END +
      CASE WHEN (SELECT COUNT(*) FROM certifications c WHERE c.professional_id = p.id) > 0 THEN 10 ELSE 0 END +
      CASE WHEN (SELECT COUNT(*) FROM professional_categories pc WHERE pc.professional_id = p.id) > 0 THEN 10 ELSE 0 END
    )                                                             AS profile_completeness,
    to_tsvector('english',
      COALESCE(u.name, '') || ' ' ||
      COALESCE(p.headline, '') || ' ' ||
      COALESCE(p.bio, '')
    )                                                             AS tsv_content
  FROM professionals p
  JOIN users u ON u.id = p.user_id
  WHERE u.is_active = TRUE
WITH DATA;

CREATE UNIQUE INDEX IF NOT EXISTS idx_search_index_professional ON search_index(professional_id);
CREATE INDEX IF NOT EXISTS idx_search_index_tsv ON search_index USING gin(tsv_content);
CREATE INDEX IF NOT EXISTS idx_search_index_reputation ON search_index(reputation_score DESC);
CREATE INDEX IF NOT EXISTS idx_search_index_completeness ON search_index(profile_completeness DESC);
