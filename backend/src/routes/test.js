// Admin-only test fixtures reset endpoint.
// Gated by env TEST_RESET_SECRET. Only operates on accounts with is_test=TRUE.
// Used by Patrol E2E suites to bring a persona back to a known clean state
// between scenarios without touching real users.

const express = require('express');
const fs = require('fs');
const path = require('path');
const router = express.Router();
const db = require('../config/db');

const METRICS_DIR = '/tmp/besafe_metrics';
try { fs.mkdirSync(METRICS_DIR, { recursive: true }); } catch (_) {}

const SECRET = process.env.TEST_RESET_SECRET;

// Default fixture coords — Września rynek
const DEFAULT_LAT = 52.3247;
const DEFAULT_LNG = 17.5667;

function checkSecret(req, res) {
  if (!SECRET) {
    res.status(503).json({ error: 'TEST_RESET_SECRET not configured' });
    return false;
  }
  const provided = req.headers['x-test-secret'] || req.body?.secret;
  if (provided !== SECRET) {
    res.status(401).json({ error: 'Invalid test secret' });
    return false;
  }
  return true;
}

// POST /api/v1/test/reset-persona
// body: { username, secret? } (secret can also come from X-Test-Secret header)
//
// Resets per-user state:
//  - clears author's alerts
//  - clears author's votes/reports/comments
//  - clears user's alert_notifications
//  - clears user's location_history
//  - clears user's fcm_token (so notifications don't go to stale devices)
//  - resets last_location to default (Września rynek)
//  - clears battery / last_seen
// Does NOT delete the user, groups, geofences, or safe_routes — those are
// shared fixtures across the persona suite and rebuilt only by seed script.
router.post('/reset-persona', async (req, res) => {
  if (!checkSecret(req, res)) return;
  const { username } = req.body || {};
  if (!username || typeof username !== 'string') {
    return res.status(400).json({ error: 'username required' });
  }

  const { rows: [user] } = await db.query(
    `SELECT id FROM users WHERE username = $1 AND is_test = TRUE`,
    [username]
  );
  if (!user) {
    return res.status(404).json({ error: 'Test user not found or not flagged is_test' });
  }

  const userId = user.id;
  const cleanup = {};

  // 1) Alerts authored by this user (cascades to votes/comments/reports/notifications)
  const a = await db.query(`DELETE FROM alerts WHERE author_id = $1`, [userId]);
  cleanup.alerts = a.rowCount;

  // 2) Votes/reports/comments made by this user on other people's alerts
  const v = await db.query(`DELETE FROM alert_votes WHERE user_id = $1`, [userId]);
  cleanup.votes = v.rowCount;
  const r = await db.query(`DELETE FROM alert_reports WHERE reporter_id = $1`, [userId]);
  cleanup.reports = r.rowCount;
  const c = await db.query(`DELETE FROM alert_comments WHERE user_id = $1`, [userId]);
  cleanup.comments = c.rowCount;

  // 3) Notification dedup state for this user
  const n = await db.query(`DELETE FROM alert_notifications WHERE user_id = $1`, [userId]);
  cleanup.notifications = n.rowCount;

  // 4) Location history
  const h = await db.query(`DELETE FROM location_history WHERE user_id = $1`, [userId]);
  cleanup.location_history = h.rowCount;

  // 5) Family pings — both as sender and as recipient
  const p1 = await db.query(`DELETE FROM family_pings WHERE sender_id = $1 OR recipient_id = $1`, [userId]);
  cleanup.family_pings = p1.rowCount;

  // 6) Reset user fields (location to Września rynek, clear device + battery + last_seen)
  await db.query(
    `UPDATE users SET
       fcm_token = NULL,
       last_location = ST_SetSRID(ST_MakePoint($2, $3), 4326)::geography,
       last_location_at = NOW(),
       last_battery_level = NULL,
       last_battery_at = NULL,
       last_seen_at = NOW(),
       alert_radius_m = 1000
     WHERE id = $1`,
    [userId, DEFAULT_LNG, DEFAULT_LAT]
  );

  // 7) Check-ins
  const ci = await db.query(`DELETE FROM user_checkins WHERE user_id = $1`, [userId]);
  cleanup.checkins = ci.rowCount;

  res.json({ ok: true, username, user_id: userId, cleanup });
});

// POST /api/v1/test/reset-all
// Resets ALL is_test=TRUE users to clean fixture state in one shot.
// Body: { secret? }
router.post('/reset-all', async (req, res) => {
  if (!checkSecret(req, res)) return;

  const { rows: users } = await db.query(
    `SELECT id, username FROM users WHERE is_test = TRUE`
  );
  if (users.length === 0) {
    return res.json({ ok: true, reset: 0, message: 'No test users found' });
  }

  const ids = users.map(u => u.id);

  await db.query(`DELETE FROM alerts WHERE author_id = ANY($1::uuid[])`, [ids]);
  await db.query(`DELETE FROM alert_votes WHERE user_id = ANY($1::uuid[])`, [ids]);
  await db.query(`DELETE FROM alert_reports WHERE reporter_id = ANY($1::uuid[])`, [ids]);
  await db.query(`DELETE FROM alert_comments WHERE user_id = ANY($1::uuid[])`, [ids]);
  await db.query(`DELETE FROM alert_notifications WHERE user_id = ANY($1::uuid[])`, [ids]);
  await db.query(`DELETE FROM location_history WHERE user_id = ANY($1::uuid[])`, [ids]);
  await db.query(`DELETE FROM family_pings WHERE sender_id = ANY($1::uuid[]) OR recipient_id = ANY($1::uuid[])`, [ids]);
  await db.query(`DELETE FROM user_checkins WHERE user_id = ANY($1::uuid[])`, [ids]);

  await db.query(
    `UPDATE users SET
       fcm_token = NULL,
       last_location = ST_SetSRID(ST_MakePoint($2, $3), 4326)::geography,
       last_location_at = NOW(),
       last_battery_level = NULL,
       last_battery_at = NULL,
       last_seen_at = NOW(),
       alert_radius_m = 1000
     WHERE id = ANY($1::uuid[])`,
    [ids, DEFAULT_LNG, DEFAULT_LAT]
  );

  res.json({ ok: true, reset: users.length, usernames: users.map(u => u.username) });
});

// GET /api/v1/test/health
// Lightweight probe — confirms endpoint is mounted and secret is configured.
// POST /api/v1/test/metrics — zapisuje/appenduje metryki E2E do /tmp/besafe_metrics/<runId>.json
// Supports two modes:
//   1) full payload: {run_id, flushed_at, metrics: {...}} (overwrite)
//   2) incremental: {run_id, persona, suite, entry: {name, value?, passed?, note?, ...}} (append)
router.post('/metrics', express.json({ limit: '2mb' }), (req, res) => {
  if (!checkSecret(req, res)) return;
  const body = req.body || {};
  const runId = String(body.run_id || `run_${Date.now()}`).replace(/[^a-zA-Z0-9_-]/g, '_');
  const file = path.join(METRICS_DIR, `${runId}.json`);
  try {
    if (body.entry) {
      // Incremental append
      const key = `${body.persona || 'global'}__${body.suite || 'unknown'}`;
      let doc;
      try {
        doc = JSON.parse(fs.readFileSync(file, 'utf8'));
      } catch (_) {
        doc = { run_id: runId, started_at: new Date().toISOString(), metrics: {} };
      }
      doc.metrics = doc.metrics || {};
      doc.metrics[key] = doc.metrics[key] || [];
      doc.metrics[key].push(body.entry);
      doc.updated_at = new Date().toISOString();
      fs.writeFileSync(file, JSON.stringify(doc, null, 2));
      return res.json({ ok: true, mode: 'append', file, run_id: runId, count: doc.metrics[key].length });
    }
    // Full overwrite
    fs.writeFileSync(file, JSON.stringify(body, null, 2));
    console.log(`[metrics] wrote ${file} (${(JSON.stringify(body).length / 1024).toFixed(1)} KB)`);
    res.json({ ok: true, mode: 'full', file, run_id: runId });
  } catch (e) {
    console.error('[metrics]', e.message);
    res.status(500).json({ error: e.message });
  }
});

// GET /api/v1/test/metrics — listuje wszystkie pliki metryk
router.get('/metrics', (req, res) => {
  if (!checkSecret(req, res)) return;
  try {
    const files = fs.readdirSync(METRICS_DIR)
      .filter(f => f.endsWith('.json'))
      .map(f => {
        const stat = fs.statSync(path.join(METRICS_DIR, f));
        return { file: f, size: stat.size, mtime: stat.mtime };
      })
      .sort((a, b) => b.mtime - a.mtime);
    res.json({ files });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/v1/test/metrics/:runId — zwraca konkretny plik
router.get('/metrics/:runId', (req, res) => {
  if (!checkSecret(req, res)) return;
  const safe = String(req.params.runId).replace(/[^a-zA-Z0-9_-]/g, '_');
  const file = path.join(METRICS_DIR, `${safe}.json`);
  if (!fs.existsSync(file)) return res.status(404).json({ error: 'not found' });
  res.type('application/json').send(fs.readFileSync(file, 'utf8'));
});

// F15: nadanie/odebranie weryfikacji konta (instytucja: police/firefighter/emt/city/school)
// body: { username, is_verified, verified_role?, organization?, secret? }
router.post('/verify-user', express.json(), async (req, res) => {
  if (!checkSecret(req, res)) return;
  const { username, is_verified, verified_role, organization } = req.body || {};
  if (!username || typeof username !== 'string') {
    return res.status(400).json({ error: 'username required' });
  }
  if (typeof is_verified !== 'boolean') {
    return res.status(400).json({ error: 'is_verified (boolean) required' });
  }
  const allowedRoles = ['police', 'firefighter', 'emt', 'ambulance', 'city', 'gov', 'school', null];
  const role = is_verified ? (verified_role ?? null) : null;
  if (is_verified && verified_role && !allowedRoles.includes(verified_role)) {
    return res.status(400).json({ error: `verified_role must be one of: ${allowedRoles.filter(Boolean).join('|')}` });
  }
  const org = is_verified ? (organization ?? null) : null;
  try {
    const { rows } = await db.query(
      `UPDATE users SET is_verified=$2, verified_role=$3, organization=$4 WHERE username=$1
       RETURNING id, username, is_verified, verified_role, organization`,
      [username, is_verified, role, org]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'User not found' });
    res.json({ ok: true, user: rows[0] });
  } catch (e) {
    console.error('[verify-user]', e.message);
    res.status(500).json({ error: 'Server error' });
  }
});

router.get('/health', (req, res) => {
  res.json({
    ok: true,
    secret_configured: !!SECRET,
    time: new Date().toISOString(),
  });
});

module.exports = router;
