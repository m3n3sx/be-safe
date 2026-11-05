// FCM Push Notification Service (HTTP v1 via Firebase Admin SDK)
// Requires service account JSON at path specified in FIREBASE_SERVICE_ACCOUNT env var
// Default: /home/ubuntu/alertmap/firebase-admin.json

const path = require('path');
const fs = require('fs');
const db = require('../config/db');
const { schoolSilentApplies } = require('../domain/safetyContracts');

let admin = null;
let messaging = null;
let initFailed = false;

function tryInit() {
  if (messaging || initFailed) return messaging;
  try {
    const saPath = process.env.FIREBASE_SERVICE_ACCOUNT || path.join(__dirname, '..', '..', 'firebase-admin.json');
    if (!fs.existsSync(saPath)) {
      console.log('[FCM] Service account not found at', saPath, '— FCM disabled');
      initFailed = true;
      return null;
    }
    admin = require('firebase-admin');
    if (admin.apps.length === 0) {
      admin.initializeApp({ credential: admin.credential.cert(require(saPath)) });
    }
    messaging = admin.messaging();
    console.log('[FCM] Firebase Admin initialized');
    return messaging;
  } catch (e) {
    console.error('[FCM] Init error:', e.message);
    initFailed = true;
    return null;
  }
}

// F20: Check if user is in school hours silent mode (any group where they're child + Warsaw pn-pt 8-15)
async function isSilentSchoolHours(userId) {
  try {
    // Warsaw time check (no DB query needed)
    const fmt = new Intl.DateTimeFormat('en-GB', {
      timeZone: 'Europe/Warsaw',
      weekday: 'short',
      hour: '2-digit',
      hour12: false,
    });
    const parts = Object.fromEntries(fmt.formatToParts(new Date()).map((p) => [p.type, p.value]));
    const weekday = parts.weekday; // Mon, Tue, ..., Sun
    const hour = parseInt(parts.hour, 10);
    const isSchoolDay = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'].includes(weekday);
    const isSchoolHour = hour >= 8 && hour < 15;
    if (!isSchoolDay || !isSchoolHour) return false;
    const { rows } = await db.query(
      `SELECT 1 FROM family_members WHERE user_id = $1 AND role = 'child' AND school_hours_silent = TRUE LIMIT 1`,
      [userId]
    );
    return rows.length > 0;
  } catch (_) { return false; }
}

// Centrum powiadomień: zapis powiadomienia do inboxu użytkownika (best-effort).
// Wołane z notifyUser i notifyNearbyUsers — łapie WSZYSTKIE typy powiadomień.
// NIGDY nie rzuca: błąd zapisu nie może zablokować wysyłki pusha.
async function recordNotification(userId, title, body, data = {}) {
  const type = (data && data.type) ? String(data.type) : 'generic';
  const sourceId = data && data.source_id ? String(data.source_id) : null;
  const payload = JSON.stringify(data || {});
  try {
    if (sourceId) {
      const inserted = await db.query(
        `INSERT INTO notifications (user_id, type, title, body, data, source_id)
         VALUES ($1, $2, $3, $4, $5::jsonb, $6)
         ON CONFLICT (user_id, type, source_id) WHERE source_id IS NOT NULL DO NOTHING
         RETURNING id`,
        [userId, type, title || '', body || null, payload, sourceId]
      );
      if (inserted.rows[0]) return { id: inserted.rows[0].id, created: true };
      const existing = await db.query(
        `SELECT id FROM notifications WHERE user_id = $1 AND type = $2 AND source_id = $3`,
        [userId, type, sourceId]
      );
      return { id: existing.rows[0]?.id || null, created: false };
    }
    const inserted = await db.query(
      `INSERT INTO notifications (user_id, type, title, body, data)
       VALUES ($1, $2, $3, $4, $5::jsonb) RETURNING id`,
      [userId, type, title || '', body || null, payload]
    );
    return { id: inserted.rows[0]?.id || null, created: true };
  } catch (e) {
    console.error('[notifications] record failed:', e.message);
    return { id: null, created: true };
  }
}

async function tokensForUser(userId) {
  try {
    const { rows } = await db.query(
      `SELECT token FROM user_push_tokens
        WHERE user_id = $1 AND disabled_at IS NULL
        ORDER BY last_seen_at DESC`,
      [userId]
    );
    if (rows.length) return rows.map((row) => row.token);
  } catch (e) {
    if (e.code !== '42P01') console.error('[FCM] token lookup', e.message);
  }
  const { rows } = await db.query(`SELECT fcm_token FROM users WHERE id = $1`, [userId]);
  return rows[0]?.fcm_token ? [rows[0].fcm_token] : [];
}

async function sendPush(fcmToken, title, body, data = {}, options = {}) {
  const m = tryInit();
  if (!m || !fcmToken) return null;

  const silent = options.silent === true;

  try {
    const messageId = await m.send({
      token: fcmToken,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: {
        priority: silent ? 'normal' : 'high',
        notification: {
          channelId: silent ? 'school_silent' : 'danger_alerts',
          priority: silent ? 'low' : 'max',
          defaultSound: !silent,
          defaultVibrateTimings: !silent,
        },
      },
      apns: {
        headers: silent ? { 'apns-priority': '5' } : undefined,
        payload: { aps: { sound: silent ? null : 'default', 'content-available': 1 } },
      },
    });
    return messageId;
  } catch (e) {
    // Token invalid? Remove from DB
    if (e.code === 'messaging/registration-token-not-registered' ||
        e.code === 'messaging/invalid-registration-token') {
      await db.query(`UPDATE users SET fcm_token = NULL WHERE fcm_token = $1`, [fcmToken]).catch(() => {});
      await db.query(`UPDATE user_push_tokens SET disabled_at = NOW() WHERE token = $1 AND disabled_at IS NULL`, [fcmToken]).catch(() => {});
    }
    console.error('[FCM] Send error:', e.message);
    return null;
  }
}

async function notifyUser(userId, title, body, data = {}) {
  const recorded = await recordNotification(userId, title, body, data);
  if (recorded && recorded.created === false) {
    return { notificationId: recorded.id, fcmAccepted: 0, duplicate: true };
  }
  const type = data.type ? String(data.type) : 'generic';
  const silent = schoolSilentApplies(type) ? await isSilentSchoolHours(userId) : false;
  const tokens = await tokensForUser(userId);
  const payload = { ...data, notification_id: recorded?.id || '' };
  let fcmAccepted = 0;
  for (const token of tokens) {
    const messageId = await sendPush(token, title, body, payload, { silent });
    if (messageId) fcmAccepted += 1;
  }
  return { notificationId: recorded?.id || null, fcmAccepted, duplicate: false };
}

async function notifyNearbyUsers(alert, options = {}) {
  const exclude = new Set(options.excludeUserIds || []);
  const { rows } = await db.query(
    `SELECT u.id FROM users u
     WHERE u.id != $1
     AND u.last_location IS NOT NULL
     AND ST_DWithin(u.last_location, ST_MakePoint($3, $2)::geography, u.alert_radius_m)
     AND NOT EXISTS (SELECT 1 FROM alert_notifications n WHERE n.alert_id = $4 AND n.user_id = u.id)`,
    [alert.author_id, alert.lat, alert.lng, alert.id]
  );

  let fcmAccepted = 0;
  for (const user of rows) {
    if (exclude.has(user.id)) continue;
    const pushData = {
      alert_id: alert.id,
      source_id: alert.id,
      type: 'new_alert',
      category: alert.category || '',
      lat: alert.lat != null ? String(alert.lat) : '',
      lng: alert.lng != null ? String(alert.lng) : '',
      title: alert.title || '',
    };
    const result = await notifyUser(
      user.id,
      `⚠️ ${alert.title}`,
      alert.description || 'Nowe zagrożenie w Twojej okolicy',
      pushData
    );
    fcmAccepted += result?.fcmAccepted || 0;
    await db.query(`INSERT INTO alert_notifications (alert_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, [alert.id, user.id]);
  }
  if (fcmAccepted > 0) console.log(`[FCM] Accepted ${fcmAccepted} pushes for alert ${alert.id}`);
  return fcmAccepted;
}

module.exports = { sendPush, notifyNearbyUsers, notifyUser, isSilentSchoolHours, recordNotification, tokensForUser };
