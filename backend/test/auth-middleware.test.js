const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const jwt = require('jsonwebtoken');
const express = require('express');
const { fakeDb, src } = require('./helpers');

const auth = require(src('middleware/auth.js'));

const app = express();
app.get('/private', auth, (req, res) => res.json({ user: req.user }));

beforeEach(() => fakeDb.reset());

test('bez nagłówka Authorization → 401', async () => {
  const res = await request(app).get('/private');
  assert.equal(res.status, 401);
  assert.equal(res.body.error, 'No token');
});

test('zły format nagłówka → 401', async () => {
  const res = await request(app).get('/private').set('Authorization', 'Token abc');
  assert.equal(res.status, 401);
});

test('token podpisany innym sekretem → 401', async () => {
  const token = jwt.sign({ id: 1 }, 'inny-sekret');
  const res = await request(app).get('/private').set('Authorization', `Bearer ${token}`);
  assert.equal(res.status, 401);
  assert.equal(res.body.error, 'Invalid token');
});

test('wygasły token → 401', async () => {
  const token = jwt.sign({ id: 1, exp: Math.floor(Date.now() / 1000) - 60 }, process.env.JWT_SECRET);
  const res = await request(app).get('/private').set('Authorization', `Bearer ${token}`);
  assert.equal(res.status, 401);
});

test('poprawny token → przepuszcza i ustawia req.user', async () => {
  const token = jwt.sign({ id: 42, email: 'a@b.pl' }, process.env.JWT_SECRET);
  const res = await request(app).get('/private').set('Authorization', `Bearer ${token}`);
  assert.equal(res.status, 200);
  assert.equal(res.body.user.id, 42);
  assert.equal(res.body.user.email, 'a@b.pl');
});
