// GDDKiA road incidents → alerts integration.
//
// Uwaga: oficjalna lista utrudnień (https://drogi.gddkia.gov.pl/informacje-drogowe/lista-utrudnien)
// chroniona jest przez Imperva/Incapsula WAF — bezpośredni scraping z serwera
// zwykle zwraca challenge HTML. Ten service próbuje dwóch strategii:
//
//   1. Publiczny RSS/JSON feed gov.pl (jeśli udostępniony).
//   2. Bezpośredni scraping listy utrudnień (działa tylko gdy IP VPS nie jest
//      zablokowany przez Imperve).
//
// Jeśli obie metody zawiodą, service loguje błąd i kończy bez wstawiania alertów.
// Nie blokuje to reszty backendu.
//
// W przyszłości można podpiąć prywatny feed z umową dostępu lub
// crowdsourcing od użytkowników (ręczne zgłaszanie drogowe alerty).

const db = require('../config/db');

const DEFAULT_RADIUS_M = 5000;
const DEFAULT_TTL_HOURS = 6;

let _systemUserId = null;
async function getSystemUserId() {
  if (_systemUserId) return _systemUserId;
  const { rows } = await db.query(
    `SELECT id FROM users WHERE email = 'system-gddkia@alert.u235.pl' LIMIT 1`
  );
  if (rows[0]) return (_systemUserId = rows[0].id);

  const bcrypt = require('bcryptjs');
  const hash = await bcrypt.hash(require('crypto').randomBytes(32).toString('hex'), 10);
  const { rows: ins } = await db.query(
    `INSERT INTO users (email, password_hash, username, email_verified, referral_code)
     VALUES ('system-gddkia@alert.u235.pl', $1, 'GDDKiA', TRUE, 'SYSGDD') RETURNING id`,
    [hash]
  );
  return (_systemUserId = ins[0].id);
}

// Dedupe: skip incidents already imported (matched by ext_id prefix in title).
async function alertExists(extId) {
  const { rows } = await db.query(
    `SELECT 1 FROM alerts WHERE title LIKE $1 LIMIT 1`,
    [`%[${extId}]%`]
  );
  return rows.length > 0;
}

/**
 * Try to parse the gov.pl aggregated feed. Returns an array of incidents.
 * Current gov.pl v3 API shape is a moving target; the service tries a few
 * known endpoints and returns [] on failure.
 */
async function fetchFromGovPl() {
  const endpoints = [
    'https://www.gov.pl/api/feed/cms/dep/gddkia?mostImportant=false&ps=50',
    'https://www.gov.pl/api/feed/cms/rss/gddkia',
  ];
  for (const url of endpoints) {
    try {
      const res = await fetch(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; beSafeBot/1.0; +https://alert.u235.pl)',
          Accept: 'application/json, application/rss+xml, text/xml;q=0.9',
          'Accept-Language': 'pl-PL',
        },
      });
      if (!res.ok) continue;
      const ct = res.headers.get('content-type') || '';
      if (ct.includes('json')) {
        const data = await res.json();
        if (Array.isArray(data)) return data;
        if (Array.isArray(data?.items)) return data.items;
      }
      // XML/RSS: naive parse — extract <item><title>/<description>/<pubDate>
      const body = await res.text();
      const items = [];
      const itemRe = /<item[^>]*>([\s\S]*?)<\/item>/gi;
      let m;
      while ((m = itemRe.exec(body)) != null) {
        const inner = m[1];
        const get = (tag) => {
          const t = new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`).exec(inner);
          return t ? t[1].replace(/<!\\[CDATA\\[|\\]\\]>/g, '').trim() : null;
        };
        items.push({
          title: get('title'),
          link: get('link'),
          description: get('description'),
          pubDate: get('pubDate'),
        });
      }
      if (items.length) return items;
    } catch (e) {
      console.error('[GDDKiA] gov.pl fetch error:', e.message);
    }
  }
  return [];
}

/**
 * Try the official incidents page. Incapsula/Imperva usually blocks server
 * IPs; the call returns [] if blocked.
 */
async function fetchFromGddkiaDirect() {
  try {
    const res = await fetch('https://drogi.gddkia.gov.pl/informacje-drogowe/lista-utrudnien', {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        Accept: 'text/html,application/xhtml+xml',
        'Accept-Language': 'pl-PL,pl;q=0.9',
        Referer: 'https://www.gov.pl/web/gddkia',
      },
    });
    const body = await res.text();
    if (body.includes('Incapsula') || body.includes('_Incapsula_Resource')) {
      console.log('[GDDKiA] drogi.gddkia.gov.pl: zablokowane przez Imperva WAF, pomijam.');
      return [];
    }
    // Naive HTML parse — look for entries like <div class="incident">...<h3>Title</h3>...
    // The real markup needs verification once we can fetch the page; this is a placeholder
    // that returns empty (and logs) so the pipeline is wired but non-breaking.
    console.log('[GDDKiA] drogi.gddkia.gov.pl: pobrane, ale parser jeszcze nie dostrojony.');
    return [];
  } catch (e) {
    console.error('[GDDKiA] direct fetch error:', e.message);
    return [];
  }
}

// Geokodowanie przez Nominatim (fallback jeśli incident nie ma lat/lng).
// Rate-limit: 1 req/s. Cache w pamięci.
const _geoCache = new Map();
async function geocode(q) {
  if (!q) return null;
  if (_geoCache.has(q)) return _geoCache.get(q);
  try {
    const url = 'https://nominatim.openstreetmap.org/search?' +
      new URLSearchParams({ q: `${q}, Polska`, format: 'json', limit: '1' });
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'beSafe/1.0 (https://alert.u235.pl)',
        'Accept-Language': 'pl',
      },
    });
    const data = await res.json();
    const p = Array.isArray(data) && data[0]
      ? { lat: parseFloat(data[0].lat), lng: parseFloat(data[0].lon) }
      : null;
    _geoCache.set(q, p);
    await new Promise((r) => setTimeout(r, 1100)); // Nominatim rate-limit
    return p;
  } catch (e) {
    console.error('[GDDKiA] geocode error:', e.message);
    return null;
  }
}

async function syncGddkia(io) {
  try {
    let incidents = await fetchFromGovPl();
    if (!incidents.length) incidents = await fetchFromGddkiaDirect();
    if (!incidents.length) {
      console.log('[GDDKiA] Brak nowych incydentów / źródło niedostępne.');
      return;
    }

    const uid = await getSystemUserId();
    let imported = 0;
    let skipped = 0;

    for (const inc of incidents) {
      const title = (inc.title || '').trim();
      if (!title) { skipped++; continue; }

      // Minimalny filtr na utrudnienia — tytuły newsów typu "wstępnie otwarte",
      // "mamy pozwolenie" wyłączamy, bo to nie są realne utrudnienia.
      const t = title.toLowerCase();
      const looksLikeIncident = /utrudnien|zamkni|awari|wypadek|objazd|kolizja|zamknię|roboty|remont/.test(t);
      if (!looksLikeIncident) { skipped++; continue; }

      const extId = `gddkia-${Buffer.from(inc.link || title).toString('base64').slice(0, 20)}`;
      if (await alertExists(extId)) { skipped++; continue; }

      // Próba wyciągnięcia lokalizacji z tytułu/opisu
      const locText = extractLocation(title + ' ' + (inc.description || ''));
      const coords = locText ? await geocode(locText) : null;
      if (!coords) { skipped++; continue; }

      const expires = new Date(Date.now() + DEFAULT_TTL_HOURS * 3600 * 1000);
      const pubDate = inc.pubDate ? new Date(inc.pubDate) : new Date();

      const { rows } = await db.query(
        `INSERT INTO alerts (author_id, category, title, description, location, radius_m, expires_at, status, created_at)
         VALUES ($1, 'construction', $2, $3, ST_MakePoint($5, $4)::geography, $6, $7, 'active', $8)
         RETURNING id, ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng`,
        [
          uid,
          `🚧 ${title} [${extId}]`,
          (inc.description || '').replace(/<[^>]+>/g, '').trim().slice(0, 500) +
            (inc.link ? `\n\nŹródło: ${inc.link}` : ''),
          coords.lat,
          coords.lng,
          DEFAULT_RADIUS_M,
          expires,
          pubDate,
        ]
      );
      imported++;
      if (io && rows[0]) {
        io.emit('alert:new', {
          ...rows[0],
          title,
          category: 'construction',
          radius_m: DEFAULT_RADIUS_M,
        });
      }
    }

    console.log(`[GDDKiA] Import: ${imported} nowych, ${skipped} pominiętych.`);
  } catch (e) {
    console.error('[GDDKiA] Sync error:', e.message);
  }
}

/**
 * Regex-based location extractor: finds a road code like "A2", "S7", "DK94"
 * plus nearest town/powiat name if mentioned. Heuristic, imperfect.
 */
function extractLocation(text) {
  if (!text) return null;
  const road = /(autostrada|droga ekspresowa|DK|A|S)\s?\d{1,3}[a-z]?/i.exec(text);
  const town = /(?:w okolicy|w pobliżu|k\.|koło|w|przy)\s+([A-ZŁŚŹŻŃĆĄĘÓ][a-ząćęłńóśźż]+(?:\s+[A-ZŁŚŹŻŃĆĄĘÓ][a-ząćęłńóśźż]+)*)/.exec(text);
  const parts = [];
  if (road) parts.push(road[0]);
  if (town) parts.push(town[1]);
  return parts.length ? parts.join(' ') : null;
}

module.exports = { syncGddkia };
