-- ============================================================
-- Migration 014: Phase 4 (Storefront), Phase 5 (Social),
--                Phase 7 (Trust) — New tables and columns
-- ============================================================

-- ── ENUMs ──────────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE storefront_media_type AS ENUM ('reel', 'before_after', 'highlight', 'testimonial', 'gallery');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE story_status AS ENUM ('active', 'expired');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── Phase 4: Storefront Media ──────────────────────────────

CREATE TABLE IF NOT EXISTS storefront_media (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  storefront_id  UUID        NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  type           storefront_media_type NOT NULL DEFAULT 'gallery',
  media_url      TEXT        NOT NULL,
  thumbnail_url  TEXT,
  caption        TEXT,
  before_url     TEXT,        -- for before_after type: the "before" image
  sort_order     INT         DEFAULT 0,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_storefront_media_storefront ON storefront_media(storefront_id);
CREATE INDEX IF NOT EXISTS idx_storefront_media_type ON storefront_media(storefront_id, type);

-- ── Phase 4: Storefront Themes ─────────────────────────────

CREATE TABLE IF NOT EXISTS storefront_themes (
  storefront_id  UUID        PRIMARY KEY REFERENCES professionals(id) ON DELETE CASCADE,
  theme_name     VARCHAR(50) NOT NULL DEFAULT 'modern',
  primary_color  VARCHAR(7)  NOT NULL DEFAULT '#6366F1',
  accent_color   VARCHAR(7)  NOT NULL DEFAULT '#8B5CF6',
  layout         VARCHAR(20) NOT NULL DEFAULT 'centered',
  section_order  JSONB       DEFAULT '["about","services","portfolio","reviews","faq"]'::jsonb,
  custom_intro   TEXT,
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Phase 4: Service Packages ──────────────────────────────

CREATE TABLE IF NOT EXISTS service_packages (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id UUID        NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  name            VARCHAR(100) NOT NULL,
  tier            VARCHAR(20)  NOT NULL DEFAULT 'standard',  -- basic, standard, premium
  price           DECIMAL(10,2),
  description     TEXT,
  features        JSONB       DEFAULT '[]'::jsonb,
  is_popular      BOOLEAN     NOT NULL DEFAULT FALSE,
  sort_order      INT         DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_service_packages_pro ON service_packages(professional_id);

-- ── Phase 4: Add new columns to professionals ──────────────

ALTER TABLE professionals ADD COLUMN IF NOT EXISTS tagline VARCHAR(200);
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS intro_video_url TEXT;
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS repeat_customer_rate DECIMAL(5,2) DEFAULT 0;
ALTER TABLE professionals ADD COLUMN IF NOT EXISTS total_customers INT DEFAULT 0;

-- ── Phase 5: Follows ───────────────────────────────────────

CREATE TABLE IF NOT EXISTS follows (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id  UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  following_id UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);

-- ── Phase 5: Stories ───────────────────────────────────────

CREATE TABLE IF NOT EXISTS stories (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  media_url       TEXT        NOT NULL,
  text_overlay    TEXT,
  cta_url         TEXT,
  cta_label       VARCHAR(50),
  view_count      INT         NOT NULL DEFAULT 0,
  expires_at      TIMESTAMPTZ NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_stories_professional ON stories(professional_id);
CREATE INDEX IF NOT EXISTS idx_stories_expires ON stories(expires_at) WHERE expires_at IS NOT NULL;

-- ── Phase 5: Community Posts ───────────────────────────────

CREATE TABLE IF NOT EXISTS community_posts (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id   UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title       VARCHAR(200) NOT NULL,
  content     TEXT        NOT NULL,
  category    VARCHAR(50),
  media_urls  JSONB       DEFAULT '[]'::jsonb,
  likes_count INT         NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_community_posts_author ON community_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_community_posts_category ON community_posts(category);

-- ── Phase 5: Community Post Likes ──────────────────────────

CREATE TABLE IF NOT EXISTS community_post_likes (
  user_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  post_id  UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, post_id)
);

-- ── Phase 7: Professional Badges ───────────────────────────

CREATE TABLE IF NOT EXISTS professional_badges (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id UUID        NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  badge_type      VARCHAR(50) NOT NULL,
  earned_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata        JSONB       DEFAULT '{}'::jsonb,
  UNIQUE(professional_id, badge_type)
);
CREATE INDEX IF NOT EXISTS idx_professional_badges_pro ON professional_badges(professional_id);

-- ── Phase 6: User Interactions (for discovery/recommendations) ─

CREATE TABLE IF NOT EXISTS user_interactions (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  item_type  VARCHAR(20) NOT NULL,  -- professional, reel, story, post
  item_id    UUID        NOT NULL,
  action     VARCHAR(20) NOT NULL,  -- view, save, book, watch, like
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_user_interactions_user_created ON user_interactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_interactions_item ON user_interactions(item_type, item_id);
