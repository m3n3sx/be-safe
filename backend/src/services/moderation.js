// F05 Alert text moderation
//
// Heurystyczna analiza tytułu + opisu alertu pod kątem spamu/trolla.
// Zwraca { score, reasons }:
//   - score 0-100 (100 = bardzo prawdopodobnie troll/spam)
//   - reasons: lista rule-id które zadziałały (np. ['profanity', 'all_caps', 'repeated_chars'])
//
// Backend POST /alerts decyduje:
//   - score >= 80 → odrzuca alert (HTTP 422) z reason
//   - score 40-79 → zapisuje ale flag=auto_moderated, status='hidden'
//   - score < 40 → normalna publikacja
//
// W przyszłości można podłączyć Vertex AI / OpenAI Moderation API.

const PROFANITY = [
  // polski profanity list - subset
  'kurwa', 'chuj', 'chuja', 'pierdol', 'jebać', 'jebac', 'jebany', 'pizda',
  'huj', 'cipa', 'dupek', 'cwel', 'spadaj', 'idioci',
  // english
  'fuck', 'shit', 'bitch', 'asshole', 'dick', 'pussy',
];

const TROLL_PATTERNS = [
  /aaaa+/i,                 // długie 'aaaa'
  /test\s*test/i,           // 'test test'
  /(.)\1{4,}/,              // 5+ tych samych znaków pod rząd
  /(?:lol|xd|haha){3,}/i,   // spam śmiechu
  /^[\W_]+$/,               // sam interpunkcja
];

function check(text) {
  if (!text || typeof text !== 'string') return { score: 0, reasons: [] };
  const lower = text.toLowerCase();
  const reasons = [];
  let score = 0;

  // 1. Profanity
  const profanityHits = PROFANITY.filter(w => lower.includes(w));
  if (profanityHits.length > 0) {
    score += 40 + profanityHits.length * 10;
    reasons.push(`profanity:${profanityHits.length}`);
  }

  // 2. ALL CAPS w dłuższym tekście
  const letters = text.replace(/[^a-zA-ZąęćłńóśźżĄĘĆŁŃÓŚŹŻ]/g, '');
  if (letters.length > 15) {
    const upper = letters.replace(/[^A-ZĄĘĆŁŃÓŚŹŻ]/g, '');
    if (upper.length / letters.length > 0.7) {
      score += 25;
      reasons.push('all_caps');
    }
  }

  // 3. Troll patterns
  for (const p of TROLL_PATTERNS) {
    if (p.test(text)) {
      score += 30;
      reasons.push(`pattern:${p.source.slice(0, 20)}`);
    }
  }

  // 4. Sam emoji bez treści
  const stripped = text.replace(/[\p{Emoji}\s]/gu, '');
  if (text.length >= 10 && stripped.length < 3) {
    score += 35;
    reasons.push('only_emoji');
  }

  // 5. Bardzo krótkie + brak treści informacyjnej
  if (text.trim().length < 4) {
    score += 20;
    reasons.push('too_short');
  }

  return { score: Math.min(score, 100), reasons };
}

/**
 * Zwraca werdykt moderacji dla pary (title, description).
 * action: 'allow' | 'flag' | 'block'
 */
function moderate({ title, description }) {
  const t = check(title || '');
  const d = check(description || '');
  const maxScore = Math.max(t.score, d.score);
  const reasons = [...t.reasons.map(r => `title:${r}`), ...d.reasons.map(r => `desc:${r}`)];

  let action = 'allow';
  if (maxScore >= 80) action = 'block';
  else if (maxScore >= 40) action = 'flag';

  return { action, score: maxScore, reasons };
}

module.exports = { moderate, check };
