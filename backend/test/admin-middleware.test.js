const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const express = require('express');
const { fakeDb, src } = require('./helpers');

const requireAdmin = require(src('middleware/requireAdmin.js'));

function appAs(user) {
  const app = express();
  app.get('/admin', (req, _res, next) => { req.user = user; next(); }, requireAdmin, (_req, res) => res.json({ ok: true }));
  return app;
}

beforeEach(() => fakeDb.reset());

test('brak użytkownika → 401', async () => {
  const res = await request(appAs(undefined)).get('/admin');
  assert.equal(res.status, 401);
});

test('użytkownik bez is_admin → 403', async () => {
  fakeDb.responses.push({ rows: [{ is_admin: false }] });
  const res = await request(appAs({ id: 5 })).get('/admin');
  assert.equal(res.status, 403);
  assert.deepEqual(fakeDb.calls[0].params, [5]);
});

test('admin → 200', async () => {
  fakeDb.responses.push({ rows: [{ is_admin: true }] });
  const res = await request(appAs({ id: 1 })).get('/admin');
  assert.equal(res.status, 200);
});

test('błąd bazy → 500 bez szczegółów', async () => {
  fakeDb.responses.push(new Error('db down'));
  const orig = console.error; console.error = () => {};
  const res = await request(appAs({ id: 1 })).get('/admin');
  console.error = orig;
  assert.equal(res.status, 500);
  assert.equal(res.body.error, 'Internal error');
});
