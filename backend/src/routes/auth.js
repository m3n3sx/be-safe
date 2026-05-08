const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/db');
const auth = require('../middleware/auth');

const signToken = (user) =>
  jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN,
  });

const genReferralCode = () => crypto.randomBytes(3).toString('hex').toUpperCase();

async function createVerificationToken(userId) {
  const token = crypto.randomBytes(32).toString('hex');
  const expires = new Date(Date.now() + 7 * 24 * 3600 * 1000);
  await db.query(
    `INSERT INTO email_verification_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)`,
    [userId, token, expires]
  );
  return token;
}

// ------ REGISTER ------
router.post('/register', async (req, res) => {
  try {
    const { email, password, username, referral_code } = req.body;
    if (!email || !password || !username) return res.status(400).json({ error: 'Missing fields' });
    if (password.length < 6) return res.status(400).json({ error: 'Password too short' });

    const hash = await bcrypt.hash(password, 10);
    const myCode = genReferralCode();

    // Find referrer
    let referredBy = null;
    if (referral_code) {
      const { rows: ref } = await db.query(`SELECT id FROM users WHERE referral_code = $1`, [referral_code.toUpperCase()]);
      if (ref[0]) referredBy = ref[0].id;
    }

    const { rows } = await db.query(
      `INSERT INTO users (email, password_hash, username, referral_code, referred_by)
       VALUES ($1, $2, $3, $4, $5) RETURNING id, email, username, referral_code, email_verified`,
      [email, hash, username, myCode, referredBy]
    );

    // Create verification token
    const verifyToken = await createVerificationToken(rows[0].id);
    console.log(`[Email Verification] Token for ${email}: ${verifyToken}`);
    // TODO: send email via SMTP or external service

    res.status(201).json({
      token: signToken(rows[0]),
      user: rows[0],
      verify_url: `https://alert.u235.pl/verify-email?token=${verifyToken}`,
    });
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'Email or username taken' });
    res.status(500).json({ error: e.message });
  }
});

// ------ LOGIN ------
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

// ------ GOOGLE ------
router.post('/google', async (req, res) => {
  try {
    const { email, display_name, avatar_url, referral_code } = req.body;
    if (!email) return res.status(400).json({ error: 'Email required' });

    const { rows: existing } = await db.query(`SELECT id FROM users WHERE email = $1`, [email]);
    if (existing[0]) {
      const uid = existing[0].id;
      if (avatar_url) await db.query(`UPDATE users SET avatar_url = $1 WHERE id = $2`, [avatar_url, uid]);
      if (display_name) await db.query(`UPDATE users SET username = $1 WHERE id = $2`, [display_name, uid]);
      // Google emails are auto-verified
      await db.query(`UPDATE users SET email_verified = TRUE WHERE id = $1`, [uid]);
      const { rows } = await db.query(
        `SELECT id, email, username, avatar_url, alert_radius_m, reputation_score, is_child, email_verified, referral_code FROM users WHERE id = $1`, [uid]);
      return res.json({ token: signToken(rows[0]), user: rows[0] });
    }

    const username = display_name || email.split('@')[0];
    const hash = await bcrypt.hash(Math.random().toString(36), 10);
    const myCode = genReferralCode();

    let referredBy = null;
    if (referral_code) {
      const { rows: ref } = await db.query(`SELECT id FROM users WHERE referral_code = $1`, [referral_code.toUpperCase()]);
      if (ref[0]) referredBy = ref[0].id;
    }

    const { rows } = await db.query(
      `INSERT INTO users (email, password_hash, username, avatar_url, email_verified, referral_code, referred_by)
       VALUES ($1, $2, $3, $4, TRUE, $5, $6)
       RETURNING id, email, username, avatar_url, email_verified, referral_code`,
      [email, hash, username, avatar_url || null, myCode, referredBy]
    );
    res.status(201).json({ token: signToken(rows[0]), user: rows[0] });
  } catch (e) {
    if (e.code === '23505') {
      const { rows } = await db.query(`SELECT id, email, username, avatar_url, email_verified, referral_code FROM users WHERE email = $1`, [req.body.email]);
      if (rows[0]) return res.json({ token: signToken(rows[0]), user: rows[0] });
    }
    res.status(500).json({ error: e.message });
  }
});

// ------ EMAIL VERIFICATION ------
router.post('/verify-email', async (req, res) => {
  const { token } = req.body;
  const { rows } = await db.query(
    `SELECT user_id FROM email_verification_tokens
     WHERE token = $1 AND used = FALSE AND expires_at > NOW()`,
    [token]
  );
  if (!rows[0]) return res.status(400).json({ error: 'Invalid or expired token' });

  await db.query(`UPDATE users SET email_verified = TRUE WHERE id = $1`, [rows[0].user_id]);
  await db.query(`UPDATE email_verification_tokens SET used = TRUE WHERE token = $1`, [token]);
  res.json({ ok: true });
});

router.post('/resend-verification', auth, async (req, res) => {
  const { rows } = await db.query(`SELECT email, email_verified FROM users WHERE id = $1`, [req.user.id]);
  if (rows[0]?.email_verified) return res.json({ ok: true, already_verified: true });

  await db.query(`UPDATE email_verification_tokens SET used = TRUE WHERE user_id = $1 AND used = FALSE`, [req.user.id]);
  const token = await createVerificationToken(req.user.id);
  console.log(`[Email Verification] Resend for ${rows[0].email}: ${token}`);
  res.json({ ok: true, verify_url: `https://alert.u235.pl/verify-email?token=${token}` });
});

// ------ REFRESH ------
router.post('/refresh', auth, (req, res) => {
  res.json({ token: signToken(req.user) });
});

module.exports = router;
