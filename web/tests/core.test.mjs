import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import ts from 'typescript';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
function load(relative, globals = {}) {
  const source = fs.readFileSync(path.join(root, relative), 'utf8');
  const code = ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 } }).outputText;
  const exports = {};
  vm.runInNewContext(code, { exports, require, URL, URLSearchParams, FormData, AbortSignal, Event, process: { env: {} }, ...globals });
  return exports;
}

test('returnTo preserves internal tasks and rejects external/ambiguous redirects', () => {
  const { safeReturnTo } = load('src/lib/routes.ts');
  for (const value of ['https://example.com', '//example.com', '/\\example.com', '/login?returnTo=/', '/register', '/\n/example.com']) assert.equal(safeReturnTo(value), '/');
  assert.equal(safeReturnTo('/alerts/abc?from=map#comments'), '/alerts/abc?from=map#comments');
  assert.equal(safeReturnTo('/report'), '/report');
});

test('all existing page routes are registered, including dynamic family/admin routes', () => {
  const { routes, routeFor } = load('src/lib/navigation.ts');
  const app = path.join(root, 'src/app');
  const pages = fs.readdirSync(app, { recursive: true }).filter(file => file === 'page.tsx' || file.endsWith('/page.tsx'));
  for (const file of pages) {
    const route = '/' + file.replace(/(^|\/)page\.tsx$/, '');
    assert.ok(routes.some(entry => entry.href === route), `Missing registry route: ${route}`);
  }
  assert.equal(routeFor('/family/g/members/u').section, 'family');
  assert.equal(routeFor('/alerts/mine').section, 'profile');
  assert.equal(routeFor('/alerts/id').section, 'nearby');
  assert.equal(routes.filter(route => route.permission !== undefined).length, 8);
});

test('alert adapter uses existing paths, radius_m, votes, and multipart photo contract', async () => {
  const calls = [];
  const transport = new Proxy({}, { get: (_, method) => async (...args) => { calls.push([method, ...args]); return {}; } });
  const { alertsApi } = load('src/lib/api/alerts.ts', { require: name => { assert.equal(name, '@/lib/api'); return { default: transport }; } });
  await alertsApi.nearby({ lat: 51.2, lng: 19.3 }, 5000);
  const request = new URL(calls[0][1], 'https://test.invalid');
  assert.equal(request.pathname, '/alerts/nearby');
  assert.equal(request.searchParams.get('radius_m'), '5000');
  assert.equal(request.searchParams.has('radius'), false);
  await alertsApi.vote('abc', 'deny');
  assert.equal(calls[1][1], '/alerts/abc/vote');
  assert.equal(calls[1][2].vote, 'deny');
  const data = new FormData(); data.set('is_anonymous', 'true'); data.set('photo', new Blob(['photo'], { type: 'image/jpeg' }), 'photo.jpg');
  await alertsApi.create(data);
  assert.equal(calls[2][0], 'multipart'); assert.equal(calls[2][1], '/alerts'); assert.equal(calls[2][2], data);
  await alertsApi.report('abc', 'Nieprawdziwe informacje');
  assert.equal(calls[3][1], '/alerts/abc/report'); assert.equal(calls[3][2].reason, 'Nieprawdziwe informacje');
});

test('transport preserves HTTP errors and retry information, never retries mutations', async () => {
  let count = 0; let options;
  const { api } = load('src/lib/api.ts', { fetch: async (_, init) => { count++; options = init; return new Response(JSON.stringify({ error: 'Already voted' }), { status: 409, headers: { 'Retry-After': '60' } }); } });
  const result = await api.post('/alerts/a/vote', { vote: 'confirm' });
  assert.equal(result.httpStatus, 409); assert.equal(result.error, 'Already voted'); assert.equal(result.retryAfter, '60'); assert.equal(count, 1);
  assert.equal(JSON.parse(options.body).vote, 'confirm');
  const multipart = new FormData(); multipart.set('title', 'Zgłoszenie'); await api.multipart('/alerts', multipart);
  assert.equal(options.body, multipart); assert.equal(options.headers['Content-Type'], undefined);
});

test('transport handles non-JSON rate limiting and ambiguous network failure', async () => {
  const { api } = load('src/lib/api.ts', { fetch: async () => new Response('Too many requests', { status: 429, headers: { 'Retry-After': '120' } }) });
  assert.equal((await api.post('/alerts')).retryAfter, '120');
  let calls = 0;
  const offline = load('src/lib/api.ts', { fetch: async () => { calls++; throw new Error('offline'); } }).api;
  assert.equal((await offline.post('/alerts')).httpStatus, 0);
  assert.equal(calls, 1);
});

test('light and dark core token pairs meet text and control contrast', () => {
  const css = fs.readFileSync(path.join(root, 'src/app/globals.css'), 'utf8');
  function luminance(hex) {
    const value = hex.length === 4 ? hex.slice(1).split('').map(c => c + c).join('') : hex.slice(1);
    const rgb = value.match(/../g).map(c => parseInt(c, 16) / 255).map(c => c <= .04045 ? c / 12.92 : ((c + .055) / 1.055) ** 2.4);
    return rgb[0] * .2126 + rgb[1] * .7152 + rgb[2] * .0722;
  }
  for (const selector of [':root', '.dark']) {
    const body = css.slice(css.indexOf(selector)).split('}')[0];
    const tokens = Object.fromEntries([...body.matchAll(/--([\w-]+):\s*(#[\da-f]+)/gi)].map(match => [match[1], match[2]]));
    for (const [a, b, minimum] of [['ink', 'surface', 4.5], ['ink-2', 'surface', 4.5], ['ink-2', 'background', 4.5], ['primary', 'on-primary', 4.5], ['danger', 'on-danger', 4.5], ['success', 'surface', 4.5], ['warning', 'surface', 4.5], ['control', 'surface', 3], ['focus', 'surface', 3]]) {
      const x = luminance(tokens[a]); const y = luminance(tokens[b]);
      const ratio = (Math.max(x, y) + .05) / (Math.min(x, y) + .05);
      assert.ok(ratio >= minimum, `${selector} ${a}/${b}: ${ratio.toFixed(2)}`);
    }
  }
});

test('Google Maps configuration has only the public environment source', () => {
  const source = fs.readFileSync(path.join(root, 'src/lib/constants.ts'), 'utf8');
  assert.match(source, /process\.env\.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY/);
  assert.doesNotMatch(source, /AIza[\w-]{20,}/);
});

test('SOS uses the existing recognition contract and only the supplied location', async () => {
  const calls = [];
  const transport = { post: async (url, body) => { calls.push({ url, body }); return { id: 'sos-id' }; } };
  const { sendSos } = load('src/lib/sos.ts', { require: name => { assert.equal(name, './api'); return { default: transport }; } });
  const result = await sendSos({ lat: 51.123, lng: 17.456 });
  assert.equal(result.id, 'sos-id');
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, '/alerts');
  assert.equal(calls[0].body.category, 'aggression');
  assert.ok(calls[0].body.title.includes('🆘'));
  assert.equal(calls[0].body.lat, 51.123);
  assert.equal(calls[0].body.lng, 17.456);
  assert.equal(calls[0].body.radius_m, 500);
  assert.equal('recipients' in calls[0].body, false);
});

test('notification fixtures route to the actual task, without trusting URLs in payloads', () => {
  const { notificationHref } = load('src/lib/notification-routes.ts');
  const fixtures = [
    [{ type: 'family_ping', data: { ping_id: 'p', group_id: 'g' } }, '/family/pings/p'],
    [{ type: 'ping_response', data: { ping_id: 'p', status: 'expired' } }, '/family/pings/p'],
    [{ type: 'family_sos', data: { group_id: 'g', alert_id: 'a' } }, '/family/g/sos/a'],
    [{ type: 'kpp_responder_call', data: { alert_id: 'a' } }, '/alerts/a'],
    [{ type: 'escort_panic', data: { escort_id: 'e' } }, '/escort/e'],
    [{ type: 'family_message', data: { group_id: 'g', message_id: 'm' } }, '/family/g/chat'],
    [{ type: 'family_event_reminder', data: { group_id: 'g', event_id: 'e' } }, '/family/g/planner#event-e'],
    [{ type: 'route_exit', data: { group_id: 'g', user_id: 'u', route_id: 'r' } }, '/family/g/members/u/safe-routes/r'],
    [{ type: 'child_low_battery', data: { group_id: 'g', child_id: 'u' } }, '/family/g/members/u'],
    [{ type: 'checkin_reminder', data: {} }, '/family'],
    [{ type: 'broadcast', data: { url: 'https://untrusted.invalid' } }, null],
    [{ type: 'new_alert', data: { alert_id: 'a?redirect=//untrusted.invalid' } }, '/alerts/a%3Fredirect%3D%2F%2Funtrusted.invalid'],
  ];
  for (const [item, expected] of fixtures) assert.equal(notificationHref(item), expected);
  const pets = notificationHref({ type: 'pet_lost_nearby', data: { pet_id: 'p', lat: '51', lng: '19' } });
  const url = new URL(pets, 'https://test.invalid');
  assert.equal(url.pathname, '/pets'); assert.equal(url.searchParams.get('view'), 'lost');
  assert.equal(url.searchParams.get('lat'), '51'); assert.equal(url.hash, '#pet-p');
});
