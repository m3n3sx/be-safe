/**
 * Admin routes — wymaga is_admin=TRUE.
 *
 * Wpięcie w index.js:
 *   const auth = require('./middleware/auth');
 *   const requireAdmin = require('./middleware/requireAdmin');
 *   app.use('/api/v1/admin', auth, requireAdmin, require('./routes/admin'));
 */
const express = require('express');
const fs = require('fs');
const path = require('path');
const db = require('../config/db');
const requirePermission = require('../middleware/requirePermission');
const { loadAccess } = require('../services/rbac');
const { processMetrics, dbMetrics, cached } = require('../services/system_metrics');
const { gcpMetrics } = require('../services/gcp_metrics');
const { integrationsHealth } = require('../services/integrations_health');
const { notifyUser } = require('../services/fcm');
const router = express.Router();

// Rate-limit broadcastów (in-memory, per proces): max N/godzinę.
let _bcTimes = [];

const BACKUP_DIR = '/home/ubuntu/backups';
const LAST_BACKUP_FILE = path.join(BACKUP_DIR, 'last_backup.json');

// ----- helpers -----
async function audit(adminId, action, targetType, targetId, payload) {
  try {
    await db.query(
      `INSERT INTO admin_audit_log (admin_id, action, target_type, target_id, payload)
       VALUES ($1, $2, $3, $4, $5)`,
      [adminId, action, targetType, targetId || null, payload || null]
    );
  } catch (e) {
    console.error('[audit]', e.message);
  }
}

// Token z metadata server (Cloud Run) — tożsamość SA do wywołań GCP REST.
async function metadataToken() {
  const r = await fetch(
    'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',
    { headers: { 'Metadata-Flavor': 'Google' } }
  );
  if (!r.ok) throw new Error(`metadata token ${r.status}`);
  return (await r.json()).access_token;
}

// =========================================================================
// SYSTEM
// =========================================================================

router.get('/ping', requirePermission(), (req, res) => res.json({ ok: true, user: req.user.id }));

// /admin/me — role + uprawnienia zalogowanego admina (UI decyduje co pokazać).
router.get('/me', requirePermission(), async (req, res) => {
  try {
    const access = await loadAccess(req.user.id);
    res.json({
      user_id: req.user.id,
      roles: access.roles,
      permissions: access.isSuperadmin ? ['*'] : [...access.permissions],
      is_superadmin: access.isSuperadmin,
    });
  } catch (e) {
    res.status(500).json({ error: 'Cannot load access' });
  }
});

router.get('/backup-status', requirePermission('system.read'), async (req, res) => {
  const PROJECT = process.env.GCP_PROJECT_ID || 'project-1674d55f-90e0-4e1a-884';
  const INSTANCE = process.env.CLOUD_SQL_INSTANCE || 'besafe-pg';
  try {
    const token = await metadataToken();
    const r = await fetch(
      `https://sqladmin.googleapis.com/v1/projects/${PROJECT}/instances/${INSTANCE}/backupRuns?maxResults=5`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    if (!r.ok) return res.status(502).json({ error: `Cloud SQL API ${r.status}` });
    const data = await r.json();
    const runs = (data.items || []).map((b) => ({
      id: b.id, status: b.status, type: b.type,
      start_time: b.startTime, end_time: b.endTime, location: b.location,
    }));
    const latest = runs.find((b) => b.status === 'SUCCESSFUL') || runs[0] || null;
    const ageH = latest?.end_time ? (Date.now() - new Date(latest.end_time).getTime()) / 3.6e6 : null;
    res.json({
      source: 'cloud_sql_automated',
      instance: INSTANCE,
      latest,
      age_hours: ageH != null ? Math.round(ageH * 10) / 10 : null,
      is_stale: ageH != null ? ageH > 26 : null,
      recent: runs,
    });
  } catch (e) {
    console.error('[admin/backup-status]', e.message);
    res.status(500).json({ error: 'Cannot read Cloud SQL backups', detail: e.message?.slice(0, 120) });
  }
});

// /admin/system — zasoby: proces backendu + baza + metryki GCP (Cloud Run/GCS).
router.get('/system', requirePermission('system.read'), async (req, res) => {
  try {
    const [db_, gcp] = await Promise.all([
      cached('db', 15000, dbMetrics),
      cached('gcp', 60000, gcpMetrics),
    ]);
    res.json({ process: processMetrics(), database: db_, gcp, time: new Date().toISOString() });
  } catch (e) {
    console.error('[admin/system]', e.message);
    res.status(500).json({ error: 'Cannot load system metrics' });
  }
});

// /admin/analytics — szereg czasowy (14 dni): nowi użytkownicy + alerty / dzień.
router.get('/analytics', requirePermission('system.read'), async (req, res) => {
  const days = Math.min(parseInt(req.query.days, 10) || 14, 90);
  try {
    const { rows } = await db.query(
      `WITH d AS (
         SELECT generate_series(CURRENT_DATE - ($1::int - 1), CURRENT_DATE, '1 day')::date AS day
       )
       SELECT to_char(d.day,'YYYY-MM-DD') AS day,
         (SELECT count(*)::int FROM users  u WHERE u.created_at::date = d.day) AS users,
         (SELECT count(*)::int FROM alerts a WHERE a.created_at::date = d.day) AS alerts
       FROM d ORDER BY d.day`,
      [days]
    );
    res.json({ days, series: rows });
  } catch (e) {
    console.error('[admin/analytics]', e.message);
    res.status(500).json({ error: 'Cannot load analytics' });
  }
});
router.get('/integrations/health', requirePermission('system.read'), async (req, res) => {
  try {
    const data = await cached('integrations', 30000, integrationsHealth);
    res.json(data);
  } catch (e) {
    res.status(500).json({ error: 'Cannot check integrations' });
  }
});

router.get('/stats', requirePermission('system.read'), async (req, res) => {
  try {
    const [users, alerts, groups, pets, reports] = await Promise.all([
      db.query("SELECT COUNT(*)::int AS n, COUNT(*) FILTER (WHERE is_banned)::int AS banned, COUNT(*) FILTER (WHERE is_admin)::int AS admins, COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '7 days')::int AS new_week FROM users"),
      db.query("SELECT COUNT(*)::int AS n, COUNT(*) FILTER (WHERE status='active')::int AS active, COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '24 hours')::int AS new_24h FROM alerts"),
      db.query('SELECT COUNT(*)::int AS n FROM family_groups'),
      db.query("SELECT COUNT(*)::int AS n, COUNT(*) FILTER (WHERE status='lost')::int AS lost FROM pets"),
      db.query("SELECT COUNT(*)::int AS pending FROM alert_reports WHERE status='pending'"),
    ]);
    res.json({
      users: users.rows[0],
      alerts: alerts.rows[0],
      groups: groups.rows[0],
      pets: pets.rows[0],
      reports_pending: reports.rows[0].pending,
    });
  } catch (e) {
    console.error('stats err', e.message);
    res.status(500).json({ error: 'Cannot load stats' });
  }
});

router.get('/audit-log', requirePermission('audit.read'), async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 100, 500);
  const { rows } = await db.query(
    `SELECT a.*, u.username AS admin_username
     FROM admin_audit_log a
     JOIN users u ON u.id = a.admin_id
     ORDER BY a.created_at DESC LIMIT $1`,
    [limit]
  );
  res.json({ entries: rows });
});

// =========================================================================
// USERS
// =========================================================================

router.get('/users', requirePermission('users.read'), async (req, res) => {
  const q = (req.query.q || '').toString().trim();
  const limit = Math.min(parseInt(req.query.limit) || 50, 200);
  const offset = parseInt(req.query.offset) || 0;
  const params = [];
  let where = '1=1';
  if (q) {
    params.push(`%${q.toLowerCase()}%`);
    where = `(LOWER(email) LIKE $1 OR LOWER(username) LIKE $1)`;
  }
  params.push(limit, offset);
  const { rows } = await db.query(
    `SELECT id, email, username, avatar_url, reputation_score, is_child, is_admin, is_banned,
            banned_at, ban_reason, is_kpp, is_verified, verified_role, app_mode, email_verified,
            last_seen_at, created_at
     FROM users
     WHERE ${where}
     ORDER BY created_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );
  res.json({ users: rows, limit, offset });
});

router.get('/users/:id', requirePermission('users.read'), async (req, res) => {
  const { rows } = await db.query(
    `SELECT id, email, username, avatar_url, reputation_score, is_child, is_admin, is_banned,
            banned_at, ban_reason, is_kpp, is_verified, verified_role, app_mode, email_verified,
            phone, organization, last_seen_at, created_at
     FROM users WHERE id = $1`,
    [req.params.id]
  );
  if (!rows.length) return res.status(404).json({ error: 'Not found' });
  res.json(rows[0]);
});

router.patch('/users/:id', requirePermission(), async (req, res) => {
  // Kontrola per-pole (zapobieganie eskalacji uprawnień):
  //   is_admin → rbac.manage | is_banned/ban_reason → users.ban | reszta → users.edit
  const { hasPermission } = require('../services/rbac');
  const body = req.body || {};
  const needs = new Set();
  if ('is_admin' in body) needs.add('rbac.manage');
  if ('is_banned' in body || 'ban_reason' in body) needs.add('users.ban');
  for (const k of ['is_verified', 'verified_role', 'is_kpp', 'reputation_score']) {
    if (k in body) needs.add('users.edit');
  }
  for (const p of needs) {
    if (!hasPermission(req._access, p)) {
      return res.status(403).json({ error: 'Forbidden', required: p });
    }
  }
  const allowed = ['is_admin', 'is_banned', 'ban_reason', 'is_verified', 'verified_role', 'is_kpp', 'reputation_score'];
  const sets = [];
  const params = [req.params.id];
  for (const [k, v] of Object.entries(req.body || {})) {
    if (!allowed.includes(k)) continue;
    params.push(v);
    sets.push(`${k} = $${params.length}`);
  }
  if (req.body.is_banned === true) {
    params.push(new Date());
    sets.push(`banned_at = $${params.length}`);
  }
  if (req.body.is_banned === false) {
    sets.push('banned_at = NULL', 'ban_reason = NULL');
  }
  if (!sets.length) return res.status(400).json({ error: 'No editable fields' });

  const { rows } = await db.query(
    `UPDATE users SET ${sets.join(', ')}, updated_at = NOW() WHERE id = $1 RETURNING id, username, is_admin, is_banned, is_verified`,
    params
  );
  if (!rows.length) return res.status(404).json({ error: 'Not found' });
  await audit(req.user.id, 'user.update', 'user', req.params.id, req.body);
  res.json(rows[0]);
});

// =========================================================================
// ALERTS
// =========================================================================

router.get('/alerts', requirePermission('alerts.read'), async (req, res) => {
  const status = req.query.status;
  const limit = Math.min(parseInt(req.query.limit) || 100, 500);
  const params = [];
  let where = '1=1';
  if (status) {
    params.push(status);
    where = `a.status = $${params.length}`;
  }
  params.push(limit);
  const { rows } = await db.query(
    `SELECT a.id, a.category, a.title, a.description, a.status, a.confirms, a.denies,
            a.trust_score, a.is_anonymous, a.created_at, a.expires_at, a.radius_m,
            ST_Y(a.location::geometry) AS lat, ST_X(a.location::geometry) AS lng,
            u.username AS author_username, u.id AS author_id,
            (SELECT COUNT(*)::int FROM alert_reports r WHERE r.alert_id = a.id AND r.status='pending') AS reports_count
     FROM alerts a
     LEFT JOIN users u ON u.id = a.author_id
     WHERE ${where}
     ORDER BY a.created_at DESC LIMIT $${params.length}`,
    params
  );
  res.json({ alerts: rows });
});

router.delete('/alerts/:id', requirePermission('alerts.delete'), async (req, res) => {
  const { rows } = await db.query('DELETE FROM alerts WHERE id = $1 RETURNING id, title, author_id', [req.params.id]);
  if (!rows.length) return res.status(404).json({ error: 'Not found' });
  await audit(req.user.id, 'alert.delete', 'alert', req.params.id, { title: rows[0].title, author_id: rows[0].author_id });
  res.json({ ok: true, deleted: rows[0].id });
});

router.patch('/alerts/:id', requirePermission('alerts.edit'), async (req, res) => {
  const allowed = ['status', 'title', 'description', 'category', 'radius_m'];
  const sets = [];
  const params = [req.params.id];
  for (const [k, v] of Object.entries(req.body || {})) {
    if (!allowed.includes(k)) continue;
    params.push(v);
    sets.push(`${k} = $${params.length}`);
  }
  if (!sets.length) return res.status(400).json({ error: 'No editable fields' });
  const { rows } = await db.query(
    `UPDATE alerts SET ${sets.join(', ')} WHERE id = $1 RETURNING id, status, title`,
    params
  );
  if (!rows.length) return res.status(404).json({ error: 'Not found' });
  await audit(req.user.id, 'alert.update', 'alert', req.params.id, req.body);
  res.json(rows[0]);
});

// =========================================================================
// REPORTS (zgłoszenia użytkowników na alerty)
// =========================================================================

router.get('/reports', requirePermission('reports.read'), async (req, res) => {
  const status = req.query.status || 'pending';
  const { rows } = await db.query(
    `SELECT r.id, r.alert_id, r.reporter_id, r.reason, r.details, r.status, r.created_at, r.resolved_at,
            ur.username AS reporter_username,
            a.title AS alert_title, a.category, a.status AS alert_status,
            ua.username AS alert_author_username
     FROM alert_reports r
     JOIN users ur ON ur.id = r.reporter_id
     LEFT JOIN alerts a ON a.id = r.alert_id
     LEFT JOIN users ua ON ua.id = a.author_id
     WHERE r.status = $1
     ORDER BY r.created_at DESC LIMIT 200`,
    [status]
  );
  res.json({ reports: rows });
});

router.post('/reports/:id/resolve', requirePermission('reports.resolve'), async (req, res) => {
  const action = (req.body.action || 'dismiss').toString();
  const { rows: rep } = await db.query('SELECT * FROM alert_reports WHERE id = $1', [req.params.id]);
  if (!rep.length) return res.status(404).json({ error: 'Not found' });
  if (action === 'delete_alert' && rep[0].alert_id) {
    await db.query('DELETE FROM alerts WHERE id = $1', [rep[0].alert_id]);
  }
  await db.query(
    `UPDATE alert_reports SET status = $1, resolved_by = $2, resolved_at = NOW() WHERE id = $3`,
    [action === 'delete_alert' ? 'resolved' : 'dismissed', req.user.id, req.params.id]
  );
  await audit(req.user.id, `report.${action}`, 'report', req.params.id, { alert_id: rep[0].alert_id });
  res.json({ ok: true });
});

// =========================================================================
// GROUPS
// =========================================================================

router.get('/groups', requirePermission('groups.read'), async (req, res) => {
  const { rows } = await db.query(
    `SELECT g.id, g.name, g.invite_code, g.created_at, g.owner_id,
            u.username AS owner_username,
            (SELECT COUNT(*)::int FROM family_members m WHERE m.group_id = g.id) AS members_count
     FROM family_groups g
     LEFT JOIN users u ON u.id = g.owner_id
     ORDER BY g.created_at DESC LIMIT 200`
  );
  res.json({ groups: rows });
});

router.delete('/groups/:id', requirePermission('groups.delete'), async (req, res) => {
  const { rows } = await db.query('DELETE FROM family_groups WHERE id = $1 RETURNING id, name', [req.params.id]);
  if (!rows.length) return res.status(404).json({ error: 'Not found' });
  await audit(req.user.id, 'group.delete', 'group', req.params.id, { name: rows[0].name });
  res.json({ ok: true });
});

// =========================================================================
// CONFIG (konfiguracja runtime) + FEATURE FLAGS
// =========================================================================

router.get('/config', requirePermission('config.read'), async (req, res) => {
  const { rows } = await db.query('SELECT key, value, description, updated_at, updated_by FROM app_config ORDER BY key');
  res.json({ config: rows });
});

// PUT /config/:key { value }  — zapisuje + trzyma prev_value (rollback) + audyt.
router.put('/config/:key', requirePermission('config.write'), async (req, res) => {
  if (!('value' in (req.body || {}))) return res.status(400).json({ error: 'value required' });
  const { rows } = await db.query(
    `INSERT INTO app_config (key, value, description, updated_by, updated_at)
       VALUES ($1, $2::jsonb, $3, $4, NOW())
     ON CONFLICT (key) DO UPDATE SET
       prev_value = app_config.value,
       value = EXCLUDED.value,
       updated_by = EXCLUDED.updated_by,
       updated_at = NOW()
     RETURNING key, value, prev_value`,
    [req.params.key, JSON.stringify(req.body.value), req.body.description || null, req.user.id]
  );
  await audit(req.user.id, 'config.write', 'config', req.params.key, { value: req.body.value });
  res.json(rows[0]);
});

// POST /config/:key/rollback — przywraca prev_value.
router.post('/config/:key/rollback', requirePermission('config.write'), async (req, res) => {
  const { rows } = await db.query(
    `UPDATE app_config SET value = prev_value, prev_value = value, updated_by = $2, updated_at = NOW()
     WHERE key = $1 AND prev_value IS NOT NULL RETURNING key, value`,
    [req.params.key, req.user.id]
  );
  if (!rows.length) return res.status(404).json({ error: 'No previous value' });
  await audit(req.user.id, 'config.rollback', 'config', req.params.key, null);
  res.json(rows[0]);
});

router.get('/flags', requirePermission('config.read'), async (req, res) => {
  const { rows } = await db.query('SELECT key, enabled, description, segment, updated_at FROM feature_flags ORDER BY key');
  res.json({ flags: rows });
});

// PUT /flags/:key { enabled, segment?, description? } — flags.write.
router.put('/flags/:key', requirePermission('flags.write'), async (req, res) => {
  const enabled = req.body?.enabled === true;
  const { rows } = await db.query(
    `INSERT INTO feature_flags (key, enabled, description, segment, updated_by, updated_at)
       VALUES ($1, $2, $3, $4, $5, NOW())
     ON CONFLICT (key) DO UPDATE SET
       enabled = EXCLUDED.enabled,
       description = COALESCE(EXCLUDED.description, feature_flags.description),
       segment = COALESCE(EXCLUDED.segment, feature_flags.segment),
       updated_by = EXCLUDED.updated_by, updated_at = NOW()
     RETURNING key, enabled, segment`,
    [req.params.key, enabled, req.body.description || null, req.body.segment || null, req.user.id]
  );
  await audit(req.user.id, 'flag.write', 'flag', req.params.key, { enabled, segment: req.body.segment });
  res.json(rows[0]);
});

// =========================================================================
// BROADCAST (powiadomienie do segmentu userów) — broadcast.send
// =========================================================================
// body: { title, body, segment?, confirm:true }
//   segment: 'all' | 'kids' | 'senior' | 'normal' (app_mode). Domyślnie 'all'.
// Wymaga confirm=true (zabezpieczenie). Rate-limit + audyt. Reuse FCM notifyUser
// (zapisuje też do inboxu /notifications każdego odbiorcy).
router.post('/broadcast', requirePermission('broadcast.send'), async (req, res) => {
  const { title, body, segment = 'all', confirm } = req.body || {};
  if (!title || !body) return res.status(400).json({ error: 'title i body wymagane' });
  if (confirm !== true) return res.status(400).json({ error: 'Wymagane confirm:true' });

  // Rate-limit (z app_config jeśli ustawione, inaczej 5/h)
  let limit = 5;
  try {
    const { rows } = await db.query("SELECT value FROM app_config WHERE key='broadcast_rate_limit_per_hour'");
    if (rows[0]) limit = parseInt(rows[0].value, 10) || 5;
  } catch (_) {}
  const now = Date.now();
  _bcTimes = _bcTimes.filter((t) => now - t < 3600000);
  if (_bcTimes.length >= limit) {
    return res.status(429).json({ error: `Limit broadcastów: ${limit}/h osiągnięty` });
  }

  // Segment → warunek na app_mode
  const allowed = ['all', 'kids', 'senior', 'normal'];
  if (!allowed.includes(segment)) return res.status(400).json({ error: 'Zły segment' });
  const where = segment === 'all' ? '1=1' : 'app_mode = $1';
  const params = segment === 'all' ? [] : [segment];
  const { rows: users } = await db.query(
    `SELECT id FROM users WHERE ${where} AND is_banned = FALSE`,
    params
  );

  _bcTimes.push(now);
  // Wyślij (fire-and-forget per user; notifyUser zapisuje do inboxu + push jeśli token).
  let queued = 0;
  for (const u of users) {
    notifyUser(u.id, title, body, { type: 'broadcast', segment }).catch(() => {});
    queued++;
  }
  await audit(req.user.id, 'broadcast.send', 'broadcast', null, { title, segment, recipients: queued });
  res.json({ ok: true, segment, recipients: queued });
});

module.exports = router;
