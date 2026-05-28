-- Migration 028: Gamification — user_points, point_transactions, response_streaks
-- Phase 8: Loyalty points, leaderboards, professional gamification

BEGIN;

-- ── User loyalty points ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_points (
  user_id         UUID        PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  points_balance  INT         NOT NULL DEFAULT 0 CHECK (points_balance >= 0),
  lifetime_points INT         NOT NULL DEFAULT 0 CHECK (lifetime_points >= 0),
  level           SMALLINT    NOT NULL DEFAULT 1 CHECK (level BETWEEN 1 AND 5),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Point transaction log ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS point_transactions (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type         VARCHAR(10) NOT NULL CHECK (type IN ('earn', 'redeem')),
  points       INT         NOT NULL CHECK (points > 0),
  reason       VARCHAR(200) NOT NULL,
  reference_id UUID,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_point_tx_user ON point_transactions(user_id, created_at DESC);

-- ── Professional response streaks ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS response_streaks (
  professional_id UUID       PRIMARY KEY REFERENCES professionals(id) ON DELETE CASCADE,
  current_streak  INT        NOT NULL DEFAULT 0,
  best_streak     INT        NOT NULL DEFAULT 0,
  last_response   TIMESTAMPTZ,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Monthly leaderboard snapshot (populated by cron) ─────────────────────────
CREATE TABLE IF NOT EXISTS leaderboard_snapshots (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  snapshot_month   DATE        NOT NULL,  -- first day of month
  type             VARCHAR(20) NOT NULL CHECK (type IN ('professional_jobs', 'professional_rating', 'customer_points')),
  entity_id        UUID        NOT NULL,
  rank             INT         NOT NULL,
  score            NUMERIC(10, 2) NOT NULL,
  metadata         JSONB       DEFAULT '{}'::jsonb,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(snapshot_month, type, entity_id)
);

CREATE INDEX IF NOT EXISTS idx_leaderboard_month_type ON leaderboard_snapshots(snapshot_month, type, rank);

-- Update function for user_points.updated_at
CREATE OR REPLACE FUNCTION update_user_points_ts()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS trg_user_points_ts ON user_points;
CREATE TRIGGER trg_user_points_ts
  BEFORE UPDATE ON user_points
  FOR EACH ROW EXECUTE FUNCTION update_user_points_ts();

COMMIT;
