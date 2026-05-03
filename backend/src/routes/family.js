const router = require('express').Router();
const crypto = require('crypto');
const db = require('../config/db');
const auth = require('../middleware/auth');

router.use(auth);

// Middleware: check group membership
const memberOf = async (req, res, next) => {
  const { rows } = await db.query(
    `SELECT role FROM family_members WHERE group_id = $1 AND user_id = $2`,
    [req.params.id, req.user.id]
  );
  if (!rows[0]) return res.status(403).json({ error: 'Not a member' });
  req.memberRole = rows[0].role;
  next();
};
const parentOnly = (req, res, next) => {
  if (req.memberRole !== 'parent') return res.status(403).json({ error: 'Parent role required' });
  next();
};

// --- Groups ---

router.post('/groups', async (req, res) => {
  const code = crypto.randomBytes(4).toString('hex').toUpperCase();
  const { rows } = await db.query(
    `INSERT INTO family_groups (name, owner_id, invite_code) VALUES ($1, $2, $3) RETURNING *`,
    [req.body.name, req.user.id, code]
  );
  await db.query(
    `INSERT INTO family_members (group_id, user_id, role) VALUES ($1, $2, 'parent')`,
    [rows[0].id, req.user.id]
  );
  res.status(201).json(rows[0]);
});

router.get('/groups', async (req, res) => {
  const { rows } = await db.query(
    `SELECT g.* FROM family_groups g JOIN family_members m ON g.id = m.group_id WHERE m.user_id = $1`,
    [req.user.id]
  );
  res.json({ groups: rows });
});

router.post('/groups/join', async (req, res) => {
  const { rows: groups } = await db.query(`SELECT id FROM family_groups WHERE invite_code = $1`, [req.body.invite_code]);
  if (!groups[0]) return res.status(404).json({ error: 'Invalid code' });

  try {
    await db.query(
      `INSERT INTO family_members (group_id, user_id, role) VALUES ($1, $2, 'child')`,
      [groups[0].id, req.user.id]
    );
    await db.query(`UPDATE users SET is_child = TRUE WHERE id = $1`, [req.user.id]);
    res.json({ ok: true, group_id: groups[0].id });
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'Already a member' });
    res.status(500).json({ error: e.message });
  }
});

router.get('/groups/:id/members', memberOf, async (req, res) => {
  const { rows } = await db.query(
    `SELECT m.user_id, u.username, m.role, m.tracking_enabled,
            ST_Y(u.last_location::geometry) AS lat, ST_X(u.last_location::geometry) AS lng,
            u.last_location_at
     FROM family_members m JOIN users u ON m.user_id = u.id WHERE m.group_id = $1`,
    [req.params.id]
  );
  res.json({ members: rows });
});

router.patch('/groups/:id/members/:uid', memberOf, parentOnly, async (req, res) => {
  const allowed = ['tracking_enabled', 'role'];
  const fields = Object.keys(req.body).filter((k) => allowed.includes(k));
  if (!fields.length) return res.status(400).json({ error: 'No valid fields' });

  const sets = fields.map((f, i) => `${f} = $${i + 3}`).join(', ');
  const vals = fields.map((f) => req.body[f]);
  await db.query(`UPDATE family_members SET ${sets} WHERE group_id = $1 AND user_id = $2`, [req.params.id, req.params.uid, ...vals]);
  res.json({ ok: true });
});

router.delete('/groups/:id/members/:uid', memberOf, parentOnly, async (req, res) => {
  await db.query(`DELETE FROM family_members WHERE group_id = $1 AND user_id = $2`, [req.params.id, req.params.uid]);
  res.json({ ok: true });
});

router.delete('/groups/:id', async (req, res) => {
  const { rowCount } = await db.query(`DELETE FROM family_groups WHERE id = $1 AND owner_id = $2`, [req.params.id, req.user.id]);
  if (!rowCount) return res.status(403).json({ error: 'Not owner' });
  res.json({ ok: true });
});

// --- Geofences ---

router.post('/groups/:id/geofences', memberOf, parentOnly, async (req, res) => {
  const { name, lat, lng, radius_m = 200 } = req.body;
  const { rows } = await db.query(
    `INSERT INTO geofences (group_id, name, center, radius_m) VALUES ($1, $2, ST_MakePoint($4, $3)::geography, $5) RETURNING *`,
    [req.params.id, name, lat, lng, radius_m]
  );
  res.status(201).json(rows[0]);
});

router.get('/groups/:id/geofences', memberOf, async (req, res) => {
  const { rows } = await db.query(
    `SELECT id, group_id, name, ST_Y(center::geometry) AS lat, ST_X(center::geometry) AS lng, radius_m, is_active, created_at FROM geofences WHERE group_id = $1`,
    [req.params.id]
  );
  res.json({ geofences: rows });
});

router.patch('/groups/:id/geofences/:gid', memberOf, parentOnly, async (req, res) => {
  const { name, lat, lng, radius_m, is_active } = req.body;
  const updates = [], params = [req.params.gid, req.params.id];
  if (name !== undefined) { params.push(name); updates.push(`name = $${params.length}`); }
  if (radius_m !== undefined) { params.push(radius_m); updates.push(`radius_m = $${params.length}`); }
  if (is_active !== undefined) { params.push(is_active); updates.push(`is_active = $${params.length}`); }
  if (lat !== undefined && lng !== undefined) {
    params.push(lat, lng);
    updates.push(`center = ST_MakePoint($${params.length}, $${params.length - 1})::geography`);
  }
  if (!updates.length) return res.status(400).json({ error: 'Nothing to update' });
  const { rows } = await db.query(
    `UPDATE geofences SET ${updates.join(', ')} WHERE id = $1 AND group_id = $2 RETURNING *`,
    params
  );
  if (!rows[0]) return res.status(404).json({ error: 'Not found' });
  res.json(rows[0]);
});

router.delete('/groups/:id/geofences/:gid', memberOf, parentOnly, async (req, res) => {
  await db.query(`DELETE FROM geofences WHERE id = $1 AND group_id = $2`, [req.params.gid, req.params.id]);
  res.json({ ok: true });
});

// --- Location tracking ---

router.get('/groups/:id/members/:uid/location', memberOf, parentOnly, async (req, res) => {
  const { rows } = await db.query(
    `SELECT ST_Y(last_location::geometry) AS lat, ST_X(last_location::geometry) AS lng, last_location_at
     FROM users WHERE id = $1`,
    [req.params.uid]
  );
  res.json(rows[0] || {});
});

router.get('/groups/:id/members/:uid/location/history', memberOf, parentOnly, async (req, res) => {
  const { from, to, limit = 100 } = req.query;
  let q = `SELECT ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng, recorded_at
           FROM location_history WHERE user_id = $1`;
  const params = [req.params.uid];

  if (from) { params.push(from); q += ` AND recorded_at >= $${params.length}`; }
  if (to) { params.push(to); q += ` AND recorded_at <= $${params.length}`; }
  params.push(limit);
  q += ` ORDER BY recorded_at DESC LIMIT $${params.length}`;

  const { rows } = await db.query(q, params);
  res.json({ history: rows });
});

module.exports = router;
