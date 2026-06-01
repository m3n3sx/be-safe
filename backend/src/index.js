require('dotenv').config();

// Sentry init MUSI być przed pozostałymi requires dla auto-instrumentacji express/http/pg.
const Sentry = require('@sentry/node');
if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.NODE_ENV || 'production',
    tracesSampleRate: 0.1,
    integrations: [
      Sentry.httpIntegration(),
      Sentry.expressIntegration(),
      Sentry.postgresIntegration(),
    ],
  });
}

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const db = require('./config/db');
const { notifyUser } = require('./services/fcm');
const auth = require('./middleware/auth');
const requireAdmin = require('./middleware/requireAdmin');

// In-memory geofence state per (childId:geofenceId) → 'inside' | 'outside'
// Resetuje się przy restart serwera (akceptowalne — pierwszy update będzie pominięty bo brak prevState).
const geofenceState = new Map();

// In-memory safe-route state per (childId:routeId) → 'on' | 'off'
const routeState = new Map();

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
app.use('/api/v1/test', require('./routes/test'));
app.use('/api/v1/users', require('./routes/users'));
app.use('/api/v1/alerts', require('./routes/alerts'));
app.use('/api/v1/events', require('./routes/events'));
app.use('/api/v1/family', require('./routes/family'));
app.use('/api/v1/aeds', require('./routes/aeds'));
app.use('/api/v1/aqi', require('./routes/aqi'));
app.use('/api/v1/escort', require('./routes/escort'));
app.use('/api/v1/pets', require('./routes/pets'));
app.use('/api/v1/admin', auth, requireAdmin, require('./routes/admin'));
app.use('/api/v1/permissions', require('./routes/permissions'));
app.use('/api/v1', require('./routes/community'));

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

app.get('/version', (_, res) => res.json({ version: 101, url: 'https://besafe.org.pl/download' }));

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
  // Heartbeat: mark user online on connect
  db.query(`UPDATE users SET last_seen_at = NOW() WHERE id = $1`, [socket.user.id]).catch(() => {});
  socket.on('disconnect', () => {
    // Heartbeat: mark on disconnect (server still knows when client last touched it)
    db.query(`UPDATE users SET last_seen_at = NOW() WHERE id = $1`, [socket.user.id]).catch(() => {});
  });

  // Join/leave a specific alert's comments room for live chat.
  socket.on('alert:join', (alertId) => {
    if (typeof alertId === 'string' && alertId.length < 64) {
      socket.join(`alert:${alertId}`);
    }
  });
  socket.on('alert:leave', (alertId) => {
    if (typeof alertId === 'string') socket.leave(`alert:${alertId}`);
  });

  // Realtime typing indicator (optional — emits to all other listeners in the alert room).
  socket.on('alert:typing', ({ alert_id, is_typing }) => {
    if (typeof alert_id !== 'string') return;
    socket.to(`alert:${alert_id}`).emit('alert:typing', {
      alert_id,
      user_id: socket.user.id,
      is_typing: !!is_typing,
    });
  });

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

    // Check geofences — wykrywamy transitions outside↔inside per (child, geofence)
    // Stan trzymamy w pamięci procesu: geofenceState['<childId>:<geofenceId>'] = 'inside' | 'outside'
    const { rows: gfStates } = await db.query(
      `SELECT gf.id AS geofence_id, gf.name AS geofence_name, gf.group_id,
              ST_DWithin(gf.center, ST_MakePoint($3, $2)::geography, gf.radius_m) AS inside
       FROM geofences gf
       JOIN family_members m ON gf.group_id = m.group_id
       WHERE m.user_id = $1 AND m.role = 'child' AND gf.is_active = TRUE`,
      [socket.user.id, lat, lng]
    );
    if (gfStates.length) {
      const { rows: [me] } = await db.query(`SELECT username FROM users WHERE id = $1`, [socket.user.id]);
      for (const v of gfStates) {
        const key = `${socket.user.id}:${v.geofence_id}`;
        const newState = v.inside ? 'inside' : 'outside';
        const prevState = geofenceState.get(key);
        geofenceState.set(key, newState);
        if (!prevState || prevState === newState) continue;
        // transition!
        const transition = newState === 'inside' ? 'enter' : 'exit';
        const { rows: parents } = await db.query(
          `SELECT user_id FROM family_members WHERE group_id = $1 AND role = 'parent'`,
          [v.group_id]
        );
        const titlePrefix = transition === 'enter' ? '✅' : '⚠️';
        const titleVerb = transition === 'enter' ? 'wróciło do strefy' : 'opuściło strefę';
        const bodyVerb = transition === 'enter' ? 'Weszło do strefy' : 'Wyszło ze strefy';
        for (const p of parents) {
          io.to(`user:${p.user_id}`).emit(
            transition === 'enter' ? 'family:geofence_enter' : 'family:geofence_exit',
            {
              user_id: socket.user.id, username: me?.username,
              geofence_id: v.geofence_id, geofence_name: v.geofence_name,
              transition,
            }
          );
          notifyUser(
            p.user_id,
            `${titlePrefix} ${me?.username || 'Dziecko'} ${titleVerb}`,
            `${bodyVerb} "${v.geofence_name}"`,
            {
              type: `geofence_${transition}`,
              user_id: socket.user.id,
              child_username: me?.username || '',
              geofence_id: v.geofence_id,
              geofence_name: v.geofence_name,
              group_id: v.group_id,
            }
          ).catch((err) => console.error('[geofence] FCM error:', err.message));
        }
        console.log(`[geofence] ${me?.username} ${transition === 'enter' ? 'WSZEDŁ DO' : 'WYSZEDŁ Z'} "${v.geofence_name}"`);
      }
    }

    // Check safe routes — wykrywamy transitions on↔off per (child, route)
    try {
      const { rows: routes } = await db.query(
        `SELECT sr.id AS route_id, sr.name AS route_name, sr.group_id, sr.threshold_m,
                ST_Distance(sr.polyline, ST_MakePoint($2, $1)::geography) <= sr.threshold_m AS on_route
         FROM safe_routes sr
         WHERE sr.user_id = $3 AND sr.is_active = TRUE`,
        [lat, lng, socket.user.id]
      );
      if (routes.length) {
        const { rows: [meRow] } = await db.query(`SELECT username FROM users WHERE id = $1`, [socket.user.id]);
        for (const r of routes) {
          const key = `${socket.user.id}:${r.route_id}`;
          const newState = r.on_route ? 'on' : 'off';
          const prevState = routeState.get(key);
          routeState.set(key, newState);
          if (!prevState || prevState === newState) continue;
          const transition = newState === 'off' ? 'exit' : 'return';

          const { rows: parents } = await db.query(
            `SELECT user_id FROM family_members WHERE group_id = $1 AND role = 'parent' AND user_id != $2`,
            [r.group_id, socket.user.id]
          );
          for (const p of parents) {
            io.to(`user:${p.user_id}`).emit(
              transition === 'exit' ? 'family:route_exit' : 'family:route_return',
              {
                user_id: socket.user.id,
                child_username: meRow?.username || '',
                route_id: r.route_id,
                route_name: r.route_name,
                lat, lng,
                at: new Date().toISOString(),
              }
            );
            if (transition === 'exit') {
              notifyUser(
                p.user_id,
                `🚸 ${meRow?.username || 'Dziecko'} zboczyło z trasy`,
                `Opuściło bezpieczną trasę "${r.route_name}".`,
                {
                  type: 'route_exit',
                  route_id: r.route_id,
                  route_name: r.route_name,
                  user_id: socket.user.id,
                  child_username: meRow?.username || '',
                  group_id: r.group_id,
                  lat: String(lat),
                  lng: String(lng),
                }
              ).catch((err) => console.error('[route] FCM error:', err.message));
            }
          }
          console.log(`[route] ${meRow?.username} ${transition === 'exit' ? 'ZBOCZYŁ Z' : 'WRÓCIŁ NA'} "${r.route_name}"`);
        }
      }
    } catch (e) {
      console.error('[route]', e.message);
    }

    // I.2A — dziecko jest w obszarze aktywnego alertu? Push do parentów (z dedupem per alert_notifications).
    try {
      // tylko jeśli ten user jest dzieckiem w jakiejś grupie i ma trackingEnabled
      const { rows: parentLinks } = await db.query(
        `SELECT DISTINCT p.user_id AS parent_id, fm.group_id
         FROM family_members fm
         JOIN family_members p ON p.group_id = fm.group_id AND p.role = 'parent'
         WHERE fm.user_id = $1 AND fm.role = 'child' AND fm.tracking_enabled = TRUE`,
        [socket.user.id]
      );
      if (parentLinks.length) {
        const { rows: alertsNear } = await db.query(
          `SELECT id, title, category, ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng
           FROM alerts
           WHERE status = 'active' AND expires_at > NOW()
             AND ST_DWithin(location, ST_MakePoint($2, $1)::geography, radius_m)
           LIMIT 5`,
          [lat, lng]
        );
        if (alertsNear.length) {
          const { rows: [me] } = await db.query(`SELECT username FROM users WHERE id = $1`, [socket.user.id]);
          for (const a of alertsNear) {
            for (const link of parentLinks) {
              // Dedup: tylko jeden push per (alert, parent, child) — używamy alert_notifications z user_id=parent_id
              // Wstrzykujemy "syntetyczny" wpis: parent jako recipient, alert jako source.
              const { rowCount } = await db.query(
                `INSERT INTO alert_notifications (alert_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
                [a.id, link.parent_id]
              );
              if (!rowCount) continue; // już wysłany
              notifyUser(
                link.parent_id,
                `⚠️ ${me?.username || 'Dziecko'} w obszarze zagrożenia`,
                `${a.title || 'Aktywny alert'} obok lokalizacji dziecka.`,
                {
                  type: 'child_in_alert_area',
                  alert_id: a.id,
                  child_id: socket.user.id,
                  child_username: me?.username || '',
                  group_id: link.group_id,
                  lat: String(a.lat),
                  lng: String(a.lng),
                }
              ).catch(() => {});
            }
          }
        }
      }
    } catch (e) {
      console.error('[child_in_alert_area]', e.message);
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

// Expire stale family_pings (no response after 30 min) - notify sender
setInterval(async () => {
  try {
    const { rows } = await db.query(
      `UPDATE family_pings p SET response_status = 'expired', response_at = NOW()
        WHERE p.response_status IS NULL AND p.sent_at < NOW() - INTERVAL '30 minutes'
        RETURNING p.id, p.sender_id, p.recipient_id, p.group_id`
    );
    if (!rows.length) return;
    const ids = rows.map(r => r.recipient_id);
    const { rows: users } = await db.query(`SELECT id, username FROM users WHERE id = ANY($1)`, [ids]);
    const nameById = new Map(users.map(u => [u.id, u.username]));
    for (const r of rows) {
      const username = nameById.get(r.recipient_id) || 'odbiorca';
      io.to(`user:${r.sender_id}`).emit('family:ping_response', {
        ping_id: r.id,
        from_user_id: r.recipient_id,
        from_username: username,
        group_id: r.group_id,
        status: 'expired',
        response_at: new Date(),
      });
      try {
        await notifyUser(r.sender_id, `⏱ ${username} nie odpowiedział`,
          'Sygnał wygasł po 30 minutach bez odpowiedzi.',
          { type: 'ping_response', ping_id: r.id, status: 'expired',
            from_user_id: r.recipient_id, from_username: username, group_id: r.group_id });
      } catch {}
    }
    console.log(`[ping_expired] ${rows.length} pings expired`);
  } catch (e) { console.error('[ping_expired]', e.message); }
}, 60 * 1000);

// F03: Eskorta panic — gdy active session przekroczy ETA + 5min bez complete → status=panic + alarm watcher
const { notifyUser: notifyUserEscort } = require('./services/fcm');
setInterval(async () => {
  try {
    const { rows } = await db.query(
      `UPDATE escort_sessions e
         SET status = 'panic', completed_at = NOW()
       WHERE e.status = 'active'
         AND e.started_at + (e.eta_seconds + 300) * INTERVAL '1 second' < NOW()
       RETURNING e.id, e.requester_id, e.watcher_id, e.last_location_lat, e.last_location_lng,
                 e.destination_name`
    );
    if (rows.length === 0) return;
    for (const r of rows) {
      const { rows: meRows } = await db.query(`SELECT username, phone FROM users WHERE id=$1`, [r.requester_id]);
      const reqName = meRows[0]?.username || 'Osoba';
      try {
        await notifyUserEscort(
          r.watcher_id,
          `🚨 ALARM: ${reqName} nie dotarł(a)`,
          `Eskorta przekroczyła czas. Skontaktuj się!`,
          { type: 'escort_panic', escort_id: r.id, requester_id: r.requester_id,
            requester_username: reqName,
            last_lat: r.last_location_lat, last_lng: r.last_location_lng,
            destination_name: r.destination_name || '' }
        );
      } catch {}
      io.to(`user:${r.watcher_id}`).emit('escort:panic', {
        escort_id: r.id, requester_id: r.requester_id,
        last_lat: r.last_location_lat, last_lng: r.last_location_lng,
      });
    }
    console.log(`[escort_panic] ${rows.length} escorts entered panic`);
  } catch (e) { console.error('[escort_panic]', e.message); }
}, 30 * 1000);

// F19 Family planner reminders — fire FCM N minutes before starts_at
setInterval(async () => {
  try {
    const { rows: events } = await db.query(
      `SELECT e.id, e.group_id, e.author_id, e.title, e.starts_at, e.reminder_minutes_before,
              u.username AS author_username
       FROM family_events e
       JOIN users u ON u.id = e.author_id
       WHERE e.reminder_sent = FALSE
         AND e.starts_at > NOW() - INTERVAL '15 minutes'
         AND e.starts_at <= NOW() + (e.reminder_minutes_before * INTERVAL '1 minute')
       LIMIT 50`
    );
    for (const e of events) {
      const { rows: members } = await db.query(
        `SELECT user_id FROM family_members WHERE group_id = $1`,
        [e.group_id]
      );
      const fmt = new Intl.DateTimeFormat('pl-PL', {
        timeZone: 'Europe/Warsaw', hour: '2-digit', minute: '2-digit',
        day: '2-digit', month: '2-digit'
      });
      const when = fmt.format(new Date(e.starts_at));
      for (const m of members) {
        await notifyUser(m.user_id, `📅 ${e.title}`, `Wydarzenie rodzinne · ${when}`,
          { type: 'family_event_reminder', event_id: e.id, group_id: e.group_id }).catch(() => {});
      }
      await db.query(`UPDATE family_events SET reminder_sent = TRUE WHERE id = $1`, [e.id]);
      console.log(`[event_reminder] notified ${members.length} for "${e.title}"`);
    }
  } catch (e) { console.error('[event_reminder]', e.message); }
}, 60 * 1000);

// F21: Senior daily check-in reminder + missed-checkin push at 20:00 Europe/Warsaw
// Run every minute, fire only at the 20:00 minute, dedup via Set
const f21FiredFor = new Set(); // key: YYYY-MM-DD
setInterval(async () => {
  try {
    const now = new Date();
    const warsawHour = parseInt(
      new Intl.DateTimeFormat('pl-PL', { hour: '2-digit', hour12: false, timeZone: 'Europe/Warsaw' })
        .format(now), 10
    );
    const warsawMin = parseInt(
      new Intl.DateTimeFormat('pl-PL', { minute: '2-digit', timeZone: 'Europe/Warsaw' })
        .format(now), 10
    );
    if (warsawHour !== 20 || warsawMin !== 0) return;
    const dayKey = new Intl.DateTimeFormat('sv-SE', { timeZone: 'Europe/Warsaw' }).format(now); // YYYY-MM-DD
    if (f21FiredFor.has(dayKey)) return;
    f21FiredFor.add(dayKey);
    // Cleanup old keys (keep last 3)
    if (f21FiredFor.size > 3) {
      const arr = Array.from(f21FiredFor).sort();
      arr.slice(0, arr.length - 3).forEach((k) => f21FiredFor.delete(k));
    }

    // Find seniors who didn't check in today
    const { rows: seniors } = await db.query(
      `SELECT u.id, u.username
       FROM users u
       WHERE u.app_mode = 'senior'
         AND NOT EXISTS (
           SELECT 1 FROM user_checkins c
           WHERE c.user_id = u.id
             AND c.status = 'safe'
             AND (c.created_at AT TIME ZONE 'Europe/Warsaw')::date = (NOW() AT TIME ZONE 'Europe/Warsaw')::date
         )`
    );
    if (seniors.length === 0) return;

    let pushedToParents = 0;
    for (const s of seniors) {
      // Self-reminder
      notifyUser(s.id, '⏰ Czas się zameldować',
        'Daj rodzinie znak, że wszystko w porządku', { type: 'checkin_reminder' }
      ).catch(() => {});

      // Parents in groups (anyone marked as parent in any of senior's groups)
      const { rows: parents } = await db.query(
        `SELECT DISTINCT m2.user_id AS parent_id
         FROM family_members m1
         JOIN family_members m2 ON m1.group_id = m2.group_id
         WHERE m1.user_id = $1 AND m2.role = 'parent' AND m2.user_id != $1`,
        [s.id]
      );
      for (const p of parents) {
        notifyUser(p.parent_id, `⚠️ ${s.username} jeszcze się dzisiaj nie zameldował`,
          'Sprawdź, czy wszystko w porządku', {
            type: 'checkin_missing', user_id: s.id, username: s.username,
          }
        ).catch(() => {});
        pushedToParents++;
      }
    }
    console.log(`[checkin_reminder] Pinged ${seniors.length} seniors, ${pushedToParents} parents`);
  } catch (e) { console.error('[checkin_reminder]', e.message); }
}, 60 * 1000);

// IMGW weather warnings sync every 15 min
// F11: AED sync co 24h (initial fetch po 30s startu)
const { syncAeds } = require('./services/aeds');
setTimeout(() => { syncAeds().catch(() => {}); }, 30 * 1000);
setInterval(() => syncAeds().catch(() => {}), 24 * 60 * 60 * 1000);

// F17: GIOŚ stations daily sync
const { syncStations: syncAqiStations } = require('./services/aqi');
setTimeout(() => { syncAqiStations().catch(() => {}); }, 60 * 1000);
setInterval(() => syncAqiStations().catch(() => {}), 24 * 60 * 60 * 1000);

const { syncWarnings } = require('./services/imgw');
syncWarnings(io); // Initial sync on startup
setInterval(() => syncWarnings(io), 15 * 60 * 1000);

// GDDKiA road incidents sync every 30 min
const { syncGddkia } = require('./services/gddkia');
syncGddkia(io);
setInterval(() => syncGddkia(io), 30 * 60 * 1000);

// Sentry error handler MUSI być wpięty po wszystkich routes a przed innymi error middleware.
if (process.env.SENTRY_DSN) {
  Sentry.setupExpressErrorHandler(app);
}

// Fallback error handler — loguje do konsoli, zwraca 500.
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, _next) => {
  console.error('[unhandled]', err.message, err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`AlertMap API running on :${PORT}`));
