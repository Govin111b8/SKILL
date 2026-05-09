-- ============================================================
-- Migration 015: Phase 5.2 (Collections), Phase 8.2 (User Points)
-- ============================================================

-- ── Phase 5.2: Save Collections (Pinterest-style) ──────────

CREATE TABLE IF NOT EXISTS collections (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name       VARCHAR(100) NOT NULL,
  is_public  BOOLEAN     NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_collections_user ON collections(user_id);

CREATE TABLE IF NOT EXISTS collection_items (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  collection_id UUID        NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
  item_type     VARCHAR(20) NOT NULL,  -- professional, service, post
  item_id       UUID        NOT NULL,
  added_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(collection_id, item_type, item_id)
);
CREATE INDEX IF NOT EXISTS idx_collection_items_collection ON collection_items(collection_id);

-- ── Phase 8.2: User Points ─────────────────────────────────

CREATE TABLE IF NOT EXISTS user_points (
  user_id         UUID    PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  points_balance  INT     NOT NULL DEFAULT 0,
  lifetime_points INT     NOT NULL DEFAULT 0,
  level           INT     NOT NULL DEFAULT 1
);
