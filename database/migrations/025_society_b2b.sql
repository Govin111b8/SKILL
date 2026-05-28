-- Migration 025: Society & B2B Module
-- Adds support for housing societies, corporate clients, and bulk service requests

BEGIN;

-- Society / corporate entity
CREATE TABLE IF NOT EXISTS societies (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            VARCHAR(200) NOT NULL,
  type            VARCHAR(30) NOT NULL DEFAULT 'housing' CHECK (type IN ('housing','corporate','government','ngo')),
  address         TEXT NOT NULL,
  city            VARCHAR(100) NOT NULL,
  pincode         VARCHAR(10),
  total_units     INTEGER, -- apartments for housing; employees for corporate
  contact_name    VARCHAR(150) NOT NULL,
  contact_phone   VARCHAR(20) NOT NULL,
  contact_email   VARCHAR(200),
  gstin           VARCHAR(20), -- GST number for corporate invoicing
  status          VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','active','suspended')),
  verified_at     TIMESTAMPTZ,
  verified_by     UUID REFERENCES users(id),
  metadata        JSONB NOT NULL DEFAULT '{}',
  created_by      UUID REFERENCES users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Bulk service requests posted by societies
CREATE TABLE IF NOT EXISTS society_service_requests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  society_id      UUID NOT NULL REFERENCES societies(id) ON DELETE CASCADE,
  category_id     UUID REFERENCES categories(id) ON DELETE SET NULL,
  title           VARCHAR(300) NOT NULL,
  description     TEXT NOT NULL,
  preferred_date  DATE,
  preferred_time  VARCHAR(50), -- e.g. "Morning (9am-12pm)"
  units_covered   INTEGER, -- no. of apartments / employees covered
  frequency       VARCHAR(30) DEFAULT 'one_time' CHECK (frequency IN ('one_time','weekly','monthly','quarterly')),
  budget_range    VARCHAR(100), -- e.g. "₹10,000 - ₹20,000"
  status          VARCHAR(30) NOT NULL DEFAULT 'open' CHECK (status IN ('open','bidding','awarded','in_progress','completed','cancelled')),
  awarded_to      UUID REFERENCES professionals(id) ON DELETE SET NULL,
  awarded_at      TIMESTAMPTZ,
  created_by      UUID NOT NULL REFERENCES users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Professional bids on society service requests
CREATE TABLE IF NOT EXISTS society_bids (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id          UUID NOT NULL REFERENCES society_service_requests(id) ON DELETE CASCADE,
  professional_id     UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  amount              NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  per_unit_amount     NUMERIC(12,2), -- amount per apartment / employee
  proposal            TEXT NOT NULL,
  timeline_days       INTEGER,
  status              VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','shortlisted','awarded','rejected','withdrawn')),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (request_id, professional_id)
);

-- B2B enquiries from corporates who haven't registered yet
CREATE TABLE IF NOT EXISTS b2b_enquiries (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name    VARCHAR(200) NOT NULL,
  contact_name    VARCHAR(150) NOT NULL,
  contact_email   VARCHAR(200) NOT NULL,
  phone           VARCHAR(20) NOT NULL,
  service_type    VARCHAR(200), -- free text description of required service
  employee_count  INTEGER,
  frequency       VARCHAR(50),
  city            VARCHAR(100),
  budget          VARCHAR(100),
  additional_info TEXT,
  status          VARCHAR(20) NOT NULL DEFAULT 'new' CHECK (status IN ('new','contacted','converted','closed')),
  assigned_to     UUID REFERENCES users(id),
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Society membership (which users/professionals are linked to a society)
CREATE TABLE IF NOT EXISTS society_members (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  society_id      UUID NOT NULL REFERENCES societies(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role            VARCHAR(30) NOT NULL DEFAULT 'resident' CHECK (role IN ('resident','admin','manager')),
  unit_number     VARCHAR(50),
  joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (society_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_societies_city ON societies (city, status);
CREATE INDEX IF NOT EXISTS idx_society_requests_society ON society_service_requests (society_id, status);
CREATE INDEX IF NOT EXISTS idx_society_requests_category ON society_service_requests (category_id, status);
CREATE INDEX IF NOT EXISTS idx_society_bids_request ON society_bids (request_id, status);
CREATE INDEX IF NOT EXISTS idx_society_bids_pro ON society_bids (professional_id, status);
CREATE INDEX IF NOT EXISTS idx_b2b_enquiries_status ON b2b_enquiries (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_society_members_user ON society_members (user_id);

COMMIT;
