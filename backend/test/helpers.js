// Wspólne narzędzia do testów: atrapa bazy danych i serwisu e-mail,
// żeby testy nie łączyły się z prawdziwą bazą ani nie wysyłały maili.
const path = require('path');
const express = require('express');

process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-jwt-secret';
process.env.JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1h';
process.env.EMAIL_DISABLED = '1';

const src = (p) => path.join(__dirname, '..', 'src', p);

// Atrapa db: kolejka odpowiedzi + zapis wywołań.
const fakeDb = {
  calls: [],
  responses: [],
  query(sql, params) {
    fakeDb.calls.push({ sql, params });
    const next = fakeDb.responses.length ? fakeDb.responses.shift() : { rows: [] };
    if (next instanceof Error) return Promise.reject(next);
    return Promise.resolve(next);
  },
  reset() {
    fakeDb.calls = [];
    fakeDb.responses = [];
  },
};

const fakeEmail = new Proxy({}, { get: () => () => Promise.resolve() });

function mockModule(file, exports) {
  const id = require.resolve(src(file));
  require.cache[id] = { id, filename: id, loaded: true, exports };
}

mockModule('config/db.js', fakeDb);
mockModule('services/email.js', fakeEmail);

function appWith(mountPath, router) {
  const app = express();
  app.use(express.json());
  app.use(mountPath, router);
  return app;
}

module.exports = { fakeDb, src, appWith };
