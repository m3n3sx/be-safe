// Lokalny PostgreSQL. Pomija się, gdy nie ma gniazda peer. Nie używa produkcji.
const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const http = require('http');
const path = require('path');
const { execSync } = require('child_process');
const { Client } = require('pg');
const jwt = require('jsonwebtoken');

const DB = 'besafe_mig_verify';
const SECRET = 'migration-test-secret';
const ROOT = path.join(__dirname, '..', '..');

const socket = { host: '/var/run/postgresql', user: 'ubuntu' };

async function admin() {
  const client = new Client({ ...socket, database: 'postgres' });
  await client.connect();
  return client;
}

function httpCall(server, method, urlPath, { token, body } = {}) {
  const payload = body ? JSON.stringify(body) : null;
  return new Promise((resolve, reject) => {
    const req = http.request({
      hostname: '127.0.0.1',
      port: server.address().port,
      path: urlPath,
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
      },
    }, (res) => {
      const chunks = [];
      res.on('data', (chunk) => chunks.push(chunk));
      res.on('end', () => {
        const text = Buffer.concat(chunks).toString('utf8');
        let json = {};
        try { json = text ? JSON.parse(text) : {}; } catch (_) { json = { raw: text }; }
        resolve({ status: res.statusCode, json });
      });
    });
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

test('migration, SOS membership, invite role and inbox ack on an old schema', async (t) => {
  let control;
  try {
    control = await admin();
  } catch (error) {
    t.skip(`brak lokalnego PostgreSQL: ${error.message}`);
    return;
  }
  await control.query(`DROP DATABASE IF EXISTS ${DB}`);
  await control.query(`CREATE DATABASE ${DB}`);
  await control.end();

  const db = new Client({ ...socket, database: DB });
  await db.connect();
  const oldSchema = execSync('git show 6dc4ffb^:db/schema.sql', { cwd: ROOT, encoding: 'utf8' });
  await db.query(oldSchema);
  // Kolumny, których bieżący kod używał już przed tą zmianą, a schema.sql ich nie miał.
  await db.query(`ALTER TABLE alerts ADD COLUMN IF NOT EXISTS is_anonymous BOOLEAN NOT NULL DEFAULT FALSE`);
  await db.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS is_kpp BOOLEAN NOT NULL DEFAULT FALSE`);
  await db.query(`
    CREATE TABLE family_pings (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
      sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      response_status TEXT,
      response_at TIMESTAMPTZ,
      response_message TEXT
    )`);

  const ids = await db.query(`
    INSERT INTO users (email, password_hash, username, phone, fcm_token, last_location, last_location_at)
    VALUES
      ('owner@example.test', 'hash', 'wlasciciel', '+48111000001', 'legacy-owner-token', ST_MakePoint(21, 52.2), NOW()),
      ('member@example.test', 'hash', 'czlonek', NULL, NULL, ST_MakePoint(21, 52.2), NOW()),
      ('child@example.test', 'hash', 'dziecko', '+48111000003', NULL, ST_MakePoint(21.01, 52.21), NOW()),
      ('outsider@example.test', 'hash', 'obcy', NULL, NULL, NULL, NULL),
      ('ghost@example.test', 'hash', 'duch', NULL, NULL, ST_MakePoint(21.02, 52.22), NOW())
    RETURNING id, username`);
  const id = Object.fromEntries(ids.rows.map((row) => [row.username, row.id]));
  const group = await db.query(
    `INSERT INTO family_groups (name, owner_id, invite_code) VALUES ('Kowalscy', $1, 'AB12CD34') RETURNING id`,
    [id.wlasciciel]
  );
  const groupId = group.rows[0].id;
  await db.query(
    `INSERT INTO family_members (group_id, user_id, role) VALUES ($1, $2, 'parent'), ($1, $3, 'family_member'), ($1, $4, 'child'), ($1, $5, 'family_member')`,
    [groupId, id.wlasciciel, id.czlonek, id.dziecko, id.duch]
  );
  await db.query(`UPDATE users SET ghost_until = NOW() + INTERVAL '2 hours' WHERE id = $1`, [id.duch]);
  const ping = await db.query(
    `INSERT INTO family_pings (group_id, sender_id, recipient_id) VALUES ($1, $2, $3) RETURNING id`,
    [groupId, id.wlasciciel, id.czlonek]
  );

  const migration = fs.readFileSync(path.join(ROOT, 'db/migrations/2026-11-05_alerts_inbox_invites.sql'), 'utf8');
  await db.query(migration);
  const firstExpiry = (await db.query(`SELECT invite_expires_at FROM family_groups WHERE id = $1`, [groupId])).rows[0].invite_expires_at;
  await db.query(migration);
  const secondExpiry = (await db.query(`SELECT invite_expires_at FROM family_groups WHERE id = $1`, [groupId])).rows[0].invite_expires_at;
  assert.equal(new Date(firstExpiry).toISOString(), new Date(secondExpiry).toISOString());
  const days = (new Date(firstExpiry) - Date.now()) / 86400000;
  assert.ok(days > 29 && days < 31, `grace ${days}`);
  const copied = await db.query(`SELECT token, platform FROM user_push_tokens WHERE user_id = $1`, [id.wlasciciel]);
  assert.deepEqual(copied.rows, [{ token: 'legacy-owner-token', platform: 'unknown' }]);
  assert.equal((await db.query(`SELECT id FROM family_pings WHERE id = $1`, [ping.rows[0].id])).rowCount, 1);
  const kind = await db.query(`SELECT column_name FROM information_schema.columns WHERE table_name = 'alerts' AND column_name = 'kind'`);
  assert.equal(kind.rowCount, 1);

  process.env.DATABASE_URL = `postgres://ubuntu@/${DB}?host=/var/run/postgresql`;
  process.env.JWT_SECRET = SECRET;
  process.env.FIREBASE_SERVICE_ACCOUNT = '/tmp/besafe-no-such-firebase.json';
  const express = require('express');
  const app = express();
  app.use(express.json());
  app.use('/api/v1/family', require('../src/routes/family'));
  app.use('/api/v1/alerts', require('../src/routes/alerts'));
  app.use('/api/v1/notifications', require('../src/routes/notifications'));
  app.use('/api/v1/users', require('../src/routes/users'));
  const server = await new Promise((resolve) => {
    const listening = app.listen(0, '127.0.0.1', () => resolve(listening));
  });
  const token = (userId, email) => jwt.sign({ id: userId, email }, SECRET);

  try {
    const parentJoin = await httpCall(server, 'POST', '/api/v1/family/groups/join', {
      token: token(id.obcy, 'outsider@example.test'),
      body: { invite_code: 'AB12CD34', role: 'parent' },
    });
    assert.equal(parentJoin.status, 403);

    const garbage = await httpCall(server, 'POST', '/api/v1/family/groups/join/preview', {
      token: token(id.obcy, 'outsider@example.test'),
      body: { invite_code: 'https://evil.example/family/join?code=LEGACY01' },
    });
    assert.equal(garbage.status, 404);
    assert.equal(garbage.json.error, 'Kod jest nieprawidłowy lub wygasł');
    assert.equal(garbage.json.group_name, undefined);

    const preview = await httpCall(server, 'POST', '/api/v1/family/groups/join/preview', {
      token: token(id.obcy, 'outsider@example.test'),
      body: { invite_code: 'https://besafe.org.pl/family/join?code=ab12cd34' },
    });
    assert.equal(preview.status, 200);
    assert.equal(preview.json.group_name, 'Kowalscy');
    assert.equal(preview.json.members, undefined);
    assert.equal(preview.json.phone, undefined);

    const joined = await httpCall(server, 'POST', '/api/v1/family/groups/join', {
      token: token(id.obcy, 'outsider@example.test'),
      body: { invite_code: 'AB12CD34', role: 'family_member' },
    });
    assert.equal(joined.status, 200, JSON.stringify(joined.json));

    await db.query(`UPDATE family_groups SET invite_expires_at = NOW() - INTERVAL '1 minute' WHERE id = $1`, [groupId]);
    const expired = await httpCall(server, 'POST', '/api/v1/family/groups/join/preview', {
      token: token(id.obcy, 'outsider@example.test'),
      body: { invite_code: 'NOTEXIST' },
    });
    const expiredKnown = await httpCall(server, 'POST', '/api/v1/family/groups/join/preview', {
      token: token(id.wlasciciel, 'owner@example.test'),
      body: { invite_code: 'AB12CD34' },
    });
    assert.equal(expired.status, 404);
    assert.equal(expiredKnown.status, 404);
    assert.equal(expired.json.error, expiredKnown.json.error);

    const sos = await httpCall(server, 'POST', '/api/v1/alerts', {
      token: token(id.dziecko, 'child@example.test'),
      body: { category: 'other', kind: 'sos', title: 'Potrzebuję pomocy', description: 'test', lat: 52.2, lng: 21, radius_m: 200 },
    });
    assert.equal(sos.status, 201, JSON.stringify(sos.json));
    assert.equal(sos.json.kind, 'sos');
    const alertId = sos.json.id;

    const allowed = await httpCall(server, 'GET', `/api/v1/alerts/${alertId}/sos-context`, {
      token: token(id.czlonek, 'member@example.test'),
    });
    assert.equal(allowed.status, 200, JSON.stringify(allowed.json));
    assert.equal(Number(allowed.json.lat), 52.2);
    assert.equal(allowed.json.phone, '+48111000003');

    await db.query(
      `INSERT INTO family_visibility (group_id, viewer_id, target_id, field, granted)
       VALUES ($1, $2, $3, 'phone', FALSE)`,
      [groupId, id.czlonek, id.dziecko]
    );
    const hiddenPhone = await httpCall(server, 'GET', `/api/v1/alerts/${alertId}/sos-context`, {
      token: token(id.czlonek, 'member@example.test'),
    });
    assert.equal(hiddenPhone.json.phone, null);

    const removed = await db.query(`DELETE FROM family_members WHERE user_id = $1 RETURNING user_id`, [id.czlonek]);
    assert.equal(removed.rowCount, 1);
    const denied = await httpCall(server, 'GET', `/api/v1/alerts/${alertId}/sos-context`, {
      token: token(id.czlonek, 'member@example.test'),
    });
    assert.equal(denied.status, 404);
    assert.equal(denied.json.lat, undefined);

    const inbox = await db.query(
      `SELECT id, acknowledged_at, is_read FROM notifications WHERE user_id = $1 AND type = 'family_sos' AND source_id = $2`,
      [id.wlasciciel, alertId]
    );
    assert.equal(inbox.rowCount, 1);
    const noteId = inbox.rows[0].id;
    const read = await httpCall(server, 'POST', `/api/v1/notifications/${noteId}/read`, {
      token: token(id.wlasciciel, 'owner@example.test'),
    });
    assert.equal(read.json.is_read, true);
    assert.equal(read.json.acknowledged_at, null);
    const pending = await httpCall(server, 'GET', '/api/v1/notifications/unacked-sos', {
      token: token(id.wlasciciel, 'owner@example.test'),
    });
    assert.equal(pending.json.notifications.length, 1);
    const ack = await httpCall(server, 'POST', `/api/v1/notifications/${noteId}/ack`, {
      token: token(id.wlasciciel, 'owner@example.test'),
    });
    assert.ok(ack.json.acknowledged_at);
    const after = await httpCall(server, 'GET', '/api/v1/notifications/unacked-sos', {
      token: token(id.wlasciciel, 'owner@example.test'),
    });
    assert.equal(after.json.notifications.length, 0);
    const foreign = await httpCall(server, 'POST', `/api/v1/notifications/${noteId}/ack`, {
      token: token(id.obcy, 'outsider@example.test'),
    });
    assert.equal(foreign.status, 404);

    const again = await db.query(
      `INSERT INTO notifications (user_id, type, title, body, data, source_id)
       VALUES ($1, 'family_sos', 'x', 'y', '{}', $2)
       ON CONFLICT (user_id, type, source_id) WHERE source_id IS NOT NULL DO NOTHING
       RETURNING id`,
      [id.wlasciciel, alertId]
    );
    assert.equal(again.rowCount, 0);

    const viewers = await db.query(
      `SELECT m2.user_id AS viewer_id,
              COALESCE(v.granted, TRUE) AS location_granted,
              (u.ghost_until IS NOT NULL AND u.ghost_until > NOW()) AS ghosting
         FROM family_members m1
         JOIN family_members m2 ON m2.group_id = m1.group_id AND m2.user_id <> m1.user_id
         JOIN users u ON u.id = m1.user_id
         LEFT JOIN family_visibility v
           ON v.group_id = m1.group_id AND v.viewer_id = m2.user_id
          AND v.target_id = m1.user_id AND v.field = 'location'
        WHERE m1.user_id = $1`,
      [id.duch]
    );
    const { canReceivePassiveLocation } = require('../src/domain/safetyContracts');
    const allowedViewers = viewers.rows.filter((row) => canReceivePassiveLocation({
      viewerId: row.viewer_id,
      targetId: id.duch,
      locationGranted: row.location_granted === true,
      ghosting: row.ghosting === true,
    }));
    assert.equal(allowedViewers.length, 0);

    const registered = await httpCall(server, 'PUT', '/api/v1/users/me/fcm-token', {
      token: token(id.czlonek, 'member@example.test'),
      body: { fcm_token: 'new-device-token' },
    });
    assert.equal(registered.status, 200, JSON.stringify(registered.json));
    const legacy = await db.query(`SELECT fcm_token FROM users WHERE id = $1`, [id.czlonek]);
    assert.equal(legacy.rows[0].fcm_token, 'new-device-token');
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await db.end();
    const pooled = require('../src/config/db');
    await pooled.pool.end();
    const cleanup = await admin();
    await cleanup.query(
      `SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = $1 AND pid <> pg_backend_pid()`,
      [DB]
    );
    await cleanup.query(`DROP DATABASE IF EXISTS ${DB}`);
    await cleanup.end();
  }
});
