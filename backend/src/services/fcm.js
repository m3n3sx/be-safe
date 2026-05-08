// FCM Push Notification Service (HTTP v1 via Firebase Admin SDK)
// Requires service account JSON at path specified in FIREBASE_SERVICE_ACCOUNT env var
// Default: /home/ubuntu/alertmap/firebase-admin.json

const path = require('path');
const fs = require('fs');
const db = require('../config/db');

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

async function sendPush(fcmToken, title, body, data = {}) {
  const m = tryInit();
  if (!m || !fcmToken) return null;

  try {
    const messageId = await m.send({
      token: fcmToken,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: {
        priority: 'high',
        notification: {
          channelId: 'danger_alerts',
          priority: 'max',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: { aps: { sound: 'default', 'content-available': 1 } },
      },
    });
    return messageId;
  } catch (e) {
    // Token invalid? Remove from DB
    if (e.code === 'messaging/registration-token-not-registered' ||
        e.code === 'messaging/invalid-registration-token') {
      await db.query(`UPDATE users SET fcm_token = NULL WHERE fcm_token = $1`, [fcmToken]).catch(() => {});
    }
    console.error('[FCM] Send error:', e.message);
    return null;
  }
}

async function notifyNearbyUsers(alert) {
  const { rows } = await db.query(
    `SELECT u.id, u.fcm_token FROM users u
     WHERE u.fcm_token IS NOT NULL AND u.id != $1
     AND u.last_location IS NOT NULL
     AND ST_DWithin(u.last_location, ST_MakePoint($3, $2)::geography, u.alert_radius_m)
     AND NOT EXISTS (SELECT 1 FROM alert_notifications n WHERE n.alert_id = $4 AND n.user_id = u.id)`,
    [alert.author_id, alert.lat, alert.lng, alert.id]
  );

  let sent = 0;
  for (const user of rows) {
    const result = await sendPush(
      user.fcm_token,
      `⚠️ ${alert.title}`,
      alert.description || 'Nowe zagrożenie w Twojej okolicy',
      { alert_id: alert.id, type: 'new_alert', category: alert.category || '' }
    );
    if (result) sent++;
    await db.query(`INSERT INTO alert_notifications (alert_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, [alert.id, user.id]);
  }
  if (sent > 0) console.log(`[FCM] Sent ${sent}/${rows.length} notifications for alert ${alert.id}`);
  return sent;
}

async function notifyUser(userId, title, body, data = {}) {
  const { rows } = await db.query(`SELECT fcm_token FROM users WHERE id = $1`, [userId]);
  if (!rows[0]?.fcm_token) return null;
  return sendPush(rows[0].fcm_token, title, body, data);
}

module.exports = { sendPush, notifyNearbyUsers, notifyUser };
