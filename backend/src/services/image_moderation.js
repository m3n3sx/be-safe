// F06 AI image moderation (Google Cloud Vision — SafeSearch)
//
// Trzecia warstwa moderacji (obok heurystyki tekstu w moderation.js i
// AI tekstu w ai_moderation.js). Analizuje zdjęcie dołączone do alertu.
//
// Vision SafeSearch zwraca 5 kategorii z likelihood:
//   UNKNOWN | VERY_UNLIKELY | UNLIKELY | POSSIBLE | LIKELY | VERY_LIKELY
//   - adult    (treści dla dorosłych / pornografia)
//   - violence (przemoc, gore)
//   - racy      (sugestywne, ale nie pornografia)
//   - medical
//   - spoof
//
// Decyzja (analogicznie do ai_moderation tekstu):
//   { action: 'allow' | 'review' | 'block', reason: string }
//   - adult/violence == VERY_LIKELY                 → block
//   - adult/violence == LIKELY  lub racy==VERY_LIKELY → review (status hidden)
//   - reszta                                         → allow
//
// Fail-open: jeśli Vision padnie (timeout/quota/error) → allow.
// Cena: ~$1.50 / 1000 obrazów (SafeSearch feature).

const LIKELIHOOD = {
  UNKNOWN: 0, VERY_UNLIKELY: 1, UNLIKELY: 2, POSSIBLE: 3, LIKELY: 4, VERY_LIKELY: 5,
};

let _client = null;
function client() {
  if (_client) return _client;
  try {
    const vision = require('@google-cloud/vision');
    _client = new vision.ImageAnnotatorClient();
    return _client;
  } catch (e) {
    console.error('[image_moderation] Vision init failed:', e.message);
    return null;
  }
}

/**
 * Moderuje obraz przez Vision SafeSearch.
 * @param {Buffer} buffer surowe bajty obrazu
 * @returns {Promise<{action:'allow'|'review'|'block', reason:string, scores?:object}>}
 */
async function moderateImage(buffer) {
  if (!buffer || !buffer.length) return { action: 'allow', reason: 'empty' };
  const c = client();
  if (!c) return { action: 'allow', reason: 'vision_unavailable' };

  try {
    const result = await Promise.race([
      c.safeSearchDetection({ image: { content: buffer } }),
      new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 6000)),
    ]);
    const ss = result?.[0]?.safeSearchAnnotation;
    if (!ss) return { action: 'allow', reason: 'no_annotation' };

    const adult = LIKELIHOOD[ss.adult] ?? 0;
    const violence = LIKELIHOOD[ss.violence] ?? 0;
    const racy = LIKELIHOOD[ss.racy] ?? 0;
    const scores = { adult: ss.adult, violence: ss.violence, racy: ss.racy };

    if (adult >= LIKELIHOOD.VERY_LIKELY || violence >= LIKELIHOOD.VERY_LIKELY) {
      return { action: 'block', reason: `adult=${ss.adult} violence=${ss.violence}`, scores };
    }
    if (adult >= LIKELIHOOD.LIKELY || violence >= LIKELIHOOD.LIKELY || racy >= LIKELIHOOD.VERY_LIKELY) {
      return { action: 'review', reason: `adult=${ss.adult} violence=${ss.violence} racy=${ss.racy}`, scores };
    }
    return { action: 'allow', reason: 'safe', scores };
  } catch (e) {
    console.error('[image_moderation] error:', e.message);
    return { action: 'allow', reason: `vision_error:${e.message.slice(0, 50)}` };
  }
}

module.exports = { moderateImage };
