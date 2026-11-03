// Weryfikacja Google ID tokenów dla POST /auth/google (P0.2 z docs/PLAN_BEZPIECZENSTWA.md).
//
// Env:
//   GOOGLE_CLIENT_IDS                — lista client ID (po przecinku), które akceptujemy jako `aud`
//                                      tokena. Domyślnie web client be:Safe (ten sam jest
//                                      serverClientId w apce Flutter i client_id w GIS na webie).
//   GOOGLE_AUTH_LEGACY_EMAIL_ONLY    — "true" tymczasowo przepuszcza stare klienty, które
//                                      wysyłają tylko email (bez id_token). Domyślnie wyłączone.
//                                      NIEBEZPIECZNE: pozwala zalogować się na dowolny email.
const { OAuth2Client } = require('google-auth-library');

const DEFAULT_CLIENT_IDS = [
  '1098119585965-1dmn79cgjbhsr84f1iu3dibvpilc906p.apps.googleusercontent.com',
];

function getAllowedClientIds() {
  const raw = process.env.GOOGLE_CLIENT_IDS;
  if (!raw || !raw.trim()) return DEFAULT_CLIENT_IDS.slice();
  return raw.split(',').map((s) => s.trim()).filter(Boolean);
}

function isLegacyEmailOnlyEnabled() {
  return /^(1|true|yes|on)$/i.test(String(process.env.GOOGLE_AUTH_LEGACY_EMAIL_ONLY || '').trim());
}

let client = new OAuth2Client();

class GoogleAuthError extends Error {
  constructor(message, status = 401) {
    super(message);
    this.status = status;
  }
}

/**
 * Weryfikuje podpis, `aud`, `iss` i `exp` tokena i zwraca dane z payloadu.
 * Rzuca GoogleAuthError, gdy token jest nieprawidłowy lub email niezweryfikowany.
 */
async function verifyGoogleIdToken(idToken) {
  if (!idToken || typeof idToken !== 'string') {
    throw new GoogleAuthError('id_token required', 400);
  }
  let payload;
  try {
    const ticket = await client.verifyIdToken({ idToken, audience: getAllowedClientIds() });
    payload = ticket.getPayload();
  } catch (e) {
    throw new GoogleAuthError('Invalid Google token', 401);
  }
  if (!payload || !payload.email) throw new GoogleAuthError('Google token has no email', 401);
  if (payload.email_verified !== true && payload.email_verified !== 'true') {
    throw new GoogleAuthError('Google email not verified', 401);
  }
  return {
    sub: payload.sub,
    email: String(payload.email),
    name: payload.name || null,
    picture: payload.picture || null,
  };
}

// Tylko do testów.
function _setClient(c) { client = c; }

module.exports = {
  verifyGoogleIdToken,
  getAllowedClientIds,
  isLegacyEmailOnlyEnabled,
  GoogleAuthError,
  DEFAULT_CLIENT_IDS,
  _setClient,
};
