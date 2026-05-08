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
    filename: (_, file, cb) => cb(null, `avatar-${Date.now()}${path.extname(file.originalname)}`),
  }),
  limits: { fileSize: 2 * 1024 * 1024 },
});

router.use(auth);

// Upload avatar for any user (parent can set child avatar)
router.post('/:id/avatar', upload.single('avatar'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'File required' });
  const avatar_url = `/uploads/${req.file.filename}`;
  await db.query(`UPDATE users SET avatar_url = $1 WHERE id = $2`, [avatar_url, req.params.id]);
  res.json({ avatar_url });
});

router.get('/ranking', async (req, res) => {
  const { rows } = await db.query(
    `SELECT u.id, u.username, u.reputation_score,
            COUNT(a.id)::int AS alert_count,
            COALESCE(SUM(a.confirms), 0)::int AS total_confirms
     FROM users u LEFT JOIN alerts a ON a.author_id = u.id AND a.status != 'removed'
     GROUP BY u.id ORDER BY alert_count DESC, u.reputation_score DESC LIMIT 50`
  );
  res.json({ ranking: rows });
});

router.get('/me', async (req, res) => {
  const { rows } = await db.query(
    `SELECT u.id, u.email, u.username, u.avatar_url, u.alert_radius_m, u.reputation_score,
            u.is_child, u.email_verified, u.referral_code, u.created_at,
            (SELECT COUNT(*)::int FROM users WHERE referred_by = u.id) AS referrals_count
     FROM users u WHERE u.id = $1`,
    [req.user.id]
  );
  res.json(rows[0] || {});
});

router.patch('/me', async (req, res) => {
  const allowed = ['username', 'alert_radius_m', 'avatar_url'];
  const fields = Object.keys(req.body).filter((k) => allowed.includes(k));
  if (!fields.length) return res.status(400).json({ error: 'No valid fields' });

  const sets = fields.map((f, i) => `${f} = $${i + 2}`).join(', ');
  const vals = fields.map((f) => req.body[f]);
  const { rows } = await db.query(
    `UPDATE users SET ${sets}, updated_at = NOW() WHERE id = $1 RETURNING id, email, username, alert_radius_m`,
    [req.user.id, ...vals]
  );
  res.json(rows[0]);
});

router.put('/me/location', async (req, res) => {
  const { lat, lng } = req.body;
  await db.query(
    `UPDATE users SET last_location = ST_MakePoint($2, $1)::geography, last_location_at = NOW() WHERE id = $3`,
    [lat, lng, req.user.id]
  );
  const { rows } = await db.query(`SELECT * FROM find_alerts_nearby($1, $2, (SELECT alert_radius_m FROM users WHERE id = $3))`, [lat, lng, req.user.id]);
  res.json({ nearby_alerts: rows });
});

router.put('/me/fcm-token', async (req, res) => {
  await db.query(`UPDATE users SET fcm_token = $1 WHERE id = $2`, [req.body.fcm_token, req.user.id]);
  res.json({ ok: true });
});

router.post('/me/email', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'Email and password required' });
  const { rows } = await db.query(`SELECT password_hash FROM users WHERE id = $1`, [req.user.id]);
  if (!rows[0] || !(await require('bcryptjs').compare(password, rows[0].password_hash)))
    return res.status(401).json({ error: 'Wrong password' });
  try {
    await db.query(`UPDATE users SET email = $1, updated_at = NOW() WHERE id = $2`, [email, req.user.id]);
    res.json({ ok: true });
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'Email taken' });
    res.status(500).json({ error: e.message });
  }
});

router.post('/me/password', async (req, res) => {
  const { current_password, new_password } = req.body;
  if (!current_password || !new_password) return res.status(400).json({ error: 'Both passwords required' });
  if (new_password.length < 6) return res.status(400).json({ error: 'Min 6 characters' });
  const { rows } = await db.query(`SELECT password_hash FROM users WHERE id = $1`, [req.user.id]);
  if (!rows[0] || !(await require('bcryptjs').compare(current_password, rows[0].password_hash)))
    return res.status(401).json({ error: 'Wrong password' });
  const hash = await require('bcryptjs').hash(new_password, 10);
  await db.query(`UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2`, [hash, req.user.id]);
  res.json({ ok: true });
});

router.post('/me/share-location', async (req, res) => {
  const crypto = require('crypto');
  const token = crypto.randomBytes(16).toString('hex');
  const hours = req.body.hours || 1;
  const expires = new Date(Date.now() + hours * 3600000).toISOString();
  const { rows } = await db.query(
    `INSERT INTO share_links (user_id, token, expires_at) VALUES ($1, $2, $3) RETURNING token, expires_at`,
    [req.user.id, token, expires]
  );
  res.status(201).json({ url: `https://alert.u235.pl/track/${rows[0].token}`, expires_at: rows[0].expires_at });
});

// GDPR data export — zwraca wszystkie dane użytkownika w JSON
router.get('/me/export', async (req, res) => {
  const uid = req.user.id;
  const user = (await db.query(`SELECT id, email, username, avatar_url, alert_radius_m, reputation_score, is_child, email_verified, referral_code, created_at FROM users WHERE id = $1`, [uid])).rows[0];
  const alerts = (await db.query(`SELECT id, category, title, description, ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng, radius_m, status, created_at, expires_at FROM alerts WHERE author_id = $1`, [uid])).rows;
  const votes = (await db.query(`SELECT alert_id, vote, created_at FROM alert_votes WHERE user_id = $1`, [uid])).rows;
  const comments = (await db.query(`SELECT alert_id, content, created_at FROM alert_comments WHERE user_id = $1`, [uid])).rows;
  const locationHistory = (await db.query(`SELECT ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng, recorded_at FROM location_history WHERE user_id = $1 ORDER BY recorded_at DESC LIMIT 10000`, [uid])).rows;
  const groups = (await db.query(`SELECT g.id, g.name, g.invite_code, m.role, m.joined_at FROM family_members m JOIN family_groups g ON g.id = m.group_id WHERE m.user_id = $1`, [uid])).rows;

  res.setHeader('Content-Disposition', `attachment; filename=besafe-export-${uid}.json`);
  res.json({
    exported_at: new Date().toISOString(),
    notice: 'Export danych osobowych zgodnie z RODO art. 20',
    user, alerts, votes, comments, location_history: locationHistory, family_groups: groups,
  });
});

router.post('/me/delete', async (req, res) => {
  const { password } = req.body;
  const { rows } = await db.query(`SELECT password_hash FROM users WHERE id = $1`, [req.user.id]);
  if (!rows[0] || !(await require('bcryptjs').compare(password, rows[0].password_hash)))
    return res.status(401).json({ error: 'Wrong password' });
  await db.query(`DELETE FROM location_history WHERE user_id = $1`, [req.user.id]);
  await db.query(`DELETE FROM alert_votes WHERE user_id = $1`, [req.user.id]);
  await db.query(`DELETE FROM alert_notifications WHERE user_id = $1`, [req.user.id]);
  await db.query(`DELETE FROM alerts WHERE author_id = $1`, [req.user.id]);
  await db.query(`DELETE FROM family_members WHERE user_id = $1`, [req.user.id]);
  await db.query(`DELETE FROM users WHERE id = $1`, [req.user.id]);
  res.json({ ok: true });
});

// Check-in — "Jestem bezpieczny"
router.post('/me/checkin', async (req, res) => {
  const { status, message, lat, lng, battery_level } = req.body;
  const loc = (lat != null && lng != null) ? `ST_MakePoint(${lng}, ${lat})::geography` : 'NULL';
  await db.query(
    `INSERT INTO user_checkins (user_id, status, message, location, battery_level)
     VALUES ($1, $2, $3, ${loc}, $4)`,
    [req.user.id, status || 'safe', message || null, battery_level]
  );
  // Notify family parents via socket
  const io = req.app.get('io');
  if (io) {
    const { rows: groups } = await db.query(
      `SELECT m2.user_id AS parent_id, u.username
       FROM family_members m1
       JOIN family_members m2 ON m1.group_id = m2.group_id
       JOIN users u ON u.id = $1
       WHERE m1.user_id = $1 AND m2.role = 'parent'`,
      [req.user.id]
    );
    for (const g of groups) {
      io.to(`user:${g.parent_id}`).emit('family:checkin', {
        user_id: req.user.id, username: g.username, status: status || 'safe', message,
      });
    }
  }
  res.json({ ok: true });
});

// Battery update — z apki przesyłane w tle
router.put('/me/battery', async (req, res) => {
  const { level } = req.body;
  if (typeof level !== 'number' || level < 0 || level > 100) {
    return res.status(400).json({ error: 'Invalid battery level' });
  }
  await db.query(
    `UPDATE users SET last_battery_level = $1, last_battery_at = NOW() WHERE id = $2`,
    [level, req.user.id]
  );
  // Alert parents gdy < 15%
  if (level <= 15) {
    const io = req.app.get('io');
    if (io) {
      const { rows: parents } = await db.query(
        `SELECT m2.user_id AS parent_id, u.username FROM family_members m1
         JOIN family_members m2 ON m1.group_id = m2.group_id
         JOIN users u ON u.id = $1
         WHERE m1.user_id = $1 AND m1.role = 'child' AND m2.role = 'parent'`,
        [req.user.id]
      );
      for (const p of parents) {
        io.to(`user:${p.parent_id}`).emit('family:low_battery', {
          user_id: req.user.id, username: p.username, level,
        });
      }
    }
  }
  res.json({ ok: true });
});

// Block a user
router.post('/:id/block', async (req, res) => {
  try {
    await db.query(`INSERT INTO user_blocks (blocker_id, blocked_id) VALUES ($1, $2)`, [req.user.id, req.params.id]);
    res.json({ ok: true });
  } catch (e) {
    if (e.code === '23505') return res.json({ ok: true, already: true });
    res.status(500).json({ error: e.message });
  }
});

router.delete('/:id/block', async (req, res) => {
  await db.query(`DELETE FROM user_blocks WHERE blocker_id = $1 AND blocked_id = $2`, [req.user.id, req.params.id]);
  res.json({ ok: true });
});

module.exports = router;
