-- Migration 020: Composite indexes for query performance
-- Addresses N+1 query performance issues identified in Deep Audit v2

BEGIN;

-- Bookings: frequently queried by customer + status
CREATE INDEX IF NOT EXISTS idx_bookings_customer_status
  ON bookings (customer_id, status);

-- Bookings: professional + status for dashboard queries
CREATE INDEX IF NOT EXISTS idx_bookings_professional_status
  ON bookings (professional_id, status);

-- Reviews: professional + created_at for sorted review lists
CREATE INDEX IF NOT EXISTS idx_reviews_professional_created
  ON reviews (professional_id, created_at DESC);

-- Payments: payer + status for payment history
CREATE INDEX IF NOT EXISTS idx_payments_payer_status
  ON payments (payer_id, status);

-- Messages: thread + created_at for chat pagination
CREATE INDEX IF NOT EXISTS idx_messages_thread_created
  ON messages (thread_id, created_at DESC);

-- Notifications: user + read status for unread count
CREATE INDEX IF NOT EXISTS idx_notifications_user_read
  ON notifications (user_id, is_read, created_at DESC);

-- Professional services: professional + active for catalog queries
CREATE INDEX IF NOT EXISTS idx_professional_services_active
  ON professional_services (professional_id, is_active);

-- Search history: user + created for recent searches
CREATE INDEX IF NOT EXISTS idx_search_history_user_created
  ON search_history (user_id, created_at DESC);

-- Referrals: referred_id for dedup check
CREATE INDEX IF NOT EXISTS idx_referrals_referred
  ON referrals (referred_id);

-- Follows: following_id for follower count
CREATE INDEX IF NOT EXISTS idx_follows_following
  ON follows (following_id);

COMMIT;
