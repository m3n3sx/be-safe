// F14 Geofence chat sąsiedzki (Nextdoor-style).
// Czat oparty na ST_DWithin: widzisz wiadomości w promieniu wokół swojej lokalizacji.
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../config/db');

router.use(auth);

const DEFAULT_RADIUS = 2000; // 2 km
const MAX_RADIUS = 10000;

// Lokalizacja usera: z query (lat/lng) lub fallback do last_location.
async function resolveLocation(req) {
  const lat = parseFloat(req.query.lat ?? req.body?.lat);
  const lng = parseFloat(req.query.lng ?? req.body?.lng);
  if (isFinite(lat) && isFinite(lng)) return { lat, lng };
  const { rows } = await db.query(
    `SELECT ST_Y(last_location::geometry) AS lat, ST_X(last_location::geometry) AS lng
     FROM users WHERE id = $1`,
    [req.user.id]
  );
  if (rows[0]?.lat != null) return { lat: rows[0].lat, lng: rows[0].lng };
  return null;
}

// GET /neighborhood/messages?lat=&lng=&radius_m=2000&limit=50&before=ISO
router.get('/messages', async (req, res) => {
  const loc = await resolveLocation(req);
  if (!loc) return res.status(400).json({ error: 'Brak lokalizacji — udostępnij GPS' });
  const radius = Math.min(parseInt(req.query.radius_m, 10) || DEFAULT_RADIUS, MAX_RADIUS);
  const limit = Math.min(parseInt(req.query.limit, 10) || 50, 200);
  const params = [loc.lng, loc.lat, radius];
  let whereExtra = '';
  if (req.query.before) {
    params.push(req.query.before);
    whereExtra = `AND m.created_at < $4`;
  }
  const { rows } = await db.query(
    `SELECT m.id, m.body, m.created_at, m.author_id,
            u.username AS author_username, u.avatar_url AS author_avatar,
            ST_Distance(m.location, ST_MakePoint($1, $2)::geography) AS distance_m
     FROM neighborhood_messages m JOIN users u ON u.id = m.author_id
     WHERE ST_DWithin(m.location, ST_MakePoint($1, $2)::geography, $3) ${whereExtra}
     ORDER BY m.created_at DESC LIMIT ${limit}`,
    params
  );
  res.json({ messages: rows.reverse(), radius_m: radius });
});

// POST /neighborhood/messages { body, lat, lng }
router.post('/messages', async (req, res) => {
  const body = (req.body?.body || '').trim();
  if (body.length === 0 || body.length > 1000) {
    return res.status(400).json({ error: 'Wiadomość musi mieć 1-1000 znaków' });
  }
  const loc = await resolveLocation(req);
  if (!loc) return res.status(400).json({ error: 'Brak lokalizacji — udostępnij GPS' });

  const { rows } = await db.query(
    `INSERT INTO neighborhood_messages (author_id, location, body)
     VALUES ($1, ST_MakePoint($2, $3)::geography, $4)
     RETURNING id, body, created_at, author_id`,
    [req.user.id, loc.lng, loc.lat, body]
  );
  const { rows: [author] } = await db.query(
    `SELECT username, avatar_url FROM users WHERE id = $1`, [req.user.id]
  );
  const payload = {
    ...rows[0],
    author_username: author.username,
    author_avatar: author.avatar_url,
    lat: loc.lat,
    lng: loc.lng,
  };
  // Broadcast geo-tagged; klient filtruje po dystansie od swojej lokalizacji.
  const io = req.app.get('io');
  if (io) io.emit('neighborhood:message', payload);
  res.status(201).json(payload);
});

module.exports = router;
