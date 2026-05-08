require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const db = require('./config/db');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.set('io', io);
app.use(cors());
app.use(helmet());
app.use(express.json());
app.use('/uploads', express.static(require('path').join(__dirname, '..', 'uploads')));
app.set('trust proxy', 1);

// Rate limiting per spec
const rlOpts = { validate: { xForwardedForHeader: false } };
app.use('/api/v1/auth', rateLimit({ windowMs: 60000, max: 5, ...rlOpts }));
app.use('/api/v1/users/me/location', rateLimit({ windowMs: 60000, max: 60, ...rlOpts }));
app.use(rateLimit({ windowMs: 60000, max: 100, ...rlOpts }));

// Routes
app.use('/api/v1/auth', require('./routes/auth'));
app.use('/api/v1/users', require('./routes/users'));
app.use('/api/v1/alerts', require('./routes/alerts'));
app.use('/api/v1/events', require('./routes/events'));
app.use('/api/v1/family', require('./routes/family'));

app.get('/health', (_, res) => res.json({ status: 'ok', time: new Date().toISOString() }));

// Public location tracking via shared link
app.get('/api/v1/track/:token', async (req, res) => {
  const { rows } = await db.query(
    `SELECT u.username, ST_Y(u.last_location::geometry) AS lat, ST_X(u.last_location::geometry) AS lng, u.last_location_at
     FROM share_links s JOIN users u ON s.user_id = u.id
     WHERE s.token = $1 AND s.expires_at > NOW()`,
    [req.params.token]
  );
  if (!rows[0]) return res.status(404).json({ error: 'Link expired or invalid' });
  res.json(rows[0]);
});

app.get('/track/:token', (req, res) => {
  res.send(`<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>AlertMap — Śledzenie</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9/dist/leaflet.css"/>
<script src="https://unpkg.com/leaflet@1.9/dist/leaflet.js"></script>
<style>body{margin:0}#map{height:100vh}#info{position:absolute;top:10px;left:50%;transform:translateX(-50%);z-index:999;background:#fff;padding:8px 16px;border-radius:20px;box-shadow:0 2px 8px rgba(0,0,0,.2);font-family:sans-serif;font-size:14px}</style>
</head><body><div id="info">Ładowanie...</div><div id="map"></div>
<script>
const map=L.map('map').setView([52.23,21.01],15);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{attribution:'OSM'}).addTo(map);
let marker;
async function update(){
  const r=await fetch('/api/v1/track/${req.params.token}');
  if(!r.ok){document.getElementById('info').textContent='Link wygasł';return}
  const d=await r.json();
  const ll=[d.lat,d.lng];
  if(!marker){marker=L.marker(ll).addTo(map);map.setView(ll,16)}
  else marker.setLatLng(ll);
  document.getElementById('info').textContent=d.username+' — '+new Date(d.last_location_at).toLocaleTimeString();
}
update();setInterval(update,10000);
</script></body></html>`);
});

app.get('/version', (_, res) => res.json({ version: 12, url: 'https://alert.u235.pl/download' }));

app.get('/download', (_, res) => {
  const path = require('path');
  res.download(path.join(__dirname, '..', 'AlertMap.apk'), 'AlertMap.apk');
});

// WebSocket auth + location tracking
io.use((socket, next) => {
  try {
    const token = socket.handshake.query.token;
    socket.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    next(new Error('Unauthorized'));
  }
});

io.on('connection', (socket) => {
  socket.join(`user:${socket.user.id}`);

  socket.on('location:update', async ({ lat, lng }) => {
    await db.query(
      `UPDATE users SET last_location = ST_MakePoint($2, $1)::geography, last_location_at = NOW() WHERE id = $3`,
      [lat, lng, socket.user.id]
    );
    await db.query(
      `INSERT INTO location_history (user_id, location) VALUES ($1, ST_MakePoint($3, $2)::geography)`,
      [socket.user.id, lat, lng]
    );

    // Notify parents in family groups
    const { rows: groups } = await db.query(
      `SELECT m2.user_id AS parent_id, g.id AS group_id
       FROM family_members m1
       JOIN family_members m2 ON m1.group_id = m2.group_id
       JOIN family_groups g ON g.id = m1.group_id
       WHERE m1.user_id = $1 AND m1.role = 'child' AND m2.role = 'parent' AND m1.tracking_enabled = TRUE`,
      [socket.user.id]
    );
    for (const g of groups) {
      io.to(`user:${g.parent_id}`).emit('family:location', {
        user_id: socket.user.id, lat, lng, recorded_at: new Date(),
      });
    }

    // Check geofences
    const { rows: violations } = await db.query(
      `SELECT gf.name AS geofence_name, gf.group_id FROM geofences gf
       JOIN family_members m ON gf.group_id = m.group_id
       WHERE m.user_id = $1 AND m.role = 'child' AND gf.is_active = TRUE
       AND NOT ST_DWithin(gf.center, ST_MakePoint($3, $2)::geography, gf.radius_m)`,
      [socket.user.id, lat, lng]
    );
    if (violations.length) {
      const { rows: [me] } = await db.query(`SELECT username FROM users WHERE id = $1`, [socket.user.id]);
      for (const v of violations) {
        const { rows: parents } = await db.query(
          `SELECT user_id FROM family_members WHERE group_id = $1 AND role = 'parent'`,
          [v.group_id]
        );
        for (const p of parents) {
          io.to(`user:${p.user_id}`).emit('family:geofence_exit', {
            user_id: socket.user.id, username: me?.username, geofence_name: v.geofence_name,
          });
        }
      }
    }
  });
});

// Expire old alerts every minute + emit WS events
setInterval(async () => {
  const { rows } = await db.query(
    `UPDATE alerts SET status = 'expired' WHERE status = 'active' AND expires_at < NOW() RETURNING id`
  );
  for (const r of rows) io.emit('alert:expired', { alert_id: r.id });
}, 60000);

// IMGW weather warnings sync every 15 min
const { syncWarnings } = require('./services/imgw');
syncWarnings(io); // Initial sync on startup
setInterval(() => syncWarnings(io), 15 * 60 * 1000);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`AlertMap API running on :${PORT}`));
