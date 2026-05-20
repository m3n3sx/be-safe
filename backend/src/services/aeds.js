// F11: AED Locator - sync defibrillator locations from OpenStreetMap (Overpass API)
const https = require('https');
const db = require('../config/db');

// Multiple Overpass endpoints — try in order, fallback on 504/timeout
const OVERPASS_ENDPOINTS = [
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass-api.de/api/interpreter',
  'https://overpass.openstreetmap.fr/api/interpreter',
];
// Poland bbox: minLat=49.0, minLng=14.0, maxLat=55.0, maxLng=24.5
const POLAND_QUERY = '[out:json][timeout:60];(node["emergency"="defibrillator"](49.0,14.0,55.0,24.5);node["medical_equipment"="defibrillator"](49.0,14.0,55.0,24.5););out;';

function httpsPost(url, body) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const payload = `data=${encodeURIComponent(body)}`;
    const req = https.request({
      hostname: u.hostname,
      path: u.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(payload),
        'User-Agent': 'be:Safe/1.0 (https://besafe.org.pl; support@besafe.org.pl)',
      },
      timeout: 130000,
    }, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) resolve(data);
        else reject(new Error(`HTTP ${res.statusCode}: ${data.slice(0, 200)}`));
      });
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('Timeout')); });
    req.write(payload);
    req.end();
  });
}

async function fetchFromOverpass() {
  let lastErr = null;
  for (const url of OVERPASS_ENDPOINTS) {
    try {
      console.log(`[aeds] Trying ${url}`);
      const raw = await httpsPost(url, POLAND_QUERY);
      // Detect HTML error response (Overpass returns 200 with HTML on errors sometimes)
      if (raw.trim().startsWith('<')) {
        console.warn('[aeds] Got HTML response, trying next endpoint');
        lastErr = new Error('HTML response (likely busy)');
        continue;
      }
      return raw;
    } catch (e) {
      console.warn(`[aeds] ${url} failed: ${e.message.slice(0, 100)}`);
      lastErr = e;
    }
  }
  throw lastErr || new Error('All endpoints failed');
}

async function syncAeds() {
  console.log('[aeds] Fetching from Overpass API…');
  try {
    const raw = await fetchFromOverpass();
    const json = JSON.parse(raw);
    const elements = json.elements || [];
    console.log(`[aeds] Got ${elements.length} elements`);
    if (!elements.length) return { ok: false, count: 0, error: 'empty response' };

    let upserts = 0;
    for (const el of elements) {
      if (el.type !== 'node' || !el.lat || !el.lon) continue;
      const sourceId = String(el.id);
      const tags = el.tags || {};
      const description = tags.description || tags['defibrillator:location'] || tags.note || null;
      const address = [tags['addr:street'], tags['addr:housenumber'], tags['addr:city']]
        .filter(Boolean).join(' ') || null;
      const operator = tags.operator || null;
      const openingHours = tags.opening_hours || null;
      const indoor = tags.indoor === 'yes' ? true : (tags.indoor === 'no' ? false : null);

      await db.query(
        `INSERT INTO aeds (source, source_id, location, description, address, operator, opening_hours, indoor, last_synced_at)
         VALUES ('osm', $1, ST_SetSRID(ST_MakePoint($2, $3), 4326)::geography, $4, $5, $6, $7, $8, NOW())
         ON CONFLICT (source, source_id) DO UPDATE SET
           location = EXCLUDED.location,
           description = EXCLUDED.description,
           address = EXCLUDED.address,
           operator = EXCLUDED.operator,
           opening_hours = EXCLUDED.opening_hours,
           indoor = EXCLUDED.indoor,
           last_synced_at = NOW()`,
        [sourceId, el.lon, el.lat, description, address, operator, openingHours, indoor]
      );
      upserts++;
    }
    console.log(`[aeds] Upserted ${upserts} AEDs`);
    return { ok: true, count: upserts };
  } catch (e) {
    console.error('[aeds] Sync error:', e.message);
    return { ok: false, error: e.message };
  }
}

module.exports = { syncAeds };
