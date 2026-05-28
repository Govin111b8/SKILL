-- Migration 024: Provider Demand Prediction
-- Adds tables for tracking service demand patterns and AI-generated demand forecasts

BEGIN;

-- Hourly demand log: aggregated booking signals per category/city/hour
CREATE TABLE IF NOT EXISTS service_demand_logs (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id    UUID REFERENCES categories(id) ON DELETE CASCADE,
  city           VARCHAR(100) NOT NULL,
  hour_of_day    SMALLINT NOT NULL CHECK (hour_of_day BETWEEN 0 AND 23),
  day_of_week    SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday
  week_start     DATE NOT NULL,
  booking_count  INTEGER NOT NULL DEFAULT 0,
  search_count   INTEGER NOT NULL DEFAULT 0,
  quote_count    INTEGER NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (category_id, city, hour_of_day, day_of_week, week_start)
);

-- AI-generated demand forecasts for professionals
CREATE TABLE IF NOT EXISTS demand_forecasts (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id   UUID REFERENCES professionals(id) ON DELETE CASCADE,
  category_id       UUID REFERENCES categories(id) ON DELETE SET NULL,
  city              VARCHAR(100) NOT NULL,
  forecast_date     DATE NOT NULL,
  demand_score      NUMERIC(5,2) NOT NULL CHECK (demand_score BETWEEN 0 AND 100),
  peak_hours        JSONB NOT NULL DEFAULT '[]', -- e.g. [9, 10, 14, 15, 16]
  predicted_bookings INTEGER NOT NULL DEFAULT 0,
  confidence_level  VARCHAR(20) NOT NULL DEFAULT 'medium' CHECK (confidence_level IN ('low','medium','high')),
  trend             VARCHAR(20) NOT NULL DEFAULT 'stable' CHECK (trend IN ('rising','stable','falling')),
  insight           TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (professional_id, forecast_date)
);

-- Area-level demand summary (for admin / supply-demand matching)
CREATE TABLE IF NOT EXISTS area_demand_summary (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city              VARCHAR(100) NOT NULL,
  category_id       UUID REFERENCES categories(id) ON DELETE CASCADE,
  summary_date      DATE NOT NULL,
  total_demand      INTEGER NOT NULL DEFAULT 0,
  available_pros    INTEGER NOT NULL DEFAULT 0,
  avg_response_time NUMERIC(8,2), -- minutes
  unmet_demand      INTEGER NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (city, category_id, summary_date)
);

-- Indexes for fast lookup
CREATE INDEX IF NOT EXISTS idx_demand_logs_category_city ON service_demand_logs (category_id, city, week_start);
CREATE INDEX IF NOT EXISTS idx_demand_forecasts_pro ON demand_forecasts (professional_id, forecast_date DESC);
CREATE INDEX IF NOT EXISTS idx_demand_forecasts_city_cat ON demand_forecasts (city, category_id, forecast_date DESC);
CREATE INDEX IF NOT EXISTS idx_area_demand_city_cat ON area_demand_summary (city, category_id, summary_date DESC);

COMMIT;
