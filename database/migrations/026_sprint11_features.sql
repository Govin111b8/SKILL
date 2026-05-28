-- Migration 026: Sprint 11 Features
-- Recurring Bookings, Rescheduling, Payment History, Saved Searches,
-- Coupons, Professional Comparison, Chat Attachments, Buffer Time, etc.

BEGIN;

-- =====================================================
-- 1. RECURRING BOOKINGS
-- =====================================================
CREATE TABLE IF NOT EXISTS recurring_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES users(id),
  professional_id UUID NOT NULL REFERENCES professionals(id),
  category_id UUID REFERENCES categories(id),
  service_id UUID REFERENCES professional_services(id),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  service_address TEXT,
  frequency VARCHAR(20) NOT NULL CHECK (frequency IN ('daily', 'weekly', 'biweekly', 'monthly', 'quarterly')),
  day_of_week INTEGER CHECK (day_of_week >= 0 AND day_of_week <= 6),
  day_of_month INTEGER CHECK (day_of_month >= 1 AND day_of_month <= 28),
  preferred_time TIME,
  start_date DATE NOT NULL,
  end_date DATE,
  max_occurrences INTEGER,
  occurrences_created INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled', 'completed')),
  last_booking_date DATE,
  next_booking_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_recurring_bookings_customer ON recurring_bookings(customer_id);
CREATE INDEX idx_recurring_bookings_professional ON recurring_bookings(professional_id);
CREATE INDEX idx_recurring_bookings_next ON recurring_bookings(next_booking_date) WHERE status = 'active';

-- =====================================================
-- 2. BOOKING RESCHEDULING LOG
-- =====================================================
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS original_date TIMESTAMPTZ;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS reschedule_count INTEGER DEFAULT 0;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS rescheduled_by UUID REFERENCES users(id);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS reschedule_reason TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS urgency VARCHAR(20) DEFAULT 'flexible'
  CHECK (urgency IN ('emergency', 'same_day', 'this_week', 'flexible'));

CREATE TABLE IF NOT EXISTS booking_reschedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES bookings(id),
  old_date TIMESTAMPTZ NOT NULL,
  new_date TIMESTAMPTZ NOT NULL,
  old_time TIME,
  new_time TIME,
  reason TEXT,
  rescheduled_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_booking_reschedules_booking ON booking_reschedules(booking_id);

-- =====================================================
-- 3. SAVED SEARCHES / ALERTS
-- =====================================================
CREATE TABLE IF NOT EXISTS saved_searches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  name VARCHAR(100),
  query TEXT NOT NULL,
  filters JSONB DEFAULT '{}',
  alert_enabled BOOLEAN DEFAULT false,
  alert_frequency VARCHAR(20) DEFAULT 'daily' CHECK (alert_frequency IN ('instant', 'daily', 'weekly')),
  last_alerted_at TIMESTAMPTZ,
  results_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_saved_searches_user ON saved_searches(user_id);
CREATE INDEX idx_saved_searches_alert ON saved_searches(alert_enabled) WHERE alert_enabled = true;

-- =====================================================
-- 4. COUPONS / DISCOUNT CODES
-- =====================================================
CREATE TABLE IF NOT EXISTS coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value NUMERIC(10,2) NOT NULL,
  min_order_amount NUMERIC(10,2) DEFAULT 0,
  max_discount NUMERIC(10,2),
  usage_limit INTEGER,
  used_count INTEGER DEFAULT 0,
  per_user_limit INTEGER DEFAULT 1,
  valid_from TIMESTAMPTZ DEFAULT NOW(),
  valid_until TIMESTAMPTZ,
  categories UUID[],
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS coupon_usages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id UUID NOT NULL REFERENCES coupons(id),
  user_id UUID NOT NULL REFERENCES users(id),
  booking_id UUID REFERENCES bookings(id),
  discount_applied NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_coupons_code ON coupons(code) WHERE is_active = true;
CREATE INDEX idx_coupon_usages_user ON coupon_usages(user_id, coupon_id);

-- =====================================================
-- 5. CHAT ATTACHMENTS
-- =====================================================
ALTER TABLE messages ADD COLUMN IF NOT EXISTS attachment_url TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS attachment_type VARCHAR(20)
  CHECK (attachment_type IN ('image', 'file', 'voice', 'video'));
ALTER TABLE messages ADD COLUMN IF NOT EXISTS attachment_name VARCHAR(255);
ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT false;

-- Quick reply templates for professionals
CREATE TABLE IF NOT EXISTS quick_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  title VARCHAR(100) NOT NULL,
  content TEXT NOT NULL,
  shortcut VARCHAR(20),
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_quick_replies_user ON quick_replies(user_id);

-- =====================================================
-- 6. SCHEDULE ENHANCEMENTS
-- =====================================================
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS buffer_minutes INTEGER DEFAULT 0;
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS max_bookings_per_day INTEGER DEFAULT 10;
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS auto_accept_repeat BOOLEAN DEFAULT false;

CREATE TABLE IF NOT EXISTS recurring_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id UUID NOT NULL REFERENCES professionals(id),
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  start_time TIME,
  end_time TIME,
  reason VARCHAR(255),
  is_full_day BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_recurring_blocks_professional ON recurring_blocks(professional_id);

-- =====================================================
-- 7. USER ADDRESSES (Multiple)
-- =====================================================
CREATE TABLE IF NOT EXISTS user_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  label VARCHAR(50) NOT NULL DEFAULT 'Home',
  address_line1 TEXT NOT NULL,
  address_line2 TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  pincode VARCHAR(10),
  lat NUMERIC(10,7),
  lng NUMERIC(10,7),
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_addresses_user ON user_addresses(user_id);

-- =====================================================
-- 8. PROFESSIONAL COMPARISON TRACKING
-- =====================================================
CREATE TABLE IF NOT EXISTS comparison_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  professional_ids UUID[] NOT NULL,
  category_id UUID REFERENCES categories(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 9. PROMOTIONAL BANNERS
-- =====================================================
CREATE TABLE IF NOT EXISTS promotional_banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  subtitle TEXT,
  image_url TEXT,
  link_url TEXT,
  cta_text VARCHAR(50),
  position INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  starts_at TIMESTAMPTZ DEFAULT NOW(),
  ends_at TIMESTAMPTZ,
  target_roles VARCHAR(20)[] DEFAULT ARRAY['customer'],
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_banners_active ON promotional_banners(is_active, starts_at, ends_at);

-- =====================================================
-- 10. GOALS & TARGETS
-- =====================================================
CREATE TABLE IF NOT EXISTS professional_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id UUID NOT NULL REFERENCES professionals(id),
  goal_type VARCHAR(30) NOT NULL CHECK (goal_type IN ('revenue', 'bookings', 'rating', 'reviews')),
  target_value NUMERIC(12,2) NOT NULL,
  current_value NUMERIC(12,2) DEFAULT 0,
  period VARCHAR(20) NOT NULL CHECK (period IN ('weekly', 'monthly', 'quarterly', 'yearly')),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'achieved', 'missed', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_professional_goals ON professional_goals(professional_id, status);

-- =====================================================
-- 11. 2FA SUPPORT
-- =====================================================
ALTER TABLE users ADD COLUMN IF NOT EXISTS two_factor_enabled BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS two_factor_secret TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS two_factor_backup_codes TEXT[];

CREATE TABLE IF NOT EXISTS active_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  token_hash VARCHAR(64) NOT NULL,
  device_info JSONB DEFAULT '{}',
  ip_address INET,
  last_active TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_active_sessions_user ON active_sessions(user_id);

COMMIT;
