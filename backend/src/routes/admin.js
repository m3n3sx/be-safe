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
const router = express.Router();

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

// =========================================================================
// SYSTEM
// =========================================================================

router.get('/ping', (req, res) => res.json({ ok: true, user: req.user.id }));

router.get('/backup-status', (req, res) => {
  try {
    if (!fs.existsSync(LAST_BACKUP_FILE)) {
      return res.status(404).json({ error: 'No backup yet' });
    }
    const data = JSON.parse(fs.readFileSync(LAST_BACKUP_FILE, 'utf-8'));
    const ageHours = (Date.now() - new Date(data.timestamp).getTime()) / 3.6e6;
    data.age_hours = Math.round(ageHours * 10) / 10;
    data.is_stale = ageHours > 26;
    res.json(data);
  } catch (e) {
    res.status(500).json({ error: 'Cannot read backup status' });
  }
});

router.get('/stats', async (req, res) => {
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

router.get('/audit-log', async (req, res) => {
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

router.get('/users', async (req, res) => {
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

router.get('/users/:id', async (req, res) => {
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

router.patch('/users/:id', async (req, res) => {
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

router.get('/alerts', async (req, res) => {
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

router.delete('/alerts/:id', async (req, res) => {
  const { rows } = await db.query('DELETE FROM alerts WHERE id = $1 RETURNING id, title, author_id', [req.params.id]);
  if (!rows.length) return res.status(404).json({ error: 'Not found' });
  await audit(req.user.id, 'alert.delete', 'alert', req.params.id, { title: rows[0].title, author_id: rows[0].author_id });
  res.json({ ok: true, deleted: rows[0].id });
});

router.patch('/alerts/:id', async (req, res) => {
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

router.get('/reports', async (req, res) => {
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

router.post('/reports/:id/resolve', async (req, res) => {
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

router.get('/groups', async (req, res) => {
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

router.delete('/groups/:id', async (req, res) => {
  const { rows } = await db.query('DELETE FROM family_groups WHERE id = $1 RETURNING id, name', [req.params.id]);
  if (!rows.length) return res.status(404).json({ error: 'Not found' });
  await audit(req.user.id, 'group.delete', 'group', req.params.id, { name: rows[0].name });
  res.json({ ok: true });
});

module.exports = router;
