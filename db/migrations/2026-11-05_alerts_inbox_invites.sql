-- Skrzynka, tokeny wielu urządzeń, rodzaj SOS i ważność zaproszeń.
-- Uruchom przed nowym kodem:
--   psql "$DATABASE_URL" -f db/migrations/2026-11-05_alerts_inbox_invites.sql
-- Kod starego klienta nadal zapisuje users.fcm_token. Nowe kolumny mają wartości domyślne.

ALTER TABLE alerts ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'alert';
UPDATE alerts SET kind = 'sos'
 WHERE kind = 'alert' AND category = 'aggression' AND title LIKE '%🆘%';

ALTER TABLE notifications ADD COLUMN IF NOT EXISTS source_id TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS acknowledged_at TIMESTAMPTZ;
CREATE UNIQUE INDEX IF NOT EXISTS notifications_user_type_source_uidx
  ON notifications (user_id, type, source_id)
  WHERE source_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS user_push_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL DEFAULT 'unknown',
  device_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  disabled_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS user_push_tokens_user_idx
  ON user_push_tokens (user_id)
  WHERE disabled_at IS NULL;
INSERT INTO user_push_tokens (user_id, token, platform)
SELECT id, fcm_token, 'unknown' FROM users
 WHERE fcm_token IS NOT NULL
ON CONFLICT (token) DO NOTHING;

ALTER TABLE family_groups ADD COLUMN IF NOT EXISTS invite_expires_at TIMESTAMPTZ;
UPDATE family_groups
   SET invite_expires_at = NOW() + INTERVAL '30 days'
 WHERE invite_expires_at IS NULL;

CREATE TABLE IF NOT EXISTS family_pings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  response_status TEXT,
  response_at TIMESTAMPTZ,
  response_message TEXT
);
