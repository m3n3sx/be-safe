-- F23 Ghost mode (czasowy) — kolumna ghost_until na users.
-- Gdy ghost_until > NOW(), lokalizacja użytkownika jest ukrywana przed rodziną.
-- Idempotentne. Uruchom na prod:
--   psql "$DATABASE_URL" -f db/migrations/2026-06-04_f23_ghost_until.sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS ghost_until TIMESTAMPTZ;
