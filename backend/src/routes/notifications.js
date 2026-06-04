// Centrum powiadomień (inbox użytkownika).
// Lista, licznik nieprzeczytanych, oznacz przeczytane, usuń jedno, wyczyść wszystkie.
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../config/db');

router.use(auth);

// GET /notifications?limit=50&before=ISO
router.get('/', async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit, 10) || 50, 200);
  const params = [req.user.id];
  let whereExtra = '';
  if (req.query.before) {
    params.push(req.query.before);
    whereExtra = `AND created_at < $2`;
  }
  try {
    const { rows } = await db.query(
      `SELECT id, type, title, body, data, is_read, created_at
       FROM notifications
       WHERE user_id = $1 ${whereExtra}
       ORDER BY created_at DESC LIMIT ${limit}`,
      params
    );
    res.json({ notifications: rows });
  } catch (e) {
    console.error('[notifications] list:', e.message);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /notifications/unread-count → { count }
router.get('/unread-count', async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT COUNT(*)::int AS count FROM notifications WHERE user_id = $1 AND is_read = FALSE`,
      [req.user.id]
    );
    res.json({ count: rows[0].count });
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /notifications/read — oznacz wszystkie jako przeczytane
router.post('/read', async (req, res) => {
  try {
    await db.query(
      `UPDATE notifications SET is_read = TRUE WHERE user_id = $1 AND is_read = FALSE`,
      [req.user.id]
    );
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /notifications/:id — usuń jedno
router.delete('/:id', async (req, res) => {
  try {
    const { rowCount } = await db.query(
      `DELETE FROM notifications WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.user.id]
    );
    res.json({ ok: true, deleted: rowCount });
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /notifications — wyczyść wszystkie
router.delete('/', async (req, res) => {
  try {
    const { rowCount } = await db.query(
      `DELETE FROM notifications WHERE user_id = $1`,
      [req.user.id]
    );
    res.json({ ok: true, deleted: rowCount });
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
