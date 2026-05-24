-- AlertMap Database Schema
-- PostgreSQL + PostGIS

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    avatar_url TEXT,
    alert_radius_m INT NOT NULL DEFAULT 500,
    reputation_score INT NOT NULL DEFAULT 100,
    is_child BOOLEAN NOT NULL DEFAULT FALSE,
    phone VARCHAR(20),
    fcm_token TEXT,
    last_location GEOGRAPHY(POINT, 4326),
    last_location_at TIMESTAMPTZ,
    last_seen_at TIMESTAMPTZ,
    last_battery_level INT,
    last_battery_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_location ON users USING GIST(last_location);

-- ============================================
-- ALERTS (zgłoszenia zagrożeń)
-- ============================================
CREATE TYPE alert_category AS ENUM (
    -- ogólne
    'aggression', 'theft', 'accident', 'fire', 'flood',
    'ice', 'construction', 'animal', 'dark_area', 'drugs',
    'police', 'weather', 'other',
    -- ochrona dzieci
    'stranger_danger', 'traffic_danger', 'playground_hazard',
    'water_hazard', 'school_zone'
);

CREATE TYPE alert_status AS ENUM ('active', 'expired', 'hidden', 'removed');

CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID NOT NULL REFERENCES users(id),
    category alert_category NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    photo_url TEXT,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    radius_m INT NOT NULL DEFAULT 100,
    status alert_status NOT NULL DEFAULT 'active',
    confirms INT NOT NULL DEFAULT 0,
    denies INT NOT NULL DEFAULT 0,
    trust_score REAL NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alerts_location ON alerts USING GIST(location);
CREATE INDEX idx_alerts_status_expires ON alerts(status, expires_at);
CREATE INDEX idx_alerts_author ON alerts(author_id);

-- ============================================
-- ALERT VOTES (potwierdzenia / odrzucenia)
-- ============================================
CREATE TYPE vote_type AS ENUM ('confirm', 'deny');

CREATE TABLE alert_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_id UUID NOT NULL REFERENCES alerts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    vote vote_type NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(alert_id, user_id)
);

-- ============================================
-- ALERT NOTIFICATIONS (wysłane powiadomienia — deduplikacja)
-- ============================================
CREATE TABLE alert_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_id UUID NOT NULL REFERENCES alerts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(alert_id, user_id)
);

-- ============================================
-- FAMILY GROUPS
-- ============================================
CREATE TABLE family_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    owner_id UUID NOT NULL REFERENCES users(id),
    invite_code VARCHAR(8) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- F35: rozszerzone role rodzinne (v69)
-- Original: ('parent', 'child') — na prod rozszerzone przez ALTER TYPE
CREATE TYPE family_role AS ENUM (
    'parent',
    'child',
    'senior',
    'guardian',
    'family_member',
    'partner',
    'friend',
    'other'
);

CREATE TABLE family_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    role family_role NOT NULL,
    tracking_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    school_hours_silent BOOLEAN NOT NULL DEFAULT FALSE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

-- ============================================
-- GEOFENCES (bezpieczne strefy)
-- ============================================
CREATE TABLE geofences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    center GEOGRAPHY(POINT, 4326) NOT NULL,
    radius_m INT NOT NULL DEFAULT 200,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_geofences_center ON geofences USING GIST(center);

-- ============================================
-- SAFE ROUTES (bezpieczne trasy dziecka)
-- ============================================
CREATE TABLE safe_routes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    polyline GEOGRAPHY(LINESTRING, 4326) NOT NULL,
    threshold_m INT NOT NULL DEFAULT 100 CHECK (threshold_m BETWEEN 30 AND 1000),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_safe_routes_user ON safe_routes(user_id) WHERE is_active = TRUE;
CREATE INDEX idx_safe_routes_polyline ON safe_routes USING GIST(polyline);

-- ============================================
-- ESCORT SESSIONS (F03 Follow Me)
-- ============================================
CREATE TABLE escort_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    watcher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    group_id UUID REFERENCES family_groups(id) ON DELETE SET NULL,
    destination_lat DOUBLE PRECISION NOT NULL,
    destination_lng DOUBLE PRECISION NOT NULL,
    destination_name VARCHAR(200),
    eta_seconds INTEGER NOT NULL CHECK (eta_seconds > 0 AND eta_seconds <= 14400),
    status VARCHAR(16) NOT NULL DEFAULT 'active' CHECK (status IN ('active','completed','expired','panic')),
    last_location_lat DOUBLE PRECISION,
    last_location_lng DOUBLE PRECISION,
    last_update_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX idx_escort_active_requester ON escort_sessions(requester_id) WHERE status='active';
CREATE INDEX idx_escort_active_watcher ON escort_sessions(watcher_id) WHERE status='active';
CREATE INDEX idx_escort_active_started ON escort_sessions(started_at) WHERE status='active';

-- ============================================
-- ALERT COMMENTS
-- ============================================
CREATE TABLE alert_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_id UUID NOT NULL REFERENCES alerts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alert_comments_alert ON alert_comments(alert_id, created_at);

-- ============================================
-- LOCATION HISTORY (historia lokalizacji dzieci)
-- ============================================
CREATE TABLE location_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_location_history_user_time ON location_history(user_id, recorded_at DESC);

-- ============================================
-- SHARE LOCATION LINKS (tymczasowe linki do śledzenia)
-- ============================================
CREATE TABLE share_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    token VARCHAR(32) UNIQUE NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Znajdź aktywne alerty w promieniu od punktu
CREATE OR REPLACE FUNCTION find_alerts_nearby(
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    radius_m INT DEFAULT 1000
)
RETURNS SETOF alerts AS $$
    SELECT * FROM alerts
    WHERE status = 'active'
      AND expires_at > NOW()
      AND ST_DWithin(location, ST_MakePoint(lng, lat)::geography, radius_m)
    ORDER BY created_at DESC;
$$ LANGUAGE sql STABLE;

-- Auto-ukryj alerty z >3 odrzuceniami
CREATE OR REPLACE FUNCTION check_alert_denies()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.vote = 'deny' THEN
        UPDATE alerts SET denies = denies + 1
        WHERE id = NEW.alert_id;

        IF (SELECT denies FROM alerts WHERE id = NEW.alert_id) > 3 THEN
            UPDATE alerts SET status = 'hidden' WHERE id = NEW.alert_id;
        END IF;
    ELSE
        UPDATE alerts SET confirms = confirms + 1
        WHERE id = NEW.alert_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_alert_vote
    AFTER INSERT ON alert_votes
    FOR EACH ROW EXECUTE FUNCTION check_alert_denies();

-- Auto-wygaszanie alertów
CREATE OR REPLACE FUNCTION expire_old_alerts()
RETURNS void AS $$
    UPDATE alerts SET status = 'expired'
    WHERE status = 'active' AND expires_at < NOW();
$$ LANGUAGE sql;

-- ============================================
-- ADMIN / CAPABILITIES (v68+)
-- ============================================
-- NOTE: schema.sql is partially out of date — many ALTER TABLE migrations
-- live only on prod. New additions below are also applied on prod via migrations.

ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT FALSE;

-- F34 capability matrix (user's recorded permission preferences).
-- Tracks app-side intent (toggle ON/OFF) — actual system grant is checked via
-- permission_handler on device. This table is the SOURCE OF TRUTH for "user
-- chose to enable feature X" so we can re-prompt or skip features cleanly.
CREATE TABLE IF NOT EXISTS user_capabilities (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    capability VARCHAR(32) NOT NULL,
    granted BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, capability)
);

-- Capabilities: 'location', 'camera', 'microphone', 'notifications', 'biometrics', 'sensors'

-- F23 Ghost mode (granular visibility per viewer x target x field) - dodano 2026-05-21
CREATE TABLE IF NOT EXISTS family_visibility (
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  viewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  field VARCHAR(32) NOT NULL,
  granted BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (group_id, viewer_id, target_id, field)
);
CREATE INDEX IF NOT EXISTS idx_visibility_target ON family_visibility(group_id, target_id);
CREATE INDEX IF NOT EXISTS idx_visibility_viewer ON family_visibility(group_id, viewer_id);
