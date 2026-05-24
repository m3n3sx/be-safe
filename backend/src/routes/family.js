const router = require('express').Router();
const crypto = require('crypto');
const db = require('../config/db');
const auth = require('../middleware/auth');
const { notifyUser } = require('../services/fcm');

router.use(auth);

// F35: dozwolone role rodzinne
const ALLOWED_ROLES = new Set([
  'parent',
  'child',
  'senior',
  'guardian',
  'family_member',
  'partner',
  'friend',
  'other',
]);

// Role z pełnym wglądem w dziecko (lokalizacja, alerty, check-in)
const GUARDIAN_ROLES = new Set(['parent', 'guardian']);

// Middleware: check group membership
const memberOf = async (req, res, next) => {
  const { rows } = await db.query(
    `SELECT role FROM family_members WHERE group_id = $1 AND user_id = $2`,
    [req.params.id, req.user.id]
  );
  if (!rows[0]) return res.status(403).json({ error: 'Not a member' });
  req.memberRole = rows[0].role;
  next();
};

// Dawniej "parentOnly". Teraz: parent LUB guardian (F35).
// Zachowane dla wstecznej kompatybilności (alerty, safe routes, geofences itd).
const guardianOnly = (req, res, next) => {
  if (!GUARDIAN_ROLES.has(req.memberRole)) {
    return res.status(403).json({ error: 'Parent or guardian role required' });
  }
  next();
};
// Alias żeby reszta kodu się nie posypała:
const parentOnly = guardianOnly;

// Owner-only: tylko owner_id grupy (do zmiany ról i usuwania członków)
const ownerOnly = async (req, res, next) => {
  const { rows } = await db.query(
    `SELECT owner_id FROM family_groups WHERE id = $1`,
    [req.params.id]
  );
  if (!rows[0]) return res.status(404).json({ error: 'Group not found' });
  if (rows[0].owner_id !== req.user.id) {
    return res.status(403).json({ error: 'Only group owner can do this' });
  }
  next();
};

// ============================================
// F23 Ghost Mode - per-field visibility
// ============================================
// 7 pól które można ukryć przed konkretnym członkiem grupy:
const VISIBILITY_FIELDS = new Set([
  'location',  // live last_location lat/lng
  'history',   // location_history 24h
  'battery',   // last_battery_level
  'online',    // last_seen_at, online indicator
  'phone',     // phone number
  'alerts',    // czy widzi że ja zgłaszam alerty
  'checkin',   // senior check-in status
]);

// Defaultnie wszystko widoczne (TRUE) - przesłaniane przez DB row.
function defaultVisibility() {
  const o = {};
  for (const f of VISIBILITY_FIELDS) o[f] = true;
  return o;
}

// Zwraca obiekt { location:true, history:false, ... } - jak `viewer` widzi `target` w `group`.
async function getVisibility(groupId, viewerId, targetId) {
  if (viewerId === targetId) return defaultVisibility(); // siebie zawsze
  const out = defaultVisibility();
  const { rows } = await db.query(
    `SELECT field, granted FROM family_visibility
     WHERE group_id = $1 AND viewer_id = $2 AND target_id = $3`,
    [groupId, viewerId, targetId]
  );
  for (const r of rows) {
    if (VISIBILITY_FIELDS.has(r.field)) out[r.field] = r.granted;
  }
  return out;
}

// Sprawdza czy viewer może edytować ustawienia visibility:
// - zawsze może edytować swoje (viewer_id == self)
// - parent/guardian może edytować jak inni widzą jego DZIECKO (target_id ma role=child w tej grupie)
async function canEditVisibility(groupId, editorId, viewerId, targetId, editorRole) {
  if (viewerId === editorId) return true; // mojej widoczności wobec kogoś
  if (!GUARDIAN_ROLES.has(editorRole)) return false;
  // muszę być parent/guardian I target musi być child w tej samej grupie
  const { rows } = await db.query(
    `SELECT role FROM family_members WHERE group_id = $1 AND user_id = $2`,
    [groupId, targetId]
  );
  return rows[0]?.role === 'child';
}

// GET /family/groups/:id/visibility/:targetId
// Zwraca matrycę: jak ja widzę :targetId (default + DB overrides).
// Jeśli targetId == 'children-overrides', zwraca grupowo dla wszystkich dzieci których jestem parent/guardian.
router.get('/groups/:id/visibility/:targetId', memberOf, async (req, res) => {
  const visibility = await getVisibility(req.params.id, req.user.id, req.params.targetId);
  res.json({ visibility, fields: Array.from(VISIBILITY_FIELDS) });
});

// GET /family/groups/:id/visibility-matrix/:childId
// Dla rodzica/opiekuna: jak WSZYSCY członkowie grupy widzą :childId.
// Zwraca { viewers: [{viewer_id, viewer_username, visibility: {...}}] }
router.get('/groups/:id/visibility-matrix/:childId', memberOf, async (req, res) => {
  // czek: muszę być parent/guardian I childId musi być child
  if (!GUARDIAN_ROLES.has(req.memberRole)) {
    return res.status(403).json({ error: 'Parent or guardian required' });
  }
  const { rows: childCheck } = await db.query(
    `SELECT role FROM family_members WHERE group_id = $1 AND user_id = $2`,
    [req.params.id, req.params.childId]
  );
  if (!childCheck[0] || childCheck[0].role !== 'child') {
    return res.status(403).json({ error: 'Target must be a child member' });
  }
  // wszyscy członkowie grupy oprócz dziecka i mnie
  const { rows: viewers } = await db.query(
    `SELECT m.user_id AS viewer_id, u.username AS viewer_username, u.avatar_url, m.role
     FROM family_members m JOIN users u ON m.user_id = u.id
     WHERE m.group_id = $1 AND m.user_id <> $2`,
    [req.params.id, req.params.childId]
  );
  const matrix = [];
  for (const v of viewers) {
    const visibility = await getVisibility(req.params.id, v.viewer_id, req.params.childId);
    matrix.push({
      viewer_id: v.viewer_id,
      viewer_username: v.viewer_username,
      avatar_url: v.avatar_url,
      role: v.role,
      visibility,
    });
  }
  res.json({ matrix, fields: Array.from(VISIBILITY_FIELDS) });
});

// PUT /family/groups/:id/visibility/:targetId
// Body: { viewer_id?, field, granted } - viewer_id default self.
// Self może ustawić jak go inni widzą; parent/guardian może ustawić jak inni widzą jego DZIECKO.
router.put('/groups/:id/visibility/:targetId', memberOf, async (req, res) => {
  const { field, granted } = req.body || {};
  const viewerId = req.body.viewer_id || req.user.id;
  if (!VISIBILITY_FIELDS.has(field)) {
    return res.status(400).json({ error: 'Invalid field', allowed: Array.from(VISIBILITY_FIELDS) });
  }
  if (typeof granted !== 'boolean') {
    return res.status(400).json({ error: 'granted must be boolean' });
  }
  // Walidacja uprawnień:
  // Przypadek A: viewer_id == self I target jakikolwiek (ja ustawiam jak ja widzę kogoś — nieużyteczne, ale dozwolone? nie - to bez sensu)
  // Przypadek B: target_id == self (jak inni widzą mnie) — viewer_id musi być != self
  // Przypadek C: parent/guardian edytuje jak inni widzą jego dziecko (viewer_id != target_id, target_id == child)
  const targetId = req.params.targetId;
  const selfId = req.user.id;

  let allowed = false;
  if (targetId === selfId) {
    // Ja ustawiam jak ktoś widzi mnie — OK, viewer_id musi być != self
    if (viewerId === selfId) return res.status(400).json({ error: 'Cannot set visibility for self viewing self' });
    allowed = true;
  } else {
    // target != self - możliwe tylko jeśli parent/guardian edytuje dla dziecka
    allowed = await canEditVisibility(req.params.id, selfId, viewerId, targetId, req.memberRole);
  }
  if (!allowed) return res.status(403).json({ error: 'Not allowed to edit this visibility' });

  await db.query(
    `INSERT INTO family_visibility (group_id, viewer_id, target_id, field, granted, updated_at)
     VALUES ($1, $2, $3, $4, $5, NOW())
     ON CONFLICT (group_id, viewer_id, target_id, field)
     DO UPDATE SET granted = EXCLUDED.granted, updated_at = NOW()`,
    [req.params.id, viewerId, targetId, field, granted]
  );
  res.json({ ok: true });
});

// --- Groups ---

router.post('/groups', async (req, res) => {
  const code = crypto.randomBytes(4).toString('hex').toUpperCase();
  const { rows } = await db.query(
    `INSERT INTO family_groups (name, owner_id, invite_code) VALUES ($1, $2, $3) RETURNING *`,
    [req.body.name, req.user.id, code]
  );
  await db.query(
    `INSERT INTO family_members (group_id, user_id, role) VALUES ($1, $2, 'parent')`,
    [rows[0].id, req.user.id]
  );
  res.status(201).json(rows[0]);
});

router.get('/groups', async (req, res) => {
  const { rows } = await db.query(
    `SELECT g.*, m.role AS your_role FROM family_groups g JOIN family_members m ON g.id = m.group_id WHERE m.user_id = $1`,
    [req.user.id]
  );
  res.json({ groups: rows });
});

router.post('/groups/join', async (req, res) => {
  const { rows: groups } = await db.query(`SELECT id FROM family_groups WHERE invite_code = $1`, [req.body.invite_code]);
  if (!groups[0]) return res.status(404).json({ error: 'Invalid code' });

  // F35: role wybierana przez dołączającego. Default 'family_member' (najbezpieczniejszy).
  const requestedRole = req.body.role || 'family_member';
  if (!ALLOWED_ROLES.has(requestedRole)) {
    return res.status(400).json({ error: 'Invalid role', allowed: Array.from(ALLOWED_ROLES) });
  }

  try {
    await db.query(
      `INSERT INTO family_members (group_id, user_id, role) VALUES ($1, $2, $3)`,
      [groups[0].id, req.user.id, requestedRole]
    );
    // is_child=TRUE tylko gdy faktycznie role='child' (do filtrów na liście dzieci itp.)
    if (requestedRole === 'child') {
      await db.query(`UPDATE users SET is_child = TRUE WHERE id = $1`, [req.user.id]);
    }
    res.json({ ok: true, group_id: groups[0].id, role: requestedRole });
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'Already a member' });
    res.status(500).json({ error: e.message });
  }
});

router.get('/groups/:id/members', memberOf, async (req, res) => {
  const { rows } = await db.query(
    `SELECT m.user_id, u.username, u.avatar_url, u.phone, m.role, m.tracking_enabled,
            m.school_hours_silent, u.app_mode,
            ST_Y(u.last_location::geometry) AS lat, ST_X(u.last_location::geometry) AS lng,
            u.last_location_at, u.last_seen_at, u.last_battery_level
     FROM family_members m JOIN users u ON m.user_id = u.id WHERE m.group_id = $1`,
    [req.params.id]
  );
  // F23 Ghost mode: filtrowanie pól wg family_visibility względem req.user.id.
  const filtered = [];
  for (const r of rows) {
    if (r.user_id === req.user.id) {
      filtered.push(r); // siebie zawsze pełna widoczność
      continue;
    }
    const vis = await getVisibility(req.params.id, req.user.id, r.user_id);
    const out = { ...r };
    if (!vis.location) { out.lat = null; out.lng = null; out.last_location_at = null; }
    if (!vis.battery) out.last_battery_level = null;
    if (!vis.online) out.last_seen_at = null;
    if (!vis.phone) out.phone = null;
    out._visibility = vis; // klient może chcieć wiedzieć co jest ukryte
    filtered.push(out);
  }
  res.json({ members: filtered });
});

router.patch('/groups/:id/members/:uid', memberOf, async (req, res, next) => {
  // F35: zmiana roli wymaga ownera, ale tracking_enabled/school_hours_silent może zmienić parent/guardian.
  const wantsRoleChange = 'role' in (req.body || {});
  if (wantsRoleChange) {
    // owner check
    const { rows } = await db.query(`SELECT owner_id FROM family_groups WHERE id = $1`, [req.params.id]);
    if (!rows[0]) return res.status(404).json({ error: 'Group not found' });
    if (rows[0].owner_id !== req.user.id) {
      return res.status(403).json({ error: 'Only group owner can change roles' });
    }
    if (!ALLOWED_ROLES.has(req.body.role)) {
      return res.status(400).json({ error: 'Invalid role', allowed: Array.from(ALLOWED_ROLES) });
    }
  } else {
    // pozostałe pola: parent/guardian może
    if (!GUARDIAN_ROLES.has(req.memberRole)) {
      return res.status(403).json({ error: 'Parent or guardian role required' });
    }
  }
  next();
}, async (req, res) => {
  const allowed = ['tracking_enabled', 'role', 'school_hours_silent'];
  const fields = Object.keys(req.body).filter((k) => allowed.includes(k));
  if (!fields.length) return res.status(400).json({ error: 'No valid fields' });

  const sets = fields.map((f, i) => `${f} = $${i + 3}`).join(', ');
  const vals = fields.map((f) => req.body[f]);
  await db.query(`UPDATE family_members SET ${sets} WHERE group_id = $1 AND user_id = $2`, [req.params.id, req.params.uid, ...vals]);

  // Side-effect: jeśli zmieniono rolę na/z 'child', zaktualizuj users.is_child
  if (fields.includes('role')) {
    await db.query(`UPDATE users SET is_child = $1 WHERE id = $2`, [req.body.role === 'child', req.params.uid]);
  }
  res.json({ ok: true });
});

router.delete('/groups/:id/members/:uid', memberOf, ownerOnly, async (req, res) => {
  await db.query(`DELETE FROM family_members WHERE group_id = $1 AND user_id = $2`, [req.params.id, req.params.uid]);
  res.json({ ok: true });
});

router.delete('/groups/:id', async (req, res) => {
  const { rowCount } = await db.query(`DELETE FROM family_groups WHERE id = $1 AND owner_id = $2`, [req.params.id, req.user.id]);
  if (!rowCount) return res.status(403).json({ error: 'Not owner' });
  res.json({ ok: true });
});

// --- Ping: wyślij sygnał do wszystkich członków grupy (oprócz nadawcy) ---
router.post('/groups/:id/ping', memberOf, async (req, res) => {
  const { rows: me } = await db.query(`SELECT username FROM users WHERE id = $1`, [req.user.id]);
  const senderName = me[0]?.username || 'Ktoś z rodziny';

  const { rows: members } = await db.query(
    `SELECT user_id FROM family_members WHERE group_id = $1 AND user_id != $2`,
    [req.params.id, req.user.id]
  );

  const { rows: group } = await db.query(`SELECT name FROM family_groups WHERE id = $1`, [req.params.id]);
  const groupName = group[0]?.name || 'Rodzina';

  const io = req.app.get('io');
  const title = `Sygnał od ${senderName}`;
  const body = `${senderName} prosi o znak życia w grupie "${groupName}"`;

  let sent = 0;
  const pingIds = [];
  for (const m of members) {
    // Zapisz wiersz pinga - każdy odbiorca dostaje swój własny ID, na który odpowiada
    const { rows: pingRow } = await db.query(
      `INSERT INTO family_pings (group_id, sender_id, recipient_id) VALUES ($1, $2, $3) RETURNING id, sent_at`,
      [req.params.id, req.user.id, m.user_id]
    );
    const pingId = pingRow[0].id;
    pingIds.push(pingId);

    if (io) {
      io.to(`user:${m.user_id}`).emit('family:ping', {
        ping_id: pingId,
        from_user_id: req.user.id,
        from_username: senderName,
        group_id: req.params.id,
        group_name: groupName,
        sent_at: pingRow[0].sent_at,
      });
    }
    const result = await notifyUser(m.user_id, title, body, {
      type: 'family_ping',
      ping_id: pingId,
      group_id: req.params.id,
      group_name: groupName,
      from_user_id: req.user.id,
      from_username: senderName,
    });
    if (result) sent++;
  }

  console.log(`[ping] ${senderName} → ${members.length} members in ${req.params.id} (FCM sent: ${sent})`);
  res.json({ ok: true, recipients: members.length, fcm_sent: sent, ping_ids: pingIds });
});

// --- Pending pings: lista nieodpowiedzianych ping'ów do mnie (np. po zalogowaniu) ---
router.get('/pings/pending', async (req, res) => {
  const { rows } = await db.query(
    `SELECT p.id AS ping_id, p.group_id, p.sender_id, p.sent_at,
            u.username AS from_username, g.name AS group_name
       FROM family_pings p
       JOIN users u ON u.id = p.sender_id
       JOIN family_groups g ON g.id = p.group_id
      WHERE p.recipient_id = $1 AND p.response_status IS NULL
        AND p.sent_at > NOW() - INTERVAL '30 minutes'
      ORDER BY p.sent_at DESC`,
    [req.user.id]
  );
  res.json({ pings: rows });
});

// --- Pojedynczy ping (np. po tapnięciu w powiadomienie - widok dla odbiorcy) ---
router.get('/pings/:pingId', async (req, res) => {
  const { rows } = await db.query(
    `SELECT p.id AS ping_id, p.group_id, p.sender_id, p.recipient_id, p.sent_at,
            p.response_status, p.response_at, p.response_message,
            u.username AS from_username, g.name AS group_name
       FROM family_pings p
       JOIN users u ON u.id = p.sender_id
       JOIN family_groups g ON g.id = p.group_id
      WHERE p.id = $1 AND (p.recipient_id = $2 OR p.sender_id = $2)`,
    [req.params.pingId, req.user.id]
  );
  if (!rows[0]) return res.status(404).json({ error: 'Ping not found' });
  res.json(rows[0]);
});

// --- Odpowiedź na ping: status ok|not_ok + opcjonalna wiadomość ---
router.post('/pings/:pingId/respond', async (req, res) => {
  const { status, message } = req.body || {};
  if (status !== 'ok' && status !== 'not_ok') {
    return res.status(400).json({ error: 'status must be ok or not_ok' });
  }
  const trimmedMessage = typeof message === 'string' ? message.trim().slice(0, 300) : null;

  // Pobierz ping (musi być adresowany do mnie i jeszcze niewypełniony)
  const { rows: pings } = await db.query(
    `SELECT p.id, p.group_id, p.sender_id, p.recipient_id, p.response_status, p.sent_at,
            u.username AS recipient_username, g.name AS group_name
       FROM family_pings p
       JOIN users u ON u.id = p.recipient_id
       JOIN family_groups g ON g.id = p.group_id
      WHERE p.id = $1`,
    [req.params.pingId]
  );
  const ping = pings[0];
  if (!ping) return res.status(404).json({ error: 'Ping not found' });
  if (ping.recipient_id !== req.user.id) return res.status(403).json({ error: 'Not your ping' });
  if (ping.response_status) return res.status(409).json({ error: 'Already responded', status: ping.response_status });

  await db.query(
    `UPDATE family_pings SET response_status = $1, response_at = NOW(), response_message = $2 WHERE id = $3`,
    [status, trimmedMessage, ping.id]
  );

  // Powiadom nadawcę
  const io = req.app.get('io');
  if (io) {
    io.to(`user:${ping.sender_id}`).emit('family:ping_response', {
      ping_id: ping.id,
      from_user_id: req.user.id,
      from_username: ping.recipient_username,
      group_id: ping.group_id,
      group_name: ping.group_name,
      status,
      message: trimmedMessage,
      response_at: new Date(),
    });
  }
  const emoji = status === 'ok' ? '✅' : '⚠️';
  const title = status === 'ok'
    ? `${emoji} ${ping.recipient_username}: wszystko OK`
    : `${emoji} ${ping.recipient_username} potrzebuje pomocy`;
  const body = trimmedMessage
    ? trimmedMessage
    : (status === 'ok' ? 'Odpowiedział na Twój sygnał.' : 'Sprawdź czy nic się nie stało.');
  await notifyUser(ping.sender_id, title, body, {
    type: 'ping_response',
    ping_id: ping.id,
    status,
    from_user_id: req.user.id,
    from_username: ping.recipient_username,
    group_id: ping.group_id,
    group_name: ping.group_name,
  });

  console.log(`[ping_response] ${ping.recipient_username} → ${ping.sender_id} (${status})`);
  res.json({ ok: true, status });
});

// --- Geofences ---

router.post('/groups/:id/geofences', memberOf, parentOnly, async (req, res) => {
  const { name, lat, lng, radius_m = 200 } = req.body;
  const { rows } = await db.query(
    `INSERT INTO geofences (group_id, name, center, radius_m) VALUES ($1, $2, ST_MakePoint($4, $3)::geography, $5) RETURNING *`,
    [req.params.id, name, lat, lng, radius_m]
  );
  res.status(201).json(rows[0]);
});

router.get('/groups/:id/geofences', memberOf, async (req, res) => {
  const { rows } = await db.query(
    `SELECT id, group_id, name, ST_Y(center::geometry) AS lat, ST_X(center::geometry) AS lng, radius_m, is_active, created_at FROM geofences WHERE group_id = $1`,
    [req.params.id]
  );
  res.json({ geofences: rows });
});

router.patch('/groups/:id/geofences/:gid', memberOf, parentOnly, async (req, res) => {
  const { name, lat, lng, radius_m, is_active } = req.body;
  const updates = [], params = [req.params.gid, req.params.id];
  if (name !== undefined) { params.push(name); updates.push(`name = $${params.length}`); }
  if (radius_m !== undefined) { params.push(radius_m); updates.push(`radius_m = $${params.length}`); }
  if (is_active !== undefined) { params.push(is_active); updates.push(`is_active = $${params.length}`); }
  if (lat !== undefined && lng !== undefined) {
    params.push(lat, lng);
    updates.push(`center = ST_MakePoint($${params.length}, $${params.length - 1})::geography`);
  }
  if (!updates.length) return res.status(400).json({ error: 'Nothing to update' });
  const { rows } = await db.query(
    `UPDATE geofences SET ${updates.join(', ')} WHERE id = $1 AND group_id = $2 RETURNING *`,
    params
  );
  if (!rows[0]) return res.status(404).json({ error: 'Not found' });
  res.json(rows[0]);
});

router.delete('/groups/:id/geofences/:gid', memberOf, parentOnly, async (req, res) => {
  await db.query(`DELETE FROM geofences WHERE id = $1 AND group_id = $2`, [req.params.gid, req.params.id]);
  res.json({ ok: true });
});

// --- Location tracking ---

router.get('/groups/:id/members/:uid/location', memberOf, parentOnly, async (req, res) => {
  // F23: szanuj visibility nawet dla parent/guardian (rodzic może świadomie ukryć location dziecka przed sobą? raczej nie - ale viewer != target wciąż egzekwujemy)
  if (req.params.uid !== req.user.id) {
    const vis = await getVisibility(req.params.id, req.user.id, req.params.uid);
    if (!vis.location) return res.json({ hidden: true });
  }
  const { rows } = await db.query(
    `SELECT ST_Y(last_location::geometry) AS lat, ST_X(last_location::geometry) AS lng, last_location_at
     FROM users WHERE id = $1`,
    [req.params.uid]
  );
  res.json(rows[0] || {});
});

router.get('/groups/:id/members/:uid/location/history', memberOf, parentOnly, async (req, res) => {
  if (req.params.uid !== req.user.id) {
    const vis = await getVisibility(req.params.id, req.user.id, req.params.uid);
    if (!vis.history) return res.json({ history: [], hidden: true });
  }
  const { from, to, limit = 100 } = req.query;
  let q = `SELECT ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng, recorded_at
           FROM location_history WHERE user_id = $1`;
  const params = [req.params.uid];

  if (from) { params.push(from); q += ` AND recorded_at >= $${params.length}`; }
  if (to) { params.push(to); q += ` AND recorded_at <= $${params.length}`; }
  params.push(limit);
  q += ` ORDER BY recorded_at DESC LIMIT $${params.length}`;

  const { rows } = await db.query(q, params);
  res.json({ history: rows });
});

// ============================================
// SAFE ROUTES (bezpieczne trasy dziecka)
// ============================================

// Parent tworzy bezpieczną trasę dla dziecka
router.post('/groups/:id/members/:uid/safe-routes', memberOf, parentOnly, async (req, res) => {
  const { name, points, threshold_m } = req.body;
  if (!name || typeof name !== 'string' || name.trim().length === 0) {
    return res.status(400).json({ error: 'Name required' });
  }
  if (!Array.isArray(points) || points.length < 2) {
    return res.status(400).json({ error: 'At least 2 points required' });
  }
  const threshold = Math.max(30, Math.min(1000, parseInt(threshold_m) || 100));

  // Buduj LINESTRING z punktów [[lat, lng], ...] -> 'LINESTRING(lng lat, lng lat, ...)'
  const lineParts = [];
  for (const p of points) {
    if (!Array.isArray(p) || p.length < 2) return res.status(400).json({ error: 'Invalid point' });
    const lat = Number(p[0]);
    const lng = Number(p[1]);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) return res.status(400).json({ error: 'Invalid coords' });
    lineParts.push(`${lng} ${lat}`);
  }
  const wkt = `LINESTRING(${lineParts.join(', ')})`;

  try {
    const { rows } = await db.query(
      `INSERT INTO safe_routes (user_id, created_by, group_id, name, polyline, threshold_m)
       VALUES ($1, $2, $3, $4, ST_GeographyFromText($5), $6)
       RETURNING id, user_id, name, threshold_m, is_active, created_at`,
      [req.params.uid, req.user.id, req.params.id, name.trim().slice(0, 120), wkt, threshold]
    );
    res.status(201).json({ route: rows[0] });
  } catch (e) {
    console.error('[safe_routes] insert failed', e.message);
    res.status(500).json({ error: 'Insert failed' });
  }
});

// Lista bezpiecznych tras dziecka (parent lub dziecko widzi swoje)
router.get('/groups/:id/members/:uid/safe-routes', memberOf, async (req, res) => {
  const { rows } = await db.query(
    `SELECT id, name, threshold_m, is_active, created_at, created_by,
            ST_AsGeoJSON(polyline)::json AS polyline_geojson
     FROM safe_routes
     WHERE user_id = $1 AND group_id = $2
     ORDER BY created_at DESC`,
    [req.params.uid, req.params.id]
  );
  // Zamień GeoJSON [lng,lat] -> [[lat,lng], ...] dla wygody klienta
  const routes = rows.map((r) => {
    const coords = r.polyline_geojson?.coordinates || [];
    return {
      id: r.id,
      name: r.name,
      threshold_m: r.threshold_m,
      is_active: r.is_active,
      created_at: r.created_at,
      created_by: r.created_by,
      points: coords.map(([lng, lat]) => [lat, lng]),
    };
  });
  res.json({ routes });
});

// Edycja trasy (parent)
router.patch('/groups/:id/members/:uid/safe-routes/:rid', memberOf, parentOnly, async (req, res) => {
  const allowed = ['name', 'threshold_m', 'is_active'];
  const fields = [];
  const values = [];
  let idx = 1;
  for (const k of allowed) {
    if (k in req.body) {
      let v = req.body[k];
      if (k === 'threshold_m') v = Math.max(30, Math.min(1000, parseInt(v) || 100));
      if (k === 'name') v = String(v).trim().slice(0, 120);
      if (k === 'is_active') v = Boolean(v);
      fields.push(`${k} = $${idx++}`);
      values.push(v);
    }
  }
  if (fields.length === 0) return res.status(400).json({ error: 'Nothing to update' });
  fields.push(`updated_at = NOW()`);
  values.push(req.params.rid, req.params.uid, req.params.id);
  const { rowCount } = await db.query(
    `UPDATE safe_routes SET ${fields.join(', ')} WHERE id = $${idx++} AND user_id = $${idx++} AND group_id = $${idx}`,
    values
  );
  if (rowCount === 0) return res.status(404).json({ error: 'Not found' });
  res.json({ ok: true });
});

// Usuwanie trasy (parent)
router.delete('/groups/:id/members/:uid/safe-routes/:rid', memberOf, parentOnly, async (req, res) => {
  const { rowCount } = await db.query(
    `DELETE FROM safe_routes WHERE id = $1 AND user_id = $2 AND group_id = $3`,
    [req.params.rid, req.params.uid, req.params.id]
  );
  if (rowCount === 0) return res.status(404).json({ error: 'Not found' });
  res.json({ ok: true });
});

// F08 Smart routing: aktywne alerty blisko bezpiecznej trasy (ostrzeżenie)
// Buffer dodawany do threshold_m, żeby ostrzec wcześniej (default 200m)
router.get('/groups/:id/members/:uid/safe-routes/:rid/alerts-near', memberOf, async (req, res) => {
  try {
    const buffer = Math.max(0, Math.min(1000, parseInt(req.query.buffer_m || '200', 10)));
    const { rows: routeRows } = await db.query(
      `SELECT id, name, threshold_m FROM safe_routes
       WHERE id = $1 AND user_id = $2 AND group_id = $3 AND is_active = TRUE`,
      [req.params.rid, req.params.uid, req.params.id]
    );
    if (routeRows.length === 0) return res.status(404).json({ error: 'Route not found' });
    const route = routeRows[0];
    const radius = (route.threshold_m || 100) + buffer;

    const { rows: alertsRows } = await db.query(
      `SELECT a.id, a.category, a.title, a.description, a.radius_m,
              ST_Y(a.location::geometry) AS lat, ST_X(a.location::geometry) AS lng,
              a.confirms, a.denies, a.expires_at,
              ST_Distance((SELECT polyline FROM safe_routes WHERE id=$1), a.location) AS distance_to_route_m
       FROM alerts a
       WHERE a.status = 'active' AND a.expires_at > NOW()
         AND ST_DWithin((SELECT polyline FROM safe_routes WHERE id=$1), a.location, $2)
       ORDER BY distance_to_route_m ASC
       LIMIT 30`,
      [route.id, radius]
    );

    res.json({
      route: { id: route.id, name: route.name, threshold_m: route.threshold_m, buffer_m: buffer },
      alerts: alertsRows,
    });
  } catch (e) {
    console.error('[alerts-near]', e.message);
    res.status(500).json({ error: 'Server error' });
  }
});

// F19 Family planner: lista wydarzeń grupy
router.get('/groups/:id/events', memberOf, async (req, res) => {
  const upcoming = req.query.upcoming === '1' || req.query.upcoming === 'true';
  const { rows } = await db.query(
    `SELECT e.id, e.group_id, e.author_id, e.title, e.description, e.starts_at, e.ends_at,
            e.location, e.reminder_minutes_before, e.created_at,
            u.username AS author_username, u.avatar_url AS author_avatar
     FROM family_events e
     JOIN users u ON u.id = e.author_id
     WHERE e.group_id = $1
       ${upcoming ? "AND e.starts_at >= NOW() - INTERVAL '6 hours'" : ''}
     ORDER BY e.starts_at ASC
     LIMIT 200`,
    [req.params.id]
  );
  res.json({ events: rows });
});

router.post('/groups/:id/events', memberOf, async (req, res) => {
  const { title, description, starts_at, ends_at, location, reminder_minutes_before } = req.body || {};
  if (!title || typeof title !== 'string' || title.length > 200) {
    return res.status(400).json({ error: 'title required (1-200 chars)' });
  }
  if (!starts_at) return res.status(400).json({ error: 'starts_at required (ISO timestamp)' });
  const reminder = Math.max(0, Math.min(10080, parseInt(reminder_minutes_before ?? 30, 10) || 0));
  try {
    const { rows } = await db.query(
      `INSERT INTO family_events (group_id, author_id, title, description, starts_at, ends_at, location, reminder_minutes_before)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, group_id, author_id, title, description, starts_at, ends_at, location, reminder_minutes_before, created_at`,
      [req.params.id, req.user.id, title.trim(), description ?? null, starts_at, ends_at ?? null, location ?? null, reminder]
    );
    res.status(201).json(rows[0]);
  } catch (e) {
    console.error('[event-create]', e.message);
    res.status(500).json({ error: 'Server error' });
  }
});

router.patch('/groups/:id/events/:eid', memberOf, async (req, res) => {
  const allowed = ['title', 'description', 'starts_at', 'ends_at', 'location', 'reminder_minutes_before'];
  const sets = [];
  const params = [req.params.eid, req.params.id, req.user.id];
  for (const k of allowed) {
    if (k in (req.body || {})) {
      params.push(req.body[k]);
      sets.push(`${k} = $${params.length}`);
    }
  }
  if (sets.length === 0) return res.json({ ok: true });
  sets.push(`updated_at = NOW()`);
  sets.push(`reminder_sent = FALSE`);
  const { rowCount } = await db.query(
    `UPDATE family_events SET ${sets.join(', ')}
     WHERE id = $1 AND group_id = $2 AND author_id = $3`,
    params
  );
  if (rowCount === 0) return res.status(404).json({ error: 'Not found or not owner' });
  res.json({ ok: true });
});

router.delete('/groups/:id/events/:eid', memberOf, async (req, res) => {
  const { rowCount } = await db.query(
    `DELETE FROM family_events WHERE id = $1 AND group_id = $2 AND author_id = $3`,
    [req.params.eid, req.params.id, req.user.id]
  );
  if (rowCount === 0) return res.status(404).json({ error: 'Not found or not owner' });
  res.json({ ok: true });
});

// F21: Status meldunków wszystkich członków grupy (dla rodziny — kto się zameldował dzisiaj)
router.get('/groups/:id/checkins/today', memberOf, async (req, res) => {
  try {
    const { rows } = await db.query(
      `SELECT u.id AS user_id, u.username, u.avatar_url, u.app_mode, fm.role,
              MAX(c.created_at) AS last_checkin_at,
              BOOL_OR(
                c.status = 'safe'
                AND (c.created_at AT TIME ZONE 'Europe/Warsaw')::date = (NOW() AT TIME ZONE 'Europe/Warsaw')::date
              ) AS checked_in_today
       FROM family_members fm
       JOIN users u ON u.id = fm.user_id
       LEFT JOIN user_checkins c ON c.user_id = u.id
         AND c.created_at > NOW() - INTERVAL '7 days'
       WHERE fm.group_id = $1
       GROUP BY u.id, u.username, u.avatar_url, u.app_mode, fm.role
       ORDER BY fm.role DESC, u.username ASC`,
      [req.params.id]
    );
    res.json({ members: rows });
  } catch (e) {
    console.error('[checkins/today]', e.message);
    res.status(500).json({ error: 'Server error' });
  }
});

// F14: Family chat — proste wiadomości w grupie rodzinnej
router.get('/groups/:id/messages', memberOf, async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit, 10) || 50, 200);
  const before = req.query.before; // ISO timestamp, opcjonalnie
  const params = [req.params.id];
  let whereExtra = '';
  if (before) {
    params.push(before);
    whereExtra = `AND m.created_at < $2`;
  }
  const { rows } = await db.query(
    `SELECT m.id, m.body, m.created_at, m.author_id,
            u.username AS author_username, u.avatar_url AS author_avatar
     FROM family_messages m JOIN users u ON u.id = m.author_id
     WHERE m.group_id = $1 ${whereExtra}
     ORDER BY m.created_at DESC LIMIT ${limit}`,
    params
  );
  res.json({ messages: rows.reverse() });
});

router.post('/groups/:id/messages', memberOf, async (req, res) => {
  const body = (req.body?.body || '').trim();
  if (body.length === 0 || body.length > 2000) {
    return res.status(400).json({ error: 'Wiadomość musi mieć 1-2000 znaków' });
  }
  const { rows } = await db.query(
    `INSERT INTO family_messages (group_id, author_id, body)
     VALUES ($1, $2, $3)
     RETURNING id, body, created_at, author_id`,
    [req.params.id, req.user.id, body]
  );
  const msg = rows[0];

  // Author info dla broadcastu
  const { rows: [author] } = await db.query(
    `SELECT username, avatar_url FROM users WHERE id = $1`, [req.user.id]
  );
  const payload = { ...msg, author_username: author.username, author_avatar: author.avatar_url, group_id: req.params.id };

  // Socket emit + FCM dla pozostałych członków
  const io = req.app.get('io');
  const { rows: members } = await db.query(
    `SELECT user_id FROM family_members WHERE group_id = $1 AND user_id != $2`,
    [req.params.id, req.user.id]
  );
  for (const m of members) {
    if (io) io.to(`user:${m.user_id}`).emit('family:message', payload);
    notifyUser(m.user_id, `💬 ${author.username}`, body.length > 100 ? body.slice(0, 97) + '…' : body, {
      type: 'family_message', group_id: req.params.id, message_id: msg.id,
    }).catch(() => {});
  }
  res.status(201).json(payload);
});

module.exports = router;
