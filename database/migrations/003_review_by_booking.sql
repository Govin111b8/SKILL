-- 003_review_by_booking.sql — allow reviews to be tied to a booking instead of a contact

ALTER TABLE reviews ALTER COLUMN contact_id DROP NOT NULL;
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_contact_id_key;

ALTER TABLE reviews ADD COLUMN IF NOT EXISTS booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL;
CREATE UNIQUE INDEX IF NOT EXISTS reviews_booking_unique ON reviews(booking_id) WHERE booking_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS reviews_contact_unique ON reviews(contact_id) WHERE contact_id IS NOT NULL;

-- Require at least one of contact_id / booking_id
ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_source_chk;
ALTER TABLE reviews ADD CONSTRAINT reviews_source_chk
  CHECK (contact_id IS NOT NULL OR booking_id IS NOT NULL);
