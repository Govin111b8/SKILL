-- ============================================================
-- Migration 009: Agent System & Reward Engine
-- SkillConnect - Reward-Driven Growth Engine
-- ============================================================

-- 1. Add 'agent' to user_role enum
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'agent';

-- 2. Agent profiles - extends user with agent-specific data
CREATE TABLE IF NOT EXISTS agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    agent_code VARCHAR(20) NOT NULL UNIQUE,
    zone VARCHAR(100),  -- city/zone focus (e.g. 'Hyderabad', 'Bangalore', 'Chennai')
    kyc_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    wallet_balance DECIMAL(12, 2) NOT NULL DEFAULT 0,
    total_earned DECIMAL(12, 2) NOT NULL DEFAULT 0,
    providers_onboarded INTEGER NOT NULL DEFAULT 0,
    customers_onboarded INTEGER NOT NULL DEFAULT 0,
    level VARCHAR(20) NOT NULL DEFAULT 'bronze', -- bronze, silver, gold, platinum
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Agent reward actions - defines what earns rewards
CREATE TYPE reward_action_type AS ENUM (
    'provider_onboarded',
    'provider_profile_complete',
    'provider_first_job',
    'customer_onboarded',
    'customer_first_booking',
    'referral_joined'
);

CREATE TYPE reward_status AS ENUM ('pending', 'unlocked', 'paid', 'rejected');

-- 4. Agent rewards log - tracks individual reward events
CREATE TABLE IF NOT EXISTS agent_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    action reward_action_type NOT NULL,
    target_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    points INTEGER NOT NULL DEFAULT 0,
    amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    status reward_status NOT NULL DEFAULT 'pending',
    unlocked_at TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Agent wallet transactions
CREATE TYPE wallet_txn_type AS ENUM ('credit', 'debit', 'withdrawal');

CREATE TABLE IF NOT EXISTS agent_wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    type wallet_txn_type NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    balance_after DECIMAL(12, 2) NOT NULL,
    description TEXT,
    reference_id UUID,  -- links to agent_rewards.id or payout id
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Agent onboarded users tracking
CREATE TABLE IF NOT EXISTS agent_onboarded_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_role user_role NOT NULL,
    profile_completed BOOLEAN NOT NULL DEFAULT FALSE,
    first_transaction_done BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(agent_id, user_id)
);

-- 7. Reward configuration table (admin-controlled)
CREATE TABLE IF NOT EXISTS reward_config (
    id SERIAL PRIMARY KEY,
    action reward_action_type NOT NULL UNIQUE,
    points INTEGER NOT NULL DEFAULT 0,
    amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    min_kyc_level INTEGER NOT NULL DEFAULT 0,  -- minimum KYC level required
    description TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Seed default reward configuration
INSERT INTO reward_config (action, points, amount, description) VALUES
    ('provider_onboarded', 50, 100.00, 'Agent registers a new service provider'),
    ('provider_profile_complete', 30, 50.00, 'Provider completes full profile (bio, skills, photo)'),
    ('provider_first_job', 100, 200.00, 'Provider completes their first job on platform'),
    ('customer_onboarded', 20, 50.00, 'Agent registers a new customer'),
    ('customer_first_booking', 50, 100.00, 'Customer makes their first booking'),
    ('referral_joined', 10, 25.00, 'Referred user joins the platform')
ON CONFLICT (action) DO NOTHING;

-- 9. Zones/Cities table for geo-based growth tracking
CREATE TABLE IF NOT EXISTS zones (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    state VARCHAR(100),
    latitude DECIMAL(9, 6),
    longitude DECIMAL(9, 6),
    radius_km INTEGER DEFAULT 50,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    phase INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed Phase 1 zones
INSERT INTO zones (name, state, latitude, longitude, radius_km, phase) VALUES
    ('Hyderabad', 'Telangana', 17.3850, 78.4867, 50, 1),
    ('Bangalore', 'Karnataka', 12.9716, 77.5946, 50, 1),
    ('Chennai', 'Tamil Nadu', 13.0827, 80.2707, 50, 1)
ON CONFLICT (name) DO NOTHING;

-- 10. Indexes
CREATE INDEX IF NOT EXISTS idx_agents_user_id ON agents(user_id);
CREATE INDEX IF NOT EXISTS idx_agents_zone ON agents(zone);
CREATE INDEX IF NOT EXISTS idx_agents_agent_code ON agents(agent_code);
CREATE INDEX IF NOT EXISTS idx_agent_rewards_agent_id ON agent_rewards(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_rewards_status ON agent_rewards(status);
CREATE INDEX IF NOT EXISTS idx_agent_wallet_agent_id ON agent_wallet_transactions(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_onboarded_agent_id ON agent_onboarded_users(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_onboarded_user_id ON agent_onboarded_users(user_id);

-- 11. Add agent_id field to users table for tracking who onboarded them
ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarded_by_agent UUID REFERENCES agents(id) ON DELETE SET NULL;
