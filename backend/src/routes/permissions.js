/**
 * F34 — User capability matrix.
 *
 * Tracks user's app-side intent for each system permission category.
 * Source of truth = `user_capabilities` table.
 *
 * Frontend: `lib/screens/permissions/permissions_screen.dart`
 *
 * Wpięcie:
 *   app.use('/api/v1/permissions', auth, require('./routes/permissions'));
 */
const express = require('express');
const db = require('../config/db');
const auth = require('../middleware/auth');
const router = express.Router();

router.use(auth);

const ALLOWED_CAPABILITIES = new Set([
  'location',
  'camera',
  'microphone',
  'notifications',
  'biometrics',
  'sensors',
]);

const DEFAULTS = {
  location: false,
  camera: false,
  microphone: false,
  notifications: false,
  biometrics: false,
  sensors: false,
};

/**
 * GET /api/v1/permissions
 * Zwraca aktualne preferencje user (merge z DEFAULTS dla brakujących wpisów).
 */
router.get('/', async (req, res) => {
  try {
    const { rows } = await db.query(
      'SELECT capability, granted, updated_at FROM user_capabilities WHERE user_id = $1',
      [req.user.id]
    );
    const map = { ...DEFAULTS };
    const updated = {};
    for (const r of rows) {
      if (ALLOWED_CAPABILITIES.has(r.capability)) {
        map[r.capability] = r.granted;
        updated[r.capability] = r.updated_at;
      }
    }
    res.json({ capabilities: map, updated });
  } catch (e) {
    console.error('GET /permissions error', e);
    res.status(500).json({ error: 'Internal error' });
  }
});

/**
 * PUT /api/v1/permissions
 * Body: { capability: 'location', granted: true }
 * lub batch: { updates: [{capability,granted}, ...] }
 */
router.put('/', async (req, res) => {
  const updates = Array.isArray(req.body.updates)
    ? req.body.updates
    : [{ capability: req.body.capability, granted: req.body.granted }];

  for (const u of updates) {
    if (!ALLOWED_CAPABILITIES.has(u.capability) || typeof u.granted !== 'boolean') {
      return res.status(400).json({ error: `Invalid update: ${JSON.stringify(u)}` });
    }
  }

  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');
    for (const u of updates) {
      await client.query(
        `INSERT INTO user_capabilities (user_id, capability, granted, updated_at)
         VALUES ($1, $2, $3, NOW())
         ON CONFLICT (user_id, capability)
         DO UPDATE SET granted = EXCLUDED.granted, updated_at = NOW()`,
        [req.user.id, u.capability, u.granted]
      );
    }
    await client.query('COMMIT');
    res.json({ ok: true, updated: updates.length });
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('PUT /permissions error', e);
    res.status(500).json({ error: 'Internal error' });
  } finally {
    client.release();
  }
});

module.exports = router;
