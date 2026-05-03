// FCM Push Notification Service
// Requires GOOGLE_APPLICATION_CREDENTIALS env var pointing to service account JSON
// or FCM_SERVER_KEY for legacy API

const https = require('https');
const db = require('../config/db');

const FCM_URL = 'https://fcm.googleapis.com/fcm/send';

async function sendPush(fcmToken, title, body, data = {}) {
  const key = process.env.FCM_SERVER_KEY;
  if (!key || !fcmToken) return;

  const payload = JSON.stringify({
    to: fcmToken,
    notification: { title, body, sound: 'default', priority: 'high' },
    data,
    priority: 'high',
  });

  return new Promise((resolve) => {
    const req = https.request(FCM_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `key=${key}`, 'Content-Length': Buffer.byteLength(payload) },
    }, (res) => { res.resume(); resolve(res.statusCode); });
    req.on('error', () => resolve(null));
    req.write(payload);
    req.end();
  });
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

  for (const user of rows) {
    await sendPush(user.fcm_token, `⚠️ ${alert.category}`, alert.title, { alert_id: alert.id, type: 'new_alert' });
    await db.query(`INSERT INTO alert_notifications (alert_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, [alert.id, user.id]);
  }
  return rows.length;
}

module.exports = { sendPush, notifyNearbyUsers };
