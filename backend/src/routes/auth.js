const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../config/db');
const auth = require('../middleware/auth');
const email = require('../services/email');

const APP_URL = process.env.APP_URL || 'https://besafe.org.pl';

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

async function createPasswordResetToken(userId) {
  const token = crypto.randomBytes(32).toString('hex');
  const expires = new Date(Date.now() + 60 * 60 * 1000); // 1h
  // Invalidate previous unused tokens for this user
  await db.query(`UPDATE password_reset_tokens SET used = TRUE WHERE user_id = $1 AND used = FALSE`, [userId]);
  await db.query(
    `INSERT INTO password_reset_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)`,
    [userId, token, expires]
  );
  return token;
}

// ------ REGISTER ------
router.post('/register', async (req, res) => {
  try {
    const { email: userEmail, password, username, referral_code } = req.body;
    if (!userEmail || !password || !username) return res.status(400).json({ error: 'Missing fields' });
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
      [userEmail, hash, username, myCode, referredBy]
    );

    // Send verification email (async — don't block response)
    const verifyToken = await createVerificationToken(rows[0].id);
    const verifyUrl = `${APP_URL}/verify-email?token=${verifyToken}`;
    email.sendVerificationEmail({ to: userEmail, username, verifyUrl }).catch((e) => {
      console.error('[auth/register] verification email failed:', e.message);
    });

    res.status(201).json({
      token: signToken(rows[0]),
      user: rows[0],
      verify_url: verifyUrl,
    });
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'Email or username taken' });
    res.status(500).json({ error: e.message });
  }
});

// ------ LOGIN ------
router.post('/login', async (req, res) => {
  try {
    const { email: userEmail, password } = req.body;
    const { rows } = await db.query(`SELECT * FROM users WHERE email = $1`, [userEmail]);
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
    const { email: userEmail, display_name, avatar_url, referral_code } = req.body;
    if (!userEmail) return res.status(400).json({ error: 'Email required' });

    const { rows: existing } = await db.query(`SELECT id FROM users WHERE email = $1`, [userEmail]);
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

    const username = display_name || userEmail.split('@')[0];
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
      [userEmail, hash, username, avatar_url || null, myCode, referredBy]
    );

    // Google auto-verified — send welcome email directly
    email.sendWelcomeEmail({ to: userEmail, username }).catch((e) => {
      console.error('[auth/google] welcome email failed:', e.message);
    });

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
    `SELECT t.user_id, u.email, u.username, u.email_verified
       FROM email_verification_tokens t
       JOIN users u ON u.id = t.user_id
      WHERE t.token = $1 AND t.used = FALSE AND t.expires_at > NOW()`,
    [token]
  );
  if (!rows[0]) return res.status(400).json({ error: 'Invalid or expired token' });

  const alreadyVerified = rows[0].email_verified;
  await db.query(`UPDATE users SET email_verified = TRUE WHERE id = $1`, [rows[0].user_id]);
  await db.query(`UPDATE email_verification_tokens SET used = TRUE WHERE token = $1`, [token]);

  // Send welcome email only on FIRST verification
  if (!alreadyVerified) {
    email.sendWelcomeEmail({ to: rows[0].email, username: rows[0].username }).catch((e) => {
      console.error('[auth/verify-email] welcome email failed:', e.message);
    });
  }

  res.json({ ok: true });
});

router.post('/resend-verification', auth, async (req, res) => {
  const { rows } = await db.query(
    `SELECT email, username, email_verified FROM users WHERE id = $1`,
    [req.user.id]
  );
  if (rows[0]?.email_verified) return res.json({ ok: true, already_verified: true });

  await db.query(`UPDATE email_verification_tokens SET used = TRUE WHERE user_id = $1 AND used = FALSE`, [req.user.id]);
  const token = await createVerificationToken(req.user.id);
  const verifyUrl = `${APP_URL}/verify-email?token=${token}`;

  email.sendVerificationEmail({ to: rows[0].email, username: rows[0].username, verifyUrl }).catch((e) => {
    console.error('[auth/resend] email failed:', e.message);
  });

  res.json({ ok: true, verify_url: verifyUrl });
});

// ------ PASSWORD RESET ------

// Step 1: request reset — always returns 200 to prevent email enumeration
router.post('/forgot-password', async (req, res) => {
  try {
    const { email: userEmail } = req.body;
    if (!userEmail) return res.status(400).json({ error: 'Email required' });

    const { rows } = await db.query(
      `SELECT id, email, username FROM users WHERE email = $1`,
      [userEmail]
    );
    if (rows[0]) {
      const token = await createPasswordResetToken(rows[0].id);
      const resetUrl = `${APP_URL}/reset-password?token=${token}`;
      email.sendPasswordResetEmail({
        to: rows[0].email,
        username: rows[0].username,
        resetUrl,
      }).catch((e) => console.error('[auth/forgot] email failed:', e.message));
    }

    // Always 200 — don't leak whether email exists
    res.json({ ok: true, message: 'Jeśli konto istnieje, link do resetu został wysłany.' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Step 2: verify token + set new password
router.post('/reset-password', async (req, res) => {
  try {
    const { token, password } = req.body;
    if (!token || !password) return res.status(400).json({ error: 'Token and password required' });
    if (password.length < 6) return res.status(400).json({ error: 'Password too short' });

    const { rows } = await db.query(
      `SELECT t.user_id, u.email, u.username
         FROM password_reset_tokens t
         JOIN users u ON u.id = t.user_id
        WHERE t.token = $1 AND t.used = FALSE AND t.expires_at > NOW()`,
      [token]
    );
    if (!rows[0]) return res.status(400).json({ error: 'Invalid or expired token' });

    const hash = await bcrypt.hash(password, 10);
    await db.query(`UPDATE users SET password_hash = $1 WHERE id = $2`, [hash, rows[0].user_id]);
    await db.query(`UPDATE password_reset_tokens SET used = TRUE WHERE token = $1`, [token]);

    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ------ DEMO ------
router.post('/demo', async (req, res) => {
  try {
    const suffix = crypto.randomBytes(4).toString('hex');
    const userEmail = `demo-${suffix}@besafe.demo`;
    const username = `Gość${suffix.substring(0, 4).toUpperCase()}`;
    const hash = await bcrypt.hash(crypto.randomBytes(16).toString('hex'), 10);
    const code = genReferralCode();

    const { rows } = await db.query(
      `INSERT INTO users (email, password_hash, username, email_verified, referral_code, alert_radius_m)
       VALUES ($1, $2, $3, TRUE, $4, 5000)
       RETURNING id, email, username, email_verified, referral_code`,
      [userEmail, hash, username, code]
    );
    res.status(201).json({ token: signToken(rows[0]), user: { ...rows[0], is_demo: true } });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/refresh', auth, (req, res) => {
  res.json({ token: signToken(req.user) });
});

module.exports = router;
