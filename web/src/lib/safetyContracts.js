// Czyste reguły be:Safe: rodzaj alarmu, tekst nadawcy, skrzynka, zaproszenia, tokeny.
// Bez bazy, Firebase i sieci. Trasy tylko stosują te decyzje.

const INVITE_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const LEGACY_INVITE_GRACE_MS = 30 * 24 * 60 * 60 * 1000;
const CODE_RE = /^[A-F0-9]{8}$/;
const GUARDIAN_ROLES = new Set(['parent', 'guardian']);
const SELF_JOIN_ROLES = new Set(['child', 'senior', 'family_member', 'partner', 'friend', 'other']);
const LOCATION_THROTTLE_MS = 5000;
const LOCATION_THROTTLE_M = 20;

function resolveAlertKind({ kind, category, title } = {}) {
  if (kind === 'sos') return { kind: 'sos', legacy: false };
  if (category === 'aggression' && typeof title === 'string' && title.includes('🆘')) {
    return { kind: 'sos', legacy: true };
  }
  return { kind: 'alert', legacy: false };
}

function schoolSilentApplies(type) {
  return type !== 'family_sos';
}

function signalReceipt({ recipients, fcmAccepted }) {
  const n = Number(recipients) || 0;
  const m = Number(fcmAccepted) || 0;
  if (n <= 0) {
    return {
      persisted: false,
      recipients: 0,
      fcm_accepted: 0,
      message: 'W grupie nie ma innych osób. Nic nie zapisano dla odbiorców.',
    };
  }
  return {
    persisted: true,
    recipients: n,
    fcm_accepted: m,
    message: `Zapisano dla ${n} osób. Usługa push przyjęła ${m} zgłoszeń. To nie znaczy, że ktoś je zobaczył ani że dotarły na urządzenie.`,
  };
}

function sosPushText({ senderName }) {
  const name = senderName || 'bliska osoba';
  return {
    title: `be:Safe · SOS od ${name}`,
    body: 'Otwórz be:Safe, aby zobaczyć czas i miejsce alarmu.',
  };
}

function applyInboxAction(row, action, at) {
  if (action === 'dismiss') return row;
  if (action === 'read') return { ...row, is_read: true };
  if (action === 'ack') return { ...row, is_read: true, acknowledged_at: at };
  return row;
}

function shouldShowSosLatch({ acknowledgedAt, alertStatus, expiresAt, now, shownThisProcess }) {
  if (acknowledgedAt) return false;
  if (alertStatus !== 'active') return false;
  if (expiresAt && Date.parse(expiresAt) <= now) return false;
  if (shownThisProcess) return false;
  return true;
}

function addKey(keys, value) {
  if (value == null) return;
  const text = String(value);
  if (text) keys.push(text);
}

function shouldPresentSignal(event, seen) {
  const keys = [];
  const data = event && event.data && typeof event.data === 'object' ? event.data : {};
  addKey(keys, event && event.id);
  addKey(keys, event && event.ping_id);
  addKey(keys, data.ping_id);
  addKey(keys, data.notification_id);
  const alertId = (event && event.alert_id) || data.alert_id;
  if ((event && event.type) === 'family_sos') addKey(keys, alertId ? `sos:${alertId}` : null);
  if (keys.some((key) => seen.has(key))) {
    keys.forEach((key) => seen.add(key));
    return false;
  }
  keys.forEach((key) => seen.add(key));
  return keys.length > 0;
}

function parseInvite(input) {
  if (typeof input !== 'string') return null;
  const raw = input.trim();
  if (!raw) return null;
  const direct = raw.toUpperCase();
  if (CODE_RE.test(direct) && !raw.includes('://') && !raw.includes('/')) return direct;
  let url;
  try {
    url = new URL(raw);
  } catch (_) {
    return null;
  }
  let code = null;
  if (url.protocol === 'besafe:' && url.hostname === 'family') {
    const parts = url.pathname.split('/').filter(Boolean);
    if (parts[0] !== 'join') return null;
    code = parts[1] || url.searchParams.get('code');
  } else if (url.protocol === 'https:' && url.hostname === 'besafe.org.pl') {
    const parts = url.pathname.split('/').filter(Boolean);
    if (parts[0] !== 'family' || parts[1] !== 'join') return null;
    code = parts[2] || url.searchParams.get('code');
  } else {
    return null;
  }
  if (!code) return null;
  code = code.toUpperCase();
  return CODE_RE.test(code) ? code : null;
}

function inviteExpiryForNew(now) {
  return new Date(now + INVITE_TTL_MS);
}

function inviteExpiryForLegacy(migrationAt) {
  return new Date(migrationAt + LEGACY_INVITE_GRACE_MS);
}

function isInviteActive(expiresAt, now) {
  if (!expiresAt) return false;
  const ts = expiresAt instanceof Date ? expiresAt.getTime() : Date.parse(expiresAt);
  return Number.isFinite(ts) && ts > now;
}

function joinRoleDecision(requested) {
  const role = requested || 'family_member';
  if (GUARDIAN_ROLES.has(role)) {
    return { ok: false, error: 'Rolę rodzica lub opiekuna nadaje właściciel grupy' };
  }
  if (!SELF_JOIN_ROLES.has(role)) return { ok: false, error: 'Nieprawidłowa rola' };
  return { ok: true, role };
}

function publicInviteFailure() {
  return { status: 404, error: 'Kod jest nieprawidłowy lub wygasł' };
}

function canReceivePassiveLocation({ viewerId, targetId, locationGranted, ghosting }) {
  if (viewerId === targetId) return true;
  if (ghosting) return false;
  return locationGranted === true;
}

function canReadExplicitSos({ member }) {
  return member === true;
}

function planPushTokens({ tokens, incoming, now, max = 10 }) {
  const without = tokens.filter((row) => row.token !== incoming.token);
  const next = [
    ...without,
    {
      token: incoming.token,
      platform: incoming.platform || 'unknown',
      device_id: incoming.device_id || null,
      disabled_at: null,
      last_seen_at: now,
    },
  ];
  const enabled = next
    .filter((row) => !row.disabled_at)
    .sort((a, b) => Date.parse(b.last_seen_at) - Date.parse(a.last_seen_at));
  const alreadyDisabled = next.filter((row) => row.disabled_at);
  const kept = enabled.slice(0, max);
  const overflow = enabled.slice(max).map((row) => ({ ...row, disabled_at: now }));
  return {
    rows: [...kept, ...overflow, ...alreadyDisabled],
    legacyColumnToken: kept[0] ? kept[0].token : null,
    fanout: kept.map((row) => row.token),
  };
}

function haversineMeters(a, b) {
  const r = 6371000;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const lat1 = (a.lat * Math.PI) / 180;
  const lat2 = (b.lat * Math.PI) / 180;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * r * Math.asin(Math.min(1, Math.sqrt(h)));
}

function shouldEmitLocation({ prev, next, now }) {
  if (!prev) return true;
  if (now - prev.at >= LOCATION_THROTTLE_MS) return true;
  return haversineMeters(prev, next) >= LOCATION_THROTTLE_M;
}

module.exports = {
  INVITE_TTL_MS,
  LEGACY_INVITE_GRACE_MS,
  resolveAlertKind,
  schoolSilentApplies,
  signalReceipt,
  sosPushText,
  applyInboxAction,
  shouldShowSosLatch,
  shouldPresentSignal,
  parseInvite,
  inviteExpiryForNew,
  inviteExpiryForLegacy,
  isInviteActive,
  joinRoleDecision,
  publicInviteFailure,
  canReceivePassiveLocation,
  canReadExplicitSos,
  planPushTokens,
  haversineMeters,
  shouldEmitLocation,
};
