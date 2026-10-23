-- be:Safe VPS schema catch-up (v137 code vs partial DB).
-- Idempotent. Apply:
--   docker exec -i be-safe-postgres-1 psql -U besafe -d besafe -v ON_ERROR_STOP=1 < this_file
-- Created 2026-10-20 after interrupted VPS bring-up left backend crashing on missing columns/tables.

BEGIN;

-- ---------- users columns (F12/F15/F33/admin) ----------
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_kpp BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS kpp_certificate TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS app_mode VARCHAR(16) NOT NULL DEFAULT 'normal';
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_banned BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS banned_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS ban_reason TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS verified_role VARCHAR(32);
ALTER TABLE users ADD COLUMN IF NOT EXISTS organization TEXT;

DO $$ BEGIN
  ALTER TABLE users ADD CONSTRAINT users_app_mode_check
    CHECK (app_mode IN ('kids', 'senior', 'normal'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------- alerts ----------
ALTER TABLE alerts ADD COLUMN IF NOT EXISTS is_anonymous BOOLEAN NOT NULL DEFAULT FALSE;

-- ---------- auth tokens ----------
CREATE TABLE IF NOT EXISTS email_verification_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(128) NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_email_verify_user ON email_verification_tokens(user_id);

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(128) NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_password_reset_user ON password_reset_tokens(user_id);

-- ---------- family pings / events / messages ----------
CREATE TABLE IF NOT EXISTS family_pings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  response_status VARCHAR(16),
  response_at TIMESTAMPTZ,
  response_message VARCHAR(300)
);
CREATE INDEX IF NOT EXISTS idx_family_pings_recipient
  ON family_pings(recipient_id, sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_family_pings_pending
  ON family_pings(recipient_id) WHERE response_status IS NULL;

CREATE TABLE IF NOT EXISTS family_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  location TEXT,
  reminder_minutes_before INT,
  reminder_sent BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_family_events_group ON family_events(group_id, starts_at);
CREATE INDEX IF NOT EXISTS idx_family_events_reminders
  ON family_events(starts_at) WHERE reminder_sent = FALSE AND reminder_minutes_before IS NOT NULL;

CREATE TABLE IF NOT EXISTS family_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body VARCHAR(2000) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_family_messages_group_time
  ON family_messages(group_id, created_at DESC);

-- ---------- pets (F25) ----------
CREATE TABLE IF NOT EXISTS pets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(80) NOT NULL,
  species VARCHAR(16) NOT NULL DEFAULT 'dog',
  breed TEXT,
  color TEXT,
  age_years INT,
  microchip TEXT,
  photo_url TEXT,
  notes TEXT,
  home_location GEOGRAPHY(POINT, 4326),
  last_seen_location GEOGRAPHY(POINT, 4326),
  last_seen_at TIMESTAMPTZ,
  status VARCHAR(16) NOT NULL DEFAULT 'home',
  lost_at TIMESTAMPTZ,
  lost_description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_pets_group ON pets(group_id);
CREATE INDEX IF NOT EXISTS idx_pets_lost_loc ON pets USING GIST(last_seen_location);

-- ---------- AEDs (F11) ----------
CREATE TABLE IF NOT EXISTS aeds (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source VARCHAR(32) NOT NULL DEFAULT 'osm',
  source_id VARCHAR(64) NOT NULL,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  description TEXT,
  address TEXT,
  operator TEXT,
  opening_hours TEXT,
  indoor BOOLEAN,
  last_synced_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (source, source_id)
);
CREATE INDEX IF NOT EXISTS idx_aeds_loc ON aeds USING GIST(location);

-- ---------- AQI GIOŚ (F17) ----------
CREATE TABLE IF NOT EXISTS air_quality_stations (
  id INTEGER PRIMARY KEY,
  name TEXT,
  location GEOGRAPHY(POINT, 4326),
  city TEXT,
  address TEXT,
  last_synced_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_aqi_loc ON air_quality_stations USING GIST(location);

CREATE TABLE IF NOT EXISTS air_quality_readings (
  station_id INTEGER PRIMARY KEY REFERENCES air_quality_stations(id) ON DELETE CASCADE,
  aqi_index INT,
  aqi_label TEXT,
  pm10 REAL,
  pm25 REAL,
  no2 REAL,
  so2 REAL,
  o3 REAL,
  measured_at TIMESTAMPTZ,
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------- check-ins / reports / audit ----------
CREATE TABLE IF NOT EXISTS user_checkins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(32) NOT NULL DEFAULT 'safe',
  message TEXT,
  location GEOGRAPHY(POINT, 4326),
  battery_level INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_user_checkins_user ON user_checkins(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS alert_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  alert_id UUID NOT NULL REFERENCES alerts(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason VARCHAR(64),
  details TEXT,
  status VARCHAR(32) NOT NULL DEFAULT 'open',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_alert_reports_alert ON alert_reports(alert_id, created_at DESC);

CREATE TABLE IF NOT EXISTS admin_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(64) NOT NULL,
  target_type VARCHAR(64),
  target_id TEXT,
  payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_admin_audit_created ON admin_audit_log(created_at DESC);

COMMIT;
