// F11: AED Locator endpoints
const express = require('express');
const router = express.Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

router.use(auth);

// GET /aeds/nearby?lat=X&lng=Y&radius=2000 (default 2km, max 20km)
router.get('/nearby', async (req, res) => {
  const lat = parseFloat(req.query.lat);
  const lng = parseFloat(req.query.lng);
  let radius = parseInt(req.query.radius, 10) || 2000;
  if (radius > 20000) radius = 20000;
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return res.status(400).json({ error: 'Invalid lat/lng' });
  }
  try {
    const { rows } = await db.query(
      `SELECT id, source, source_id,
              ST_Y(location::geometry) AS lat,
              ST_X(location::geometry) AS lng,
              description, address, operator, opening_hours, indoor,
              ST_Distance(location, ST_MakePoint($2, $1)::geography)::int AS distance_m
       FROM aeds
       WHERE ST_DWithin(location, ST_MakePoint($2, $1)::geography, $3)
       ORDER BY distance_m ASC
       LIMIT 200`,
      [lat, lng, radius]
    );
    res.json({ aeds: rows });
  } catch (e) {
    console.error('[aeds/nearby]', e.message);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
