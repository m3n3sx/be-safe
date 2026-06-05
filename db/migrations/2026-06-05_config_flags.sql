-- PowerAdmin — konfiguracja runtime (app_config) + feature flags.
-- Idempotentna. Uruchom na prod:
--   psql "$DATABASE_URL" -f db/migrations/2026-06-05_config_flags.sql

-- Konfiguracja runtime (klucz→wartość JSONB) z historią poprzedniej wartości (rollback).
CREATE TABLE IF NOT EXISTS app_config (
  key VARCHAR(64) PRIMARY KEY,
  value JSONB NOT NULL,
  prev_value JSONB,
  description TEXT,
  updated_by UUID REFERENCES users(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Feature flags (włącz/wyłącz funkcje globalnie lub per-segment).
CREATE TABLE IF NOT EXISTS feature_flags (
  key VARCHAR(64) PRIMARY KEY,
  enabled BOOLEAN NOT NULL DEFAULT FALSE,
  description TEXT,
  segment VARCHAR(32),                 -- np. 'all','kids','senior','beta' (NULL=all)
  updated_by UUID REFERENCES users(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed kilku flag startowych (idempotentnie)
INSERT INTO feature_flags (key, enabled, description, segment) VALUES
  ('neighborhood_chat', TRUE,  'Czat sąsiedzki (F14)', 'all'),
  ('ai_image_moderation', TRUE, 'Moderacja zdjęć Vision (F06)', 'all'),
  ('ghost_mode', TRUE, 'Czasowy ghost lokalizacji (F23)', 'all')
ON CONFLICT (key) DO NOTHING;

-- Seed konfiguracji startowej
INSERT INTO app_config (key, value, description) VALUES
  ('alert_default_radius_m', '500', 'Domyślny promień alertu (m)'),
  ('moderation_ai_enabled', 'true', 'Druga warstwa moderacji AI (Vertex)'),
  ('broadcast_rate_limit_per_hour', '5', 'Limit broadcastów/godzinę')
ON CONFLICT (key) DO NOTHING;
