-- Migration 027: Security Enhancements
-- Adds tables for refresh token tracking, audit logging, and CSRF tokens

BEGIN;

-- Refresh token families for reuse detection
CREATE TABLE IF NOT EXISTS refresh_token_families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  family_id VARCHAR(64) NOT NULL UNIQUE,
  is_revoked BOOLEAN DEFAULT FALSE,
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  revoke_reason VARCHAR(100)
);

CREATE INDEX IF NOT EXISTS idx_token_families_user ON refresh_token_families(user_id);
CREATE INDEX IF NOT EXISTS idx_token_families_family ON refresh_token_families(family_id);

-- Security audit log for sensitive operations
CREATE TABLE IF NOT EXISTS security_audit_log (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(100) NOT NULL,
  ip_address INET,
  user_agent TEXT,
  details JSONB DEFAULT '{}',
  risk_level VARCHAR(20) DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_security_audit_user ON security_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_security_audit_action ON security_audit_log(action);
CREATE INDEX IF NOT EXISTS idx_security_audit_risk ON security_audit_log(risk_level) WHERE risk_level IN ('high', 'critical');
CREATE INDEX IF NOT EXISTS idx_security_audit_created ON security_audit_log(created_at);

-- API rate limit tracking (for persistent limits across restarts)
CREATE TABLE IF NOT EXISTS rate_limit_overrides (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  endpoint_pattern VARCHAR(200) NOT NULL,
  max_requests INTEGER NOT NULL,
  window_seconds INTEGER NOT NULL DEFAULT 60,
  reason VARCHAR(255),
  created_by UUID REFERENCES users(id),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_user ON rate_limit_overrides(user_id);

-- File upload audit (track all uploads for security review)
CREATE TABLE IF NOT EXISTS upload_audit_log (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  original_filename VARCHAR(500),
  stored_key VARCHAR(500),
  mime_type VARCHAR(100),
  file_size INTEGER,
  folder VARCHAR(50),
  magic_bytes_valid BOOLEAN DEFAULT TRUE,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_upload_audit_user ON upload_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_upload_audit_created ON upload_audit_log(created_at);

COMMIT;
