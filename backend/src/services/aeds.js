// F11: AED Locator — synchronizacja lokalizacji defibrylatorów z OpenStreetMap.
//
// Źródła (w kolejności):
//   1) OpenAEDMap (OpenStreetMap Polska) — gotowy plik GeoJSON z AED w Polsce,
//      jedno lekkie GET dziennie, cache na Cloudflare. Dane: © współtwórcy OpenStreetMap, ODbL.
//   2) Publiczne instancje Overpass API jako fallback (zgodnie z ich zasadami użycia:
//      identyfikujący User-Agent, brak zapytań równoległych, max 1 pełne zapytanie na dobę).
//
// overpass.openstreetmap.fr od 2026 obsługuje tylko „white-listed usages” (stąd HTTP 403),
// a overpass.kumi.systems zmienił nazwę na overpass.private.coffee — obie pozycje usunięte.
const https = require('https');
const db = require('../config/db');

const USER_AGENT = 'be:Safe/1.0 (https://besafe.org.pl; support@besafe.org.pl)';
const ATTRIBUTION = '© współtwórcy OpenStreetMap (ODbL), via OpenAEDMap.org';

const GEOJSON_URL = process.env.AED_GEOJSON_URL || 'https://openaedmap.org/api/v1/countries/PL.geojson';

const OVERPASS_ENDPOINTS = (process.env.AED_OVERPASS_ENDPOINTS
  ? process.env.AED_OVERPASS_ENDPOINTS.split(',').map((s) => s.trim()).filter(Boolean)
  : [
    'https://overpass.private.coffee/api/interpreter',
    'https://overpass-api.de/api/interpreter',
    'https://ovp.dresel.systems/api/interpreter', // ekstrakt Europy, aktualizowany raz na dobę
  ]);

// Poland bbox: minLat=49.0, minLng=14.0, maxLat=55.0, maxLng=24.5
const POLAND_QUERY = '[out:json][timeout:120];(node["emergency"="defibrillator"](49.0,14.0,55.0,24.5);node["medical_equipment"="defibrillator"](49.0,14.0,55.0,24.5););out;';

// Nie synchronizuj częściej niż co N godzin — także po restarcie backendu.
const MIN_INTERVAL_HOURS = parseFloat(process.env.AED_SYNC_MIN_INTERVAL_HOURS || '20');
// Odrzuć podejrzanie mały wynik (np. ucięta odpowiedź), żeby nie „odświeżać” połowy danych.
const MIN_ELEMENTS = parseInt(process.env.AED_SYNC_MIN_ELEMENTS || '1000', 10);
const BATCH_SIZE = 500;

function httpsRequest(url, { method = 'GET', body = null, timeout = 130000 } = {}) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const headers = { 'User-Agent': USER_AGENT, Accept: 'application/json, application/geo+json' };
    let payload = null;
    if (body != null) {
      payload = `data=${encodeURIComponent(body)}`;
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
      headers['Content-Length'] = Buffer.byteLength(payload);
    }
    const req = https.request({
      hostname: u.hostname, path: u.pathname + u.search, method, headers, timeout,
    }, (res) => {
      // proste przekierowania (np. po zmianie domeny)
      if ([301, 302, 307, 308].includes(res.statusCode) && res.headers.location) {
        res.resume();
        return resolve(httpsRequest(new URL(res.headers.location, url).toString(), { method, body, timeout }));
      }
      let data = '';
      res.setEncoding('utf8');
      res.on('data', (c) => (data += c));
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) resolve(data);
        else {
          const err = new Error(`HTTP ${res.statusCode}: ${data.slice(0, 200)}`);
          err.status = res.statusCode;
          reject(err);
        }
      });
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('Timeout')); });
    if (payload) req.write(payload);
    req.end();
  });
}

function normTags(tags) {
  const t = tags || {};
  const description = t.description || t['defibrillator:location:pl'] || t['defibrillator:location'] || t.note || null;
  const address = [t['addr:street'] || t['addr:place'], t['addr:housenumber'], t['addr:city']]
    .filter(Boolean).join(' ') || null;
  const indoor = t.indoor === 'yes' ? true : (t.indoor === 'no' ? false : null);
  return {
    description, address, operator: t.operator || null, opening_hours: t.opening_hours || null, indoor,
  };
}

function validCoord(lat, lon) {
  return Number.isFinite(lat) && Number.isFinite(lon) && Math.abs(lat) <= 90 && Math.abs(lon) <= 180;
}

// GeoJSON OpenAEDMap → [{ sourceId, lat, lon, ...tags }]
function parseGeoJson(raw) {
  const json = typeof raw === 'string' ? JSON.parse(raw) : raw;
  if (!json || !Array.isArray(json.features)) throw new Error('GeoJSON without features');
  const out = [];
  for (const f of json.features) {
    const p = (f && f.properties) || {};
    const g = f && f.geometry;
    if (!g || g.type !== 'Point' || !Array.isArray(g.coordinates)) continue;
    const [lon, lat] = g.coordinates.map(Number);
    if (!validCoord(lat, lon) || p['@osm_id'] == null) continue;
    const type = p['@osm_type'] || 'node';
    // node → samo id (zgodne z dotychczasowymi rekordami z Overpass), inne typy z prefiksem
    const sourceId = type === 'node' ? String(p['@osm_id']) : `${type}/${p['@osm_id']}`;
    out.push({ sourceId, lat, lon, ...normTags(p) });
  }
  return out;
}

// Overpass JSON → [{ sourceId, lat, lon, ...tags }]
function parseOverpass(raw) {
  if (typeof raw === 'string' && raw.trim().startsWith('<')) throw new Error('HTML response (likely busy)');
  const json = typeof raw === 'string' ? JSON.parse(raw) : raw;
  if (json && json.remark && /runtime error|timed out|out of memory/i.test(json.remark)) {
    throw new Error(`Overpass remark: ${json.remark.slice(0, 120)}`);
  }
  const out = [];
  for (const el of (json && json.elements) || []) {
    if (el.type !== 'node') continue;
    const lat = Number(el.lat); const lon = Number(el.lon);
    if (!validCoord(lat, lon)) continue;
    out.push({ sourceId: String(el.id), lat, lon, ...normTags(el.tags) });
  }
  return out;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function fetchAeds({ request = httpsRequest, wait = sleep, log = console } = {}) {
  const errors = [];
  try {
    log.log(`[aeds] Fetching ${GEOJSON_URL}`);
    const items = parseGeoJson(await request(GEOJSON_URL, { timeout: 90000 }));
    if (items.length >= MIN_ELEMENTS) return { source: 'openaedmap', items };
    throw new Error(`too few features (${items.length})`);
  } catch (e) {
    log.warn(`[aeds] OpenAEDMap failed: ${String(e.message).slice(0, 120)}`);
    errors.push(`openaedmap: ${e.message}`);
  }
  // Fallback: Overpass, sekwencyjnie (bez zapytań równoległych).
  for (const url of OVERPASS_ENDPOINTS) {
    try {
      log.log(`[aeds] Trying ${url}`);
      const items = parseOverpass(await request(url, { method: 'POST', body: POLAND_QUERY, timeout: 130000 }));
      if (items.length >= MIN_ELEMENTS) return { source: url, items };
      throw new Error(`too few elements (${items.length})`);
    } catch (e) {
      log.warn(`[aeds] ${url} failed: ${String(e.message).slice(0, 120)}`);
      errors.push(`${url}: ${e.message}`);
      // Zasady overpass-api.de: po 429/406/503 odczekaj zanim spróbujesz dalej.
      if ([429, 406, 503].includes(e.status)) await wait(30000);
    }
  }
  const err = new Error('All AED sources failed');
  err.details = errors;
  throw err;
}

async function lastSyncAgeHours(dbc) {
  const { rows } = await dbc.query("SELECT MAX(last_synced_at) AS last FROM aeds WHERE source = 'osm'");
  const last = rows[0] && rows[0].last;
  if (!last) return Infinity;
  return (Date.now() - new Date(last).getTime()) / 3600000;
}

async function upsertBatch(dbc, batch) {
  await dbc.query(
    `INSERT INTO aeds (source, source_id, location, description, address, operator, opening_hours, indoor, last_synced_at)
     SELECT 'osm', t.sid, ST_SetSRID(ST_MakePoint(t.lon, t.lat), 4326)::geography,
            t.descr, t.addr, t.op, t.oh, t.indoor, NOW()
     FROM unnest($1::text[], $2::float8[], $3::float8[], $4::text[], $5::text[], $6::text[], $7::text[], $8::boolean[])
          AS t(sid, lon, lat, descr, addr, op, oh, indoor)
     ON CONFLICT (source, source_id) DO UPDATE SET
       location = EXCLUDED.location,
       description = EXCLUDED.description,
       address = EXCLUDED.address,
       operator = EXCLUDED.operator,
       opening_hours = EXCLUDED.opening_hours,
       indoor = EXCLUDED.indoor,
       last_synced_at = NOW()`,
    [
      batch.map((a) => a.sourceId), batch.map((a) => a.lon), batch.map((a) => a.lat),
      batch.map((a) => a.description), batch.map((a) => a.address), batch.map((a) => a.operator),
      batch.map((a) => a.opening_hours), batch.map((a) => a.indoor),
    ]
  );
}

let running = false;

/**
 * @param {object} [opts]
 * @param {boolean} [opts.force] pomiń sprawdzenie świeżości danych
 */
async function syncAeds(opts = {}) {
  const { force = false, dbc = db, request, wait, log = console } = opts;
  if (running) {
    log.log('[aeds] Sync already running, skipping');
    return { ok: false, skipped: 'running' };
  }
  running = true;
  try {
    if (!force) {
      const age = await lastSyncAgeHours(dbc);
      if (age < MIN_INTERVAL_HOURS) {
        log.log(`[aeds] Data is fresh (${age.toFixed(1)} h old), skipping sync`);
        return { ok: true, skipped: 'fresh', ageHours: age };
      }
    }
    const { source, items } = await fetchAeds({ request, wait, log });
    // deduplikacja (jeden rekord nie może być aktualizowany 2x w jednym INSERT ... ON CONFLICT)
    const byId = new Map();
    for (const a of items) byId.set(a.sourceId, a);
    const unique = [...byId.values()];
    for (let i = 0; i < unique.length; i += BATCH_SIZE) {
      await upsertBatch(dbc, unique.slice(i, i + BATCH_SIZE));
    }
    log.log(`[aeds] Upserted ${unique.length} AEDs from ${source}`);
    return { ok: true, count: unique.length, source };
  } catch (e) {
    log.error('[aeds] Sync error:', e.message, e.details ? JSON.stringify(e.details).slice(0, 400) : '');
    return { ok: false, error: e.message };
  } finally {
    running = false;
  }
}

module.exports = {
  syncAeds, fetchAeds, parseGeoJson, parseOverpass, ATTRIBUTION, OVERPASS_ENDPOINTS, GEOJSON_URL,
};
