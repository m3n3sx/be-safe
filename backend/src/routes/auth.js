const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const auth = require('../middleware/auth');

const signToken = (user) =>
  jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN,
  });

router.post('/register', async (req, res) => {
  try {
    const { email, password, username } = req.body;
    const hash = await bcrypt.hash(password, 10);
    const { rows } = await db.query(
      `INSERT INTO users (email, password_hash, username) VALUES ($1, $2, $3) RETURNING id, email, username`,
      [email, hash, username]
    );
    res.status(201).json({ token: signToken(rows[0]), user: rows[0] });
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'Email or username taken' });
    res.status(500).json({ error: e.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const { rows } = await db.query(`SELECT * FROM users WHERE email = $1`, [email]);
    if (!rows[0] || !(await bcrypt.compare(password, rows[0].password_hash)))
      return res.status(401).json({ error: 'Invalid credentials' });

    const { password_hash, ...user } = rows[0];
    res.json({ token: signToken(user), user });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/google', async (req, res) => {
  try {
    const { email, display_name, avatar_url } = req.body;
    if (!email) return res.status(400).json({ error: 'Email required' });

    const { rows: existing } = await db.query(`SELECT * FROM users WHERE email = $1`, [email]);
    if (existing[0]) {
      // Update avatar and name from Google profile
      if (avatar_url || display_name) {
        await db.query(`UPDATE users SET avatar_url = COALESCE($2, avatar_url), username = COALESCE($3, username) WHERE id = $1`,
          [existing[0].id, avatar_url || null, display_name || null]);
        existing[0].avatar_url = avatar_url || existing[0].avatar_url;
        existing[0].username = display_name || existing[0].username;
      }
      const { password_hash, ...user } = existing[0];
      return res.json({ token: signToken(user), user });
    }

    const username = display_name || email.split('@')[0];
    const hash = await bcrypt.hash(Math.random().toString(36), 10);
    const { rows } = await db.query(
      `INSERT INTO users (email, password_hash, username, avatar_url) VALUES ($1, $2, $3, $4) RETURNING id, email, username, avatar_url`,
      [email, hash, username, avatar_url || null]
    );
    res.status(201).json({ token: signToken(rows[0]), user: rows[0] });
  } catch (e) {
    if (e.code === '23505') {
      const { rows } = await db.query(`SELECT * FROM users WHERE email = $1`, [req.body.email]);
      if (rows[0]) { const { password_hash, ...user } = rows[0]; return res.json({ token: signToken(user), user }); }
    }
    res.status(500).json({ error: e.message });
  }
});

router.post('/refresh', auth, (req, res) => {
  res.json({ token: signToken(req.user) });
});

module.exports = router;
