-- F14 Geofence chat sąsiedzki — tabela neighborhood_messages.
-- Idempotentne. Uruchom na prod:
--   psql "$DATABASE_URL" -f db/migrations/2026-06-04_f14_neighborhood_chat.sql
CREATE TABLE IF NOT EXISTS neighborhood_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  body VARCHAR(1000) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_neighborhood_loc ON neighborhood_messages USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_neighborhood_created ON neighborhood_messages(created_at DESC);
