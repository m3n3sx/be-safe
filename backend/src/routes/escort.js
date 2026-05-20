// F03: Eskorta / Follow Me — sesja eskorty z ETA + share lokalizacji + auto-panic
const express = require('express');
const router = express.Router();
const db = require('../config/db');
const auth = require('../middleware/auth');
const { notifyUser } = require('../services/fcm');

router.use(auth);

const ACTIVE_SELECT = `
  SELECT e.id, e.requester_id, e.watcher_id, e.group_id,
         e.destination_lat, e.destination_lng, e.destination_name,
         e.eta_seconds, e.status,
         e.last_location_lat, e.last_location_lng, e.last_update_at,
         e.started_at, e.completed_at,
         ru.username AS requester_username, ru.avatar_url AS requester_avatar,
         ru.phone AS requester_phone,
         wu.username AS watcher_username, wu.avatar_url AS watcher_avatar,
         wu.phone AS watcher_phone
  FROM escort_sessions e
  JOIN users ru ON ru.id = e.requester_id
  JOIN users wu ON wu.id = e.watcher_id
`;

// POST /escort/start { watcher_id, destination_lat, destination_lng, destination_name?, eta_seconds, group_id? }
router.post('/start', async (req, res) => {
  const { watcher_id, destination_lat, destination_lng, destination_name, eta_seconds, group_id } = req.body || {};
  const lat = parseFloat(destination_lat);
  const lng = parseFloat(destination_lng);
  const eta = parseInt(eta_seconds, 10);
  if (!watcher_id || !Number.isFinite(lat) || !Number.isFinite(lng)) {
    return res.status(400).json({ error: 'Invalid watcher_id or destination' });
  }
  if (!Number.isFinite(eta) || eta <= 0 || eta > 14400) {
    return res.status(400).json({ error: 'eta_seconds must be 1..14400 (max 4h)' });
  }
  if (watcher_id === req.user.id) {
    return res.status(400).json({ error: 'Cannot watch yourself' });
  }
  try {
    // Anuluj poprzednią aktywną sesję requestera (1 aktywna naraz)
    await db.query(
      `UPDATE escort_sessions SET status='expired', completed_at=NOW()
       WHERE requester_id = $1 AND status='active'`,
      [req.user.id]
    );
    const { rows } = await db.query(
      `INSERT INTO escort_sessions
         (requester_id, watcher_id, group_id, destination_lat, destination_lng,
          destination_name, eta_seconds, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'active')
       RETURNING id, started_at, eta_seconds`,
      [req.user.id, watcher_id, group_id || null, lat, lng,
       (destination_name || '').slice(0, 200), eta]
    );
    const session = rows[0];
    // Pobierz username requestera
    const { rows: meRows } = await db.query(`SELECT username FROM users WHERE id=$1`, [req.user.id]);
    const requesterName = meRows[0]?.username || 'Ktoś z rodziny';
    // Push do watchera
    notifyUser(
      watcher_id,
      `🛡 ${requesterName} prosi o eskortę`,
      `${destination_name ? `Cel: ${destination_name}. ` : ''}ETA: ${Math.round(eta / 60)} min`,
      {
        type: 'escort_invite',
        escort_id: session.id,
        requester_id: req.user.id,
        requester_username: requesterName,
        destination_lat: lat,
        destination_lng: lng,
        destination_name: destination_name || '',
        eta_seconds: eta,
      }
    ).catch(() => {});
    // Socket emit
    const io = req.app.get('io');
    if (io) {
      io.to(`user:${watcher_id}`).emit('escort:started', {
        escort_id: session.id,
        requester_id: req.user.id,
        requester_username: requesterName,
        destination_lat: lat,
        destination_lng: lng,
        destination_name: destination_name || '',
        eta_seconds: eta,
        started_at: session.started_at,
      });
    }
    console.log(`[escort] ${requesterName} → ${watcher_id} (${session.id}, ${Math.round(eta/60)}min)`);
    res.status(201).json({ ok: true, escort_id: session.id, started_at: session.started_at });
  } catch (e) {
    console.error('[escort/start]', e.message);
    res.status(500).json({ error: 'Server error' });
  }
});

// PATCH /escort/:id/location { lat, lng } — requester live updates
router.patch('/:id/location', async (req, res) => {
  const { lat, lng } = req.body || {};
  const lat_ = parseFloat(lat);
  const lng_ = parseFloat(lng);
  if (!Number.isFinite(lat_) || !Number.isFinite(lng_)) {
    return res.status(400).json({ error: 'Invalid lat/lng' });
  }
  try {
    const { rows } = await db.query(
      `UPDATE escort_sessions
       SET last_location_lat = $2, last_location_lng = $3, last_update_at = NOW()
       WHERE id = $1 AND requester_id = $4 AND status = 'active'
       RETURNING id, watcher_id`,
      [req.params.id, lat_, lng_, req.user.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Active escort not found' });
    const io = req.app.get('io');
    if (io) {
      io.to(`user:${rows[0].watcher_id}`).emit('escort:location', {
        escort_id: rows[0].id, lat: lat_, lng: lng_, at: new Date().toISOString(),
      });
    }
    res.json({ ok: true });
  } catch (e) {
    console.error('[escort/location]', e.message);
    res.status(500).json({ error: 'Server error' });
  }
});

// PATCH /escort/:id/complete — requester dotarł
router.patch('/:id/complete', async (req, res) => {
  try {
    const { rows } = await db.query(
      `UPDATE escort_sessions
       SET status = 'completed', completed_at = NOW()
       WHERE id = $1 AND requester_id = $2 AND status = 'active'
       RETURNING id, watcher_id`,
      [req.params.id, req.user.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Active escort not found' });
    const { rows: meRows } = await db.query(`SELECT username FROM users WHERE id=$1`, [req.user.id]);
    const requesterName = meRows[0]?.username || 'Ktoś z rodziny';
    notifyUser(
      rows[0].watcher_id,
      `✅ ${requesterName} dotarł(a) bezpiecznie`,
      'Eskorta zakończona pomyślnie',
      { type: 'escort_completed', escort_id: rows[0].id, requester_id: req.user.id }
    ).catch(() => {});
    const io = req.app.get('io');
    if (io) io.to(`user:${rows[0].watcher_id}`).emit('escort:completed', { escort_id: rows[0].id });
    res.json({ ok: true });
  } catch (e) {
    console.error('[escort/complete]', e.message);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /escort/:id — anulacja przez requestera lub watchera
router.delete('/:id', async (req, res) => {
  try {
    const { rows } = await db.query(
      `UPDATE escort_sessions
       SET status = 'expired', completed_at = NOW()
       WHERE id = $1 AND (requester_id = $2 OR watcher_id = $2) AND status = 'active'
       RETURNING id, requester_id, watcher_id`,
      [req.params.id, req.user.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Active escort not found' });
    const r = rows[0];
    const otherId = r.requester_id === req.user.id ? r.watcher_id : r.requester_id;
    const io = req.app.get('io');
    if (io) io.to(`user:${otherId}`).emit('escort:cancelled', { escort_id: r.id, by: req.user.id });
    res.json({ ok: true });
  } catch (e) {
    console.error('[escort/cancel]', e.message);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /escort/active — moja aktywna sesja (jako requester LUB watcher)
router.get('/active', async (req, res) => {
  try {
    const { rows } = await db.query(
      `${ACTIVE_SELECT}
       WHERE (e.requester_id = $1 OR e.watcher_id = $1) AND e.status = 'active'
       ORDER BY e.started_at DESC LIMIT 5`,
      [req.user.id]
    );
    res.json({ sessions: rows });
  } catch (e) {
    console.error('[escort/active]', e.message);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /escort/:id — single session detail (requester albo watcher)
router.get('/:id', async (req, res) => {
  try {
    const { rows } = await db.query(
      `${ACTIVE_SELECT}
       WHERE e.id = $1 AND (e.requester_id = $2 OR e.watcher_id = $2)`,
      [req.params.id, req.user.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (e) {
    console.error('[escort/get]', e.message);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
