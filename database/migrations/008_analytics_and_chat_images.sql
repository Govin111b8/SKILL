BEGIN;

-- Analytics events table for mobile event tracking
CREATE TABLE IF NOT EXISTS analytics_events (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_name VARCHAR(100) NOT NULL,
    event_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    session_id VARCHAR(50),
    properties JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for querying by event type and time
CREATE INDEX IF NOT EXISTS idx_analytics_events_name_time 
    ON analytics_events(event_name, event_timestamp DESC);

-- Index for user-specific analytics
CREATE INDEX IF NOT EXISTS idx_analytics_events_user 
    ON analytics_events(user_id, event_timestamp DESC);

-- Index for session analysis
CREATE INDEX IF NOT EXISTS idx_analytics_events_session 
    ON analytics_events(session_id);

-- Analytics sessions table
CREATE TABLE IF NOT EXISTS analytics_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR(50) UNIQUE NOT NULL,
    duration_ms INTEGER DEFAULT 0,
    events_count INTEGER DEFAULT 0,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for session lookups
CREATE INDEX IF NOT EXISTS idx_analytics_sessions_user 
    ON analytics_sessions(user_id, started_at DESC);

-- Add image_url column to messages for image sharing in chat
ALTER TABLE messages ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS message_type VARCHAR(20) DEFAULT 'text';
-- message_type: 'text', 'image', 'voice_note', 'system'

-- Performance metrics summary (materialized for dashboard)
CREATE TABLE IF NOT EXISTS performance_metrics (
    id SERIAL PRIMARY KEY,
    metric_type VARCHAR(50) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    avg_value NUMERIC(10, 2),
    max_value NUMERIC(10, 2),
    sample_count INTEGER,
    measured_at DATE DEFAULT CURRENT_DATE,
    UNIQUE(metric_type, metric_name, measured_at)
);

COMMIT;
