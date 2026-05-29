-- Migration 029: Promotions / banner management
-- Supports the PromotionsBanner widget; allows admin to manage
-- promotional banners served via GET /api/promotions.

BEGIN;

CREATE TABLE IF NOT EXISTS promotions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title         VARCHAR(200) NOT NULL,
  subtitle      TEXT,
  image_url     TEXT,
  cta_url       TEXT,
  gradient_from VARCHAR(20) DEFAULT '#6366F1',
  gradient_to   VARCHAR(20) DEFAULT '#8B5CF6',
  emoji         VARCHAR(10) DEFAULT '🎁',
  active        BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INTEGER NOT NULL DEFAULT 0,
  starts_at     TIMESTAMPTZ,
  ends_at       TIMESTAMPTZ,
  created_by    UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_promotions_active ON promotions(active, display_order);

-- Seed default banners (same as the hard-coded ones in PromotionsBanner widget)
INSERT INTO promotions (title, subtitle, emoji, gradient_from, gradient_to, active, display_order) VALUES
  ('Summer Special',      'AC servicing at 20% off — verified technicians near you', '❄️', '#06B6D4', '#0284C7', TRUE, 1),
  ('New: Home Services',  'Deep cleaning, painting, pest control — book in 2 taps',  '🏠', '#10B981', '#059669', TRUE, 2),
  ('Refer & Earn ₹200',  'Share with friends, both get ₹200 off first booking',      '🎁', '#F59E0B', '#EA580C', TRUE, 3),
  ('Zero Commission',     'Professionals keep 100% earnings — better rates for you', '💰', '#8B5CF6', '#6366F1', TRUE, 4)
ON CONFLICT DO NOTHING;

COMMIT;
