const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');
const { notifyUser, notifyNearbyUsers } = require('../services/fcm');

router.use(auth);

// Sprawdza czy user jest członkiem grupy do której należy pet
async function petAccessible(req, res, next) {
  const { rows } = await db.query(
    `SELECT p.*, fm.role AS your_role
     FROM pets p
     JOIN family_members fm ON fm.group_id = p.group_id AND fm.user_id = $1
     WHERE p.id = $2`,
    [req.user.id, req.params.id]
  );
  if (!rows[0]) return res.status(404).json({ error: 'Pet not found or not accessible' });
  req.pet = rows[0];
  next();
}

const PET_SELECT = `
  p.id, p.group_id, p.owner_id, p.name, p.species, p.breed, p.color,
  p.age_years, p.microchip, p.photo_url, p.notes,
  ST_Y(p.home_location::geometry) AS home_lat,
  ST_X(p.home_location::geometry) AS home_lng,
  ST_Y(p.last_seen_location::geometry) AS last_seen_lat,
  ST_X(p.last_seen_location::geometry) AS last_seen_lng,
  p.last_seen_at, p.status, p.lost_at, p.lost_description,
  p.created_at, p.updated_at,
  u.username AS owner_username, u.avatar_url AS owner_avatar
`;

// GET /pets/mine — wszystkie pety we wszystkich moich grupach
router.get('/mine', async (req, res) => {
  const { rows } = await db.query(
    `SELECT ${PET_SELECT}, g.name AS group_name
     FROM pets p
     JOIN family_groups g ON g.id = p.group_id
     JOIN family_members fm ON fm.group_id = p.group_id AND fm.user_id = $1
     JOIN users u ON u.id = p.owner_id
     ORDER BY p.created_at DESC`,
    [req.user.id]
  );
  res.json({ pets: rows });
});

// GET /pets/lost/nearby?lat=&lng=&radius_m=5000 — publiczna mapa zaginionych w okolicy
router.get('/lost/nearby', async (req, res) => {
  const lat = parseFloat(req.query.lat);
  const lng = parseFloat(req.query.lng);
  const radius = Math.min(parseInt(req.query.radius_m || '5000', 10), 50000);
  if (!isFinite(lat) || !isFinite(lng)) return res.status(400).json({ error: 'lat/lng required' });

  const { rows } = await db.query(
    `SELECT ${PET_SELECT},
            ST_Distance(p.last_seen_location, ST_MakePoint($2,$1)::geography) AS distance_m
     FROM pets p
     JOIN users u ON u.id = p.owner_id
     WHERE p.status = 'lost'
       AND p.last_seen_location IS NOT NULL
       AND ST_DWithin(p.last_seen_location, ST_MakePoint($2,$1)::geography, $3)
     ORDER BY distance_m ASC
     LIMIT 50`,
    [lat, lng, radius]
  );
  res.json({ pets: rows });
});

// POST /pets — utwórz peta w grupie
router.post('/', async (req, res) => {
  const {
    group_id, name, species = 'dog', breed, color, age_years,
    microchip, photo_url, notes, home_lat, home_lng,
  } = req.body || {};
  if (!group_id || !name || name.length < 1 || name.length > 80) {
    return res.status(400).json({ error: 'group_id and name (1-80) required' });
  }
  // membership check
  const { rows: m } = await db.query(
    `SELECT 1 FROM family_members WHERE group_id = $1 AND user_id = $2`,
    [group_id, req.user.id]
  );
  if (!m[0]) return res.status(403).json({ error: 'Not a member of this group' });
  if (!['dog', 'cat', 'bird', 'rabbit', 'other'].includes(species)) {
    return res.status(400).json({ error: 'Invalid species' });
  }

  let homeClause = 'NULL';
  const params = [group_id, req.user.id, name, species, breed || null, color || null,
                  age_years || null, microchip || null, photo_url || null, notes || null];
  if (typeof home_lat === 'number' && typeof home_lng === 'number') {
    homeClause = `ST_MakePoint($${params.length + 1}, $${params.length + 2})::geography`;
    params.push(home_lng, home_lat);
  }
  const { rows } = await db.query(
    `INSERT INTO pets (group_id, owner_id, name, species, breed, color, age_years, microchip, photo_url, notes, home_location)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, ${homeClause})
     RETURNING id`,
    params
  );
  const { rows: full } = await db.query(
    `SELECT ${PET_SELECT} FROM pets p JOIN users u ON u.id = p.owner_id WHERE p.id = $1`,
    [rows[0].id]
  );
  res.status(201).json(full[0]);
});

// PATCH /pets/:id — aktualizuj
router.patch('/:id', petAccessible, async (req, res) => {
  const allowed = ['name', 'species', 'breed', 'color', 'age_years', 'microchip', 'photo_url', 'notes', 'lost_description'];
  const sets = [];
  const params = [];
  let i = 1;
  for (const k of allowed) {
    if (k in req.body) {
      sets.push(`${k} = $${i++}`);
      params.push(req.body[k]);
    }
  }
  // home_location
  if (typeof req.body.home_lat === 'number' && typeof req.body.home_lng === 'number') {
    sets.push(`home_location = ST_MakePoint($${i++}, $${i++})::geography`);
    params.push(req.body.home_lng, req.body.home_lat);
  }
  if (!sets.length) return res.status(400).json({ error: 'No fields' });
  sets.push(`updated_at = NOW()`);
  params.push(req.params.id);
  await db.query(`UPDATE pets SET ${sets.join(', ')} WHERE id = $${i}`, params);

  const { rows } = await db.query(
    `SELECT ${PET_SELECT} FROM pets p JOIN users u ON u.id = p.owner_id WHERE p.id = $1`,
    [req.params.id]
  );
  res.json(rows[0]);
});

// DELETE /pets/:id — tylko owner peta
router.delete('/:id', petAccessible, async (req, res) => {
  if (req.pet.owner_id !== req.user.id) {
    return res.status(403).json({ error: 'Only owner can delete' });
  }
  await db.query(`DELETE FROM pets WHERE id = $1`, [req.params.id]);
  res.json({ ok: true });
});

// POST /pets/:id/lost — zgłoś zaginięcie + broadcast
router.post('/:id/lost', petAccessible, async (req, res) => {
  const { lat, lng, description } = req.body || {};
  if (typeof lat !== 'number' || typeof lng !== 'number') {
    return res.status(400).json({ error: 'lat/lng required' });
  }
  await db.query(
    `UPDATE pets SET status = 'lost', lost_at = NOW(),
                     last_seen_location = ST_MakePoint($1, $2)::geography,
                     last_seen_at = NOW(),
                     lost_description = $3,
                     updated_at = NOW()
     WHERE id = $4`,
    [lng, lat, description || null, req.params.id]
  );

  // Powiadom wszystkich członków grupy
  const { rows: members } = await db.query(
    `SELECT user_id FROM family_members WHERE group_id = $1 AND user_id != $2`,
    [req.pet.group_id, req.user.id]
  );
  const petName = req.pet.name;
  for (const m of members) {
    await notifyUser(
      m.user_id,
      `🐾 ${petName} zaginął!`,
      description || 'Zwierzak został zgłoszony jako zaginiony',
      { type: 'pet_lost', pet_id: req.params.id, group_id: req.pet.group_id, lat: String(lat), lng: String(lng) }
    ).catch(() => {});
  }

  // Powiadom użytkowników w okolicy (3km) — fake alert, ale przez notifyNearbyUsers helper
  try {
    const { rows: nearby } = await db.query(
      `SELECT id, fcm_token FROM users
       WHERE fcm_token IS NOT NULL
         AND last_location IS NOT NULL
         AND id != $1
         AND ST_DWithin(last_location, ST_MakePoint($2, $3)::geography, 3000)
       LIMIT 200`,
      [req.user.id, lng, lat]
    );
    for (const u of nearby) {
      await notifyUser(
        u.id,
        `🐾 Zaginął ${petName} w pobliżu`,
        description || 'Pomóż odnaleźć — sprawdź zakładkę Zaginione',
        { type: 'pet_lost_nearby', pet_id: req.params.id, lat: String(lat), lng: String(lng) }
      ).catch(() => {});
    }
    console.log(`[pet_lost] ${petName} → ${members.length} members + ${nearby.length} nearby`);
  } catch (e) {
    console.error('[pet_lost] nearby push error:', e.message);
  }

  const { rows } = await db.query(
    `SELECT ${PET_SELECT} FROM pets p JOIN users u ON u.id = p.owner_id WHERE p.id = $1`,
    [req.params.id]
  );
  res.json(rows[0]);
});

// POST /pets/:id/found — odwołaj alarm
router.post('/:id/found', petAccessible, async (req, res) => {
  await db.query(
    `UPDATE pets SET status = 'home', lost_at = NULL, lost_description = NULL, updated_at = NOW()
     WHERE id = $1`,
    [req.params.id]
  );
  // Powiadom członków grupy
  const { rows: members } = await db.query(
    `SELECT user_id FROM family_members WHERE group_id = $1 AND user_id != $2`,
    [req.pet.group_id, req.user.id]
  );
  for (const m of members) {
    await notifyUser(
      m.user_id,
      `✅ ${req.pet.name} się odnalazł!`,
      'Zwierzak jest bezpieczny',
      { type: 'pet_found', pet_id: req.params.id, group_id: req.pet.group_id }
    ).catch(() => {});
  }
  const { rows } = await db.query(
    `SELECT ${PET_SELECT} FROM pets p JOIN users u ON u.id = p.owner_id WHERE p.id = $1`,
    [req.params.id]
  );
  res.json(rows[0]);
});

// POST /pets/:id/sighting — zgłoś że widziano (przez innego użytkownika)
router.post('/:id/sighting', async (req, res) => {
  const { lat, lng, note } = req.body || {};
  if (typeof lat !== 'number' || typeof lng !== 'number') {
    return res.status(400).json({ error: 'lat/lng required' });
  }
  const { rows: pet } = await db.query(
    `SELECT id, owner_id, group_id, name, status FROM pets WHERE id = $1`,
    [req.params.id]
  );
  if (!pet[0]) return res.status(404).json({ error: 'Pet not found' });
  if (pet[0].status !== 'lost') return res.status(400).json({ error: 'Pet is not lost' });

  await db.query(
    `UPDATE pets SET last_seen_location = ST_MakePoint($1, $2)::geography,
                     last_seen_at = NOW(), updated_at = NOW()
     WHERE id = $3`,
    [lng, lat, req.params.id]
  );

  // Powiadom właściciela
  const { rows: reporter } = await db.query(`SELECT username FROM users WHERE id = $1`, [req.user.id]);
  await notifyUser(
    pet[0].owner_id,
    `🐾 Ktoś widział ${pet[0].name}!`,
    `${reporter[0]?.username || 'Anonim'}: ${note || 'sprawdź mapę zaginionych'}`,
    { type: 'pet_sighting', pet_id: req.params.id, lat: String(lat), lng: String(lng) }
  ).catch(() => {});

  res.json({ ok: true });
});

module.exports = router;
