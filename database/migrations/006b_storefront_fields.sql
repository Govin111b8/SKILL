-- Migration: Add storefront fields to professionals table
-- Provides additional branding and contact fields for the professional storefront page

ALTER TABLE professionals
  ADD COLUMN IF NOT EXISTS announcement TEXT,
  ADD COLUMN IF NOT EXISTS whatsapp_number VARCHAR(20),
  ADD COLUMN IF NOT EXISTS instagram_handle VARCHAR(100),
  ADD COLUMN IF NOT EXISTS website_url TEXT,
  ADD COLUMN IF NOT EXISTS cover_image_url TEXT,
  ADD COLUMN IF NOT EXISTS accent_color VARCHAR(7) DEFAULT '#6366F1',
  ADD COLUMN IF NOT EXISTS show_rating BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS return_policy TEXT,
  ADD COLUMN IF NOT EXISTS operating_hours TEXT,
  ADD COLUMN IF NOT EXISTS operating_days TEXT;
