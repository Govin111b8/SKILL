-- Migration 022: Device push tokens for FCM and notification preferences
BEGIN;

-- Device FCM/APNs push tokens (one per device, shared across logins)
CREATE TABLE IF NOT EXISTS device_push_tokens (
  id           SERIAL PRIMARY KEY,
  user_id      INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token        TEXT NOT NULL UNIQUE,
  platform     VARCHAR(10) NOT NULL DEFAULT 'android'
                 CHECK (platform IN ('android', 'ios', 'web')),
  language     VARCHAR(10) NOT NULL DEFAULT 'en',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_device_push_tokens_user_id ON device_push_tokens(user_id);

-- User notification category preference overrides
-- transactional is always enabled (not stored — enforced in code)
CREATE TABLE IF NOT EXISTS user_notification_preferences (
  id          SERIAL PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category    VARCHAR(20) NOT NULL
                CHECK (category IN ('behavioral', 'lifecycle', 'promotional')),
  enabled     BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, category)
);

CREATE INDEX IF NOT EXISTS idx_user_notif_prefs_user ON user_notification_preferences(user_id);

COMMIT;
