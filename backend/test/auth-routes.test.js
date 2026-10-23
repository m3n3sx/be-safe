const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { fakeDb, src, appWith } = require('./helpers');

const app = appWith('/api/v1/auth', require(src('routes/auth.js')));

beforeEach(() => fakeDb.reset());

test('rejestracja bez wymaganych pól → 400', async () => {
  const res = await request(app).post('/api/v1/auth/register').send({ email: 'a@b.pl' });
  assert.equal(res.status, 400);
  assert.equal(fakeDb.calls.length, 0);
});

test('rejestracja ze zbyt krótkim hasłem → 400', async () => {
  const res = await request(app).post('/api/v1/auth/register')
    .send({ email: 'a@b.pl', password: '123', username: 'ala' });
  assert.equal(res.status, 400);
  assert.equal(res.body.error, 'Password too short');
});

test('rejestracja OK → 201, token i hasło zahashowane', async () => {
  fakeDb.responses.push({ rows: [{ id: 7, email: 'a@b.pl', username: 'ala', email_verified: false }] });
  fakeDb.responses.push({ rows: [] }); // token weryfikacyjny
  const res = await request(app).post('/api/v1/auth/register')
    .send({ email: 'a@b.pl', password: 'dobrehaslo', username: 'ala' });
  assert.equal(res.status, 201);
  const payload = jwt.verify(res.body.token, process.env.JWT_SECRET);
  assert.equal(payload.id, 7);
  const insert = fakeDb.calls[0];
  assert.match(insert.sql, /INSERT INTO users/);
  assert.notEqual(insert.params[1], 'dobrehaslo');
  assert.ok(await bcrypt.compare('dobrehaslo', insert.params[1]));
});

test('rejestracja na zajęty e-mail → 409', async () => {
  const dup = Object.assign(new Error('duplicate'), { code: '23505' });
  fakeDb.responses.push(dup);
  const res = await request(app).post('/api/v1/auth/register')
    .send({ email: 'a@b.pl', password: 'dobrehaslo', username: 'ala' });
  assert.equal(res.status, 409);
});

test('logowanie: nieznany e-mail → 401', async () => {
  fakeDb.responses.push({ rows: [] });
  const res = await request(app).post('/api/v1/auth/login').send({ email: 'x@y.pl', password: 'cokolwiek' });
  assert.equal(res.status, 401);
});

test('logowanie: złe hasło → 401', async () => {
  const hash = await bcrypt.hash('poprawne', 4);
  fakeDb.responses.push({ rows: [{ id: 3, email: 'x@y.pl', password_hash: hash }] });
  const res = await request(app).post('/api/v1/auth/login').send({ email: 'x@y.pl', password: 'zle' });
  assert.equal(res.status, 401);
});

test('logowanie OK → token, bez password_hash w odpowiedzi', async () => {
  const hash = await bcrypt.hash('poprawne', 4);
  fakeDb.responses.push({ rows: [{ id: 3, email: 'x@y.pl', username: 'x', password_hash: hash }] });
  const res = await request(app).post('/api/v1/auth/login').send({ email: 'x@y.pl', password: 'poprawne' });
  assert.equal(res.status, 200);
  assert.equal(res.body.user.password_hash, undefined);
  assert.equal(jwt.verify(res.body.token, process.env.JWT_SECRET).id, 3);
});

test('reset hasła: brak tokenu → 400', async () => {
  const res = await request(app).post('/api/v1/auth/reset-password').send({ password: 'nowehaslo' });
  assert.equal(res.status, 400);
});

test('forgot-password: zawsze 200 (nie zdradza czy konto istnieje)', async () => {
  fakeDb.responses.push({ rows: [] });
  const res = await request(app).post('/api/v1/auth/forgot-password').send({ email: 'nieistnieje@b.pl' });
  assert.equal(res.status, 200);
  assert.equal(res.body.ok, true);
});

test('refresh bez tokenu → 401', async () => {
  const res = await request(app).post('/api/v1/auth/refresh');
  assert.equal(res.status, 401);
});
