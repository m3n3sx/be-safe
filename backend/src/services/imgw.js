// IMGW weather warnings → alerts integration
// API: https://danepubliczne.imgw.pl/api/data/warningsmeteo/format/json
// Pobiera ostrzeżenia meteo co 15min i zamienia na alerty pogodowe

const db = require('../config/db');

// Mapowanie kodów TERYT (powiatów) na przybliżone centra geograficzne.
// Skupiamy się na głównych miastach — dla innych używamy lat/lng miasta wojewódzkiego.
// W produkcji można rozbudować o pełną bazę TERYT.
const TERYT_CENTERS = {
  // wielkopolskie
  '3030': { lat: 52.325, lng: 17.565, name: 'powiat wrzesiński' },
  '3063': { lat: 52.408, lng: 16.934, name: 'Poznań' },
  // mazowieckie
  '1465': { lat: 52.230, lng: 21.012, name: 'Warszawa' },
  // małopolskie
  '1261': { lat: 50.061, lng: 19.937, name: 'Kraków' },
  // dolnośląskie
  '0264': { lat: 51.107, lng: 17.038, name: 'Wrocław' },
  // pomorskie
  '2261': { lat: 54.352, lng: 18.646, name: 'Gdańsk' },
  // śląskie
  '2469': { lat: 50.262, lng: 19.021, name: 'Katowice' },
};

// Fallback: pierwsze 2 cyfry = województwo, użyj głównego miasta
const WOJEWODZTWO_CENTERS = {
  '02': { lat: 51.107, lng: 17.038 }, // dolnośląskie → Wrocław
  '04': { lat: 53.125, lng: 18.011 }, // kujawsko-pomorskie → Bydgoszcz
  '06': { lat: 51.246, lng: 22.568 }, // lubelskie → Lublin
  '08': { lat: 51.939, lng: 15.505 }, // lubuskie → Zielona Góra
  '10': { lat: 51.759, lng: 19.456 }, // łódzkie → Łódź
  '12': { lat: 50.061, lng: 19.937 }, // małopolskie → Kraków
  '14': { lat: 52.230, lng: 21.012 }, // mazowieckie → Warszawa
  '16': { lat: 50.675, lng: 17.921 }, // opolskie → Opole
  '18': { lat: 50.041, lng: 21.999 }, // podkarpackie → Rzeszów
  '20': { lat: 53.133, lng: 23.169 }, // podlaskie → Białystok
  '22': { lat: 54.352, lng: 18.646 }, // pomorskie → Gdańsk
  '24': { lat: 50.262, lng: 19.021 }, // śląskie → Katowice
  '26': { lat: 50.866, lng: 20.629 }, // świętokrzyskie → Kielce
  '28': { lat: 53.778, lng: 20.480 }, // warmińsko-mazurskie → Olsztyn
  '30': { lat: 52.408, lng: 16.934 }, // wielkopolskie → Poznań
  '32': { lat: 53.429, lng: 14.552 }, // zachodniopomorskie → Szczecin
};

function terytToLatLng(teryt) {
  if (TERYT_CENTERS[teryt]) return TERYT_CENTERS[teryt];
  const woj = teryt.substring(0, 2);
  return WOJEWODZTWO_CENTERS[woj] || null;
}

// Znajdź UUID systemowego usera dla IMGW (stworzymy go jeśli nie istnieje)
let _systemUserId = null;
async function getSystemUserId() {
  if (_systemUserId) return _systemUserId;
  const { rows } = await db.query(`SELECT id FROM users WHERE email = 'system-imgw@alert.u235.pl' LIMIT 1`);
  if (rows[0]) return _systemUserId = rows[0].id;

  const bcrypt = require('bcryptjs');
  const hash = await bcrypt.hash(require('crypto').randomBytes(32).toString('hex'), 10);
  const { rows: ins } = await db.query(
    `INSERT INTO users (email, password_hash, username, email_verified, referral_code)
     VALUES ('system-imgw@alert.u235.pl', $1, 'IMGW', TRUE, 'SYSIMG') RETURNING id`,
    [hash]
  );
  return _systemUserId = ins[0].id;
}

async function fetchWarnings() {
  const url = 'https://danepubliczne.imgw.pl/api/data/warningsmeteo/format/json';
  const res = await fetch(url);
  if (!res.ok) throw new Error(`IMGW API ${res.status}`);
  return res.json();
}

async function syncWarnings(io) {
  try {
    const warnings = await fetchWarnings();
    if (!Array.isArray(warnings)) return;

    const uid = await getSystemUserId();
    let imported = 0;

    for (const w of warnings) {
      const extId = `imgw-${w.id}`;
      // Skip if already imported
      const { rows: existing } = await db.query(
        `SELECT id FROM alerts WHERE title LIKE $1 LIMIT 1`,
        [`%[${extId}]%`]
      );
      if (existing[0]) continue;

      const title = `⛈️ ${w.nazwa_zdarzenia} — IMGW [${extId}]`;
      const description = `${w.tresc}\n\nStopień: ${w.stopien}/3 | Prawdopodobieństwo: ${w.prawdopodobienstwo}%\nOpublikowano: ${w.opublikowano}\nŹródło: ${w.biuro}`;
      const expiresAt = new Date(w.obowiazuje_do + '+02:00');
      if (expiresAt < new Date()) continue; // skip expired

      // For each powiat in teryt list, create alert at its center
      for (const teryt of w.teryt.slice(0, 5)) { // limit 5 per warning
        const loc = terytToLatLng(teryt);
        if (!loc) continue;

        const { rows: inserted } = await db.query(
          `INSERT INTO alerts (author_id, category, title, description, location, radius_m, expires_at, status)
           VALUES ($1, 'weather', $2, $3, ST_MakePoint($5, $4)::geography, 30000, $6, 'active')
           RETURNING id, ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng`,
          [uid, title, description, loc.lat, loc.lng, expiresAt]
        );
        imported++;
        if (io && inserted[0]) {
          io.emit('alert:new', { ...inserted[0], title, category: 'weather', radius_m: 30000 });
        }
      }
    }

    if (imported > 0) console.log(`[IMGW] Imported ${imported} weather alerts`);
  } catch (e) {
    console.error('[IMGW] Sync error:', e.message);
  }
}

module.exports = { syncWarnings };
