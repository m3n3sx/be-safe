-- RBAC adminów — role, uprawnienia granularne, przypisania.
-- Idempotentna. Uruchom na prod:
--   psql "$DATABASE_URL" -f db/migrations/2026-06-05_rbac.sql
-- superadmin = wildcard '*'. is_admin=TRUE zachowane (kompatybilność wstecz).

CREATE TABLE IF NOT EXISTS admin_roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key VARCHAR(32) UNIQUE NOT NULL,
  name VARCHAR(64) NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS admin_permissions (
  role_id UUID NOT NULL REFERENCES admin_roles(id) ON DELETE CASCADE,
  permission VARCHAR(48) NOT NULL,
  PRIMARY KEY (role_id, permission)
);
CREATE TABLE IF NOT EXISTS admin_role_assignments (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES admin_roles(id) ON DELETE CASCADE,
  granted_by UUID REFERENCES users(id),
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, role_id)
);
CREATE INDEX IF NOT EXISTS idx_admin_assign_user ON admin_role_assignments(user_id);

-- Seed ról (idempotentnie)
INSERT INTO admin_roles (key, name, description) VALUES
  ('superadmin', 'Super Admin', 'Pełny dostęp do wszystkiego (wildcard *)'),
  ('moderator',  'Moderator',   'Moderacja alertów i zgłoszeń'),
  ('support',    'Wsparcie',    'Obsługa użytkowników (podgląd, ban)'),
  ('analyst',    'Analityk',    'Tylko odczyt statystyk i systemu')
ON CONFLICT (key) DO NOTHING;

-- Uprawnienia per rola (czyść i ustaw na nowo, żeby było deklaratywnie/idempotentnie)
DELETE FROM admin_permissions WHERE role_id IN (SELECT id FROM admin_roles WHERE key IN ('superadmin','moderator','support','analyst'));

-- superadmin: wildcard
INSERT INTO admin_permissions (role_id, permission)
SELECT id, '*' FROM admin_roles WHERE key = 'superadmin';

-- moderator
INSERT INTO admin_permissions (role_id, permission)
SELECT r.id, p FROM admin_roles r, unnest(ARRAY[
  'system.read','users.read','alerts.read','alerts.edit','alerts.delete',
  'reports.read','reports.resolve','groups.read','audit.read'
]) AS p WHERE r.key = 'moderator';

-- support
INSERT INTO admin_permissions (role_id, permission)
SELECT r.id, p FROM admin_roles r, unnest(ARRAY[
  'system.read','users.read','users.ban','reports.read','groups.read'
]) AS p WHERE r.key = 'support';

-- analyst
INSERT INTO admin_permissions (role_id, permission)
SELECT r.id, p FROM admin_roles r, unnest(ARRAY[
  'system.read','users.read','alerts.read','reports.read','groups.read','audit.read'
]) AS p WHERE r.key = 'analyst';

-- Backfill: każdy is_admin=TRUE dostaje rolę superadmin (kompatybilność wstecz)
INSERT INTO admin_role_assignments (user_id, role_id)
SELECT u.id, r.id
FROM users u CROSS JOIN admin_roles r
WHERE u.is_admin = TRUE AND r.key = 'superadmin'
ON CONFLICT (user_id, role_id) DO NOTHING;
