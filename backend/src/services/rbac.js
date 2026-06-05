// RBAC adminów — ładowanie ról/uprawnień użytkownika.
// superadmin ma '*' (wildcard) = wszystkie uprawnienia.
// Kompatybilność wstecz: users.is_admin=TRUE traktowany jak superadmin
//   (gdyby backfill ról nie zaszedł / stare konto).
const db = require('../config/db');

/**
 * Zwraca { roles: [{key,name}], permissions: Set<string>, isSuperadmin: bool }.
 */
async function loadAccess(userId) {
  if (!userId) return { roles: [], permissions: new Set(), isSuperadmin: false };
  const { rows } = await db.query(
    `SELECT r.key, r.name, COALESCE(array_agg(p.permission) FILTER (WHERE p.permission IS NOT NULL), '{}') AS perms
     FROM admin_role_assignments a
     JOIN admin_roles r ON r.id = a.role_id
     LEFT JOIN admin_permissions p ON p.role_id = r.id
     WHERE a.user_id = $1
     GROUP BY r.key, r.name`,
    [userId]
  );
  const perms = new Set();
  const roles = [];
  for (const row of rows) {
    roles.push({ key: row.key, name: row.name });
    for (const p of row.perms) perms.add(p);
  }
  let isSuperadmin = perms.has('*');
  // Fallback kompatybilności: is_admin bez przypisanej roli → superadmin.
  if (roles.length === 0) {
    const { rows: u } = await db.query('SELECT is_admin FROM users WHERE id = $1', [userId]);
    if (u[0]?.is_admin) {
      isSuperadmin = true;
      roles.push({ key: 'superadmin', name: 'Super Admin' });
      perms.add('*');
    }
  }
  return { roles, permissions: perms, isSuperadmin };
}

/**
 * Czy access ma dane uprawnienie (wildcard '*' przechodzi zawsze).
 */
function hasPermission(access, permission) {
  if (!access) return false;
  if (access.isSuperadmin || access.permissions.has('*')) return true;
  return access.permissions.has(permission);
}

module.exports = { loadAccess, hasPermission };
