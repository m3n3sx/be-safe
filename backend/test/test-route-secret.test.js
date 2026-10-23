const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const { fakeDb, src, appWith } = require('./helpers');

// Moduł czyta TEST_RESET_SECRET przy załadowaniu – ładujemy go dwa razy
// z różną konfiguracją.
function loadTestRouter(secret) {
  const id = require.resolve(src('routes/test.js'));
  delete require.cache[id];
  if (secret === undefined) delete process.env.TEST_RESET_SECRET;
  else process.env.TEST_RESET_SECRET = secret;
  return appWith('/api/v1/test', require(id));
}

beforeEach(() => fakeDb.reset());

test('bez skonfigurowanego sekretu endpoint jest wyłączony → 503', async () => {
  const app = loadTestRouter(undefined);
  const res = await request(app).post('/api/v1/test/reset-persona').send({ username: 'p1' });
  assert.equal(res.status, 503);
  assert.equal(fakeDb.calls.length, 0);
});

test('zły sekret → 401 i brak zapytań do bazy', async () => {
  const app = loadTestRouter('poprawny-sekret');
  const res = await request(app).post('/api/v1/test/reset-persona')
    .set('X-Test-Secret', 'zly').send({ username: 'p1' });
  assert.equal(res.status, 401);
  assert.equal(fakeDb.calls.length, 0);
});

test('dobry sekret, brak username → 400', async () => {
  const app = loadTestRouter('poprawny-sekret');
  const res = await request(app).post('/api/v1/test/reset-persona')
    .set('X-Test-Secret', 'poprawny-sekret').send({});
  assert.equal(res.status, 400);
});

test('dobry sekret, użytkownik nie jest testowy → 404', async () => {
  const app = loadTestRouter('poprawny-sekret');
  fakeDb.responses.push({ rows: [] });
  const res = await request(app).post('/api/v1/test/reset-persona')
    .set('X-Test-Secret', 'poprawny-sekret').send({ username: 'prawdziwy' });
  assert.equal(res.status, 404);
  assert.match(fakeDb.calls[0].sql, /is_test = TRUE/);
});
