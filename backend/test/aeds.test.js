// Testy synchronizacji AED: node --test (bez sieci i bez bazy).
const test = require('node:test');
const assert = require('node:assert');
const path = require('node:path');

process.env.AED_SYNC_MIN_ELEMENTS = '2';
const dbPath = require.resolve(path.join(__dirname, '..', 'src', 'config', 'db'));
require.cache[dbPath] = { id: dbPath, filename: dbPath, loaded: true, exports: { query: async () => { throw new Error('real db used'); } } };

const aeds = require('../src/services/aeds');
const quiet = { log() {}, warn() {}, error() {} };

const geojson = JSON.stringify({
  type: 'FeatureCollection',
  features: [
    { type: 'Feature', geometry: { type: 'Point', coordinates: [19.5168185, 49.5878956] },
      properties: { '@osm_id': 477958354, '@osm_type': 'node', indoor: 'yes', operator: 'PTTK', description: 'Schronisko', opening_hours: '24/7' } },
    { type: 'Feature', geometry: { type: 'Point', coordinates: [21.0, 52.2] },
      properties: { '@osm_id': 99, '@osm_type': 'way', indoor: 'no', 'defibrillator:location': 'Przy wejściu', 'addr:street': 'Marszałkowska', 'addr:housenumber': '1', 'addr:city': 'Warszawa' } },
    { type: 'Feature', geometry: { type: 'Point', coordinates: [21.0, 52.2] }, properties: {} },
    { type: 'Feature', geometry: null, properties: { '@osm_id': 5 } },
  ],
});
const overpass = JSON.stringify({ elements: [
  { type: 'node', id: 1, lat: 52.1, lon: 21.1, tags: { indoor: 'no' } },
  { type: 'node', id: 2, lat: 50.1, lon: 19.9, tags: {} },
  { type: 'way', id: 3 },
] });

function fakeDb(lastSyncedAt) {
  const calls = [];
  return {
    calls,
    async query(sql, params) {
      calls.push({ sql, params });
      if (/MAX\(last_synced_at\)/.test(sql)) return { rows: [{ last: lastSyncedAt }] };
      if (/INSERT INTO aeds/.test(sql)) return { rows: [], rowCount: params[0].length };
      throw new Error('unexpected sql ' + sql);
    },
  };
}

test('parseGeoJson maps OpenAEDMap features and keeps node ids compatible', () => {
  const items = aeds.parseGeoJson(geojson);
  assert.equal(items.length, 2);
  assert.deepEqual(items[0], { sourceId: '477958354', lat: 49.5878956, lon: 19.5168185, description: 'Schronisko', address: null, operator: 'PTTK', opening_hours: '24/7', indoor: true });
  assert.equal(items[1].sourceId, 'way/99');
  assert.equal(items[1].description, 'Przy wejściu');
  assert.equal(items[1].address, 'Marszałkowska 1 Warszawa');
  assert.equal(items[1].indoor, false);
});

test('parseOverpass rejects HTML and keeps only nodes', () => {
  assert.throws(() => aeds.parseOverpass('<html>busy</html>'), /HTML/);
  const items = aeds.parseOverpass(overpass);
  assert.deepEqual(items.map((i) => i.sourceId), ['1', '2']);
});

test('no whitelist-only or renamed Overpass endpoints', () => {
  assert.ok(!aeds.OVERPASS_ENDPOINTS.some((u) => /openstreetmap\.fr|kumi\.systems/.test(u)));
});

test('skips sync when data is fresh (e.g. right after a restart)', async () => {
  const dbc = fakeDb(new Date(Date.now() - 2 * 3600e3));
  let requested = 0;
  const r = await aeds.syncAeds({ dbc, request: async () => { requested++; return geojson; }, log: quiet });
  assert.equal(r.skipped, 'fresh');
  assert.equal(requested, 0);
});

test('syncs from OpenAEDMap with batched upsert when data is stale', async () => {
  const dbc = fakeDb(new Date(Date.now() - 30 * 3600e3));
  const urls = [];
  const r = await aeds.syncAeds({ dbc, request: async (url) => { urls.push(url); return geojson; }, log: quiet });
  assert.deepEqual(r, { ok: true, count: 2, source: 'openaedmap' });
  assert.deepEqual(urls, [aeds.GEOJSON_URL]);
  const inserts = dbc.calls.filter((c) => /INSERT INTO aeds/.test(c.sql));
  assert.equal(inserts.length, 1);
  assert.deepEqual(inserts[0].params[0], ['477958354', 'way/99']);
});

test('falls back to Overpass sequentially and waits after 429', async () => {
  const dbc = fakeDb(null);
  const seen = []; let waited = 0;
  const request = async (url, opts) => {
    seen.push(url);
    if (url === aeds.GEOJSON_URL) throw Object.assign(new Error('HTTP 503'), { status: 503 });
    if (url === aeds.OVERPASS_ENDPOINTS[0]) throw Object.assign(new Error('HTTP 429'), { status: 429 });
    assert.equal(opts.method, 'POST');
    return overpass;
  };
  const r = await aeds.syncAeds({ dbc, request, wait: async () => { waited++; }, log: quiet });
  assert.equal(r.ok, true);
  assert.equal(r.source, aeds.OVERPASS_ENDPOINTS[1]);
  assert.equal(r.count, 2);
  assert.equal(waited, 1); // czekamy tylko po 429 z Overpass, nie po błędzie OpenAEDMap
});

test('reports failure without touching data when all sources fail', async () => {
  const dbc = fakeDb(null);
  const r = await aeds.syncAeds({ dbc, request: async () => { throw new Error('Timeout'); }, wait: async () => {}, log: quiet });
  assert.equal(r.ok, false);
  assert.equal(dbc.calls.filter((c) => /INSERT/.test(c.sql)).length, 0);
});

test('force bypasses freshness check; concurrent run is skipped', async () => {
  const dbc = fakeDb(new Date());
  let release;
  const gate = new Promise((r) => { release = r; });
  const p1 = aeds.syncAeds({ dbc, force: true, request: async () => { await gate; return geojson; }, log: quiet });
  const r2 = await aeds.syncAeds({ dbc, force: true, request: async () => geojson, log: quiet });
  assert.equal(r2.skipped, 'running');
  release();
  assert.equal((await p1).ok, true);
});
