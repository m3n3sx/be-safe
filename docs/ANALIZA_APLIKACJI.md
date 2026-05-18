# be:Safe — analiza aplikacji

> **Data analizy:** 2026-05-18  
> **Zakres:** przegląd repozytorium `be-safe` (backend, mobile, web, baza, CI, dokumentacja)  
> **Powiązane dokumenty:** [README.md](../README.md), [PLAN_BEZPIECZENSTWA.md](./PLAN_BEZPIECZENSTWA.md), [FULL_DOCUMENTATION.md](./FULL_DOCUMENTATION.md), [API.md](./API.md), [DATABASE.md](./DATABASE.md), [INFRASTRUCTURE.md](./INFRASTRUCTURE.md)

---

## 1. Czym jest aplikacja

**be:Safe** (kod wewnętrzny: AlertMap, pakiet mobilny: `pl.u235.alertmap`) to **społecznościowy system ostrzegania o zagrożeniach** w czasie rzeczywistym. Użytkownicy zgłaszają zdarzenia na mapie; inni w pobliżu widzą je, potwierdzają lub odrzucają. Produkt rozszerza ten rdzeń o:

- **Family Tracking** — grupy rodzinne, śledzenie pozycji dzieci, geofence, check-in „jestem bezpieczny”
- **SOS** — szybkie zgłoszenie krytyczne z lokalizacją GPS
- **Ranking, odznaki, statystyki okolicy** — gamifikacja i analityka lokalna
- **Integracje zewnętrzne** — ostrzeżenia IMGW (pogoda), zdarzenia drogowe GDDKiA
- **Udostępnianie lokalizacji** — tymczasowy link publiczny (mapa Leaflet po stronie API)

**Platformy:**

| Klient | Technologia | Rola |
|--------|-------------|------|
| Mobile (Android, iOS) | Flutter 3.x / Dart | Główny produkt: mapa, GPS w tle, FCM, SOS |
| Web | Next.js 16 / React 19 / TypeScript | Mapa i funkcje core w przeglądarce |
| Landing | Next.js (`/landing`) | Strona marketingowa |
| API | Node.js / Express / Socket.IO | REST + WebSocket, PostgreSQL + PostGIS |

Produkcyjna domena docelowa to **`besafe.org.pl`**; w kodzie wciąż występują odniesienia do starszej **`alert.u235.pl`** (web, endpoint `/version`, linki track).

---

## 2. Architektura — jak to jest złożone

Monorepo bez wspólnego pakietu typów — trzy klienty + jeden backend + schemat SQL.

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter (mobile)          Next.js (web)                     │
│  Provider + services       Context API (Auth, Socket, Theme) │
│  ApiService, SocketService api.ts, SocketContext             │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTPS  /api/v1/*
                             │ WSS    Socket.IO (JWT w query)
                    ┌────────┴────────┐
                    │  Express API    │
                    │  + Socket.IO    │
                    │  helmet, CORS,  │
                    │  rate limits    │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │ PostgreSQL      │
                    │ + PostGIS       │
                    └─────────────────┘
```

**Backend** (`backend/src/`):

- `index.js` — serwer HTTP, Socket.IO, cron wygaszania alertów, sync IMGW/GDDKiA, publiczny tracker HTML
- `routes/` — `auth`, `users`, `alerts`, `family`, `community`, `events`
- `middleware/auth.js` — JWT Bearer
- `services/` — email, FCM (`firebase-admin`), IMGW, GDDKiA

**Mobile** (`mobile/lib/`): ekrany po funkcji (`screens/`), stan w `providers/`, integracje w `services/` (API, socket, lokalizacja, cache SQLite, FCM, background service).

**Web** (`web/src/`): App Router (`app/`), komponenty mapy i alertów, konteksty w `contexts/`, klient HTTP w `lib/api.ts`.

**Baza** (`db/schema.sql`): rdzeń domeny z typami ENUM, indeksami GIST i triggerem ukrywania alertów po >3 głosach „deny”. Część tabel używana w kodzie (np. `email_verification_tokens`, odznaki, analytics) **nie jest w pełni odzwierciedlona** w tym jednym pliku — migracje nie są single source of truth.

---

## 3. Jak rozumiem działanie aplikacji

### 3.1 Autentykacja i sesja

1. Rejestracja / logowanie (`POST /api/v1/auth/*`) → hasło hashowane `bcrypt`, zwrot **JWT**.
2. Klienci dołączają token w nagłówku `Authorization: Bearer …`.
3. Web trzyma JWT w `localStorage`; mobile w `SharedPreferences`.
4. Socket.IO wymaga tokenu w `handshake.query.token` — po połączeniu socket dołącza do pokoju `user:{id}`.

Obsługiwane są też: weryfikacja e-mail, reset hasła, Google Sign-In (mobile/web), konto demo, kody polecające.

### 3.2 Mapa i alerty (rdzeń produktu)

1. Użytkownik udostępnia lokalizację (REST lub WebSocket `location:update`).
2. Mapa pobiera alerty w promieniu: `GET /alerts/nearby` — PostGIS `ST_DWithin`, tylko `status = active` i `expires_at > NOW()`.
3. **Tworzenie alertu:** kategoria (18 typów w ENUM), tytuł, opis, zdjęcie (multer, max 5 MB), punkt GIS, czas życia (domyślnie kilka godzin).
4. Po utworzeniu: powiadomienia użytkownikom w ich `alert_radius_m` (WebSocket `alert:new`, FCM jeśli skonfigurowane).
5. **Głosowanie:** confirm / deny — trigger SQL zwiększa liczniki; przy **>3 deny** alert przechodzi w `hidden`.
6. **Wygasanie:** co 60 s serwer ustawia `expired` i emituje `alert:expired`.
7. Komentarze pod alertem — REST + pokoje Socket.IO `alert:{id}` (join/leave, typing).

### 3.3 SOS

Ekran SOS (mobile) po przytrzymaniu tworzy alert o wysokim priorytecie (kategoria agresja, większy promień powiadomień) — **ten sam pipeline co zwykły alert**, bez osobnej encji w bazie.

### 3.4 Family Tracking

1. Rodzic zakłada grupę (`family_groups` + kod zaproszenia).
2. Dziecko dołącza z rolą `child`; flaga `is_child` na użytkowniku.
3. Lokalizacja dziecka (socket) → zapis w `users.last_location` + `location_history`.
4. Rodzice w grupie dostają `family:location` w czasie rzeczywistym.
5. **Geofence:** jeśli dziecko opuści okrąg (`NOT ST_DWithin`) → `family:geofence_exit` do rodziców.
6. Niski poziom baterii dziecka → `family:low_battery`.
7. **Share link:** token w `share_links`, publiczny HTML `/track/:token` z odświeżaniem co 10 s.

### 3.5 Pozostałe moduły

- **Statystyki / heatmapa** — agregacje SQL w promieniu od punktu.
- **Ranking** — TOP użytkowników wg liczby alertów i `reputation_score` (start 100; automatyczne kary w kodzie są ograniczone).
- **Odznaki i community** — `community` routes, auto-przyznawanie po kamieniach milowych.
- **Wersjonowanie APK** — `GET /version`, `GET /download`; mobile sprawdza aktualizacje.
- **Analityka** — `POST /events` (tabela tworzona runtime w `events.js`).

### 3.6 Realtime — dwa kanały

| Mechanizm | Zastosowanie |
|-----------|----------------|
| Socket.IO | Nowe/zmienione alerty, komentarze, rodzina, geofence |
| Polling `/alerts/new?since=` | Powiadomienia w tle na mobile gdy socket niedostępny |
| FCM | Push (wymaga Firebase; często opcjonalny w dev) |

---

## 4. Model danych (skrót)

Główne tabele w `db/schema.sql`:

| Encja | Opis |
|-------|------|
| `users` | Konto, reputacja, promień alertów, ostatnia pozycja (GEOGRAPHY) |
| `alerts` | Zgłoszenie z kategorią, statusem, głosami, wygaśnięciem |
| `alert_votes` | confirm / deny (unikalny głos na użytkownika) |
| `family_groups`, `family_members` | Grupy rodzinne, role parent/child |
| `geofences` | Bezpieczne strefy w grupie |
| `location_history` | Historia tras dzieci |
| `share_links` | Tymczasowe udostępnienie pozycji |
| `alert_comments` | Wątek pod alertem |

Statusy alertu: `active` → `expired` | `hidden` | `removed`.

---

## 5. Infrastruktura i CI (skrót)

- **Hosting:** VPS (AWS EC2 pod `besafe.org.pl`), Nginx SSL, PM2 (API ~3001, Next ~3005).
- **CI** (`.github/workflows/build-deploy.yml`): build APK/AAB Flutter, deploy na VPS, rsync backendu; **brak jobów testowych**; zmiany w `web/` nie uruchamiają pipeline.
- Szczegóły kont, DNS, maili: [INFRASTRUCTURE.md](./INFRASTRUCTURE.md) — **uwaga:** ten plik zawiera dane wrażliwe w plaintext; nie powinien być commitowany do publicznego repo bez redakcji.

---

## 6. Wnioski z pięciu perspektyw

### Architektura i modularność

**Mocne strony:** czytelny podział katalogów na klientach, jeden kontrakt REST `/api/v1`, sensowne podstawy bezpieczeństwa HTTP, cache offline na mobile.

**Ryzyka:** logika realtime i geofencing w „grubym” `index.js`; brak warstwy domenowej/repository w backendzie; duplikacja `ApiService` (Dart/TS) i enumów kategorii; rozjazd `schema.sql` z kodem produkcyjnym; brak Redis przy skalowaniu Socket.IO.

### Domena biznesowa

Produkt jest spójny: **mapa zagrożeń + zaufanie społeczności (głosy) + warstwa rodzinna**. Reguły wygaszania i ukrywania są jasne i zaimplementowane (SQL + cron). Reputacja i ranking są częściowo „deklaratywne” — niewiele logiki automatycznie zmienia `reputation_score` po głosach.

### Bezpieczeństwo

**Dobrze:** JWT + bcrypt, helmet, rate limiting na auth i tworzeniu alertów, walidacja uploadów alertów.

**Do poprawy (priorytet):** sekrety w dokumentacji infra; Google auth bez weryfikacji tokena po stronie serwera; możliwy IDOR na avatarze; CORS `*`; JWT w query string socketów i `localStorage`; brak rate limitu na publicznym `/track`; potencjalna interpolacja SQL w check-in (weryfikacja w `users.js`).

### Testy i walidacja

| Warstwa | Stan |
|---------|------|
| Backend | Brak testów automatycznych |
| Web | `eslint`, `next build` — tylko lokalnie |
| Mobile | Jeden szablonowy `widget_test.dart` (niezgodny z `AlertMapApp`) |
| CI | Tylko build/release, bez QA |

Lokalna walidacja przed zmianami: `flutter analyze`, `npm run lint && npm run build` (web), ręczne testy API.

### Developer experience

Bogata dokumentacja operacyjna w `docs/`, słaby onboarding (brak root README, web README to szablon Next.js). Dev wymaga ręcznego Postgres + `.env` backendu; mobile/web mają **hardcoded produkcyjne URL-e**. Folder `design/` to bogata specyfikacja UI (HTML Stitch), nie gotowe assety produkcyjne.

---

## 7. Struktura repozytorium

```
be-safe/
├── backend/          # API Node.js
├── mobile/           # Aplikacja Flutter
├── web/              # Aplikacja Next.js
├── db/               # schema.sql (PostGIS)
├── docs/             # Dokumentacja
├── design/           # Mockupy Stitch / prompty UI
└── .github/workflows # CI build & deploy
```

---

## 8. Rekomendacje (kolejność)

1. **Bezpieczeństwo:** wdrożyć [PLAN_BEZPIECZENSTWA.md](./PLAN_BEZPIECZENSTWA.md) (P0: sekrety, Google auth, SQL check-in).
2. **Spójność:** ujednolicić domeny API (`besafe.org.pl` vs `alert.u235.pl`); dodać `web/.env.example` i konfigurację env dla mobile.
3. **Baza:** jeden mechanizm migracji odzwierciedlający wszystkie tabele używane w routes.
4. **Testy:** minimalny zestaw testów API (auth, alerts nearby, vote) + naprawa lub usunięcie martwego `widget_test.dart`; job CI: `flutter analyze`, `npm run lint`, `npm run build`.
5. **Architektura:** wydzielić moduł realtime/geofence z `index.js`; rozważyć adapter Redis dla Socket.IO przy wzroście ruchu.

---

## 9. Podsumowanie jednym akapitem

**be:Safe** to dojrzały prototyp/produkt monorepo łączący mapę zagrożeń crowdsourcingowych z modułem rodzinnym i kanałami realtime. Architektura **3 klientów + API PostGIS** jest zrozumiała i spójna na poziomie folderów; logika biznesowa jest silnie zakotwiczona w PostgreSQL (geolokalizacja, głosy, wygasanie). Największe luki to **bezpieczeństwo auth/uploadów**, **brak testów i CI dla web/backend**, **rozjazd schematu bazy z kodem** oraz **DX onboardingowy**. Do dalszej pracy technicznej najlepszym uzupełnieniem tego dokumentu pozostaje [FULL_DOCUMENTATION.md](./FULL_DOCUMENTATION.md) (szczegóły endpointów, ekranów, deploy).
