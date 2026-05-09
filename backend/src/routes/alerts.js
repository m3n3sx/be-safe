const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const uploadDir = path.join(__dirname, '..', '..', 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const upload = multer({
  storage: multer.diskStorage({
    destination: (_, __, cb) => cb(null, uploadDir),
    filename: (_, file, cb) => cb(null, `${Date.now()}-${Math.random().toString(36).slice(2)}${path.extname(file.originalname)}`),
  }),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_, file, cb) => cb(null, /^image\/(jpeg|png|webp)$/.test(file.mimetype)),
});

const { notifyNearbyUsers } = require('../services/fcm');
const rateLimit = require('express-rate-limit');
const createAlertLimiter = rateLimit({ windowMs: 3600000, max: 10 });

router.use(auth);

// Nowe alerty od ostatniego sprawdzenia — dla polling notifications
router.get('/new', async (req, res) => {
  const { since } = req.query;
  if (!since) return res.status(400).json({ error: 'since required' });
  const { rows: user } = await db.query(
    `SELECT ST_Y(last_location::geometry) AS lat, ST_X(last_location::geometry) AS lng, alert_radius_m FROM users WHERE id = $1`,
    [req.user.id]
  );
  if (!user[0]?.lat) return res.json({ alerts: [] });
  const { lat, lng, alert_radius_m } = user[0];
  const { rows } = await db.query(
    `SELECT a.id, a.category, a.title, a.description, ST_Y(a.location::geometry) AS lat, ST_X(a.location::geometry) AS lng,
            a.radius_m, a.confirms, a.denies, a.created_at
     FROM alerts a WHERE a.status = 'active' AND a.author_id != $1
     AND a.created_at > $2 AND a.expires_at > NOW()
     AND ST_DWithin(a.location, ST_MakePoint($4, $3)::geography, $5)
     ORDER BY a.created_at DESC`,
    [req.user.id, since, lat, lng, Math.max(alert_radius_m, 5000)]
  );
  res.json({ alerts: rows });
});

const ALERT_COLS = `a.id, a.author_id, a.category, a.title, a.description, a.photo_url,
  ST_Y(a.location::geometry) AS lat, ST_X(a.location::geometry) AS lng,
  a.radius_m, a.status, a.confirms, a.denies, a.expires_at, a.created_at`;

router.get('/stats', async (req, res) => {
  const { lat, lng, radius_m = 2000 } = req.query;
  if (!lat || !lng) return res.status(400).json({ error: 'lat and lng required' });

  const { rows: [totals] } = await db.query(
    `SELECT COUNT(*)::int AS total,
            COUNT(*) FILTER (WHERE created_at > NOW() - interval '7 days')::int AS week,
            COUNT(*) FILTER (WHERE created_at > NOW() - interval '1 day')::int AS today
     FROM alerts WHERE ST_DWithin(location, ST_MakePoint($2, $1)::geography, $3)`,
    [lat, lng, radius_m]
  );
  const { rows: byCategory } = await db.query(
    `SELECT category, COUNT(*)::int AS count FROM alerts
     WHERE ST_DWithin(location, ST_MakePoint($2, $1)::geography, $3) AND created_at > NOW() - interval '30 days'
     GROUP BY category ORDER BY count DESC LIMIT 10`,
    [lat, lng, radius_m]
  );
  const { rows: trend } = await db.query(
    `SELECT date_trunc('day', created_at)::date AS day, COUNT(*)::int AS count
     FROM alerts WHERE ST_DWithin(location, ST_MakePoint($2, $1)::geography, $3) AND created_at > NOW() - interval '14 days'
     GROUP BY day ORDER BY day`,
    [lat, lng, radius_m]
  );
  res.json({ totals, by_category: byCategory, trend });
});

router.get('/heatmap', async (req, res) => {
  const { lat, lng, radius_m = 5000, days = 30 } = req.query;
  if (!lat || !lng) return res.status(400).json({ error: 'lat and lng required' });
  const { rows } = await db.query(
    `SELECT ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng,
            COUNT(*)::int AS weight
     FROM alerts
     WHERE created_at > NOW() - ($4 || ' days')::interval
     AND ST_DWithin(location, ST_MakePoint($2, $1)::geography, $3)
     GROUP BY ST_SnapToGrid(location::geometry, 0.001)
     ORDER BY weight DESC LIMIT 200`,
    [lat, lng, radius_m, days]
  );
  res.json({ points: rows });
});

router.get('/mine', async (req, res) => {
  const { rows } = await db.query(
    `SELECT ${ALERT_COLS}, json_build_object('username', u.username) AS author
     FROM alerts a JOIN users u ON a.author_id = u.id
     WHERE a.author_id = $1 ORDER BY a.created_at DESC LIMIT 100`,
    [req.user.id]
  );
  res.json({ alerts: rows });
});

router.get('/nearby', async (req, res) => {
  const { lat, lng, radius_m = 1000, category } = req.query;
  if (!lat || !lng) return res.status(400).json({ error: 'lat and lng required' });

  let q = `SELECT ${ALERT_COLS}, ST_Distance(a.location, ST_MakePoint($2, $1)::geography) AS distance_m,
            json_build_object('username', u.username, 'reputation_score', u.reputation_score, 'is_verified', u.is_verified, 'verified_role', u.verified_role, 'avatar_url', u.avatar_url) AS author
            FROM alerts a JOIN users u ON a.author_id = u.id
            WHERE a.status = 'active' AND a.expires_at > NOW()
            AND ST_DWithin(a.location, ST_MakePoint($2, $1)::geography, $3)`;
  const params = [lat, lng, radius_m];

  if (category) {
    params.push(category);
    q += ` AND a.category = $${params.length}`;
  }
  q += ` ORDER BY distance_m`;

  const { rows } = await db.query(q, params);
  res.json({ alerts: rows });
});

router.get('/:id', async (req, res) => {
  const { rows } = await db.query(
    `SELECT ${ALERT_COLS}, json_build_object('username', u.username, 'reputation_score', u.reputation_score, 'is_verified', u.is_verified, 'verified_role', u.verified_role, 'avatar_url', u.avatar_url) AS author
     FROM alerts a JOIN users u ON a.author_id = u.id WHERE a.id = $1`,
    [req.params.id]
  );
  if (!rows[0]) return res.status(404).json({ error: 'Not found' });
  res.json(rows[0]);
});

router.post('/', createAlertLimiter, upload.single('photo'), async (req, res) => {
  const { category, title, description, lat, lng, radius_m = 100, duration_hours = 3 } = req.body;
  const expires = new Date(Date.now() + duration_hours * 3600000).toISOString();
  const photo_url = req.file ? `/uploads/${req.file.filename}` : null;
  const { rows } = await db.query(
    `INSERT INTO alerts (author_id, category, title, description, photo_url, location, radius_m, expires_at)
     VALUES ($1, $2, $3, $4, $5, ST_MakePoint($7, $6)::geography, $8, $9)
     RETURNING id, author_id, category, title, description, photo_url,
       ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng,
       radius_m, status, confirms, denies, expires_at, created_at`,
    [req.user.id, category, title, description, photo_url, lat, lng, radius_m, expires]
  );
  // Emit only to users within their alert radius
  const io = req.app.get('io');
  if (io) {
    const { rows: nearby } = await db.query(
      `SELECT id FROM users WHERE id != $1 AND last_location IS NOT NULL
       AND ST_DWithin(last_location, ST_MakePoint($3, $2)::geography, alert_radius_m)`,
      [req.user.id, lng, lat]
    );
    for (const u of nearby) io.to(`user:${u.id}`).emit('alert:new', rows[0]);
  }
  notifyNearbyUsers(rows[0]).catch(() => {});
  res.status(201).json(rows[0]);
});

router.patch('/:id', async (req, res) => {
  const { description, extend_hours } = req.body;
  const updates = [];
  const params = [req.params.id, req.user.id];

  if (description !== undefined) {
    params.push(description);
    updates.push(`description = $${params.length}`);
  }
  if (extend_hours) {
    params.push(extend_hours);
    updates.push(`expires_at = expires_at + ($${params.length} || ' hours')::interval`);
    updates.push(`status = 'active'`);
  }
  if (!updates.length) return res.status(400).json({ error: 'Nothing to update' });

  const { rows } = await db.query(
    `UPDATE alerts SET ${updates.join(', ')} WHERE id = $1 AND author_id = $2
     RETURNING ${ALERT_COLS.replace(/a\./g, '')}`,
    params
  );
  if (!rows[0]) return res.status(404).json({ error: 'Not found or not owner' });
  req.app.get('io')?.emit('alert:updated', rows[0]);
  res.json(rows[0]);
});

router.delete('/:id', async (req, res) => {
  const { rowCount } = await db.query(
    `UPDATE alerts SET status = 'removed' WHERE id = $1 AND author_id = $2`,
    [req.params.id, req.user.id]
  );
  if (!rowCount) return res.status(404).json({ error: 'Not found or not owner' });
  res.json({ ok: true });
});

router.post('/:id/vote', async (req, res) => {
  try {
    await db.query(
      `INSERT INTO alert_votes (alert_id, user_id, vote) VALUES ($1, $2, $3)`,
      [req.params.id, req.user.id, req.body.vote]
    );
    const { rows } = await db.query(`SELECT confirms, denies FROM alerts WHERE id = $1`, [req.params.id]);
    req.app.get('io')?.emit('alert:updated', { id: req.params.id, ...rows[0] });
    res.json(rows[0]);
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'Already voted' });
    res.status(500).json({ error: e.message });
  }
});

router.post('/:id/photo', upload.single('photo'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'Photo required' });
  const photo_url = `/uploads/${req.file.filename}`;
  const { rows } = await db.query(
    `UPDATE alerts SET photo_url = $1 WHERE id = $2 AND author_id = $3 RETURNING id, photo_url`,
    [photo_url, req.params.id, req.user.id]
  );
  if (!rows[0]) return res.status(404).json({ error: 'Not found or not owner' });
  res.json(rows[0]);
});

// --- Comments ---

router.get('/:id/comments', async (req, res) => {
  const { rows } = await db.query(
    `SELECT c.id, c.content, c.created_at, json_build_object('id', u.id, 'username', u.username) AS author
     FROM alert_comments c JOIN users u ON c.user_id = u.id
     WHERE c.alert_id = $1 ORDER BY c.created_at ASC`,
    [req.params.id]
  );
  res.json({ comments: rows });
});

router.post('/:id/comments', async (req, res) => {
  const { content } = req.body;
  if (!content || !content.trim()) return res.status(400).json({ error: 'Content required' });
  const { rows } = await db.query(
    `INSERT INTO alert_comments (alert_id, user_id, content) VALUES ($1, $2, $3)
     RETURNING id, content, created_at`,
    [req.params.id, req.user.id, content.trim()]
  );
  rows[0].author = { id: req.user.id, username: req.user.email };
  // Get username
  const { rows: u } = await db.query(`SELECT username, avatar_url FROM users WHERE id = $1`, [req.user.id]);
  if (u[0]) {
    rows[0].author.username = u[0].username;
    rows[0].author.avatar_url = u[0].avatar_url;
  }
  // Broadcast to everyone currently viewing this alert's comments
  req.app.get('io')?.to(`alert:${req.params.id}`).emit('comment:new', {
    alert_id: req.params.id,
    ...rows[0],
  });
  res.status(201).json(rows[0]);
});

router.delete('/:id/comments/:commentId', async (req, res) => {
  const { id, commentId } = req.params;
  const { rowCount } = await db.query(
    `DELETE FROM alert_comments WHERE id = $1 AND user_id = $2 AND alert_id = $3`,
    [commentId, req.user.id, id]
  );
  if (!rowCount) return res.status(404).json({ error: 'Not found or not owner' });
  req.app.get('io')?.to(`alert:${id}`).emit('comment:deleted', {
    alert_id: id,
    comment_id: commentId,
  });
  res.json({ ok: true });
});

// ------ MODERATION / REPORTS ------
router.post('/:id/report', async (req, res) => {
  const { reason, details } = req.body;
  if (!reason) return res.status(400).json({ error: 'Reason required' });

  try {
    await db.query(
      `INSERT INTO alert_reports (alert_id, reporter_id, reason, details) VALUES ($1, $2, $3, $4)`,
      [req.params.id, req.user.id, reason, details || null]
    );
    // Auto-hide po 3+ zgłoszeniach
    const { rows } = await db.query(
      `SELECT COUNT(*)::int AS cnt FROM alert_reports WHERE alert_id = $1`,
      [req.params.id]
    );
    if (rows[0].cnt >= 3) {
      await db.query(`UPDATE alerts SET status = 'hidden' WHERE id = $1`, [req.params.id]);
    }
    res.json({ ok: true, reports: rows[0].cnt });
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'Already reported' });
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
