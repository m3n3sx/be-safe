// requirePermission(key) — middleware RBAC dla endpointów admin.
// Musi być PO auth (ustawia req.user). Ładuje uprawnienia usera, sprawdza key.
// superadmin/'*' przechodzi zawsze. Wynik cache'owany na req (req._access).
const { loadAccess, hasPermission } = require('../services/rbac');

module.exports = (permission) => async (req, res, next) => {
  const userId = req.user?.id;
  if (!userId) return res.status(401).json({ error: 'Unauthorized' });
  try {
    if (!req._access) req._access = await loadAccess(userId);
    if (req._access.roles.length === 0) {
      return res.status(403).json({ error: 'Admin only' });
    }
    if (permission && !hasPermission(req._access, permission)) {
      return res.status(403).json({ error: 'Forbidden', required: permission });
    }
    next();
  } catch (e) {
    console.error('[requirePermission]', e.message);
    res.status(500).json({ error: 'Internal error' });
  }
};
