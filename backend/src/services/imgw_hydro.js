// F16 Rządowa warstwa ostrzeżeń — IMGW ostrzeżenia HYDROLOGICZNE (powodziowe/susza).
//
// RCB nie wystawia publicznego RSS (RCB Alert = system SMS, feedy gov.pl → HTML).
// Jako rządową/oficjalną warstwę zagrożeń używamy publicznego API IMGW-PIB
// (Państwowa Służba Hydrologiczno-Meteorologiczna) — ostrzeżenia hydrologiczne.
//
// API: https://danepubliczne.imgw.pl/api/data/warningshydro/format/json
// Analogiczne do services/imgw.js (meteo). Tworzy alerty kategorii 'flood'
// jako użytkownik systemowy. Cron co 30 min (wywoływane z index.js).
//
// Format itemu: { opublikowano, stopień, data_od, data_do, prawdopodobienstwo,
//   numer, biuro, zdarzenie, przebieg, komentarz, obszary:[{opis, wojewodztwo, kod_zlewni}] }

const db = require('../config/db');

// Województwo (nazwa z IMGW) → przybliżone centrum (miasto wojewódzkie).
const WOJ_CENTERS = {
  'dolnośląskie': { lat: 51.107, lng: 17.038 },
  'kujawsko-pomorskie': { lat: 53.125, lng: 18.011 },
  'lubelskie': { lat: 51.246, lng: 22.568 },
  'lubuskie': { lat: 51.939, lng: 15.505 },
  'łódzkie': { lat: 51.759, lng: 19.456 },
  'małopolskie': { lat: 50.061, lng: 19.937 },
  'mazowieckie': { lat: 52.230, lng: 21.012 },
  'opolskie': { lat: 50.675, lng: 17.921 },
  'podkarpackie': { lat: 50.041, lng: 21.999 },
  'podlaskie': { lat: 53.133, lng: 23.169 },
  'pomorskie': { lat: 54.352, lng: 18.646 },
  'śląskie': { lat: 50.262, lng: 19.021 },
  'świętokrzyskie': { lat: 50.866, lng: 20.629 },
  'warmińsko-mazurskie': { lat: 53.778, lng: 20.480 },
  'wielkopolskie': { lat: 52.408, lng: 16.934 },
  'zachodniopomorskie': { lat: 53.429, lng: 14.552 },
};

function wojToLatLng(woj) {
  if (!woj) return null;
  return WOJ_CENTERS[woj.trim().toLowerCase()] || null;
}

let _systemUserId = null;
async function getSystemUserId() {
  if (_systemUserId) return _systemUserId;
  const { rows } = await db.query(
    `SELECT id FROM users WHERE email = 'system-imgw-hydro@besafe.org.pl' LIMIT 1`
  );
  if (rows[0]) return (_systemUserId = rows[0].id);

  const bcrypt = require('bcryptjs');
  const hash = await bcrypt.hash(require('crypto').randomBytes(32).toString('hex'), 10);
  const { rows: ins } = await db.query(
    `INSERT INTO users (email, password_hash, username, email_verified, referral_code)
     VALUES ('system-imgw-hydro@besafe.org.pl', $1, 'IMGW Hydro', TRUE, 'SYSHYD') RETURNING id`,
    [hash]
  );
  return (_systemUserId = ins[0].id);
}

async function fetchHydro() {
  const url = 'https://danepubliczne.imgw.pl/api/data/warningshydro/format/json';
  const res = await fetch(url);
  if (!res.ok) throw new Error(`IMGW hydro API ${res.status}`);
  return res.json();
}

async function syncHydroWarnings(io) {
  try {
    const warnings = await fetchHydro();
    if (!Array.isArray(warnings)) return;

    const uid = await getSystemUserId();
    let imported = 0;

    for (const w of warnings) {
      const stopien = parseInt(w['stopień'] ?? w.stopien ?? '0', 10);
      // Pomijamy ostrzeżenia o suszy (stopień ujemny) — to nie zagrożenie powodziowe.
      if (stopien < 1) continue;

      const extId = `imgwhydro-${w.numer}-${(w.data_od || '').slice(0, 10)}`;
      const { rows: existing } = await db.query(
        `SELECT id FROM alerts WHERE title LIKE $1 LIMIT 1`,
        [`%[${extId}]%`]
      );
      if (existing[0]) continue;

      const expiresAt = new Date((w.data_do || '').replace(' ', 'T') + '+02:00');
      // data_do bywa '9999-12-31' (bezterminowe) — ograniczamy do 7 dni od teraz.
      const maxExpiry = new Date(Date.now() + 7 * 24 * 3600 * 1000);
      const effectiveExpiry =
        isNaN(expiresAt) || expiresAt > maxExpiry ? maxExpiry : expiresAt;
      if (effectiveExpiry < new Date()) continue;

      const title = `🌊 ${w.zdarzenie || 'Ostrzeżenie hydrologiczne'} — IMGW [${extId}]`;
      const description =
        `${w.przebieg || ''}\n\nStopień: ${stopien}/3 | Prawdopodobieństwo: ${w.prawdopodobienstwo || '?'}%\n` +
        `Opublikowano: ${w.opublikowano || '?'}\nŹródło: ${w.biuro || 'IMGW-PIB'}`;

      // Deduplikacja województw w obrębie jednego ostrzeżenia.
      const wojSet = new Set(
        (w.obszary || []).map((o) => o.wojewodztwo).filter(Boolean)
      );
      for (const woj of [...wojSet].slice(0, 8)) {
        const loc = wojToLatLng(woj);
        if (!loc) continue;
        const { rows: inserted } = await db.query(
          `INSERT INTO alerts (author_id, category, title, description, location, radius_m, expires_at, status)
           VALUES ($1, 'flood', $2, $3, ST_MakePoint($5, $4)::geography, 50000, $6, 'active')
           RETURNING id, ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng`,
          [uid, title, description, loc.lat, loc.lng, effectiveExpiry]
        );
        imported++;
        if (io && inserted[0]) {
          io.emit('alert:new', { ...inserted[0], title, category: 'flood', radius_m: 50000 });
        }
      }
    }

    if (imported > 0) console.log(`[IMGW-hydro] Imported ${imported} hydro alerts`);
  } catch (e) {
    console.error('[IMGW-hydro] Sync error:', e.message);
  }
}

module.exports = { syncHydroWarnings };
