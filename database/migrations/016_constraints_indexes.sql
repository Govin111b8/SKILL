-- Migration 016: Database constraints and indexes
-- Adds missing constraints and indexes identified in gap analysis

BEGIN;

-- Add CHECK constraint on users.role (if column exists)
DO $$ BEGIN
  ALTER TABLE users ADD CONSTRAINT chk_users_role
    CHECK (role IN ('customer', 'professional', 'agent', 'admin'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Add CHECK constraint on reviews.rating range
DO $$ BEGIN
  ALTER TABLE reviews ADD CONSTRAINT chk_reviews_rating
    CHECK (rating >= 1 AND rating <= 5);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Add index on users.phone for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);

-- Add index on booking_status_log.created_at for timeline queries
CREATE INDEX IF NOT EXISTS idx_booking_status_log_created ON booking_status_log(created_at DESC);

-- Add index on bookings.customer_id for customer dashboard queries
CREATE INDEX IF NOT EXISTS idx_bookings_customer ON bookings(customer_id);

-- Add index on bookings.professional_id for professional dashboard queries
CREATE INDEX IF NOT EXISTS idx_bookings_professional ON bookings(professional_id);

-- Add CHECK constraint on user_points.level
DO $$ BEGIN
  ALTER TABLE user_points ADD CONSTRAINT chk_user_points_level
    CHECK (level >= 1);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Add CHECK constraint on user_points.points_balance
DO $$ BEGIN
  ALTER TABLE user_points ADD CONSTRAINT chk_user_points_balance
    CHECK (points_balance >= 0);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

COMMIT;
