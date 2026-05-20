/**
 * requireAdmin — middleware do ochrony endpointów /api/v1/admin/*
 *
 * Musi być WPIĘTE PO `require('./auth')` które ustawia req.user z JWT.
 * Sprawdza `users.is_admin = TRUE` w DB. NIE polega na claim w JWT
 * (token może żyć długo, a flagę odbieramy w DB w czasie rzeczywistym).
 */
const db = require('../config/db');

module.exports = async (req, res, next) => {
  const userId = req.user?.id;
  if (!userId) return res.status(401).json({ error: 'Unauthorized' });
  try {
    const { rows } = await db.query(
      'SELECT is_admin FROM users WHERE id = $1',
      [userId]
    );
    if (!rows.length || !rows[0].is_admin) {
      return res.status(403).json({ error: 'Admin only' });
    }
    next();
  } catch (e) {
    console.error('requireAdmin error', e);
    res.status(500).json({ error: 'Internal error' });
  }
};
