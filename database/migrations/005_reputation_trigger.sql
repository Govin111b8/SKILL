-- Auto-refresh professional reputation_score whenever reviews change.
-- reputation_score is a 0-100 composite: 70% rating (×20) + 30% review volume score.

CREATE OR REPLACE FUNCTION refresh_professional_reputation(pid INTEGER)
RETURNS VOID AS $$
DECLARE
  avg_rating NUMERIC;
  review_count INTEGER;
  volume_score NUMERIC;
  new_score NUMERIC;
BEGIN
  SELECT COALESCE(AVG(rating), 0), COUNT(*)
  INTO avg_rating, review_count
  FROM reviews
  WHERE professional_id = pid;

  -- Volume score saturates at 50 reviews
  volume_score := LEAST(review_count::NUMERIC / 50.0, 1.0) * 100.0;
  -- Composite: 70% rating, 30% volume
  new_score := ROUND((avg_rating * 20.0 * 0.7) + (volume_score * 0.3), 2);

  UPDATE professionals
  SET reputation_score = new_score,
      updated_at = NOW()
  WHERE id = pid;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trg_reviews_refresh_reputation()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM refresh_professional_reputation(OLD.professional_id);
    RETURN OLD;
  ELSE
    PERFORM refresh_professional_reputation(NEW.professional_id);
    IF TG_OP = 'UPDATE' AND OLD.professional_id <> NEW.professional_id THEN
      PERFORM refresh_professional_reputation(OLD.professional_id);
    END IF;
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS reviews_refresh_reputation ON reviews;
CREATE TRIGGER reviews_refresh_reputation
AFTER INSERT OR UPDATE OR DELETE ON reviews
FOR EACH ROW EXECUTE FUNCTION trg_reviews_refresh_reputation();

-- Also: when a booking is marked completed, increment professionals.completed_jobs
CREATE OR REPLACE FUNCTION trg_bookings_completed_jobs()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status <> 'completed') THEN
    UPDATE professionals
    SET completed_jobs = COALESCE(completed_jobs, 0) + 1,
        updated_at = NOW()
    WHERE id = NEW.professional_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS bookings_completed_jobs ON bookings;
CREATE TRIGGER bookings_completed_jobs
AFTER UPDATE ON bookings
FOR EACH ROW EXECUTE FUNCTION trg_bookings_completed_jobs();

-- Backfill existing data
DO $$
DECLARE
  p RECORD;
BEGIN
  FOR p IN SELECT DISTINCT professional_id FROM reviews LOOP
    PERFORM refresh_professional_reputation(p.professional_id);
  END LOOP;
END $$;
