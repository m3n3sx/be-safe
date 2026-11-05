// Kontrakt powiadomień, SOS, zaproszeń i kolizji — bez bazy i bez sieci.
const test = require('node:test');
const assert = require('node:assert');

const safety = require('../src/domain/safetyContracts');
const collision = require('../src/domain/markerCollision');

const forbidden = /pomoc w drodze|dostarczon|push dostarcz|alert rcb|komunikat rządowy|omini\w* wycisz|zawsze dotrze/i;

test('explicit kind sos does not depend on the title emoji', () => {
  const resolved = safety.resolveAlertKind({ kind: 'sos', category: 'other', title: 'Potrzebuję pomocy' });
  assert.deepEqual(resolved, { kind: 'sos', legacy: false });
});

test('legacy aggression title remains sos until old clients are gone', () => {
  const resolved = safety.resolveAlertKind({ category: 'aggression', title: '🆘 SOS — Dziecko' });
  assert.deepEqual(resolved, { kind: 'sos', legacy: true });
  assert.equal(safety.resolveAlertKind({ category: 'aggression', title: 'Kłótnia na ulicy' }).kind, 'alert');
});

test('school-hours silence does not apply to family SOS', () => {
  assert.equal(safety.schoolSilentApplies('family_sos'), false);
  assert.equal(safety.schoolSilentApplies('new_alert'), true);
  assert.equal(safety.schoolSilentApplies('family_ping'), true);
});

test('sender copy counts persisted rows and FCM acceptance, never delivery', () => {
  const none = safety.signalReceipt({ recipients: 0, fcmAccepted: 0 });
  assert.equal(none.persisted, false);
  assert.match(none.message, /nie ma innych osób/);
  assert.doesNotMatch(none.message, forbidden);

  const some = safety.signalReceipt({ recipients: 3, fcmAccepted: 2 });
  assert.equal(some.persisted, true);
  assert.equal(some.recipients, 3);
  assert.equal(some.fcm_accepted, 2);
  assert.match(some.message, /Zapisano dla 3/);
  assert.match(some.message, /przyjęła 2/);
  assert.match(some.message, /nie znaczy/);
  assert.doesNotMatch(some.message, forbidden);
});

test('SOS visible push text names be:Safe and hides coordinates and phone', () => {
  const text = safety.sosPushText({ senderName: 'Ola' });
  assert.match(text.title, /be:Safe/);
  assert.match(text.body, /be:Safe/);
  const blob = `${text.title} ${text.body}`;
  assert.doesNotMatch(blob, /52\.|21\.|\+48|Alert RCB|rządow/);
  assert.equal(safety.sosPushText({ senderName: 'Ola' }).title.includes('Ola'), true);
});

test('ack is distinct from read and dismiss does not change the server row', () => {
  const row = { id: 'n1', is_read: false, acknowledged_at: null };
  const read = safety.applyInboxAction(row, 'read', '2026-11-05T12:00:00.000Z');
  assert.equal(read.is_read, true);
  assert.equal(read.acknowledged_at, null);
  const acked = safety.applyInboxAction(row, 'ack', '2026-11-05T12:01:00.000Z');
  assert.equal(acked.is_read, true);
  assert.equal(acked.acknowledged_at, '2026-11-05T12:01:00.000Z');
  const dismissed = safety.applyInboxAction(row, 'dismiss', '2026-11-05T12:02:00.000Z');
  assert.deepEqual(dismissed, row);
});

test('SOS latch returns on the next process until ack or expiry', () => {
  const now = Date.parse('2026-11-05T12:00:00.000Z');
  const base = { acknowledgedAt: null, alertStatus: 'active', expiresAt: '2026-11-05T15:00:00.000Z', now, shownThisProcess: false };
  assert.equal(safety.shouldShowSosLatch(base), true);
  assert.equal(safety.shouldShowSosLatch({ ...base, shownThisProcess: true }), false);
  assert.equal(safety.shouldShowSosLatch({ ...base, acknowledgedAt: now }), false);
  assert.equal(safety.shouldShowSosLatch({ ...base, alertStatus: 'expired' }), false);
  assert.equal(safety.shouldShowSosLatch({ ...base, expiresAt: '2026-11-05T11:00:00.000Z' }), false);
});

test('signal dedup collapses socket and push copies of one event', () => {
  const seen = new Set();
  const push = { id: 'notif-1', type: 'family_sos', data: { alert_id: 'alert-9', notification_id: 'notif-1' } };
  const socket = { id: 'notif-1', type: 'family_sos', alert_id: 'alert-9', data: { alert_id: 'alert-9' } };
  assert.equal(safety.shouldPresentSignal(push, seen), true);
  assert.equal(safety.shouldPresentSignal(socket, seen), false);
  const other = { id: 'notif-2', type: 'family_ping', ping_id: 'ping-2', data: { ping_id: 'ping-2' } };
  assert.equal(safety.shouldPresentSignal(other, seen), true);
});

test('invite parser accepts canonical links, the legacy path and a manual code', () => {
  assert.equal(safety.parseInvite('ab12cd34'), 'AB12CD34');
  assert.equal(safety.parseInvite('https://besafe.org.pl/family/join?code=ab12cd34'), 'AB12CD34');
  assert.equal(safety.parseInvite('https://besafe.org.pl/family/join/AB12CD34'), 'AB12CD34');
  assert.equal(safety.parseInvite('besafe://family/join?code=AB12CD34'), 'AB12CD34');
  assert.equal(safety.parseInvite('besafe://family/join/AB12CD34'), 'AB12CD34');
  assert.equal(safety.parseInvite('https://evil.example/family/join?code=AB12CD34'), null);
  assert.equal(safety.parseInvite('https://besafe.org.pl/family/join?code=ZZZZZZZZ'), null);
  assert.equal(safety.parseInvite('not a code'), null);
});

test('new invites last 7 days and legacy codes get a 30 day grace from migration', () => {
  const now = Date.parse('2026-11-05T00:00:00.000Z');
  assert.equal(safety.inviteExpiryForNew(now).toISOString(), '2026-11-12T00:00:00.000Z');
  assert.equal(safety.inviteExpiryForLegacy(now).toISOString(), '2026-12-05T00:00:00.000Z');
  assert.equal(safety.isInviteActive('2026-11-06T00:00:00.000Z', now), true);
  assert.equal(safety.isInviteActive('2026-11-04T00:00:00.000Z', now), false);
  assert.equal(safety.isInviteActive(null, now), false);
});

test('self-join cannot take parent or guardian', () => {
  assert.deepEqual(safety.joinRoleDecision(undefined), { ok: true, role: 'family_member' });
  assert.deepEqual(safety.joinRoleDecision('child'), { ok: true, role: 'child' });
  assert.equal(safety.joinRoleDecision('parent').ok, false);
  assert.equal(safety.joinRoleDecision('guardian').ok, false);
  assert.match(safety.joinRoleDecision('parent').error, /właściciel/);
  assert.equal(safety.publicInviteFailure().error, 'Kod jest nieprawidłowy lub wygasł');
});

test('passive location stays hidden when ghosting or visibility denies it', () => {
  assert.equal(safety.canReceivePassiveLocation({ viewerId: 'a', targetId: 'b', locationGranted: true, ghosting: false }), true);
  assert.equal(safety.canReceivePassiveLocation({ viewerId: 'a', targetId: 'b', locationGranted: false, ghosting: false }), false);
  assert.equal(safety.canReceivePassiveLocation({ viewerId: 'a', targetId: 'b', locationGranted: true, ghosting: true }), false);
  assert.equal(safety.canReceivePassiveLocation({ viewerId: 'a', targetId: 'a', locationGranted: false, ghosting: true }), true);
});

test('explicit SOS point is membership, not passive tracking', () => {
  assert.equal(safety.canReadExplicitSos({ member: true }), true);
  assert.equal(safety.canReadExplicitSos({ member: false }), false);
});

test('push token plan keeps the legacy column and caps devices', () => {
  const now = '2026-11-05T12:00:00.000Z';
  const existing = Array.from({ length: 10 }, (_, i) => ({
    token: `t${i}`, platform: 'android', device_id: `d${i}`, disabled_at: null, last_seen_at: `2026-11-0${(i % 5) + 1}T00:00:00.000Z`,
  }));
  const plan = safety.planPushTokens({ tokens: existing, incoming: { token: 'new', platform: 'ios', device_id: 'phone' }, now, max: 10 });
  assert.equal(plan.fanout.includes('new'), true);
  assert.equal(plan.fanout.length, 10);
  assert.equal(plan.legacyColumnToken, 'new');
  assert.equal(plan.rows.filter((r) => r.disabled_at).length >= 1, true);
  const moved = safety.planPushTokens({
    tokens: [{ token: 'same', platform: 'unknown', device_id: null, disabled_at: '2026-11-01T00:00:00.000Z', last_seen_at: '2026-11-01T00:00:00.000Z' }],
    incoming: { token: 'same', platform: 'android', device_id: 'd' },
    now,
  });
  assert.equal(moved.rows[0].disabled_at, null);
  assert.equal(moved.rows[0].platform, 'android');
});

test('location fanout is throttled but a large move is not', () => {
  const prev = { at: 1_000, lat: 52.2, lng: 21.0 };
  assert.equal(safety.shouldEmitLocation({ prev, next: { lat: 52.2, lng: 21.0 }, now: 3_000 }), false);
  assert.equal(safety.shouldEmitLocation({ prev, next: { lat: 52.2, lng: 21.0 }, now: 8_000 }), true);
  assert.equal(safety.shouldEmitLocation({ prev, next: { lat: 52.21, lng: 21.0 }, now: 2_000 }), true);
  assert.equal(safety.shouldEmitLocation({ prev: null, next: { lat: 52.2, lng: 21.0 }, now: 2_000 }), true);
});

test('collision keeps real coordinates and orders SOS first', () => {
  const hazard = { id: 'h1', lat: 52.2, lng: 21.0, kind: 'hazard' };
  const sos = { id: 's1', lat: 52.2, lng: 21.0, kind: 'sos' };
  const member = { id: 'm1', lat: 52.2, lng: 21.0, kind: 'member' };
  const far = { id: 'h2', lat: 53.2, lng: 22.0, kind: 'hazard' };
  const before = JSON.stringify([hazard, sos, member, far]);
  const groups = collision.clusterItems([hazard, sos, member, far], {
    project: (item) => ({ x: item.lng * 1000, y: item.lat * 1000 }),
  });
  assert.equal(JSON.stringify([hazard, sos, member, far]), before);
  assert.equal(groups.length, 2);
  const stacked = groups.find((g) => g.items.length === 3);
  assert.deepEqual(stacked.items.map((i) => i.id), ['s1', 'h1', 'm1']);
  assert.equal(stacked.displayOnly, true);
  assert.equal(stacked.anchor.lat, 52.2);
  assert.equal(stacked.anchor.lng, 21.0);
  assert.equal(groups.find((g) => g.items.length === 1).items[0].id, 'h2');
});

test('nearby points within 15 metres cluster even when pixels are far', () => {
  const a = { id: 'a', lat: 52.2, lng: 21.0, kind: 'member' };
  const b = { id: 'b', lat: 52.2001, lng: 21.0, kind: 'member' };
  const groups = collision.clusterItems([a, b], {
    project: () => ({ x: 0, y: 0 }),
    pixelThreshold: 0,
  });
  assert.equal(groups.length, 1);
  assert.equal(groups[0].items.length, 2);
});

test('screen distance clusters distinct places without rewriting them', () => {
  const a = { id: 'a', lat: 52.2, lng: 21.0, kind: 'hazard' };
  const b = { id: 'b', lat: 52.4, lng: 21.3, kind: 'aed' };
  const groups = collision.clusterItems([a, b], {
    project: (item) => (item.id === 'a' ? { x: 0, y: 0 } : { x: 10, y: 10 }),
    metersThreshold: 0,
  });
  assert.equal(groups.length, 1);
  assert.deepEqual(groups[0].items.map((i) => [i.lat, i.lng]), [[52.2, 21.0], [52.4, 21.3]]);
});
