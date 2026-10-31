// Testy POST /auth/google: node --test (bez dodatkowych zależności).
// Tokeny są prawdziwymi JWT RS256 podpisanymi lokalnym kluczem; google-auth-library
// weryfikuje je normalnie (podpis, aud, iss, exp) — podmieniamy tylko pobieranie certów Google.
const test = require('node:test');
const assert = require('node:assert');
const crypto = require('node:crypto');
const path = require('node:path');
const http = require('node:http');
const jwt = require('jsonwebtoken');

process.env.JWT_SECRET = 'test-secret';
process.env.JWT_EXPIRES_IN = '1h';

// --- stub db + email (przed załadowaniem routera) ---
const users = [];
const dbStub = {
  async query(sql, params = []) {
    if (/^\s*SELECT id FROM users WHERE email = \$1/.test(sql)) {
      return { rows: users.filter((u) => u.email === params[0]).map((u) => ({ id: u.id })) };
    }
    if (/^\s*SELECT id FROM users WHERE referral_code/.test(sql)) return { rows: [] };
    if (/^\s*UPDATE users/.test(sql)) return { rows: [] };
    if (/^\s*SELECT .* FROM users WHERE id = \$1/s.test(sql)) {
      return { rows: users.filter((u) => u.id === params[0]) };
    }
    if (/^\s*INSERT INTO users/.test(sql)) {
      const u = { id: users.length + 1, email: params[0], username: params[2], avatar_url: params[3], email_verified: true, referral_code: params[4] };
      users.push(u);
      return { rows: [u] };
    }
    throw new Error('unexpected query in test: ' + sql);
  },
};
function stub(rel, exportsObj) {
  const p = require.resolve(path.join(__dirname, '..', 'src', rel));
  require.cache[p] = { id: p, filename: p, loaded: true, exports: exportsObj };
}
stub('config/db', dbStub);
stub('services/email', { sendWelcomeEmail: async () => {} });

const googleAuth = require('../src/services/google_auth');
const { OAuth2Client } = require('google-auth-library');

const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', { modulusLength: 2048 });
const KID = 'test-kid';
const certClient = new OAuth2Client();
certClient.getFederatedSignonCertsAsync = async () => ({
  certs: { [KID]: publicKey.export({ type: 'spki', format: 'pem' }) },
  format: 'PEM',
});
googleAuth._setClient(certClient);

const WEB_CLIENT = googleAuth.DEFAULT_CLIENT_IDS[0];
function makeToken(over = {}) {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: 'https://accounts.google.com',
    aud: WEB_CLIENT,
    sub: '1234567890',
    email: 'ala@example.com',
    email_verified: true,
    name: 'Ala Kot',
    picture: 'https://example.com/a.png',
    iat: now,
    exp: now + 600,
    ...over,
  };
  return jwt.sign(payload, privateKey, { algorithm: 'RS256', keyid: KID });
}

const express = require('express');
const app = express();
app.use(express.json());
app.use('/auth', require('../src/routes/auth'));
let server;
let base;
test.before(async () => {
  server = http.createServer(app);
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  base = `http://127.0.0.1:${server.address().port}`;
});
test.after(() => server.close());
test.beforeEach(() => {
  users.length = 0;
  delete process.env.GOOGLE_CLIENT_IDS;
  delete process.env.GOOGLE_AUTH_LEGACY_EMAIL_ONLY;
});

async function post(body) {
  const r = await fetch(base + '/auth/google', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
  return { status: r.status, body: await r.json() };
}

test('valid token → login, email taken from token, not from body', async () => {
  const r = await post({ id_token: makeToken(), email: 'ofiara@example.com', display_name: 'Haker' });
  assert.strictEqual(r.status, 201);
  assert.strictEqual(r.body.user.email, 'ala@example.com');
  assert.strictEqual(r.body.user.username, 'Ala Kot');
  const decoded = jwt.verify(r.body.token, 'test-secret');
  assert.strictEqual(decoded.email, 'ala@example.com');
  // drugi login → istniejący user (200)
  const r2 = await post({ idToken: makeToken() });
  assert.strictEqual(r2.status, 200);
  assert.strictEqual(r2.body.user.id, r.body.user.id);
});

test('GIS `credential` field is accepted too', async () => {
  const r = await post({ credential: makeToken() });
  assert.strictEqual(r.status, 201);
});

test('wrong audience → 401', async () => {
  const r = await post({ id_token: makeToken({ aud: 'someone-else.apps.googleusercontent.com' }) });
  assert.strictEqual(r.status, 401);
  assert.strictEqual(users.length, 0);
});

test('GOOGLE_CLIENT_IDS env controls allowed audiences', async () => {
  process.env.GOOGLE_CLIENT_IDS = ' other.apps.googleusercontent.com , second.apps.googleusercontent.com ';
  assert.strictEqual((await post({ id_token: makeToken() })).status, 401);
  assert.strictEqual((await post({ id_token: makeToken({ aud: 'second.apps.googleusercontent.com' }) })).status, 201);
});

test('expired token, bad signature, bad issuer → 401', async () => {
  const now = Math.floor(Date.now() / 1000);
  assert.strictEqual((await post({ id_token: makeToken({ iat: now - 7200, exp: now - 3600 }) })).status, 401);
  const other = crypto.generateKeyPairSync('rsa', { modulusLength: 2048 }).privateKey;
  const forged = jwt.sign({ iss: 'https://accounts.google.com', aud: WEB_CLIENT, sub: '1', email: 'x@example.com', email_verified: true, iat: now, exp: now + 600 }, other, { algorithm: 'RS256', keyid: KID });
  assert.strictEqual((await post({ id_token: forged })).status, 401);
  assert.strictEqual((await post({ id_token: makeToken({ iss: 'https://evil.example.com' }) })).status, 401);
  assert.strictEqual((await post({ id_token: 'not-a-jwt' })).status, 401);
});

test('email_verified=false → 401', async () => {
  const r = await post({ id_token: makeToken({ email_verified: false }) });
  assert.strictEqual(r.status, 401);
});

test('missing token (email only) → 401 when legacy flag is off (default)', async () => {
  const r = await post({ email: 'ofiara@example.com' });
  assert.strictEqual(r.status, 401);
  assert.strictEqual(users.length, 0);
});

test('legacy flag on → email-only login works and logs a warning', async (t) => {
  process.env.GOOGLE_AUTH_LEGACY_EMAIL_ONLY = 'true';
  const warn = t.mock.method(console, 'warn', () => {});
  const r = await post({ email: 'stary@example.com', display_name: 'Stary Klient' });
  assert.strictEqual(r.status, 201);
  assert.strictEqual(r.body.user.email, 'stary@example.com');
  assert.ok(warn.mock.calls.some((c) => String(c.arguments[0]).includes('LEGACY')));
});

test('legacy flag on does NOT rescue an invalid token', async () => {
  process.env.GOOGLE_AUTH_LEGACY_EMAIL_ONLY = 'true';
  const r = await post({ id_token: makeToken({ aud: 'wrong' }), email: 'ofiara@example.com' });
  assert.strictEqual(r.status, 401);
  assert.strictEqual(users.length, 0);
});

test('legacy flag on but no email → 400', async () => {
  process.env.GOOGLE_AUTH_LEGACY_EMAIL_ONLY = 'true';
  assert.strictEqual((await post({})).status, 400);
});
