-- F18 City hazards — dodaje 3 kategorie do istniejącego enuma alert_category.
-- Idempotentne (IF NOT EXISTS). Uruchom na prod:
--   psql "$DATABASE_URL" -f db/migrations/2026-06-04_f18_city_hazards.sql
ALTER TYPE alert_category ADD VALUE IF NOT EXISTS 'pothole';
ALTER TYPE alert_category ADD VALUE IF NOT EXISTS 'dark_passage';
ALTER TYPE alert_category ADD VALUE IF NOT EXISTS 'broken_lights';
