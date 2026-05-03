const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

router.use(auth);

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
    `SELECT id, email, username, avatar_url, alert_radius_m, reputation_score, is_child, created_at FROM users WHERE id = $1`,
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

module.exports = router;
