-- ============================================================
-- Migration 013: Gap Completion — All missing tables & columns
-- from Tech Supplement §A audit
-- ============================================================

-- ── ENUMs ──────────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE category_request_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE ab_experiment_status AS ENUM ('draft', 'running', 'completed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE language_proficiency AS ENUM ('basic', 'fluent', 'native');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── 1. blocked_users ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS blocked_users (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id  UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_id  UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason      TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(blocker_id, blocked_id)
);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker ON blocked_users(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked ON blocked_users(blocked_id);

-- ── 2. featured_slots ──────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE featured_slot_type AS ENUM ('home', 'category', 'search');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS featured_slots (
  id              UUID               PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id UUID               NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  slot_type       featured_slot_type NOT NULL DEFAULT 'home',
  city            VARCHAR(100),
  category_id     INTEGER            REFERENCES categories(id) ON DELETE SET NULL,
  start_date      DATE               NOT NULL,
  end_date        DATE               NOT NULL,
  status          VARCHAR(20)        NOT NULL DEFAULT 'active',
  created_by      UUID               REFERENCES users(id),
  created_at      TIMESTAMPTZ        NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ        NOT NULL DEFAULT NOW(),
  CONSTRAINT featured_slots_dates CHECK (end_date >= start_date)
);
CREATE INDEX IF NOT EXISTS idx_featured_slots_professional ON featured_slots(professional_id);
CREATE INDEX IF NOT EXISTS idx_featured_slots_active ON featured_slots(slot_type, city, start_date, end_date) WHERE status = 'active';

-- ── 3. category_requests ───────────────────────────────────
CREATE TABLE IF NOT EXISTS category_requests (
  id             UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID                    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_name  VARCHAR(150)            NOT NULL,
  description    TEXT,
  parent_id      INTEGER                 REFERENCES categories(id),
  status         category_request_status NOT NULL DEFAULT 'pending',
  admin_note     TEXT,
  reviewed_by    UUID                    REFERENCES users(id),
  reviewed_at    TIMESTAMPTZ,
  created_at     TIMESTAMPTZ             NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_category_requests_status ON category_requests(status);
CREATE INDEX IF NOT EXISTS idx_category_requests_user ON category_requests(user_id);

-- ── 4. professional_languages ──────────────────────────────
CREATE TABLE IF NOT EXISTS professional_languages (
  professional_id UUID                PRIMARY KEY REFERENCES professionals(id) ON DELETE CASCADE,
  language_codes  TEXT[]              NOT NULL DEFAULT '{}',
  updated_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);

-- ── 5. soft_deletes_log ────────────────────────────────────
CREATE TABLE IF NOT EXISTS soft_deletes_log (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type  VARCHAR(50) NOT NULL,
  entity_id    UUID        NOT NULL,
  deleted_by   UUID        REFERENCES users(id),
  reason       TEXT,
  deleted_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  can_restore  BOOLEAN     NOT NULL DEFAULT TRUE
);
CREATE INDEX IF NOT EXISTS idx_soft_deletes_log_entity ON soft_deletes_log(entity_type, entity_id);

-- ── 6. ab_experiments ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS ab_experiments (
  id          UUID                 PRIMARY KEY DEFAULT gen_random_uuid(),
  name        VARCHAR(100)         NOT NULL UNIQUE,
  description TEXT,
  variant_a   JSONB                NOT NULL DEFAULT '{}',
  variant_b   JSONB                NOT NULL DEFAULT '{}',
  traffic_pct SMALLINT             NOT NULL DEFAULT 50,
  metric      VARCHAR(100),
  status      ab_experiment_status NOT NULL DEFAULT 'draft',
  winner      CHAR(1),
  start_date  DATE,
  end_date    DATE,
  created_by  UUID                 REFERENCES users(id),
  created_at  TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ          NOT NULL DEFAULT NOW()
);

-- ── 7. waitlist ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS waitlist (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email            VARCHAR(255),
  phone            VARCHAR(20),
  city             VARCHAR(100) NOT NULL,
  service_interest TEXT,
  source           VARCHAR(50),
  notified_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT waitlist_contact CHECK (email IS NOT NULL OR phone IS NOT NULL)
);
CREATE INDEX IF NOT EXISTS idx_waitlist_city ON waitlist(city);
CREATE INDEX IF NOT EXISTS idx_waitlist_email ON waitlist(email) WHERE email IS NOT NULL;

-- ── 8. trust_index column on professionals ─────────────────
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS trust_index DECIMAL(5,2) DEFAULT 0.00;
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS repeat_customer_rate DECIMAL(5,2) DEFAULT 0.00;
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS response_rate DECIMAL(5,2) DEFAULT 0.00;
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS recent_rating DECIMAL(3,2) DEFAULT 0.00;

-- ── 9. notification_preferences on users ──────────────────
ALTER TABLE users ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{
  "security": true,
  "verification": true,
  "complaint": true,
  "subscription": true,
  "profile_activity": true,
  "quote_requests": true,
  "marketing": false
}'::jsonb;

-- ── 10. referral_code_used on users ───────────────────────
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_code_used VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS skillpoints_balance INTEGER NOT NULL DEFAULT 0;

-- ── 11. missing columns on professionals ──────────────────
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS languages TEXT[] DEFAULT '{}';

-- ── 12. appeals table ─────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE appeal_status AS ENUM ('pending', 'approved', 'rejected', 'withdrawn');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS appeals (
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  complaint_id  UUID          REFERENCES complaints(id) ON DELETE SET NULL,
  user_id       UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason        TEXT          NOT NULL,
  status        appeal_status NOT NULL DEFAULT 'pending',
  reviewed_by   UUID          REFERENCES users(id),
  review_note   TEXT,
  reviewed_at   TIMESTAMPTZ,
  expires_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_appeals_user ON appeals(user_id);
CREATE INDEX IF NOT EXISTS idx_appeals_status ON appeals(status);

-- ── 13. banned_phones / banned_govt_ids ───────────────────
CREATE TABLE IF NOT EXISTS banned_phones (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  phone      VARCHAR(20) NOT NULL UNIQUE,
  reason     TEXT,
  banned_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS banned_govt_ids (
  id          UUID       PRIMARY KEY DEFAULT gen_random_uuid(),
  id_hash     TEXT       NOT NULL UNIQUE,
  reason      TEXT,
  banned_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 14. consent_records ───────────────────────────────────
CREATE TABLE IF NOT EXISTS consent_records (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  consent_type  VARCHAR(50) NOT NULL,
  granted       BOOLEAN     NOT NULL DEFAULT FALSE,
  granted_at    TIMESTAMPTZ,
  revoked_at    TIMESTAMPTZ,
  ip_address    INET,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_consent_records_user ON consent_records(user_id, consent_type);

-- ── 15. audit_log ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_log (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        REFERENCES users(id),
  action      VARCHAR(100) NOT NULL,
  entity_type VARCHAR(50),
  entity_id   UUID,
  details     JSONB,
  ip_address  INET,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_log_user ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_entity ON audit_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON audit_log(created_at DESC);

-- ── 16. otp_log ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS otp_log (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  phone       VARCHAR(20),
  email       VARCHAR(255),
  otp_hash    TEXT        NOT NULL,
  purpose     VARCHAR(50) DEFAULT 'login',
  expires_at  TIMESTAMPTZ NOT NULL,
  is_used     BOOLEAN     NOT NULL DEFAULT FALSE,
  ip_address  INET,
  user_agent  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_otp_log_phone ON otp_log(phone) WHERE phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_otp_log_created ON otp_log(created_at);

-- ── 17. performance indexes ────────────────────────────────
-- Composite covering index for search (most critical query)
CREATE INDEX IF NOT EXISTS idx_pro_verified_available
  ON professionals(verification_status, is_available, subscription_plan)
  WHERE verification_status IS NOT NULL;

-- Partial index for open complaints
CREATE INDEX IF NOT EXISTS idx_complaints_open
  ON complaints(created_at DESC)
  WHERE status = 'pending';

-- contacts eligibility index
CREATE INDEX IF NOT EXISTS idx_contacts_eligibility
  ON contacts(customer_id, professional_id, status);

-- review useful index
CREATE INDEX IF NOT EXISTS idx_reviews_professional_visible
  ON reviews(professional_id, created_at DESC)
  WHERE moderation_status = 'approved';

-- ── 18. supported_cities ─────────────────────────────────
CREATE TABLE IF NOT EXISTS supported_cities (
  id              SERIAL      PRIMARY KEY,
  name            VARCHAR(100) NOT NULL UNIQUE,
  state           VARCHAR(100),
  is_active       BOOLEAN     NOT NULL DEFAULT FALSE,
  activated_at    TIMESTAMPTZ,
  waitlist_offer_sent BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed initial supported cities
INSERT INTO supported_cities (name, state, is_active) VALUES
  ('Bangalore', 'Karnataka', true),
  ('Hyderabad', 'Telangana', true),
  ('Mumbai', 'Maharashtra', true),
  ('Delhi', 'Delhi', true),
  ('Chennai', 'Tamil Nadu', true),
  ('Pune', 'Maharashtra', true),
  ('Kolkata', 'West Bengal', false),
  ('Ahmedabad', 'Gujarat', false),
  ('Jaipur', 'Rajasthan', false),
  ('Lucknow', 'Uttar Pradesh', false)
ON CONFLICT (name) DO NOTHING;
