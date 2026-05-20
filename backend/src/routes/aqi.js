// F17: Air Quality Index — GIOŚ Polska
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const aqi = require('../services/aqi');

router.use(auth);

// GET /aqi/nearby?lat=...&lng=...&radius_m=30000&limit=5
router.get('/nearby', async (req, res) => {
  const lat = parseFloat(req.query.lat);
  const lng = parseFloat(req.query.lng);
  if (!isFinite(lat) || !isFinite(lng)) return res.status(400).json({ error: 'Invalid lat/lng' });
  const radiusM = Math.min(parseInt(req.query.radius_m) || 30000, 100000);
  const limit = Math.min(parseInt(req.query.limit) || 5, 20);
  try {
    const stations = await aqi.getReadingsNear(lat, lng, radiusM, limit);
    res.json({ stations });
  } catch (e) {
    console.error('[aqi] /nearby error:', e.message);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
