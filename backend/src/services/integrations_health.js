// PowerAdmin — zdrowie integracji zewnętrznych. Każda: ok + latency_ms + last_error.
// Lekkie probe'y z timeoutem; fail-soft. NIE wysyła realnych maili/pushy.
const fs = require('fs');
const path = require('path');

async function probe(name, fn, timeoutMs = 5000) {
  const t0 = Date.now();
  try {
    const detail = await Promise.race([
      fn(),
      new Promise((_, rej) => setTimeout(() => rej(new Error('timeout')), timeoutMs)),
    ]);
    return { name, ok: true, latency_ms: Date.now() - t0, ...(detail || {}) };
  } catch (e) {
    return { name, ok: false, latency_ms: Date.now() - t0, last_error: (e.message || '').slice(0, 120) };
  }
}

async function httpProbe(url, opts = {}) {
  const r = await fetch(url, opts);
  return { status: r.status, ok_http: r.ok };
}

async function integrationsHealth() {
  const checks = await Promise.all([
    // GIOŚ — publiczne API jakości powietrza
    probe('gios', () => httpProbe('https://api.gios.gov.pl/pjp-api/v1/rest/station/findAll?size=1', { headers: { Accept: 'application/ld+json' } })),
    // IMGW — ostrzeżenia/dane publiczne
    probe('imgw', () => httpProbe('https://danepubliczne.imgw.pl/api/data/warningsmeteo/format/json')),
    // Mailgun — konfiguracja (nie wysyłamy maila, sprawdzamy obecność klucza + dostępność API)
    probe('mailgun', async () => {
      const key = process.env.MAILGUN_API_KEY;
      if (!key) return { configured: false, note: 'MAILGUN_API_KEY brak' };
      const region = process.env.MAILGUN_REGION === 'eu' ? 'api.eu.mailgun.net' : 'api.mailgun.net';
      const r = await fetch(`https://${region}/v3/domains`, {
        headers: { Authorization: 'Basic ' + Buffer.from(`api:${key}`).toString('base64') },
      });
      return { configured: true, status: r.status, ok_http: r.ok };
    }),
    // Vertex AI — czy klient się inicjalizuje + projekt/region
    probe('vertex', async () => {
      const { VertexAI } = require('@google-cloud/vertexai');
      const v = new VertexAI({
        project: process.env.GCP_PROJECT_ID || 'project-1674d55f-90e0-4e1a-884',
        location: process.env.VERTEX_LOCATION || 'europe-west1',
      });
      return { configured: !!v, location: process.env.VERTEX_LOCATION || 'europe-west1' };
    }),
    // FCM — firebase-admin zainicjalizowany (sekret obecny)
    probe('fcm', async () => {
      const saPath = process.env.FIREBASE_SERVICE_ACCOUNT || path.join(__dirname, '..', '..', 'firebase-admin.json');
      const present = fs.existsSync(saPath);
      return { configured: present, note: present ? 'service account obecny' : 'brak service account' };
    }),
    // Vision — klient SafeSearch
    probe('vision', async () => {
      const vision = require('@google-cloud/vision');
      const c = new vision.ImageAnnotatorClient();
      return { configured: !!c };
    }),
  ]);
  const summary = {
    ok_count: checks.filter((c) => c.ok).length,
    total: checks.length,
    checks,
    time: new Date().toISOString(),
  };
  return summary;
}

module.exports = { integrationsHealth };
