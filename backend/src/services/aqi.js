// F17: Warstwa środowiskowa — jakość powietrza z GIOŚ (Polska)
// API: https://api.gios.gov.pl/pjp-api/v1/rest/ (JSON-LD, polskie klucze)
// Limits: stacje 2 req/min, aqindex 1500 req/min
const https = require('https');
const db = require('../config/db');

const GIOS_BASE = 'https://api.gios.gov.pl/pjp-api/v1/rest';
const USER_AGENT = 'be:Safe/1.0 (https://besafe.org.pl)';

function httpsGet(url) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, {
      method: 'GET',
      headers: { 'User-Agent': USER_AGENT, 'Accept': 'application/ld+json' },
      timeout: 30000,
    }, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) resolve(data);
        else reject(new Error(`HTTP ${res.statusCode}`));
      });
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('Timeout')); });
    req.end();
  });
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

// Sync wszystkich stacji (paginacja, max 500/page). Limit 2 req/min — robimy ostrożnie.
async function syncStations() {
  console.log('[aqi] Fetching GIOŚ stations…');
  try {
    // Pobierz wszystko 1 stroną size=500 (ok 290 stacji w PL)
    const raw = await httpsGet(`${GIOS_BASE}/station/findAll?size=500&page=0`);
    const data = JSON.parse(raw);
    const list = data['Lista stacji pomiarowych'] || [];
    if (!Array.isArray(list) || list.length === 0) throw new Error('Empty station list');
    let upserted = 0;
    for (const s of list) {
      const id = s['Identyfikator stacji'];
      const lat = parseFloat(s['WGS84 φ N']);
      const lng = parseFloat(s['WGS84 λ E']);
      if (!isFinite(lat) || !isFinite(lng) || !id) continue;
      const name = s['Nazwa stacji'] || null;
      const city = s['Nazwa miasta'] || null;
      const address = s['Ulica'] || null;
      await db.query(
        `INSERT INTO air_quality_stations (id, name, location, city, address, last_synced_at)
         VALUES ($1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography, $5, $6, NOW())
         ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, location=EXCLUDED.location,
           city=EXCLUDED.city, address=EXCLUDED.address, last_synced_at=NOW()`,
        [id, name, lng, lat, city, address]
      );
      upserted++;
    }
    console.log(`[aqi] Synced ${upserted} stations`);
    return upserted;
  } catch (e) {
    console.error('[aqi] syncStations error:', e.message);
    return 0;
  }
}

async function fetchStationIndex(stationId) {
  try {
    const raw = await httpsGet(`${GIOS_BASE}/aqindex/getIndex/${stationId}`);
    const data = JSON.parse(raw);
    return data.AqIndex || null;
  } catch (_) {
    return null;
  }
}

const READING_TTL_MIN = 30;

async function getReadingsNear(lat, lng, radiusM = 30000, limit = 5) {
  const { rows } = await db.query(
    `SELECT s.id, s.name, s.city, s.address,
            ST_Y(s.location::geometry) AS lat,
            ST_X(s.location::geometry) AS lng,
            ST_Distance(s.location, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography) AS distance_m,
            r.aqi_index, r.aqi_label, r.pm10, r.pm25, r.no2, r.so2, r.o3, r.measured_at, r.fetched_at
     FROM air_quality_stations s
     LEFT JOIN air_quality_readings r ON r.station_id = s.id
     WHERE ST_DWithin(s.location, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography, $3)
     ORDER BY distance_m ASC
     LIMIT $4`,
    [lat, lng, radiusM, limit]
  );
  const now = Date.now();
  const stale = rows.filter(r => !r.fetched_at || (now - new Date(r.fetched_at).getTime()) > READING_TTL_MIN * 60 * 1000);
  if (stale.length) {
    // GIOŚ limit aqindex 1500/min — bezpiecznie sekwencyjnie
    for (const st of stale.slice(0, 5)) {
      const idx = await fetchStationIndex(st.id);
      if (!idx) continue;
      const aqi = idx['Wartość indeksu'];
      const label = idx['Nazwa kategorii indeksu'] || null;
      const measured = idx['Data wykonania obliczeń indeksu'] || null;
      const pm10 = idx['Wartość indeksu dla wskaźnika PM10'];
      const pm25 = idx['Wartość indeksu dla wskaźnika PM2.5'];
      const no2 = idx['Wartość indeksu dla wskaźnika NO2'];
      const so2 = idx['Wartość indeksu dla wskaźnika SO2'];
      const o3 = idx['Wartość indeksu dla wskaźnika O3'];
      await db.query(
        `INSERT INTO air_quality_readings (station_id, aqi_index, aqi_label, pm10, pm25, no2, so2, o3, measured_at, fetched_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,NOW())
         ON CONFLICT (station_id) DO UPDATE SET aqi_index=EXCLUDED.aqi_index, aqi_label=EXCLUDED.aqi_label,
           pm10=EXCLUDED.pm10, pm25=EXCLUDED.pm25, no2=EXCLUDED.no2, so2=EXCLUDED.so2, o3=EXCLUDED.o3,
           measured_at=EXCLUDED.measured_at, fetched_at=NOW()`,
        [st.id, aqi ?? null, label, pm10 ?? null, pm25 ?? null, no2 ?? null, so2 ?? null, o3 ?? null, measured]
      );
      // throttle delikatnie (30/min = 2s) — zachowawczo
      await sleep(150);
    }
    const { rows: fresh } = await db.query(
      `SELECT s.id, s.name, s.city, s.address,
              ST_Y(s.location::geometry) AS lat,
              ST_X(s.location::geometry) AS lng,
              ST_Distance(s.location, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography) AS distance_m,
              r.aqi_index, r.aqi_label, r.pm10, r.pm25, r.no2, r.so2, r.o3, r.measured_at, r.fetched_at
       FROM air_quality_stations s
       LEFT JOIN air_quality_readings r ON r.station_id = s.id
       WHERE ST_DWithin(s.location, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography, $3)
       ORDER BY distance_m ASC LIMIT $4`,
      [lat, lng, radiusM, limit]
    );
    return fresh;
  }
  return rows;
}

module.exports = { syncStations, getReadingsNear };
