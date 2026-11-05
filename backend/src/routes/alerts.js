const router = require('express').Router();
const db = require('../config/db');
const auth = require('../middleware/auth');
const multer = require('multer');
const { uploadBuffer, makeFilename } = require('../services/storage');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_, file, cb) => cb(null, /^image\/(jpeg|png|webp)$/.test(file.mimetype)),
});

const { notifyNearbyUsers, notifyUser } = require('../services/fcm');
const { resolveAlertKind, sosPushText } = require('../domain/safetyContracts');
const { moderate } = require('../services/moderation');
const { moderateText: aiModerate } = require('../services/ai_moderation');
const { moderateImage } = require('../services/image_moderation');
const rateLimit = require('express-rate-limit');
const createAlertLimiter = rateLimit({ windowMs: 3600000, max: 10 });

router.use(auth);

// Nowe alerty od ostatniego sprawdzenia — dla polling notifications
router.get('/new', async (req, res) => {
  const { since } = req.query;
  if (!since) return res.status(400).json({ error: 'since required' });
  const { rows: user } = await db.query(
    `SELECT ST_Y(last_location::geometry) AS lat, ST_X(last_location::geometry) AS lng, alert_radius_m FROM users WHERE id = $1`,
    [req.user.id]
  );
  if (!user[0]?.lat) return res.json({ alerts: [] });
  const { lat, lng, alert_radius_m } = user[0];
  const { rows } = await db.query(
    `SELECT a.id, a.category, a.title, a.description, ST_Y(a.location::geometry) AS lat, ST_X(a.location::geometry) AS lng,
            a.radius_m, a.confirms, a.denies, a.created_at
     FROM alerts a WHERE a.status = 'active' AND a.author_id != $1
     AND a.created_at > $2 AND a.expires_at > NOW()
     AND ST_DWithin(a.location, ST_MakePoint($4, $3)::geography, $5)
     ORDER BY a.created_at DESC`,
    [req.user.id, since, lat, lng, Math.max(alert_radius_m, 5000)]
  );
  res.json({ alerts: rows });
});

const ALERT_COLS = `a.id, a.author_id, a.category, a.title, a.description, a.photo_url,
  ST_Y(a.location::geometry) AS lat, ST_X(a.location::geometry) AS lng,
  a.radius_m, a.status, a.confirms, a.denies, a.trust_score, a.expires_at, a.created_at, a.is_anonymous, a.kind`;

// F17: gdy is_anonymous=TRUE -> ukryj author info dla innych (poza autorem)
async function notifyFamilySos(req, alert) {
  const { rows: names } = await db.query(`SELECT username FROM users WHERE id = $1`, [req.user.id]);
  const senderName = names[0]?.username || 'bliska osoba';
  const text = sosPushText({ senderName });
  const { rows } = await db.query(
    `SELECT DISTINCT ON (m2.user_id) m2.user_id, m1.group_id
       FROM family_members m1
       JOIN family_members m2 ON m2.group_id = m1.group_id AND m2.user_id <> m1.user_id
      WHERE m1.user_id = $1
      ORDER BY m2.user_id, m1.group_id`,
    [req.user.id]
  );
  const io = req.app.get('io');
  const userIds = [];
  let fcmAccepted = 0;
  for (const row of rows) {
    const result = await notifyUser(row.user_id, text.title, text.body, {
      type: 'family_sos',
      source_id: String(alert.id),
      alert_id: String(alert.id),
      group_id: String(row.group_id),
      from_user_id: req.user.id,
      from_username: senderName,
      sent_at: alert.created_at ? new Date(alert.created_at).toISOString() : new Date().toISOString(),
      lat: alert.lat != null ? String(alert.lat) : '',
      lng: alert.lng != null ? String(alert.lng) : '',
    });
    userIds.push(row.user_id);
    fcmAccepted += result?.fcmAccepted || 0;
    if (io && result && !result.duplicate && result.notificationId) {
      io.to(`user:${row.user_id}`).emit('notification:new', {
        id: result.notificationId,
        type: 'family_sos',
        title: text.title,
        body: text.body,
        source_id: String(alert.id),
        data: {
          alert_id: String(alert.id),
          group_id: String(row.group_id),
          from_username: senderName,
          notification_id: result.notificationId,
        },
      });
    }
  }
  return { userIds, fcmAccepted, recipients: rows.length };
}

const authorJson = `CASE WHEN a.is_anonymous AND a.author_id != $1 THEN NULL
  ELSE json_build_object('username', u.username, 'reputation_score', u.reputation_score, 'is_verified', u.is_verified, 'verified_role', u.verified_role, 'avatar_url', u.avatar_url) END AS author`;

router.get('/stats', async (req, res) => {
  const { lat, lng, radius_m = 2000 } = req.query;
  if (!lat || !lng) return res.status(400).json({ error: 'lat and lng required' });

  const { rows: [totals] } = await db.query(
    `SELECT COUNT(*)::int AS total,
            COUNT(*) FILTER (WHERE created_at > NOW() - interval '7 days')::int AS week,
            COUNT(*) FILTER (WHERE created_at > NOW() - interval '1 day')::int AS today
     FROM alerts WHERE ST_DWithin(location, ST_MakePoint($2, $1)::geography, $3)`,
    [lat, lng, radius_m]
  );
  const { rows: byCategory } = await db.query(
    `SELECT category, COUNT(*)::int AS count FROM alerts
     WHERE ST_DWithin(location, ST_MakePoint($2, $1)::geography, $3) AND created_at > NOW() - interval '30 days'
     GROUP BY category ORDER BY count DESC LIMIT 10`,
    [lat, lng, radius_m]
  );
  const { rows: trend } = await db.query(
    `SELECT date_trunc('day', created_at)::date AS day, COUNT(*)::int AS count
     FROM alerts WHERE ST_DWithin(location, ST_MakePoint($2, $1)::geography, $3) AND created_at > NOW() - interval '14 days'
     GROUP BY day ORDER BY day`,
    [lat, lng, radius_m]
  );
  res.json({ totals, by_category: byCategory, trend });
});

router.get('/heatmap', async (req, res) => {
  const { lat, lng, radius_m = 5000, days = 30 } = req.query;
  if (!lat || !lng) return res.status(400).json({ error: 'lat and lng required' });
  const { rows } = await db.query(
    `SELECT ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng,
            COUNT(*)::int AS weight
     FROM alerts
     WHERE created_at > NOW() - ($4 || ' days')::interval
     AND ST_DWithin(location, ST_MakePoint($2, $1)::geography, $3)
     GROUP BY ST_SnapToGrid(location::geometry, 0.001)
     ORDER BY weight DESC LIMIT 200`,
    [lat, lng, radius_m, days]
  );
  res.json({ points: rows });
});

router.get('/mine', async (req, res) => {
  const { rows } = await db.query(
    `SELECT ${ALERT_COLS}, json_build_object('username', u.username, 'reputation_score', u.reputation_score, 'is_verified', u.is_verified, 'verified_role', u.verified_role, 'avatar_url', u.avatar_url) AS author
     FROM alerts a JOIN users u ON a.author_id = u.id
     WHERE a.author_id = $1 ORDER BY a.created_at DESC LIMIT 100`,
    [req.user.id]
  );
  res.json({ alerts: rows });
});

router.get('/nearby', async (req, res) => {
  const { lat, lng, radius_m = 1000, category } = req.query;
  if (!lat || !lng) return res.status(400).json({ error: 'lat and lng required' });

  // F17: param $1 = req.user.id (dla authorJson CASE), $2=lat, $3=lng, $4=radius_m
  let q = `SELECT ${ALERT_COLS}, ST_Distance(a.location, ST_MakePoint($3, $2)::geography) AS distance_m,
            ${authorJson}
            FROM alerts a JOIN users u ON a.author_id = u.id
            WHERE a.status = 'active' AND a.expires_at > NOW()
            AND ST_DWithin(a.location, ST_MakePoint($3, $2)::geography, $4)`;
  const params = [req.user.id, lat, lng, radius_m];

  if (category) {
    params.push(category);
    q += ` AND a.category = $${params.length}`;
  }
  q += ` ORDER BY distance_m`;

  const { rows } = await db.query(q, params);
  res.json({ alerts: rows });
});

router.get('/:id', async (req, res) => {
  const { rows } = await db.query(
    `SELECT ${ALERT_COLS}, ${authorJson}
     FROM alerts a JOIN users u ON a.author_id = u.id WHERE a.id = $2`,
    [req.user.id, req.params.id]
  );
  if (!rows[0]) return res.status(404).json({ error: 'Not found' });
  res.json(rows[0]);
});

router.post('/', createAlertLimiter, upload.single('photo'), async (req, res) => {
  const { category, title, description, lat, lng, radius_m = 100, duration_hours = 3, is_anonymous = false, kind } = req.body;
  const resolvedKind = resolveAlertKind({ kind, category, title });
  const alertKind = resolvedKind.kind;
  // F17: anonimowe zgłoszenia - flaga zapisywana w DB, author_id zostaje dla moderacji
  const anonymous = is_anonymous === true || is_anonymous === 'true' || is_anonymous === 1 || is_anonymous === '1';
  const expires = new Date(Date.now() + duration_hours * 3600000).toISOString();
  let photo_url = null;
  let imageReview = false; // F06: zdjęcie wymaga przeglądu (review) → status hidden
  if (req.file) {
    // F06: Vision SafeSearch PRZED uploadem — block odrzuca zdjęcie zanim trafi do GCS.
    const isSosImg = alertKind === 'sos';
    if (!isSosImg) {
      const img = await moderateImage(req.file.buffer);
      if (img.action === 'block') {
        console.log(`[image_moderation] BLOCK by ${req.user.id}: ${img.reason}`);
        return res.status(422).json({
          error: 'Zdjęcie zostało odrzucone przez moderację (treści nieodpowiednie).',
          image_reason: img.reason,
        });
      }
      if (img.action === 'review') {
        imageReview = true;
        console.log(`[image_moderation] REVIEW by ${req.user.id}: ${img.reason}`);
      }
    }
    const filename = makeFilename(req.file, '');
    photo_url = await uploadBuffer(req.file.buffer, `alerts/${filename}`, req.file.mimetype);
  }

  // F05: Heurystyka (skip dla SOS - aggression z 🆘)
  const isSosBypass = alertKind === 'sos';
  const moderation = isSosBypass ? { action: 'allow', score: 0, reasons: [] } : moderate({ title, description });
  if (moderation.action === 'block') {
    console.log(`[moderation] BLOCK by ${req.user.id}: score=${moderation.score} reasons=${moderation.reasons.join(',')}`);
    return res.status(422).json({
      error: 'Treść została odrzucona przez moderację. Sprawdź czy nie zawiera obraźliwych słów.',
      moderation_score: moderation.score,
    });
  }

  // F06: AI moderation (Vertex AI Gemini) — druga warstwa.
  // Skip dla SOS i gdy heurystyka już oznaczyła jako flag (już idzie do admin).
  let aiResult = { action: 'allow', confidence: 0, reason: 'skipped' };
  if (!isSosBypass && moderation.action !== 'flag') {
    aiResult = await aiModerate({ title, description, category });
    if (aiResult.action === 'block' && aiResult.confidence >= 0.85) {
      console.log(`[ai_moderation] BLOCK by ${req.user.id}: conf=${aiResult.confidence} reason="${aiResult.reason}"`);
      return res.status(422).json({
        error: 'Treść została odrzucona przez moderację AI. Jeśli uważasz, że to błąd, skontaktuj się z administratorem.',
        ai_confidence: aiResult.confidence,
        ai_reason: aiResult.reason,
      });
    }
  }

  // initialStatus: 'hidden' gdy heurystyka flag LUB AI review/block z confidence>=0.6 LUB zdjęcie review (F06)
  const aiNeedsReview = (aiResult.action === 'review' || aiResult.action === 'block') && aiResult.confidence >= 0.6;
  const initialStatus = (moderation.action === 'flag' || aiNeedsReview || imageReview) ? 'hidden' : 'active';

  const { rows } = await db.query(
    `INSERT INTO alerts (author_id, category, title, description, photo_url, location, radius_m, expires_at, status, is_anonymous, kind)
     VALUES ($1, $2, $3, $4, $5, ST_MakePoint($7, $6)::geography, $8, $9, $10, $11, $12)
     RETURNING id, author_id, category, title, description, photo_url,
       ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng,
       radius_m, status, confirms, denies, expires_at, created_at, is_anonymous, kind`,
    [req.user.id, category, title, description, photo_url, lat, lng, radius_m, expires, initialStatus, anonymous, alertKind]
  );

  if (initialStatus === 'hidden') {
    // Insert do alert_reports żeby admin widział w /admin/reports
    let reason, details;
    if (moderation.action === 'flag') {
      reason = 'auto_moderation';
      details = `Heurystyka: score=${moderation.score} reasons=${moderation.reasons.join(',')}`;
    } else if (aiNeedsReview) {
      reason = 'ai_moderation';
      details = `AI: action=${aiResult.action} conf=${aiResult.confidence.toFixed(2)} reason="${aiResult.reason}"`;
    } else {
      reason = 'image_moderation';
      details = 'Vision SafeSearch oznaczył zdjęcie do przeglądu';
    }
    try {
      await db.query(
        `INSERT INTO alert_reports (alert_id, reporter_id, reason, details, status)
         VALUES ($1, $2, $3, $4, 'pending')
         ON CONFLICT (alert_id, reporter_id) DO NOTHING`,
        [rows[0].id, req.user.id, reason, details]
      );
    } catch (e) {
      console.error('[moderation] insert alert_report failed:', e.message);
    }
    console.log(`[moderation] HIDDEN by ${req.user.id}: ${reason} | ${details}`);
    return res.status(201).json({
      ...rows[0],
      moderation: {
        action: moderation.action === 'flag' ? 'flag' : 'ai_review',
        score: moderation.score,
        ai_confidence: aiResult.confidence,
        ai_reason: aiResult.reason,
        note: 'Twój alert wymaga przeglądu moderacji. Zostanie opublikowany po akceptacji administratora.',
      },
    });
  }
  // Emit only to users within their alert radius
  const io = req.app.get('io');
  if (io) {
    const { rows: nearby } = await db.query(
      `SELECT id FROM users WHERE id != $1 AND last_location IS NOT NULL
       AND ST_DWithin(last_location, ST_MakePoint($3, $2)::geography, alert_radius_m)`,
      [req.user.id, lng, lat]
    );
    for (const u of nearby) io.to(`user:${u.id}`).emit('alert:new', rows[0]);
  }
  let sosRecipientIds = [];
  if (alertKind === 'sos') {
    try {
      const fan = await notifyFamilySos(req, rows[0]);
      sosRecipientIds = fan.userIds;
      console.log(`[family_sos] ${req.user.id} -> ${fan.recipients} members (FCM accepted: ${fan.fcmAccepted})`);
    } catch (e) {
      console.error('[family_sos]', e.message);
    }
  }
  notifyNearbyUsers(rows[0], { excludeUserIds: sosRecipientIds }).catch(() => {});

  // Dzieci w pobliżu alertu nadal powiadamiają rodziców. SOS idzie osobno do całej grupy.
  (async () => {
    const alert = rows[0];
    try {
      if (alertKind === 'sos') {
        // F12: KPP responders (Kwalifikowana Pierwsza Pomoc) w promieniu 2km - osobny push
        const kppRadius = 2000;
        const { rows: kppNearby } = await db.query(
          `SELECT id, username, ST_Distance(last_location, ST_MakePoint($2, $1)::geography) AS distance_m
           FROM users
           WHERE is_kpp = TRUE
             AND last_location IS NOT NULL
             AND id != $3
             AND ST_DWithin(last_location, ST_MakePoint($2, $1)::geography, $4)
           ORDER BY distance_m ASC
           LIMIT 25`,
          [alert.lat, alert.lng, req.user.id, kppRadius]
        );
        let kppSent = 0;
        for (const r of kppNearby) {
          const result = await notifyUser(
            r.id,
            '🚑 KPP: ktoś potrzebuje pomocy',
            `Wezwanie ratownika w odległości ${Math.round(r.distance_m)}m. Możesz zareagować?`,
            {
              type: 'kpp_responder_call',
              source_id: `${alert.id}:${r.id}`,
              alert_id: alert.id,
              lat: String(alert.lat),
              lng: String(alert.lng),
              distance_m: String(Math.round(r.distance_m)),
            }
          );
          kppSent += result?.fcmAccepted || 0;
        }
        if (kppNearby.length > 0) {
          console.log(`[kpp] ${kppNearby.length} responders within ${kppRadius}m (FCM: ${kppSent})`);
        }
      }

      // I.2B - dzieci w obszarze alertu (niezależnie od lokalizacji rodziców)
      const { rows: childrenInArea } = await db.query(
        `SELECT DISTINCT fm.user_id AS child_id, c.username AS child_username,
                p.user_id AS parent_id, fm.group_id, g.name AS group_name,
                ST_Y(c.last_location::geometry) AS child_lat,
                ST_X(c.last_location::geometry) AS child_lng
         FROM family_members fm
         JOIN users c ON c.id = fm.user_id
         JOIN family_members p ON p.group_id = fm.group_id AND p.role = 'parent' AND p.user_id != fm.user_id
         JOIN family_groups g ON g.id = fm.group_id
         WHERE fm.role = 'child'
           AND fm.tracking_enabled = true
           AND c.last_location IS NOT NULL
           AND c.id != $1
           AND ST_DWithin(c.last_location, ST_MakePoint($3, $2)::geography, $4)`,
        [req.user.id, lat, lng, radius_m]
      );
      let parentNotified = 0;
      const sentToParent = new Set();
      for (const r of childrenInArea) {
        const dedupKey = `${r.parent_id}:${alert.id}:${r.child_id}`;
        if (sentToParent.has(dedupKey)) continue;
        sentToParent.add(dedupKey);
        const result = await notifyUser(
          r.parent_id,
          `⚠️ Zagrożenie obok ${r.child_username}`,
          `${alert.title || 'Nowe zgłoszenie'} — w pobliżu lokalizacji dziecka.`,
          {
            type: 'family_alert_near_child',
            source_id: `${alert.id}:${r.child_id}`,
            alert_id: alert.id,
            child_id: r.child_id,
            child_username: r.child_username,
            group_id: r.group_id,
            lat: String(alert.lat),
            lng: String(alert.lng),
          }
        );
        parentNotified += result?.fcmAccepted || 0;
      }
      if (childrenInArea.length) {
        console.log(`[alert_near_child] alert ${alert.id} -> ${childrenInArea.length} child-parent pairs, ${parentNotified} pushed`);
      }
    } catch (e) {
      console.error('[alert family-notify]', e.message);
    }
  })();

  res.status(201).json(rows[0]);
});

router.patch('/:id', async (req, res) => {
  const { description, extend_hours } = req.body;
  const updates = [];
  const params = [req.params.id, req.user.id];

  if (description !== undefined) {
    params.push(description);
    updates.push(`description = $${params.length}`);
  }
  if (extend_hours) {
    params.push(extend_hours);
    updates.push(`expires_at = expires_at + ($${params.length} || ' hours')::interval`);
    updates.push(`status = 'active'`);
  }
  if (!updates.length) return res.status(400).json({ error: 'Nothing to update' });

  const { rows } = await db.query(
    `UPDATE alerts SET ${updates.join(', ')} WHERE id = $1 AND author_id = $2
     RETURNING ${ALERT_COLS.replace(/a\./g, '')}`,
    params
  );
  if (!rows[0]) return res.status(404).json({ error: 'Not found or not owner' });
  req.app.get('io')?.emit('alert:updated', rows[0]);
  res.json(rows[0]);
});

router.delete('/:id', async (req, res) => {
  const { rowCount } = await db.query(
    `UPDATE alerts SET status = 'removed' WHERE id = $1 AND author_id = $2`,
    [req.params.id, req.user.id]
  );
  if (!rowCount) return res.status(404).json({ error: 'Not found or not owner' });
  res.json({ ok: true });
});

router.post('/:id/vote', async (req, res) => {
  try {
    await db.query(
      `INSERT INTO alert_votes (alert_id, user_id, vote) VALUES ($1, $2, $3)`,
      [req.params.id, req.user.id, req.body.vote]
    );
    // F31: ważony trust_score po każdym głosie. Waga głosu = 1 + min(reputation_score, 100) / 50
    // Score = sum(confirm_weights) - sum(deny_weights * 1.5) — fałszerstwo karzemy mocniej
    const { rows: ts } = await db.query(
      `WITH weighted AS (
         SELECT v.vote, (1.0 + LEAST(GREATEST(u.reputation_score, 0), 100) / 50.0) AS w
         FROM alert_votes v JOIN users u ON u.id = v.user_id
         WHERE v.alert_id = $1
       )
       SELECT
         COALESCE(SUM(CASE WHEN vote='confirm' THEN w ELSE 0 END), 0) AS c_w,
         COALESCE(SUM(CASE WHEN vote='deny' THEN w * 1.5 ELSE 0 END), 0) AS d_w
       FROM weighted`,
      [req.params.id]
    );
    const score = Math.max(0, Number(ts[0].c_w) - Number(ts[0].d_w));
    const { rows } = await db.query(
      `UPDATE alerts SET trust_score = $2 WHERE id = $1
       RETURNING confirms, denies, trust_score, author_id`,
      [req.params.id, score]
    );
    // F31: jeśli alert ma confirm_score >= 5 i bardzo mało denies — +1 dla autora reputation
    if (req.body.vote === 'confirm' && rows[0].denies === 0 && rows[0].confirms >= 5) {
      await db.query(
        `UPDATE users SET reputation_score = LEAST(reputation_score + 1, 200) WHERE id = $1`,
        [rows[0].author_id]
      );
    }
    req.app.get('io')?.emit('alert:updated', { id: req.params.id, ...rows[0] });
    res.json(rows[0]);
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'Already voted' });
    res.status(500).json({ error: e.message });
  }
});

router.post('/:id/photo', upload.single('photo'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'Photo required' });
  const filename = makeFilename(req.file, '');
  const photo_url = await uploadBuffer(req.file.buffer, `alerts/${filename}`, req.file.mimetype);
  const { rows } = await db.query(
    `UPDATE alerts SET photo_url = $1 WHERE id = $2 AND author_id = $3 RETURNING id, photo_url`,
    [photo_url, req.params.id, req.user.id]
  );
  if (!rows[0]) return res.status(404).json({ error: 'Not found or not owner' });
  res.json(rows[0]);
});

// --- Comments ---

router.get('/:id/comments', async (req, res) => {
  const { rows } = await db.query(
    `SELECT c.id, c.content, c.created_at, json_build_object('id', u.id, 'username', u.username) AS author
     FROM alert_comments c JOIN users u ON c.user_id = u.id
     WHERE c.alert_id = $1 ORDER BY c.created_at ASC`,
    [req.params.id]
  );
  res.json({ comments: rows });
});

router.post('/:id/comments', async (req, res) => {
  const { content } = req.body;
  if (!content || !content.trim()) return res.status(400).json({ error: 'Content required' });
  const { rows } = await db.query(
    `INSERT INTO alert_comments (alert_id, user_id, content) VALUES ($1, $2, $3)
     RETURNING id, content, created_at`,
    [req.params.id, req.user.id, content.trim()]
  );
  rows[0].author = { id: req.user.id, username: req.user.email };
  // Get username
  const { rows: u } = await db.query(`SELECT username, avatar_url FROM users WHERE id = $1`, [req.user.id]);
  if (u[0]) {
    rows[0].author.username = u[0].username;
    rows[0].author.avatar_url = u[0].avatar_url;
  }
  // Broadcast to everyone currently viewing this alert's comments
  req.app.get('io')?.to(`alert:${req.params.id}`).emit('comment:new', {
    alert_id: req.params.id,
    ...rows[0],
  });
  res.status(201).json(rows[0]);
});

router.delete('/:id/comments/:commentId', async (req, res) => {
  const { id, commentId } = req.params;
  const { rowCount } = await db.query(
    `DELETE FROM alert_comments WHERE id = $1 AND user_id = $2 AND alert_id = $3`,
    [commentId, req.user.id, id]
  );
  if (!rowCount) return res.status(404).json({ error: 'Not found or not owner' });
  req.app.get('io')?.to(`alert:${id}`).emit('comment:deleted', {
    alert_id: id,
    comment_id: commentId,
  });
  res.json({ ok: true });
});

// ------ MODERATION / REPORTS ------
router.post('/:id/report', async (req, res) => {
  const { reason, details } = req.body;
  if (!reason) return res.status(400).json({ error: 'Reason required' });

  try {
    await db.query(
      `INSERT INTO alert_reports (alert_id, reporter_id, reason, details) VALUES ($1, $2, $3, $4)`,
      [req.params.id, req.user.id, reason, details || null]
    );
    // Auto-hide po 3+ zgłoszeniach
    const { rows } = await db.query(
      `SELECT COUNT(*)::int AS cnt FROM alert_reports WHERE alert_id = $1`,
      [req.params.id]
    );
    if (rows[0].cnt >= 3) {
      await db.query(`UPDATE alerts SET status = 'hidden' WHERE id = $1`, [req.params.id]);
    }
    res.json({ ok: true, reports: rows[0].cnt });
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'Already reported' });
    res.status(500).json({ error: e.message });
  }
});

router.get('/:id/sos-context', async (req, res) => {
  const { rows } = await db.query(
    `SELECT a.id, a.author_id, a.status, a.expires_at, a.created_at, a.kind, a.category, a.title,
            ST_Y(a.location::geometry) AS lat, ST_X(a.location::geometry) AS lng, u.username
       FROM alerts a JOIN users u ON u.id = a.author_id
      WHERE a.id = $1`,
    [req.params.id]
  );
  const alert = rows[0];
  if (!alert || resolveAlertKind(alert).kind !== 'sos') {
    return res.status(404).json({ error: 'Nie znaleziono alarmu' });
  }
  let groupId = null;
  if (alert.author_id !== req.user.id) {
    const { rows: mem } = await db.query(
      `SELECT author.group_id
         FROM family_members author
         JOIN family_members viewer ON viewer.group_id = author.group_id AND viewer.user_id = $2
        WHERE author.user_id = $1
        LIMIT 1`,
      [alert.author_id, req.user.id]
    );
    if (!mem[0]) return res.status(404).json({ error: 'Nie znaleziono alarmu' });
    groupId = mem[0].group_id;
  }
  let phone = null;
  if (alert.author_id !== req.user.id) {
    const { rows: groups } = await db.query(
      `SELECT author.group_id
         FROM family_members author
         JOIN family_members viewer ON viewer.group_id = author.group_id AND viewer.user_id = $2
        WHERE author.user_id = $1`,
      [alert.author_id, req.user.id]
    );
    const { rows: phones } = await db.query(`SELECT phone FROM users WHERE id = $1`, [alert.author_id]);
    const rawPhone = phones[0]?.phone || null;
    if (rawPhone) {
      for (const group of groups) {
        const { rows: vis } = await db.query(
          `SELECT granted FROM family_visibility
            WHERE group_id = $1 AND viewer_id = $2 AND target_id = $3 AND field = 'phone'`,
          [group.group_id, req.user.id, alert.author_id]
        );
        const granted = vis.length ? vis[0].granted === true : true;
        if (granted) {
          phone = rawPhone;
          if (!groupId) groupId = group.group_id;
          break;
        }
      }
    }
  }
  const { rows: notes } = await db.query(
    `SELECT id, acknowledged_at FROM notifications
      WHERE user_id = $1 AND type = 'family_sos' AND source_id = $2
      LIMIT 1`,
    [req.user.id, String(alert.id)]
  );
  res.json({
    alert_id: alert.id,
    status: alert.status,
    expires_at: alert.expires_at,
    sent_at: alert.created_at,
    lat: alert.lat,
    lng: alert.lng,
    sender_username: alert.username,
    group_id: groupId,
    phone,
    notification_id: notes[0]?.id || null,
    acknowledged_at: notes[0]?.acknowledged_at || null,
    location_label: 'Miejsce wysłania alarmu',
  });
});

module.exports = router;
