// F06 AI text moderation (Vertex AI Gemini)
//
// Druga warstwa moderacji ponad heurystyką w services/moderation.js:
//   - Heurystyka łapie oczywiste (profanity, all-caps, troll patterns).
//   - AI łapie subtelne (false reports, hate speech, spam, off-topic).
//
// Klasyfikacja zwraca:
//   { action: 'allow' | 'review' | 'block', confidence: 0-1, reason: string }
//
//   - action='block'  + confidence>=0.85 → backend ustawia status='hidden'
//                                          + insert do alert_reports z reason='ai_moderation'
//                                          + admin reviewuje w /admin/reports.
//   - action='review' + confidence>=0.6   → status='hidden' (jak block, miękki).
//   - action='allow'                      → publikacja normalna.
//
// Jeśli Vertex API zawiedzie (timeout/quota/error) → fail-open (allow).
// Cena: Gemini 1.5 Flash ~$0.075/1M input + $0.30/1M output → ~$0.0001/zgłoszenie.

const PROJECT_ID = process.env.GCP_PROJECT_ID || 'project-1674d55f-90e0-4e1a-884';
// Gemini Flash NIE jest dostepny w europe-central2 (404). Uzywamy europe-west1 (Belgia)
// — pelna dostepnosc modeli, latency Cloud Run -> Vertex ~15-30ms (akceptowalne).
const LOCATION = process.env.VERTEX_LOCATION || 'europe-west1';
// Gemini 2.5 Flash — sprawdzone dzialajace w europe-west1 (1.5 zwracalo 404 po deprecacji).
const MODEL = process.env.VERTEX_MODEL || 'gemini-2.5-flash';

let _client = null;
function client() {
  if (_client) return _client;
  try {
    const { VertexAI } = require('@google-cloud/vertexai');
    _client = new VertexAI({ project: PROJECT_ID, location: LOCATION });
    return _client;
  } catch (e) {
    console.error('[ai_moderation] VertexAI init failed:', e.message);
    return null;
  }
}

const SYSTEM_PROMPT = `Jesteś moderatorem aplikacji be:Safe - serwisu zgłoszeń zagrożeń w okolicy.
Analizujesz tytuł i opis zgłoszenia od użytkownika.
Twoje zadanie: ocenić czy zgłoszenie jest UCZCIWE czy SZKODLIWE.

SZKODLIWE (block):
- Spam, reklama, sprzedaż
- Hate speech (atak rasowy, religijny, seksualny, narodowościowy)
- False reports - oczywiście zmyślone zagrożenia (np. "kosmici lądują", "smoki w parku")
- Doxxing - ujawnianie czyichś danych osobowych
- Treści seksualne, gore, obraźliwe wobec osób
- Treści polityczne propagandowe (nie dotyczy zgłoszenia "Protest na rynku" które jest faktem)

WĄTPLIWE (review):
- Niejasny opis, zbyt krótki ale bez profanity
- Zgłoszenie ALE bez kategorii pasującej do treści (np. tytuł "Pies" w kategorii 'fire')
- Możliwe że żart ale niepewne

UCZCIWE (allow):
- Normalne zgłoszenia zagrożeń (agresja, kradzież, wypadek, pożar, powódź itd.)
- Nawet emocjonalne ALE konkretne (np. "Pijany chłopak grozi przechodniom")
- Opisy z imionami/lokalizacjami (to dla rozpoznania)

Zwracasz TYLKO JSON: {"action":"allow|review|block","confidence":0.0-1.0,"reason":"krótkie uzasadnienie po polsku"}
Bez dodatkowego tekstu, markdown, komentarzy.`;

function _buildUserPrompt({ title, description, category }) {
  return `Kategoria: ${category || '?'}\nTytuł: ${title || ''}\nOpis: ${description || ''}`;
}

function _parseResponse(text) {
  if (!text) return null;
  // Wytnij JSON z markdown code-block jeśli model owinął
  const cleaned = text.replace(/^```(?:json)?\s*/i, '').replace(/\s*```\s*$/i, '').trim();
  try {
    const obj = JSON.parse(cleaned);
    const action = ['allow', 'review', 'block'].includes(obj.action) ? obj.action : 'allow';
    const confidence = typeof obj.confidence === 'number'
      ? Math.max(0, Math.min(1, obj.confidence)) : 0.5;
    const reason = typeof obj.reason === 'string' ? obj.reason.slice(0, 200) : '';
    return { action, confidence, reason };
  } catch (e) {
    console.warn('[ai_moderation] parse failed:', text.slice(0, 100));
    return null;
  }
}

async function moderateText({ title, description, category }) {
  const c = client();
  if (!c) return { action: 'allow', confidence: 0, reason: 'ai_unavailable' };

  // Skip pusty content
  if (!title && !description) return { action: 'allow', confidence: 0, reason: 'empty' };

  try {
    const model = c.getGenerativeModel({
      model: MODEL,
      systemInstruction: SYSTEM_PROMPT,
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 300,
        responseMimeType: 'application/json',
        responseSchema: {
          type: 'OBJECT',
          properties: {
            action: { type: 'STRING', enum: ['allow', 'review', 'block'] },
            confidence: { type: 'NUMBER' },
            reason: { type: 'STRING' },
          },
          required: ['action', 'confidence', 'reason'],
        },
      },
    });

    const result = await Promise.race([
      model.generateContent({
        contents: [{ role: 'user', parts: [{ text: _buildUserPrompt({ title, description, category }) }] }],
      }),
      new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 5000)),
    ]);

    const text = result?.response?.candidates?.[0]?.content?.parts?.[0]?.text;
    const parsed = _parseResponse(text);
    if (!parsed) return { action: 'allow', confidence: 0, reason: 'parse_failed' };
    return parsed;
  } catch (e) {
    console.error('[ai_moderation] error:', e.message);
    // Fail-open: jeśli AI padło, nie blokujemy publikacji
    return { action: 'allow', confidence: 0, reason: `ai_error:${e.message.slice(0, 50)}` };
  }
}

module.exports = { moderateText };
