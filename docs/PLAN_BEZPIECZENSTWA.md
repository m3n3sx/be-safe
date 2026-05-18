# Plan naprawy bezpieczeństwa — be:Safe

> **Data:** 2026-05-18  
> **Powiązane:** [ANALIZA_APLIKACJI.md](./ANALIZA_APLIKACJI.md)  
> **Status:** plan do wdrożenia (nie wykonany w tym dokumencie)

Plan uporządkowany według **P0 → P2**. Każdy punkt ma: problem, ryzyko, działanie, pliki, kryterium akceptacji.

---

## Legenda priorytetów

| Priorytet | Znaczenie | Termin sugerowany |
|-----------|-----------|-------------------|
| **P0** | Eksploatacja możliwa bez specjalnych uprawnień lub wyciek sekretów | Natychmiast |
| **P1** | Wysokie ryzyko przy zalogowanym użytkowniku lub XSS | 1–2 tygodnie |
| **P2** | Wzmocnienie obrony, hardening, DX bezpieczeństwa | Backlog |

---

## P0 — Krytyczne

### P0.1 Sekrety w repozytorium (`docs/INFRASTRUCTURE.md`)

**Problem:** Plik zawiera hasła, klucze API, tokeny w plaintext (AWS, Cloudflare, JWT, DB, SMTP itd.).

**Ryzyko:** Przejęcie infrastruktury po wycieku repo lub logów.

**Działania:**

1. Usunąć wartości sekretów z pliku; zostawić tylko nazwy zmiennych i **gdzie** je ustawić (1Password / AWS Secrets Manager / GitHub Secrets).
2. Dodać `docs/INFRASTRUCTURE.example.md` ze strukturą bez wartości.
3. Dodać do `.gitignore` lokalny `docs/INFRASTRUCTURE.local.md` jeśli potrzebny.
4. **Zrotować wszystkie ujawnione klucze** (AWS IAM, Cloudflare token, JWT_SECRET, hasła DB, SES SMTP, klucze OAuth).
5. Przeskanować historię Gita (`git log -p`) — rozważyć `git filter-repo` lub BFG jeśli repo było publiczne.

**Kryterium akceptacji:** `grep` po repo nie znajduje wzorców `AKIA`, `cfut_`, pełnych haseł; produkcja działa na nowych sekretach.

---

### P0.2 Google Sign-In bez weryfikacji tokena

**Problem:** `POST /api/v1/auth/google` przyjmuje `email`, `display_name`, `avatar_url` z body bez weryfikacji Google ID Token.

**Plik:** `backend/src/routes/auth.js` (ok. linia 97).

**Ryzyko:** Logowanie na cudze konto przez podanie dowolnego emaila.

**Działania:**

1. Klient (mobile/web) wysyła wyłącznie `id_token` (lub `access_token` + weryfikacja userinfo).
2. Serwer weryfikuje token przez `google-auth-library` (`OAuth2Client.verifyIdToken`) z `GOOGLE_CLIENT_ID` z env.
3. Email i `sub` bierzemy **wyłącznie** z payloadu tokena, nie z body.
4. Mapowanie kont: `google_sub` w tabeli `users` (migracja SQL).

**Kryterium akceptacji:** Request z samym `email` w body zwraca `401`; poprawny token Google zwraca JWT.

---

### P0.3 SQL injection w check-in

**Problem:** W `POST /users/me/checkin` współrzędne są wstawiane przez interpolację stringa:

```javascript
const loc = (lat != null && lng != null) ? `ST_MakePoint(${lng}, ${lat})::geography` : 'NULL';
```

**Plik:** `backend/src/routes/users.js` (ok. linia 151).

**Ryzyko:** Wykonanie dowolnego SQL przy złośliwym `lat`/`lng`.

**Działania:**

1. Walidacja: `lat`, `lng` jako liczby (`Number`, zakres -90..90 / -180..180).
2. Parametryzacja: `ST_MakePoint($n, $m)::geography` z placeholderami `$1..$n`.
3. Test jednostkowy z payloadem `'); DROP TABLE users;--`.

**Kryterium akceptacji:** Złośliwy string w `lat` nie zmienia struktury zapytania; błąd walidacji `400`.

---

## P1 — Wysokie

### P1.1 IDOR — upload avatara dowolnego użytkownika

**Problem:** `POST /users/:id/avatar` wymaga JWT, ale nie sprawdza, czy `req.user.id === :id` ani relacji rodziny.

**Plik:** `backend/src/routes/users.js` (ok. linia 21).

**Działania:**

1. Zezwolić upload gdy `req.user.id === req.params.id`.
2. Opcjonalnie: rodzic w tej samej grupie co dziecko (`family_members`) może ustawić avatar dziecka — jawna reguła w kodzie + test.
3. Dodać `fileFilter` (tylko `image/jpeg`, `image/png`, `image/webp`) jak w `alerts.js`.
4. Ignorować rozszerzenie z `originalname`; użyć stałego `.jpg` lub magic bytes.

**Kryterium akceptacji:** Użytkownik A nie może zmienić avatara użytkownika B bez relacji rodzinnej.

---

### P1.2 CORS i Socket.IO `origin: '*'`

**Problem:** `app.use(cors())` bez whitelisty; Socket.IO `cors: { origin: '*' }`.

**Plik:** `backend/src/index.js`.

**Ryzyko:** Dowolna strona w przeglądarce może wołać API z tokenem ofiary (jeśli token w JS).

**Działania:**

1. `CORS_ORIGINS` w `.env` (lista: `https://besafe.org.pl`, `http://localhost:3000`, …).
2. `cors({ origin: (origin, cb) => ... })` — odrzucać nieznane originy w produkcji.
3. Socket.IO: ta sama whitelista; w dev opcjonalnie `*`.

**Kryterium akceptacji:** Request z `Origin: https://evil.example` na produkcji → brak nagłówka CORS / odrzucenie.

---

### P1.3 JWT w `localStorage` i query string Socket.IO

**Problem:** Web: `localStorage` (`web/src/lib/api.ts`); socket: `handshake.query.token`.

**Ryzyko:** XSS → przejęcie sesji; token w logach proxy.

**Działania (fazowane):**

1. **Krótkoterminowo:** Content-Security-Policy w Next.js; sanityzacja XSS w komentarzach; HttpOnly nie dotyczy localStorage — minimalizować `dangerouslySetInnerHTML`.
2. **Docelowo:** JWT w **HttpOnly Secure SameSite** cookie; endpoint `POST /auth/refresh`; socket auth przez cookie lub krótkotrwały token z dedykowanego `POST /auth/socket-token` (jednorazowy, 30 s).
3. Usunąć token z query — przekazać w `auth: { token }` (socket.io v4) po migracji klientów.

**Kryterium akceptacji:** Token nie pojawia się w URL w DevTools Network; dokumentacja auth zaktualizowana.

---

### P1.4 Publiczny endpoint `/track` bez rate limitu

**Problem:** `GET /api/v1/track/:token` i HTML `/track/:token` bez limitu; enumeracja tokenów teoretycznie kosztowna, ale scraping możliwy.

**Plik:** `backend/src/index.js`.

**Działania:**

1. `rateLimit` na `/api/v1/track` i `/track` (np. 30 req/min/IP).
2. Opcjonalnie: CAPTCHA po N żądaniach.
3. Ujednolicić URL share z `APP_URL` (obecnie mix `alert.u235.pl` / `besafe.org.pl` w `users.js` linia 115).

**Kryterium akceptacji:** 429 po przekroczeniu limitu; link share używa `process.env.APP_URL`.

---

### P1.5 Upload avatara — brak walidacji MIME

**Problem:** Multer avatara bez `fileFilter`; nazwa z `path.extname(file.originalname)`.

**Działania:** Jak P1.1 + limit rozmiaru już jest (2 MB). Rozważyć upgrade `multer` 1.x → 2.x (CVE).

---

## P2 — Wzmocnienie

### P2.1 Hasła i konto demo

- Minimum hasła: 12 znaków + złożoność (rejestracja, zmiana hasła).
- Ograniczyć lub wyłączyć `/auth/demo` na produkcji (`NODE_ENV`).

### P2.2 Rate limiting share / auth

- Rozszerzyć limity na `forgot-password`, `verify-email` (anty-spam).
- Logowanie nieudanych prób (bez ujawniania email).

### P2.3 Socket.IO skalowanie

- Przy wielu instancjach: adapter Redis + wspólna autoryzacja.
- Audyt pokoi: użytkownik nie może `join` cudzego `user:{id}`.

### P2.4 Nagłówki i monitoring

- `helmet` — doprecyzować CSP.
- Sentry po stronie API (błędy auth, 429).
- Alert na nietypowy wolumen `POST /auth/google`.

### P2.5 Zależności

- `npm audit` w `backend/` i `web/` w CI.
- Pin wersji krytycznych pakietów.

---

## Kolejność wdrożenia (sprint)

| Krok | Zadanie | Szacunek |
|------|---------|----------|
| 1 | P0.1 Rotacja sekretów + redakcja INFRASTRUCTURE | 2–4 h |
| 2 | P0.3 SQL check-in | 1 h |
| 3 | P0.2 Google token verify | 4–6 h |
| 4 | P1.1 Avatar IDOR + MIME | 2 h |
| 5 | P1.2 CORS whitelist | 1 h |
| 6 | P1.4 Rate limit /track | 1 h |
| 7 | P1.3 Cookie auth (większy) | 1–2 dni |
| 8 | P2.* backlog | ciągłe |

---

## Testy regresji (po każdej zmianie P0/P1)

```bash
# Health
curl -s http://localhost:3000/health

# Auth — zły Google (powinien 401 po P0.2)
curl -s -X POST http://localhost:3000/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{"email":"victim@example.com"}'

# Check-in — zły lat (powinien 400 po P0.3)
curl -s -X POST http://localhost:3000/api/v1/users/me/checkin \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"lat":"1; DROP TABLE users--","lng":21}'

# Web build
cd web && npm run lint && npm run build
```

Docelowo: testy automatyczne (Jest/supertest) dla auth, check-in, avatar — patrz [ANALIZA_APLIKACJI.md](./ANALIZA_APLIKACJI.md).

---

## Odpowiedzialności

| Obszar | Właściciel sugerowany |
|--------|------------------------|
| Rotacja sekretów / infra | DevOps / właściciel AWS |
| Backend auth & SQL | Backend dev |
| Web cookie / CSP | Frontend |
| Mobile Google Sign-In | Mobile dev |
| Weryfikacja | QA + smoke powyżej |

---

*Po wdrożeniu P0 zaktualizuj [ANALIZA_APLIKACJI.md](./ANALIZA_APLIKACJI.md) (sekcja bezpieczeństwa) i zamknij odpowiednie punkty w tym planie.*
