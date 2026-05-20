const jwt = require('jsonwebtoken');
const db = require('../config/db');

// In-memory dedup: nie aktualizuj last_seen_at częściej niż co 60s per user
const lastSeenCache = new Map();
const LAST_SEEN_INTERVAL_MS = 60 * 1000;

module.exports = (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return res.status(401).json({ error: 'No token' });

  try {
    req.user = jwt.verify(header.slice(7), process.env.JWT_SECRET);

    // Async heartbeat update (nie blokuje requesta)
    const userId = req.user?.id;
    if (userId) {
      const now = Date.now();
      const prev = lastSeenCache.get(userId) || 0;
      if (now - prev > LAST_SEEN_INTERVAL_MS) {
        lastSeenCache.set(userId, now);
        db.query(`UPDATE users SET last_seen_at = NOW() WHERE id = $1`, [userId]).catch(() => {});
      }
    }

    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
};
