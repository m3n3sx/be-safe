# be:Safe — Pełna Dokumentacja Techniczna

> Wygenerowano: 2026-05-03 | Wersja aplikacji: 17 | Wersja backendu (index.js): 12 | Wersja web: 0.1.0

---

## Spis treści

1. [Przegląd projektu](#1-przegląd-projektu)
2. [Architektura](#2-architektura)
3. [Infrastruktura i deployment](#3-infrastruktura-i-deployment)
4. [Backend — szczegółowa dokumentacja](#4-backend--szczegółowa-dokumentacja)
5. [Baza danych](#5-baza-danych)
6. [Aplikacja mobilna — szczegółowa dokumentacja](#6-aplikacja-mobilna--szczegółowa-dokumentacja)
7. [Aplikacja webowa — szczegółowa dokumentacja](#7-aplikacja-webowa--szczegółowa-dokumentacja)
8. [Strona marketingowa (Landing Page)](#8-strona-marketingowa-landing-page)
9. [Konfiguracja Google Cloud](#9-konfiguracja-google-cloud)
10. [Budowanie i testowanie](#10-budowanie-i-testowanie)
11. [Znane problemy i TODO](#11-znane-problemy-i-todo)
12. [Wytyczne dla kontynuacji przez AI](#12-wytyczne-dla-kontynuacji-przez-ai)

---

## 1. Przegląd projektu

**Nazwa:** be:Safe (wewnętrzna nazwa kodowa: AlertMap, package: `pl.u235.alertmap`)

**Cel:** Mobilna aplikacja bezpieczeństwa działająca jako community-driven system ostrzeżeń o zagrożeniach w czasie rzeczywistym.

**Opis:** Użytkownicy zgłaszają niebezpieczeństwa (18 kategorii), które pojawiają się na mapie Google Maps. Aplikacja proaktywnie powiadamia o zagrożeniach w okolicy użytkownika przez WebSocket, polling i lokalne notyfikacje. Moduł **Family Tracking** pozwala rodzicom śledzić lokalizację dzieci i otrzymywać alerty dotyczące ich otoczenia, w tym naruszenia geofence'ów (bezpiecznych stref).

**Platformy:**
- Aplikacja mobilna (Android) — Flutter/Dart
- Aplikacja webowa — Next.js/React/TypeScript (https://alert.u235.pl)
- Strona marketingowa — Next.js (https://alert.u235.pl/landing)

**Główne funkcje:**
- Mapa zagrożeń w czasie rzeczywistym (Google Maps)
- Zgłaszanie zagrożeń z 18 kategoriami, zdjęciami, opisem
- System głosowania (potwierdzenia/odrzucenia) z automatycznym ukrywaniem
- Przycisk SOS — natychmiastowy alert z lokalizacją
- Family Tracking — grupy rodzinne, śledzenie dzieci, geofence
- Ranking użytkowników i system reputacji
- Statystyki okolicy (trend 14 dni, top zagrożenia 30 dni, heatmapa)
- Udostępnianie lokalizacji przez tymczasowy link (strona Leaflet)
- Komentarze pod alertami
- Wersjonowanie APK z automatycznym sprawdzaniem aktualizacji
- Wielojęzyczność (PL/EN)
- Dynamic Color (Material You) + dark/light theme (mobile), dark/light/system (web)
- Offline cache alertów (SQLite — mobile)

---

## 2. Architektura

### Diagram

```
┌──────────────────────────────────────────────────────┐
│                 FLUTTER APP (Dart)                    │
│  ┌──────────┐ ┌──────────┐ ┌───────────────────────┐ │
│  │   Mapa   │ │  Alerty  │ │   Family Tracking     │ │
│  │ (Google  │ │  (CRUD,  │ │ (grupy, geofence,     │ │
│  │  Maps)   │ │  głosy,  │ │  lokalizacja dzieci)  │ │
│  │          │ │  SOS)    │ │                       │ │
│  └────┬─────┘ └────┬─────┘ └──────────┬────────────┘ │
│       └─────────────┼─────────────────┘              │
│              ┌──────┴──────┐                         │
│              │ ApiService  │ ← HTTP (https)          │
│              │SocketService│ ← WebSocket (wss)       │
│              └──────┬──────┘                         │
└─────────────────────┼────────────────────────────────┘
                      │
┌─────────────────────┼────────────────────────────────┐
│           NEXT.JS WEB APP (React/TypeScript)          │
│  ┌──────────┐ ┌──────────┐ ┌───────────────────────┐ │
│  │  MapView │ │  Alerts  │ │   Family Tracking     │ │
│  │ (Google  │ │  (CRUD,  │ │ (grupy, geofence)     │ │
│  │  Maps JS)│ │  głosy,  │ │                       │ │
│  │          │ │  SOS)    │ │                       │ │
│  └────┬─────┘ └────┬─────┘ └──────────┬────────────┘ │
│       └─────────────┼─────────────────┘              │
│              ┌──────┴──────┐                         │
│              │  ApiService │ ← fetch (https)         │
│              │SocketContext│ ← Socket.io (wss)       │
│              └──────┬──────┘                         │
└─────────────────────┼────────────────────────────────┘
                      │ HTTPS + WSS
              ┌───────┴────────┐
              │  Nginx (SSL)   │ ← Let's Encrypt
              │  :443          │
              │  /api/* → :3001│ (Backend)
              │  /socket.io/*  │ → :3001 (WebSocket)
              │  /uploads/*    │ → :3001 (Pliki)
              │  /_next/*      │ → :3005 (Next.js static)
              │  /*            │ → :3005 (Next.js app)
              ├────────────────┤
              │  Node.js API   │ ← Express + Socket.io
              │  (PM2: port    │
              │   3001)        │
              ├────────────────┤
              │  Next.js Web   │ ← Next.js App Router
              │  (PM2: port    │
              │   3005)        │
              ├────────────────┤
              │  PostgreSQL    │ ← localhost:5432
              │  + PostGIS     │   baza: alertmap
              └────────────────┘
```

### Stos technologiczny

| Warstwa | Technologia | Wersja |
|---|---|---|
| Frontend mobilny | Flutter (Dart) | SDK ≥3.0.0 <4.0.0 |
| Frontend webowy | Next.js (React/TypeScript) | 16.2.4 (React 19.2.4) |
| Styling web | Tailwind CSS | ^4 |
| Mapy (mobile) | Google Maps Flutter | ^2.6.1 |
| Mapy (web) | @react-google-maps/api | ^2.20.8 |
| State management (mobile) | Provider | ^6.1.2 |
| State management (web) | React Context + hooks | — |
| Backend | Node.js + Express | Express ^4.21.2 |
| Baza danych | PostgreSQL + PostGIS | localhost:5432 |
| Real-time | Socket.io | ^4.8.1 (serwer), socket_io_client ^2.0.3+1 (mobile), ^4.8.3 (web) |
| Auth | JWT (jsonwebtoken ^9.0.2) + bcryptjs ^2.4.3 |  |
| Push (planowane) | Firebase Cloud Messaging | Zaimplementowany serwis, brak klucza |
| Hosting | VPS (OVH) | Ubuntu, PM2 |
| SSL | Let's Encrypt | Nginx reverse proxy |
| Lokalne notyfikacje | flutter_local_notifications | ^18.0.1 |
| Google Sign-In (mobile) | google_sign_in | ^6.2.1 |
| Google Sign-In (web) | Google Identity Services | GIS library (GSI) |
| Dynamic Color | dynamic_color | ^1.7.0 |
| Geolokalizacja (mobile) | geolocator | ^12.0.0 |
| Geolokalizacja (web) | Navigator.geolocation API | — |
| HTTP (mobile) | http (Dart) | ^1.2.1 |
| HTTP (web) | fetch API | — |
| Cache offline | sqflite | ^2.3.3 (tylko mobile) |
| Zdjęcia (mobile) | image_picker | ^1.1.2 |
| Upload plików | multer | ^1.4.5-lts.1 |
| Rate limiting | express-rate-limit | ^7.5.0 |
| Security headers | helmet | ^8.0.0 |

---

## 3. Infrastruktura i deployment

### Serwer VPS

| Parametr | Wartość |
|---|---|
| IP | `57.128.237.254` |
| SSH alias | `vps` (w `~/.ssh/config`) |
| User | `ubuntu` |
| Połączenie | `ssh vps` |

### Domena i SSL

| Parametr | Wartość |
|---|---|
| Domena | `https://alert.u235.pl` |
| SSL | Let's Encrypt (certbot + Nginx) |
| Nginx | Reverse proxy: `/api/*`, `/socket.io/*`, `/uploads/*` → `:3001` (backend); reszta → `:3005` (Next.js) |

### Backend na VPS

| Parametr | Wartość |
|---|---|
| Ścieżka na VPS | `/home/ubuntu/alertmap/src/` |
| PM2 process name | `alertmap` |
| Port | `3001` |
| Plik główny | `index.js` |
| Zmienne środowiskowe | `.env` (JWT_SECRET, DATABASE_URL, PORT=3001) |

### Aplikacja webowa na VPS

| Parametr | Wartość |
|---|---|
| Ścieżka na VPS | `/home/ubuntu/alert-web/` |
| PM2 process name | `alert-web` |
| Port | `3005` |
| Plik konfiguracji PM2 | `ecosystem.config.js` |
| Komenda | `next start -p 3005` |

### Baza danych

| Parametr | Wartość |
|---|---|
| Silnik | PostgreSQL + PostGIS |
| Host | `localhost:5432` |
| Baza | `alertmap` |
| User | `alertmap` |
| Connection string | `postgresql://alertmap:***@localhost:5432/alertmap` |

### Procedura deploymentu

#### Backend

```bash
# 1. Skopiuj zmienione pliki backendu na VPS
scp backend/src/*.js vps:/home/ubuntu/alertmap/src/
scp backend/src/routes/*.js vps:/home/ubuntu/alertmap/src/routes/
scp backend/src/middleware/*.js vps:/home/ubuntu/alertmap/src/middleware/
scp backend/src/services/*.js vps:/home/ubuntu/alertmap/src/services/

# 2. Restart procesu PM2
ssh vps "pm2 restart alertmap"

# 3. Sprawdź logi
ssh vps "pm2 logs alertmap --lines 20"

# 4. Sprawdź health
curl https://alert.u235.pl/health
```

#### Aplikacja webowa

```bash
# 1. Build lokalnie
cd /home/ooxo/alert/web
npm run build

# 2. Rsync na VPS (bez node_modules i .next)
rsync -avz --delete \
  --exclude=node_modules --exclude=.next --exclude=.git \
  /home/ooxo/alert/web/ vps:/home/ubuntu/alert-web/

# 3. Install + build na VPS
ssh vps "cd /home/ubuntu/alert-web && npm install && npm run build"

# 4. Restart PM2
ssh vps "pm2 restart alert-web"

# 5. Sprawdź
curl -sI https://alert.u235.pl
```

### Wersjonowanie i aktualizacja APK

- Endpoint `GET /version` zwraca `{ "version": 12, "url": "https://alert.u235.pl/download" }`
- Stała `appVersion = 17` w `mobile/lib/services/update_service.dart`
- Przy starcie apka porównuje wersje — jeśli serwer ma nowszą, pokazuje dialog
- `GET /download` serwuje plik `AlertMap.apk` z katalogu `backend/uploads/../AlertMap.apk`
- Po zbudowaniu nowego APK: `scp build/app/outputs/flutter-apk/app-release.apk vps:/home/ubuntu/alertmap/AlertMap.apk`
- Podbij numer wersji w `index.js` (`version: 12` → `version: 13`) i w `update_service.dart` (`appVersion = 17` → `18`)

---

## 4. Backend — szczegółowa dokumentacja

Base URL: `https://alert.u235.pl/api/v1`
Auth: Bearer JWT token (oprócz rejestracji/logowania/Google auth)
Format: JSON

### 4.1 Struktura plików (`backend/src/`)

| Plik | Opis |
|---|---|
| `index.js` | Główny plik — Express app, Socket.io, rate limiting, routing, cron, WebSocket handlers, endpointy /version, /download, /track, /health |
| `config/db.js` | Pool połączeń PostgreSQL (pg.Pool z DATABASE_URL z .env) |
| `middleware/auth.js` | Middleware JWT — weryfikuje `Authorization: Bearer <token>`, ustawia `req.user` |
| `routes/auth.js` | Rejestracja, logowanie, Google Sign-In, refresh tokena |
| `routes/alerts.js` | CRUD alertów, głosowanie, komentarze, statystyki, heatmapa, nearby, polling |
| `routes/family.js` | Grupy rodzinne, członkowie, geofence, lokalizacja dzieci |
| `routes/users.js` | Profil, lokalizacja, FCM token, ranking, zmiana email/hasła, share location, usunięcie konta |
| `services/fcm.js` | FCM push notifications (legacy API z FCM_SERVER_KEY) |

### 4.2 `index.js` — Główny plik serwera

**Middleware globalne:**
- `cors()` — CORS dla wszystkich origin
- `helmet()` — Security headers
- `express.json()` — JSON body parser
- `express.static('/uploads')` — Serwowanie uploadowanych zdjęć
- `trust proxy: 1` — Dla Nginx reverse proxy

**Rate limiting:**

| Ścieżka | Limit |
|---|---|
| `/api/v1/auth/*` | 5 req/min |
| `/api/v1/users/me/location` | 60 req/min |
| Wszystkie pozostałe | 100 req/min |

**Endpointy zdefiniowane w index.js:**

| Metoda | Ścieżka | Auth | Opis |
|---|---|---|---|
| GET | `/health` | ❌ | Health check — `{ status: 'ok', time: ISO }` |
| GET | `/version` | ❌ | Wersja APK — `{ version: 12, url: 'https://alert.u235.pl/download' }` |
| GET | `/download` | ❌ | Pobieranie pliku AlertMap.apk |
| GET | `/api/v1/track/:token` | ❌ | JSON z lokalizacją użytkownika (share link) |
| GET | `/track/:token` | ❌ | Strona HTML z mapą Leaflet — śledzenie lokalizacji na żywo |

**Cron job (setInterval co 60s):**
- Wygasza alerty: `UPDATE alerts SET status = 'expired' WHERE status = 'active' AND expires_at < NOW()`
- Emituje `alert:expired` przez WebSocket dla każdego wygasłego alertu

### 4.3 WebSocket (Socket.io)

**Autentykacja:** Token JWT w query string: `wss://alert.u235.pl?token=jwt...`
Middleware weryfikuje token i ustawia `socket.user`.

**Pokoje:** Każdy użytkownik dołącza do pokoju `user:{userId}` — umożliwia targetowane emisje.

**Eventy Server → Client:**

| Event | Payload | Kiedy |
|---|---|---|
| `alert:new` | `{ id, category, title, lat, lng, ... }` | Nowy alert w promieniu `alert_radius_m` użytkownika |
| `alert:updated` | `{ id, confirms, denies }` | Zmiana głosów lub edycja alertu |
| `alert:expired` | `{ alert_id }` | Alert wygasł (cron co 60s) |
| `family:location` | `{ user_id, lat, lng, recorded_at }` | Dziecko zaktualizowało lokalizację |
| `family:geofence_exit` | `{ user_id, username, geofence_name }` | Dziecko opuściło bezpieczną strefę |

**Eventy Client → Server:**

| Event | Payload | Działanie |
|---|---|---|
| `location:update` | `{ lat, lng }` | Aktualizuje `users.last_location`, wstawia do `location_history`, powiadamia rodziców, sprawdza geofence |

**Logika `location:update`:**
1. UPDATE `users.last_location` i `last_location_at`
2. INSERT do `location_history`
3. Znajdź grupy rodzinne gdzie user jest dzieckiem z `tracking_enabled = TRUE`
4. Emit `family:location` do wszystkich rodziców w tych grupach
5. Sprawdź geofence — jeśli dziecko jest POZA strefą (`NOT ST_DWithin`), emit `family:geofence_exit` do rodziców

### 4.4 `routes/auth.js` — Autentykacja

| Metoda | Ścieżka | Auth | Opis |
|---|---|---|---|
| POST | `/auth/register` | ❌ | Rejestracja (email, password, username) → JWT + user |
| POST | `/auth/login` | ❌ | Logowanie (email, password) → JWT + user |
| POST | `/auth/google` | ❌ | Google Sign-In (email, display_name, avatar_url) → JWT + user |
| POST | `/auth/refresh` | ✅ | Odświeżenie tokena JWT |

**Szczegóły:**
- `signToken(user)` — generuje JWT z `{ id, email }`, ważność z `JWT_EXPIRES_IN` env
- Hasła hashowane bcryptjs (salt rounds: 10)
- Google auth: jeśli user istnieje → aktualizuje avatar/username i zwraca token; jeśli nie → tworzy konto z losowym hasłem
- Duplikat email/username → HTTP 409

### 4.5 `routes/alerts.js` — Alerty

**Wszystkie endpointy wymagają auth (middleware `auth` na routerze).**

| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/alerts/nearby?lat=&lng=&radius_m=&category=` | Aktywne alerty w promieniu (domyślnie 1000m), opcjonalny filtr kategorii |
| GET | `/alerts/new?since=ISO` | Nowe alerty od `since` w promieniu `alert_radius_m` użytkownika (max 5000m) — dla polling |
| GET | `/alerts/stats?lat=&lng=&radius_m=` | Statystyki: today/week/total, top kategorie 30d, trend 14d |
| GET | `/alerts/heatmap?lat=&lng=&radius_m=&days=` | Punkty heatmapy (grupowane ST_SnapToGrid, max 200) |
| GET | `/alerts/mine` | Alerty zalogowanego użytkownika (max 100) |
| GET | `/alerts/:id` | Szczegóły alertu |
| POST | `/alerts` | Nowy alert (multipart — obsługuje zdjęcie). Rate limit: 10/h |
| PATCH | `/alerts/:id` | Edycja opisu lub przedłużenie (`extend_hours`) — tylko autor |
| DELETE | `/alerts/:id` | Usunięcie (status → 'removed') — tylko autor |
| POST | `/alerts/:id/vote` | Głosowanie `{ vote: 'confirm' \| 'deny' }`. Duplikat → 409 |
| POST | `/alerts/:id/photo` | Upload zdjęcia do istniejącego alertu — tylko autor |
| GET | `/alerts/:id/comments` | Lista komentarzy alertu |
| POST | `/alerts/:id/comments` | Dodaj komentarz `{ content }` |

**Tworzenie alertu (POST /alerts):**
- Przyjmuje: `category, title, description, lat, lng, radius_m (def 100), duration_hours (def 3)`
- Opcjonalnie zdjęcie (multipart, max 5MB, jpeg/png/webp)
- Po utworzeniu: emituje `alert:new` przez WebSocket do użytkowników w promieniu ich `alert_radius_m`
- Wywołuje `notifyNearbyUsers()` (FCM push)

**Upload zdjęć:**
- Multer z disk storage do katalogu `uploads/`
- Nazwy plików: `{timestamp}-{random}{ext}`
- Max 5MB, tylko image/jpeg, image/png, image/webp

### 4.6 `routes/family.js` — Grupy rodzinne

**Middleware wewnętrzne:**
- `memberOf` — sprawdza czy user jest członkiem grupy, ustawia `req.memberRole`
- `parentOnly` — wymaga `req.memberRole === 'parent'`

| Metoda | Ścieżka | Uprawnienia | Opis |
|---|---|---|---|
| POST | `/family/groups` | auth | Utwórz grupę (name) → invite_code (8 znaków hex uppercase) |
| GET | `/family/groups` | auth | Lista grup użytkownika |
| POST | `/family/groups/join` | auth | Dołącz kodem zaproszenia → rola 'child', `is_child = TRUE` |
| GET | `/family/groups/:id/members` | memberOf | Lista członków z lokalizacją |
| PATCH | `/family/groups/:id/members/:uid` | parentOnly | Zmiana tracking_enabled lub role |
| DELETE | `/family/groups/:id/members/:uid` | parentOnly | Usuń członka |
| DELETE | `/family/groups/:id` | owner | Usuń grupę (CASCADE) |
| POST | `/family/groups/:id/geofences` | parentOnly | Utwórz geofence (name, lat, lng, radius_m def 200) |
| GET | `/family/groups/:id/geofences` | memberOf | Lista geofence'ów |
| PATCH | `/family/groups/:id/geofences/:gid` | parentOnly | Edycja geofence (name, lat, lng, radius_m, is_active) |
| DELETE | `/family/groups/:id/geofences/:gid` | parentOnly | Usuń geofence |
| GET | `/family/groups/:id/members/:uid/location` | parentOnly | Aktualna lokalizacja członka |
| GET | `/family/groups/:id/members/:uid/location/history` | parentOnly | Historia lokalizacji (from, to, limit def 100) |

### 4.7 `routes/users.js` — Użytkownicy

| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/users/me` | Profil zalogowanego użytkownika |
| PATCH | `/users/me` | Aktualizacja (username, alert_radius_m, avatar_url) |
| PUT | `/users/me/location` | Aktualizacja lokalizacji → zwraca `nearby_alerts` |
| PUT | `/users/me/fcm-token` | Rejestracja tokena FCM |
| GET | `/users/ranking` | Top 50 użytkowników (alert_count, total_confirms, reputation) |
| POST | `/users/me/email` | Zmiana email (wymaga hasła) |
| POST | `/users/me/password` | Zmiana hasła (wymaga aktualnego, min 6 znaków) |
| POST | `/users/me/share-location` | Generuj link do śledzenia (hours def 1) → URL |
| POST | `/users/me/delete` | Usunięcie konta (wymaga hasła) — kasuje wszystkie dane |

### 4.8 `middleware/auth.js`

Prosty middleware JWT:
1. Sprawdza header `Authorization: Bearer <token>`
2. Weryfikuje token z `JWT_SECRET`
3. Ustawia `req.user = { id, email }`
4. Brak/nieprawidłowy token → 401

### 4.9 `config/db.js`

Eksportuje `{ query, pool }` — wrapper na `pg.Pool` z `DATABASE_URL` z `.env`.

### 4.10 `services/fcm.js`

**Funkcje:**
- `sendPush(fcmToken, title, body, data)` — wysyła push przez FCM Legacy API (`FCM_SERVER_KEY`)
- `notifyNearbyUsers(alert)` — znajduje użytkowników z `fcm_token` w promieniu ich `alert_radius_m`, wysyła push, zapisuje do `alert_notifications` (deduplikacja)

**Status:** Zaimplementowany, ale `FCM_SERVER_KEY` nie jest ustawiony na serwerze — push notifications nie działają. Apka używa WebSocket + polling + local notifications jako fallback.

### 4.11 `package.json` — Zależności backendu

```json
{
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.7",
    "express": "^4.21.2",
    "express-rate-limit": "^7.5.0",
    "helmet": "^8.0.0",
    "jsonwebtoken": "^9.0.2",
    "multer": "^1.4.5-lts.1",
    "pg": "^8.13.1",
    "socket.io": "^4.8.1"
  }
}
```

---

## 5. Baza danych

Plik schematu: `db/schema.sql`
Rozszerzenia: `postgis`, `uuid-ossp`

### 5.1 Enumy

**`alert_category`** — 18 wartości:
- Ogólne (13): `aggression`, `theft`, `accident`, `fire`, `flood`, `ice`, `construction`, `animal`, `dark_area`, `drugs`, `police`, `weather`, `other`
- Ochrona dzieci (5): `stranger_danger`, `traffic_danger`, `playground_hazard`, `water_hazard`, `school_zone`

**`alert_status`**: `active`, `expired`, `hidden`, `removed`

**`vote_type`**: `confirm`, `deny`

**`family_role`**: `parent`, `child`

### 5.2 Tabele

#### `users`

| Kolumna | Typ | Opis |
|---|---|---|
| `id` | UUID PK | uuid_generate_v4() |
| `email` | VARCHAR(255) UNIQUE NOT NULL | |
| `password_hash` | VARCHAR(255) NOT NULL | bcrypt hash |
| `username` | VARCHAR(50) UNIQUE NOT NULL | |
| `avatar_url` | TEXT | URL avatara (Google) |
| `alert_radius_m` | INT NOT NULL DEFAULT 500 | Promień alertów w metrach |
| `reputation_score` | INT NOT NULL DEFAULT 100 | Reputacja |
| `is_child` | BOOLEAN NOT NULL DEFAULT FALSE | Flaga konta dziecka |
| `fcm_token` | TEXT | Token FCM push |
| `last_location` | GEOGRAPHY(POINT, 4326) | Ostatnia lokalizacja |
| `last_location_at` | TIMESTAMPTZ | Czas ostatniej lokalizacji |
| `created_at` | TIMESTAMPTZ DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ DEFAULT NOW() | |

**Indeksy:** `idx_users_location` — GIST na `last_location`

#### `alerts`

| Kolumna | Typ | Opis |
|---|---|---|
| `id` | UUID PK | |
| `author_id` | UUID FK → users(id) | |
| `category` | alert_category NOT NULL | |
| `title` | VARCHAR(100) NOT NULL | |
| `description` | TEXT | |
| `photo_url` | TEXT | Ścieżka do zdjęcia |
| `location` | GEOGRAPHY(POINT, 4326) NOT NULL | |
| `radius_m` | INT NOT NULL DEFAULT 100 | |
| `status` | alert_status NOT NULL DEFAULT 'active' | |
| `confirms` | INT NOT NULL DEFAULT 0 | |
| `denies` | INT NOT NULL DEFAULT 0 | |
| `expires_at` | TIMESTAMPTZ NOT NULL | |
| `created_at` | TIMESTAMPTZ DEFAULT NOW() | |

**Indeksy:**
- `idx_alerts_location` — GIST na `location`
- `idx_alerts_status_expires` — B-tree na `(status, expires_at)`
- `idx_alerts_author` — B-tree na `author_id`

#### `alert_votes`

| Kolumna | Typ | Opis |
|---|---|---|
| `id` | UUID PK | |
| `alert_id` | UUID FK → alerts(id) ON DELETE CASCADE | |
| `user_id` | UUID FK → users(id) | |
| `vote` | vote_type NOT NULL | |
| `created_at` | TIMESTAMPTZ DEFAULT NOW() | |

**Constraint:** UNIQUE(alert_id, user_id) — jeden głos na użytkownika

#### `alert_notifications`

| Kolumna | Typ | Opis |
|---|---|---|
| `id` | UUID PK | |
| `alert_id` | UUID FK → alerts(id) ON DELETE CASCADE | |
| `user_id` | UUID FK → users(id) | |
| `sent_at` | TIMESTAMPTZ DEFAULT NOW() | |

**Constraint:** UNIQUE(alert_id, user_id) — deduplikacja powiadomień

#### `alert_comments`

| Kolumna | Typ | Opis |
|---|---|---|
| `id` | UUID PK | |
| `alert_id` | UUID FK → alerts(id) ON DELETE CASCADE | |
| `user_id` | UUID FK → users(id) | |
| `content` | TEXT NOT NULL | |
| `created_at` | TIMESTAMPTZ DEFAULT NOW() | |

**Indeksy:** `idx_alert_comments_alert` — B-tree na `(alert_id, created_at)`

#### `family_groups`

| Kolumna | Typ | Opis |
|---|---|---|
| `id` | UUID PK | |
| `name` | VARCHAR(100) NOT NULL | |
| `owner_id` | UUID FK → users(id) | |
| `invite_code` | VARCHAR(8) UNIQUE NOT NULL | 8-znakowy hex uppercase |
| `created_at` | TIMESTAMPTZ DEFAULT NOW() | |

#### `family_members`

| Kolumna | Typ | Opis |
|---|---|---|
| `id` | UUID PK | |
| `group_id` | UUID FK → family_groups(id) ON DELETE CASCADE | |
| `user_id` | UUID FK → users(id) | |
| `role` | family_role NOT NULL | parent / child |
| `tracking_enabled` | BOOLEAN NOT NULL DEFAULT TRUE | |
| `joined_at` | TIMESTAMPTZ DEFAULT NOW() | |

**Constraint:** UNIQUE(group_id, user_id)

#### `geofences`

| Kolumna | Typ | Opis |
|---|---|---|
| `id` | UUID PK | |
| `group_id` | UUID FK → family_groups(id) ON DELETE CASCADE | |
| `name` | VARCHAR(100) NOT NULL | |
| `center` | GEOGRAPHY(POINT, 4326) NOT NULL | |
| `radius_m` | INT NOT NULL DEFAULT 200 | |
| `is_active` | BOOLEAN NOT NULL DEFAULT TRUE | |
| `created_at` | TIMESTAMPTZ DEFAULT NOW() | |

**Indeksy:** `idx_geofences_center` — GIST na `center`

#### `location_history`

| Kolumna | Typ | Opis |
|---|---|---|
| `id` | UUID PK | |
| `user_id` | UUID FK → users(id) | |
| `location` | GEOGRAPHY(POINT, 4326) NOT NULL | |
| `recorded_at` | TIMESTAMPTZ DEFAULT NOW() | |

**Indeksy:** `idx_location_history_user_time` — B-tree na `(user_id, recorded_at DESC)`

#### `share_links`

| Kolumna | Typ | Opis |
|---|---|---|
| `id` | UUID PK | |
| `user_id` | UUID FK → users(id) | |
| `token` | VARCHAR(32) UNIQUE NOT NULL | 32-znakowy hex |
| `expires_at` | TIMESTAMPTZ NOT NULL | |
| `created_at` | TIMESTAMPTZ DEFAULT NOW() | |

### 5.3 Funkcje SQL

#### `find_alerts_nearby(lat, lng, radius_m)`
Zwraca aktywne alerty w promieniu od punktu. Używa `ST_DWithin` z indeksem GIST.

```sql
SELECT * FROM alerts
WHERE status = 'active' AND expires_at > NOW()
AND ST_DWithin(location, ST_MakePoint(lng, lat)::geography, radius_m)
ORDER BY created_at DESC;
```

#### `expire_old_alerts()`
Wygasza przeterminowane alerty. W praktyce zastąpiona przez `setInterval` w `index.js`.

```sql
UPDATE alerts SET status = 'expired'
WHERE status = 'active' AND expires_at < NOW();
```

### 5.4 Triggery

#### `trg_alert_vote` (AFTER INSERT ON alert_votes)
Wywołuje `check_alert_denies()`:
- Jeśli `vote = 'deny'` → `denies += 1`; jeśli `denies > 3` → `status = 'hidden'`
- Jeśli `vote = 'confirm'` → `confirms += 1`

### 5.5 Diagram relacji

```
users ──1:N── alerts (author_id)
users ──1:N── alert_votes (user_id)
alerts ──1:N── alert_votes (alert_id)
alerts ──1:N── alert_comments (alert_id)
alerts ──1:N── alert_notifications (alert_id)
users ──N:M── family_groups (przez family_members)
family_groups ──1:N── family_members
family_groups ──1:N── geofences
users ──1:N── location_history
users ──1:N── share_links
```

---

## 6. Aplikacja mobilna — szczegółowa dokumentacja

### 6.1 Struktura plików

```
mobile/
├── pubspec.yaml                          # Zależności Flutter
├── android/app/src/main/AndroidManifest.xml  # Uprawnienia, API key
├── ios/Runner/AppDelegate.swift          # Google Maps API key dla iOS
├── lib/
│   ├── main.dart                         # Entry point, MultiProvider, routing, AuthGate
│   ├── models/
│   │   ├── alert.dart                    # AlertModel + AlertCategory enum (18 kategorii)
│   │   └── user.dart                     # User model
│   ├── providers/
│   │   ├── auth_provider.dart            # AuthProvider — login, register, Google Sign-In
│   │   ├── alert_provider.dart           # AlertProvider — alerty, filtry, głosowanie, WebSocket
│   │   └── theme_provider.dart           # ThemeProvider — dark/light/system
│   ├── services/
│   │   ├── api_service.dart              # HTTP client (GET, POST, PATCH, DELETE, multipart)
│   │   ├── socket_service.dart           # Socket.io client
│   │   ├── location_service.dart         # Geolocator wrapper
│   │   ├── background_service.dart       # Tracking, polling, local notifications
│   │   ├── cache_service.dart            # SQLite offline cache
│   │   ├── update_service.dart           # Sprawdzanie aktualizacji APK
│   │   └── i18n.dart                     # Internacjonalizacja (PL/EN)
│   └── screens/
│       ├── map/map_screen.dart           # Główny ekran mapy
│       ├── auth/login_screen.dart        # Logowanie / rejestracja / Google
│       ├── alerts/
│       │   ├── create_alert_screen.dart  # Tworzenie alertu
│       │   ├── alert_detail_screen.dart  # Szczegóły alertu + komentarze
│       │   ├── my_alerts_screen.dart     # Moje zgłoszenia
│       │   └── stats_screen.dart         # Statystyki okolicy
│       ├── family/
│       │   ├── family_screen.dart        # Lista grup rodzinnych
│       │   └── family_group_screen.dart  # Szczegóły grupy + mapa + geofence
│       ├── profile/
│       │   ├── profile_screen.dart       # Profil użytkownika
│       │   └── ranking_screen.dart       # Ranking użytkowników
│       └── settings/
│           └── settings_screen.dart      # Ustawienia (motyw, język, powiadomienia, konto)
```

### 6.2 Nawigacja

**AuthGate (`_AuthGate` w main.dart):**
- Widget stanowy w `home:` MaterialApp
- Obserwuje `AuthProvider` — jeśli zalogowany → `MapScreen`, jeśli nie → `LoginScreen`
- Po zalogowaniu startuje `BackgroundService` i `AlertProvider.connectSocket()`
- Po wylogowaniu zatrzymuje tracking i rozłącza socket
- **Znany problem:** Google Sign-In wymaga `Navigator.pushReplacementNamed(context, '/map')` bo AuthGate nie przebudowuje się automatycznie

**Named routes (onGenerateRoute):**

| Route | Ekran |
|---|---|
| `/map` | MapScreen |
| `/family` | FamilyScreen |
| `/family/{groupId}` | FamilyGroupScreen (dynamiczny segment) |
| `/profile` | ProfileScreen |
| `/settings` | SettingsScreen |
| `/my-alerts` | MyAlertsScreen |
| `/stats` | StatsScreen |
| `/ranking` | RankingScreen |
| `/login` | LoginScreen |

**BottomNavigationBar (w MapScreen):**

| Index | Ikona | Akcja |
|---|---|---|
| 0 | Mapa | Pozostaje na mapie |
| 1 | Alerty (badge z liczbą) | Toggle listy alertów overlay |
| 2 | SOS (czerwone kółko) | Dialog potwierdzenia → wysyła alert SOS |
| 3 | Rodzina | Navigator.pushNamed('/family') |
| 4 | Profil | Navigator.pushNamed('/profile') |

### 6.3 Ekrany — szczegółowy opis

#### MapScreen (`screens/map/map_screen.dart`)
**Główny ekran aplikacji.** Wyświetla mapę Google Maps z alertami i dziećmi z grup rodzinnych.

**Funkcje:**
- Google Maps z custom markerami (emoji w pin shape)
- Wyszukiwanie lokalizacji (Nominatim OpenStreetMap geocoding)
- Filtrowanie alertów po kategoriach (FilterChip)
- Lista alertów overlay (toggle z BottomNav)
- Przycisk "Zgłoś" → CreateAlertScreen
- Przycisk SOS → dialog → POST /alerts z kategorią 'aggression'
- Wyświetlanie dzieci z grup rodzinnych (zielone markery)
- Kółka promienia zagrożeń (czerwone) i dzieci (zielone)
- Dark/light map styles

**API wywołania:**
- `POST /users/me/location` — przy inicjalizacji
- `GET /alerts/nearby?radius_m=10000` — ładowanie alertów
- `GET /family/groups` + `GET /family/groups/:id/members` — ładowanie dzieci
- `POST /alerts` — SOS
- Nominatim geocoding (zewnętrzne API)

#### LoginScreen (`screens/auth/login_screen.dart`)
**Ekran logowania i rejestracji.**

- Toggle między logowaniem a rejestracją
- Pola: email, password, username (tylko rejestracja)
- Przycisk Google Sign-In (OutlinedButton z favicon Google)
- Po Google Sign-In: `Navigator.pushReplacementNamed(context, '/map')` (workaround AuthGate)

**API:** `POST /auth/login`, `POST /auth/register`, `POST /auth/google`

#### CreateAlertScreen (`screens/alerts/create_alert_screen.dart`)
**Formularz tworzenia nowego alertu.**

- Mini-mapa Google Maps do wyboru lokalizacji (tap to select)
- Przycisk "moja lokalizacja" na mini-mapie
- Wyświetla współrzędne z etykietą (moja lokalizacja / wskazane miejsce)
- 18 kategorii jako ChoiceChip
- Pola: tytuł, opis (opcjonalny)
- Zdjęcie: aparat lub galeria (ImagePicker, max 1280px, quality 80%)
- Czas trwania: dropdown 1/3/6/12/24h
- Wysyłka jako multipart (ApiService.multipart)

**API:** `POST /alerts` (multipart/form-data)

#### AlertDetailScreen (`screens/alerts/alert_detail_screen.dart`)
**Szczegóły alertu z mapą, głosowaniem i komentarzami.**

- Mapa Google Maps (lite mode, statyczna) z markerem i kółkiem promienia
- Zdjęcie alertu (jeśli jest)
- Info chips: czas temu, wygasa za, odległość, autor
- Pasek wiarygodności (LinearProgressIndicator: zielony/czerwony)
- Przyciski głosowania: Potwierdzam / Nieaktualne
- Lista komentarzy z avatarami (pierwsza litera username)
- Pole dodawania komentarza (TextField + IconButton.filled send)

**API:** `POST /alerts/:id/vote`, `GET /alerts/:id/comments`, `POST /alerts/:id/comments`

#### MyAlertsScreen (`screens/alerts/my_alerts_screen.dart`)
**Lista alertów zalogowanego użytkownika.**

- Pull-to-refresh
- Każdy alert: ikona kategorii, tytuł, status (aktywny/wygasł)
- PopupMenuButton: Szczegóły, Przedłuż o 3h, Edytuj opis, Usuń

**API:** `GET /alerts/mine`, `PATCH /alerts/:id`, `DELETE /alerts/:id`

#### StatsScreen (`screens/alerts/stats_screen.dart`)
**Statystyki zagrożeń w okolicy (promień 3km).**

- 3 karty: Dziś / Tydzień / Łącznie
- Top zagrożenia 30 dni — horizontal bar chart (LinearProgressIndicator)
- Trend 14 dni — vertical bar chart (Container heights)

**API:** `GET /alerts/stats?lat=&lng=&radius_m=3000`

#### FamilyScreen (`screens/family/family_screen.dart`)
**Lista grup rodzinnych.**

- Lista grup z nazwą i kodem zaproszenia
- Przycisk usuwania grupy (z dialogiem potwierdzenia)
- FAB: utwórz grupę (dialog z nazwą) lub dołącz kodem (dialog z kodem)

**API:** `GET /family/groups`, `POST /family/groups`, `POST /family/groups/join`, `DELETE /family/groups/:id`

#### FamilyGroupScreen (`screens/family/family_group_screen.dart`)
**Szczegóły grupy rodzinnej z mapą.**

- Mapa Google Maps z markerami członków (zielone = tracking on, fioletowe = off)
- Kółka wokół dzieci (zielone) i geofence'ów (niebieskie)
- Auto-fit bounds do wszystkich członków
- Lista członków z rolą (Rodzic/Dziecko)
- Switch tracking_enabled dla dzieci
- Lista bezpiecznych stref z przyciskiem usuwania
- Przycisk dodawania geofence (dialog z mapą do wyboru lokalizacji)

**API:** `GET /family/groups/:id/members`, `GET /family/groups/:id/geofences`, `PATCH /family/groups/:id/members/:uid`, `POST /family/groups/:id/geofences`, `DELETE /family/groups/:id/geofences/:gid`

#### ProfileScreen (`screens/profile/profile_screen.dart`)
**Profil użytkownika.**

- Avatar (pierwsza litera username), nazwa, email, reputacja
- Slider promienia alertów (100m–5km, 49 kroków)
- Przycisk zapisania promienia
- Linki do: Ranking, Statystyki, Udostępnij lokalizację, Moje alerty, Grupy rodzinne, Ustawienia
- Przycisk wylogowania

**API:** `PATCH /users/me`, `POST /users/me/share-location`

#### RankingScreen (`screens/profile/ranking_screen.dart`)
**Top 50 użytkowników.**

- Medale 🥇🥈🥉 dla top 3
- Liczba zgłoszeń, potwierdzeń, reputacja

**API:** `GET /users/ranking`

#### SettingsScreen (`screens/settings/settings_screen.dart`)
**Ustawienia aplikacji.**

- Język (PL/EN) — dialog wyboru
- Motyw (Ciemny/Jasny/Systemowy) — dialog wyboru
- Powiadomienia: alerty zagrożeń, alerty rodzinne, dźwięk, wibracja (SwitchListTile → SharedPreferences)
- Konto: zmiana email (wymaga hasła), zmiana hasła, zmiana username
- Usunięcie konta (wymaga hasła)
- Wersja aplikacji

**API:** `POST /users/me/email`, `POST /users/me/password`, `PATCH /users/me`, `POST /users/me/delete`

### 6.4 Providers — State Management

Projekt używa pakietu `provider` z `MultiProvider` w `main.dart`.

#### AuthProvider (`ChangeNotifier`)
- **Stan:** `User? _user`, `bool _loading`
- **Metody:**
  - `register(email, password, username)` → POST /auth/register
  - `login(email, password)` → POST /auth/login
  - `loginWithGoogle()` → GoogleSignIn.signIn() → POST /auth/google
  - `logout()` → clearToken + GoogleSignIn.signOut()
  - `tryAutoLogin()` → loadToken z SharedPreferences → GET /users/me
- **Google Sign-In flow:** `disconnect()` → `signIn()` → wysyła email/displayName/photoUrl do backendu
- **Gettery:** `user`, `isLoggedIn`, `loading`

#### AlertProvider (`ChangeNotifier`)
- **Stan:** `List<AlertModel> _alerts`, `Set<AlertCategory> _activeFilters`, `bool _loading`
- **Metody:**
  - `loadNearby(LatLng, radiusM)` → GET /alerts/nearby; fallback na CacheService przy offline
  - `vote(alertId, voteType)` → POST /alerts/:id/vote → GET /alerts/:id (odświeżenie)
  - `toggleFilter(cat)` / `clearFilters()` — filtrowanie lokalne
  - `connectSocket(token)` — łączy SocketService z callbackiem `onNewAlert`
  - `disconnectSocket()`
- **Getter `alerts`:** zwraca przefiltrowaną listę (lub wszystkie jeśli brak filtrów)

#### ThemeProvider (`ChangeNotifier`)
- **Stan:** `ThemeMode _mode` (domyślnie `dark`)
- **Persystencja:** SharedPreferences klucz `theme_mode` (wartości: 'dark', 'light', 'system')
- **Metody:** `setMode(ThemeMode)`

### 6.5 Services

#### ApiService (`services/api_service.dart`)
- **Base URL:** `https://alert.u235.pl/api/v1`
- **Token:** przechowywany w pamięci (`_token`) i SharedPreferences (`jwt_token`)
- **Metody:** `get()`, `post()`, `patch()`, `delete()`, `multipart()`
- **`_decode(Response)`:** Kluczowa metoda — obsługuje non-JSON responses:
  - Jeśli status ≥ 400 LUB body nie zaczyna się od `{` lub `[` → zwraca `{'error': 'HTTP {code}'}`
  - W przeciwnym razie: `jsonDecode(body)`
  - Catch na błędach parsowania → `{'error': 'Invalid response'}`
- **WAŻNE:** Nie rzuca wyjątków HTTP — zawsze zwraca Map. Caller musi sprawdzić `res['error']`.

#### SocketService (`services/socket_service.dart`)
- **Server URL:** `https://alert.u235.pl`
- **Transport:** WebSocket only
- **Auth:** Token w query string
- **Metody:**
  - `connect(token, {onNewAlert, onFamilyLocation, onGeofenceExit})` — nasłuchuje 3 eventów
  - `updateLocation(lat, lng)` — emituje `location:update`
  - `disconnect()`

#### LocationService (`services/location_service.dart`)
- Wrapper na `geolocator`
- `getCurrentPosition()` — sprawdza uprawnienia, zwraca `Position?`
- `getPositionStream()` — stream z `distanceFilter: 50` (aktualizacja co 50m)

#### BackgroundService (`services/background_service.dart`)
- **Zależności:** ApiService, SocketService, FlutterLocalNotificationsPlugin
- **Kanały notyfikacji Android:**
  - `danger_alerts` — "Alerty zagrożeń" (Importance.max, fullScreenIntent, alarm category, kolor czerwony)
  - `family_alerts` — "Alerty rodzinne" (Importance.high, fullScreenIntent, kolor pomarańczowy)
- **`init()`:** Inicjalizuje plugin notyfikacji, tworzy kanały, prosi o uprawnienia (Android 13+)
- **`startTracking(token)`:**
  1. Łączy WebSocket z callbackami na `alert:new` i `family:geofence_exit`
  2. Startuje stream lokalizacji (distanceFilter: 50m) → `socket.updateLocation()` + `POST /users/me/location`
  3. Startuje polling co 60s: `GET /alerts/new?since=lastCheck` → local notification dla nowych alertów
  4. Deduplikacja: `_notifiedAlertIds` — nie pokazuje tego samego alertu z WebSocket i polling
- **`stopTracking()`:** Anuluje stream lokalizacji, timer polling, rozłącza socket
- **Preferencje:** Sprawdza SharedPreferences: `notif_alerts`, `notif_family`, `notif_sound`, `notif_vibration`

#### CacheService (`services/cache_service.dart`)
- **Baza:** SQLite (`alertmap_cache.db`)
- **Tabela:** `alerts_cache (id TEXT PK, data TEXT, cached_at INTEGER)`
- **`cacheAlerts(List<AlertModel>)`:** Czyści tabelę i wstawia nowe (batch)
- **`getCachedAlerts()`:** Zwraca alerty z cache (sortowane po cached_at DESC)
- Używane przez AlertProvider jako fallback przy braku sieci

#### UpdateService (`services/update_service.dart`)
- **Stała:** `appVersion = 17`
- **`checkForUpdate(context)`:** Wywołuje `GET /version`, porównuje z `appVersion`
  - Jeśli serwer ma nowszą wersję → dialog z przyciskami "Później" / "Pobierz"
  - "Pobierz" → MethodChannel `pl.u235.alertmap/update` → `openUrl(url)`
- Wywoływane w `_AuthGate.initState()` przez `addPostFrameCallback`

#### i18n Service (`services/i18n.dart`)
- **Klasa:** `S` (statyczna)
- **Języki:** `pl` (domyślny), `en`
- **Persystencja:** SharedPreferences klucz `lang`
- **API:** `S.get('key')`, `S.load()`, `S.setLang('en')`, `S.lang`, `S.availableLanguages`, `S.langName(code)`
- **Klucze:** ~70 tłumaczeń (app_name, map, family, profile, report, search_location, filter_categories, ...)
- **Uwaga:** Zmiana języka wymaga ręcznego `setState()` — brak automatycznego przebudowania widgetów

### 6.6 Models

#### AlertModel (`models/alert.dart`)

**AlertCategory enum** — 18 wartości z właściwościami:

| Enum | apiValue | label (PL) | emoji | iconData | color |
|---|---|---|---|---|---|
| `aggression` | `aggression` | Agresywne osoby | 🤬 | Icons.person_off | #FF1744 |
| `theft` | `theft` | Kradzież / rozbój | 🔪 | Icons.front_hand | #FF1744 |
| `accident` | `accident` | Wypadek | 💥 | Icons.car_crash | #FF6D00 |
| `fire` | `fire` | Pożar | 🔥 | Icons.local_fire_department | #FF3D00 |
| `flood` | `flood` | Powódź | 🌊 | Icons.waves | #2979FF |
| `ice` | `ice` | Oblodzenie | ❄️ | Icons.severe_cold | #00B0FF |
| `construction` | `construction` | Niebezpieczna budowa | ⛏️ | Icons.construction | #FFAB00 |
| `animal` | `animal` | Niebezpieczne zwierzę | 🐺 | Icons.pets | #FF6D00 |
| `darkArea` | `dark_area` | Nieoświetlony teren | 🌑 | Icons.dark_mode | #78909C |
| `drugs` | `drugs` | Narkotyki | 💉 | Icons.vaccines | #AA00FF |
| `police` | `police` | Akcja policyjna | 🚨 | Icons.shield | #2979FF |
| `weather` | `weather` | Zagrożenie pogodowe | ⛈️ | Icons.bolt | #1565C0 |
| `other` | `other` | Inne | ⚠️ | Icons.priority_high | #FFAB00 |
| `strangerDanger` | `stranger_danger` | Podejrzana osoba | 😈 | Icons.person_search | #FF1744 |
| `trafficDanger` | `traffic_danger` | Niebezpieczne przejście | ☠️ | Icons.do_not_step | #FF6D00 |
| `playgroundHazard` | `playground_hazard` | Uszkodzony plac zabaw | ⛔ | Icons.child_care | #FFAB00 |
| `waterHazard` | `water_hazard` | Zbiornik wodny | 🌀 | Icons.water_drop | #2979FF |
| `schoolZone` | `school_zone` | Strefa szkolna | 🚸 | Icons.directions_run | #FF6D00 |

**Konwersja apiValue:** `name.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]!.toLowerCase()}')` — camelCase → snake_case

**AlertModel fields:** id, authorId, category, title, description, photoUrl, location (LatLng), radiusM, confirms, denies, distanceM, expiresAt, createdAt, authorUsername

**fromJson:** Parsuje `author.username` lub `author_username`, konwertuje lat/lng na LatLng, parsuje daty ISO

#### User (`models/user.dart`)
**Fields:** id, email, username, avatarUrl, alertRadiusM (def 500), reputationScore (def 100), isChild (def false)

### 6.7 Custom Map Markers — generowanie przez Canvas API

Markery są generowane programowo w `MapScreen._createPinIcon()`:

1. **Wymiary:** 48×64 logical pixels × `devicePixelRatio` (HiDPI scaling)
2. **Kształt pinu:**
   - Łuk (arc) tworzący górną część okręgu
   - Linie do dolnego punktu (trójkąt wskazujący)
   - Wypełnienie kolorem kategorii
   - Obrys czarny z alpha 0.25, grubość 1.5×dpr
3. **Białe kółko wewnętrzne:** radius = 62% radius głównego
4. **Emoji:** TextPainter z fontSize 18×dpr, wycentrowany w kółku
5. **Konwersja:** Picture → Image → PNG bytes → `BitmapDescriptor.bytes()`
6. **Cache:** `_iconCache` Map<AlertCategory, BitmapDescriptor> — precache w initState

**Markery dzieci:** Ten sam kształt pinu, emoji 💚, kolor zielony

### 6.8 Google Maps — konfiguracja

**Style mapy:**
- **Light:** Ukrywa POI business, desaturuje ikony POI i transit
- **Dark:** Ciemne tło (#212121), ciemne drogi (#2c2c2c), czarna woda, ukryte POI business

**Ustawienia mapy:**
- `myLocationEnabled: true` — niebieski punkt lokalizacji
- `myLocationButtonEnabled: false` — własny przycisk
- `zoomControlsEnabled: false`, `mapToolbarEnabled: false`
- Alert detail: `liteModeEnabled: true` (statyczny screenshot)
- Create alert: `liteModeEnabled: false` (interaktywna mini-mapa)

### 6.9 Dynamic Color (Material You)

```dart
DynamicColorBuilder(
  builder: (lightDynamic, darkDynamic) => MaterialApp(
    theme: ThemeData(
      colorScheme: lightDynamic?.harmonized() ?? ColorScheme.fromSeed(seedColor: Colors.red),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: darkDynamic?.harmonized() ?? ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.dark),
      useMaterial3: true,
    ),
  ),
)
```

- Na urządzeniach z Android 12+ — kolory z tapety systemowej
- Fallback: seed color `Colors.red`
- Material 3 włączone

---

## 7. Aplikacja webowa — szczegółowa dokumentacja

**URL:** `https://alert.u235.pl`
**Lokalna ścieżka:** `/home/ooxo/alert/web`
**Technologie:** Next.js 16.2.4 (App Router), React 19.2.4, TypeScript, Tailwind CSS 4

Aplikacja webowa jest pełną repliką aplikacji mobilnej — zawiera wszystkie ekrany i funkcje (mapa, alerty, SOS, family tracking, geofence, statystyki, ranking, profil, ustawienia).

### 7.1 Stos technologiczny (web)

| Pakiet | Wersja | Opis |
|---|---|---|
| `next` | 16.2.4 | Framework React z SSR, App Router |
| `react` / `react-dom` | 19.2.4 | Biblioteka UI |
| `@react-google-maps/api` | ^2.20.8 | Wrapper Google Maps JS API |
| `@googlemaps/react-wrapper` | ^1.2.0 | Loader Google Maps |
| `socket.io-client` | ^4.8.3 | WebSocket client |
| `js-cookie` | ^3.0.5 | Cookies helper |
| `tailwindcss` | ^4 | CSS utility framework |
| `typescript` | ^5 | Typowanie |
| `eslint` + `eslint-config-next` | ^9 / 16.2.4 | Linting |

### 7.2 Struktura plików (`web/src/`)

```
web/
├── public/
│   └── icons/categories/          # 18 SVG ikon kategorii zagrożeń
│       ├── aggression.svg
│       ├── theft.svg
│       ├── accident.svg
│       ├── fire.svg
│       ├── flood.svg
│       ├── ice.svg
│       ├── construction.svg
│       ├── animal.svg
│       ├── dark_area.svg
│       ├── drugs.svg
│       ├── police.svg
│       ├── weather.svg
│       ├── other.svg
│       ├── stranger_danger.svg
│       ├── traffic_danger.svg
│       ├── playground_hazard.svg
│       ├── water_hazard.svg
│       └── school_zone.svg
├── src/
│   ├── app/
│   │   ├── layout.tsx               # Root layout (Inter font, dark mode, Providers)
│   │   ├── page.tsx                  # Strona główna — login lub mapa
│   │   ├── providers.tsx             # Client component: ThemeProvider > AuthProvider > SocketProvider
│   │   ├── globals.css               # Tailwind imports, scrollbar, range input styling
│   │   ├── alerts/page.tsx           # Moje alerty (lista + zarządzanie)
│   │   ├── family/page.tsx           # Family Tracking (grupy, członkowie, geofence)
│   │   ├── stats/page.tsx            # Statystyki okolicy (today/week/total, trend 14d, top 30d)
│   │   ├── ranking/page.tsx          # Ranking użytkowników (top 50)
│   │   ├── profile/page.tsx          # Profil (avatar, promień alertów, share location)
│   │   ├── settings/page.tsx         # Ustawienia (theme, język, email, hasło, konto)
│   │   └── landing/
│   │       ├── page.tsx              # Strona marketingowa (landing page)
│   │       └── layout.tsx            # SEO metadata dla landing page
│   ├── components/
│   │   ├── auth/
│   │   │   └── LoginPage.tsx         # Ekran logowania / rejestracji / Google Sign-In
│   │   ├── map/
│   │   │   └── MapView.tsx           # Główna mapa Google Maps z alertami
│   │   ├── alerts/
│   │   │   ├── AlertDetail.tsx       # Panel szczegółów alertu (głosowanie, komentarze)
│   │   │   └── CreateAlertModal.tsx  # Modal tworzenia alertu (kategorie, formularz, zdjęcie)
│   │   └── ui/
│   │       ├── Sidebar.tsx           # Sidebar desktop + mobile hamburger + bottom nav
│   │       ├── AppLayout.tsx         # Wrapper: auth guard + sidebar + content
│   │       └── SOSButton.tsx         # Pulsujący przycisk SOS
│   ├── contexts/
│   │   ├── AuthContext.tsx            # AuthProvider (login, register, Google, logout, refresh)
│   │   ├── ThemeContext.tsx            # ThemeProvider (dark/light/system, localStorage)
│   │   └── SocketContext.tsx           # SocketProvider (Socket.io, event listeners, updateLocation)
│   ├── lib/
│   │   ├── api.ts                     # ApiService singleton (fetch + JWT)
│   │   ├── i18n.ts                    # System tłumaczeń PL/EN (~80 kluczy)
│   │   └── constants.ts               # API keys, URLs, map styles, duration options
│   └── types/
│       ├── index.ts                   # Interfejsy TS (Alert, User, FamilyGroup, Geofence, etc.)
│       └── google-identity.d.ts       # Typy Google Identity Services
```

### 7.3 Konfiguracja (`lib/constants.ts`)

| Stała | Wartość | Opis |
|---|---|---|
| `GOOGLE_MAPS_API_KEY` | `<USUNIĘTO — wartość w menedżerze haseł>` | Klucz Google Maps Web (z ograniczeniami) |
| `SOCKET_URL` | `https://alert.u235.pl` | URL serwera WebSocket |
| `API_BASE` | `https://alert.u235.pl/api/v1` | Base URL API |
| `DEFAULT_CENTER` | `{lat: 52.2297, lng: 21.0122}` | Domyślne centrum mapy (Warszawa) |
| `DEFAULT_ZOOM` | `13` | Domyślny zoom |
| `DURATION_OPTIONS` | `[1, 3, 6, 12, 24]` | Opcje czasu trwania alertu (h) |
| `DARK_MAP_STYLES` | Google Maps style array | Ciemna mapa (odpowiednik mobilnej) |
| `LIGHT_MAP_STYLES` | Google Maps style array | Jasna mapa (ukryte POI business) |

Wartości konfigurowalne przez env: `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY`, `NEXT_PUBLIC_SOCKET_URL`, `NEXT_PUBLIC_API_URL`.

### 7.4 Typy TypeScript (`types/index.ts`)

Główne interfejsy:

| Interfejs | Kluczowe pola |
|---|---|
| `Alert` | id, author_id, category, title, description, photo_url, lat, lng, radius_m, status, confirms, denies, expires_at, created_at, author_username, distance_m |
| `User` | id, email, username, avatar_url, alert_radius_m, reputation_score, is_child |
| `FamilyGroup` | id, name, owner_id, invite_code, created_at, member_count |
| `FamilyMember` | id, user_id, username, role, tracking_enabled, lat, lng, last_location_at |
| `Geofence` | id, group_id, name, lat, lng, radius_m, is_active |
| `AlertStats` | today, week, total, top_categories, trend_14d |
| `RankingUser` | id, username, avatar_url, alert_count, total_confirms, reputation_score |
| `LocationHistory` | id, lat, lng, recorded_at |
| `AlertComment` | id, user_id, username, content, created_at |

Typ `AlertCategory` — union 18 wartości string (identyczny z backend enum).

`ALERT_CATEGORIES` array — 18 obiektów z polami: `value`, `emoji`, `color`, `labelPl`, `labelEn`.
Helper `getCategoryInfo(category)` zwraca obiekt kategorii.

### 7.5 API Service (`lib/api.ts`)

Klasa `ApiService` (singleton via `export const api`):

- **`setToken(token)` / `getToken()`** — persystencja JWT w `localStorage`
- **`request<T>(method, path, body?, options?)`** — generyczny wrapper fetch:
  - Automatycznie dodaje `Authorization: Bearer <token>`
  - Obsługuje non-JSON responses (analogicznie do mobilnej `_decode()`)
  - Zwraca `T` lub rzuca błąd
- **Metody convenience:** `get<T>()`, `post<T>()`, `patch<T>()`, `delete<T>()`, `multipart<T>()`
- **`multipart()`** — używa `FormData` dla upload zdjęć

### 7.6 Konteksty (React Context)

#### AuthContext (`contexts/AuthContext.tsx`)

- **Stan:** `user: User | null`, `loading: boolean`
- **Metody:**
  - `login(email, password)` → POST `/auth/login` → setToken + setUser
  - `register(email, password, username)` → POST `/auth/register`
  - `loginWithGoogle(email, name, avatar)` → POST `/auth/google`
  - `logout()` → clearToken, clearUser
  - `refreshUser()` → GET `/users/me`
- **Auto-login:** useEffect sprawdza token w localStorage → GET `/users/me`

#### ThemeContext (`contexts/ThemeContext.tsx`)

- **Stan:** `theme: 'dark' | 'light' | 'system'`, `resolvedTheme: 'dark' | 'light'`
- **Persystencja:** localStorage klucz `theme`
- **Mechanizm:** Toggles `dark` class na `document.documentElement`, nasłuchuje `prefers-color-scheme` media query
- **Metody:** `setTheme(theme)`

#### SocketContext (`contexts/SocketContext.tsx`)

- **Połączenie:** Socket.io z JWT z localStorage w query string
- **Stan:** `connected: boolean`
- **Event listeners:** Pattern z refs/Sets dla:
  - `alert:new` → Set<(alert) => void>
  - `alert:updated` → Set<(alert) => void>
  - `alert:expired` → Set<({alert_id}) => void>
  - `family:location` → Set<(location) => void>
  - `family:geofence_exit` → Set<(data) => void>
- **Metody:**
  - `addEventListener(event, callback)` / `removeEventListener(event, callback)`
  - `updateLocation(lat, lng)` → emituje `location:update`

### 7.7 Ekrany i komponenty

#### Strona główna (`app/page.tsx`)
- Wyświetla spinner ładowania, LoginPage (jeśli brak usera), lub Sidebar + MapView

#### LoginPage (`components/auth/LoginPage.tsx`)
- Toggle logowanie / rejestracja
- Pola: email, password, username (tylko rejestracja)
- Google Sign-In via Google Identity Services (GIS library)
  - Client ID: `200274591700-jptqm86318od93eukrg0ajccpt87gfmu.apps.googleusercontent.com`
  - Ładuje `https://accounts.google.com/gsi/client` dynamicznie
  - `google.accounts.id.initialize()` + `renderButton()`
  - Callback dekoduje JWT credential → wysyła email/name/avatar do `/auth/google`
- Przełącznik języka PL/EN
- Wyświetlanie błędów

#### MapView (`components/map/MapView.tsx`)
- **Mapa:** `GoogleMap` z `@react-google-maps/api` z LoadScript
- **Geolokalizacja:** `navigator.geolocation.watchPosition()` — śledzi lokalizację usera
- **Ładowanie alertów:** `GET /alerts/nearby` na zdarzeniu `onIdle` mapy
- **WebSocket:** addEventListener na `alert:new` / `alert:updated` / `alert:expired` — real-time aktualizacja
- **Markery:** Custom SVG pin markers z emoji i kolorem kategorii (funkcja `createMarkerSvg()`)
- **Filtrowanie:** Dropdown filtra kategorii
- **InfoWindow:** Kliknięcie markera → okno z tytułem, kategorią, datą
- **Przycisk zgłoszenia:** Otwiera `CreateAlertModal`
- **Przycisk SOS:** Otwiera `SOSButton`
- **Panel szczegółów:** Kliknięcie „Szczegóły" → `AlertDetail` panel

#### AlertDetail (`components/alerts/AlertDetail.tsx`)
- Panel po prawej (w-96) z animacją slide-in
- Zdjęcie alertu, informacje meta (data, wygasa, wiarygodność, odległość)
- Pasek wiarygodności (zielono-czerwony gradient)
- Przyciski głosowania: Potwierdzam / Odrzucam
- Akcje autora: przedłuż o 3h, edycja opisu, usuń
- Informacje o autorze
- Lista komentarzy + pole dodawania komentarza

#### CreateAlertModal (`components/alerts/CreateAlertModal.tsx`)
- Modal dwuetapowy:
  1. Grid wyboru kategorii (18 kategorii z emoji i kolorami)
  2. Formularz: tytuł, opis, czas trwania (dropdown), zdjęcie (upload z preview), lokalizacja (display)
- Tworzenie: POST `/alerts` → upload zdjęcia via `multipart`

#### SOSButton (`components/ui/SOSButton.tsx`)
- Pulsujący czerwony przycisk (bottom-left, `animate-pulse`)
- Dialog potwierdzenia
- Wysyła alert emergency z geolokalizacją via POST `/alerts`

#### Sidebar (`components/ui/Sidebar.tsx`)
- **Desktop:** Stała boczna nawigacja (w-64) z linkami do: /, /alerts, /family, /stats, /ranking, /profile, /settings
- **Mobile (< md):** Hamburger menu (top bar h-14) + dolna nawigacja (5 ikon)
- Karta użytkownika (avatar, username, email)
- Przycisk wylogowania
- SVG ikony dla każdego elementu nawigacji

#### AppLayout (`components/ui/AppLayout.tsx`)
- Wrapper: sprawdza auth → jeśli brak usera → LoginPage
- Renderuje Sidebar + children (content area)

### 7.8 Podstrony

#### /alerts — Moje alerty (`app/alerts/page.tsx`)
- Lista alertów zalogowanego użytkownika
- Karty z kategorią, tytułem, statusem, datą
- Przycisk usuwania z potwierdzeniem
- Pull-to-refresh (ręczny przycisk odświeżenia)
- **API:** `GET /alerts/mine`, `DELETE /alerts/:id`

#### /family — Family Tracking (`app/family/page.tsx`)
- **Grupy rodzinne:**
  - Lista grup z nazwą, kodem zaproszenia, liczbą członków
  - Tworzenie grupy (modal z nazwą)
  - Dołączanie kodem (modal z input)
  - Usuwanie grupy
- **Członkowie** (po kliknięciu grupy):
  - Lista z rolą (Rodzic/Dziecko), tracking toggle
  - Usuwanie członka
- **Geofence:**
  - Lista bezpiecznych stref z nazwą, promieniem, statusem
  - Tworzenie (modal z nazwą, lat, lng, promieniem)
  - Usuwanie
- **API:** Pełne CRUD: `/family/groups`, `/family/groups/:id/members`, `/family/groups/:id/geofences`

#### /stats — Statystyki (`app/stats/page.tsx`)
- 3 karty podsumowania: Dziś / Tydzień / Łącznie
- Trend 14 dni — pionowy bar chart (div heights)
- Top zagrożenia 30 dni — poziomy bar chart z progress barami
- **API:** `GET /alerts/stats?lat=&lng=&radius_m=3000`

#### /ranking — Ranking (`app/ranking/page.tsx`)
- Top 50 użytkowników
- Medale dla top 3 (gold/silver/bronze)
- Kolumny: #, username, alerty, potwierdzenia, reputacja
- **API:** `GET /users/ranking`

#### /profile — Profil (`app/profile/page.tsx`)
- Karta użytkownika (avatar z inicjałem, username, email, reputacja)
- Slider promienia alertów (500m–20km)
- Przycisk „Udostępnij lokalizację" → generuje tymczasowy link
- **API:** `PATCH /users/me`, `POST /users/me/share-location`

#### /settings — Ustawienia (`app/settings/page.tsx`)
- **Motyw:** dark / light / system (radio buttons)
- **Język:** PL / EN (radio buttons)
- **Zmiana email** (wymaga hasła) → POST `/users/me/email`
- **Zmiana hasła** (wymaga aktualnego) → POST `/users/me/password`
- **Usunięcie konta** (wymaga hasła, dialog potwierdzenia) → POST `/users/me/delete`

### 7.9 System tłumaczeń web (`lib/i18n.ts`)

- **Języki:** `pl` (domyślny), `en`
- **Persystencja:** localStorage klucz `lang`
- **API:** `t(key)`, `getLang()`, `setLang(code)`, `tLang(key, lang)`
- **~80 kluczy** — pełne tłumaczenie interfejsu: nawigacja, formularze, błędy, kategorie, statystyki, ustawienia
- `availableLanguages` array z kodem i nazwą

### 7.10 Google Maps — konfiguracja web

- **API Key:** `<USUNIĘTO — wartość w menedżerze haseł>` (nazwa: "AlertMap Web")
- **Ograniczenia HTTP referrer:** `https://alert.u235.pl/*`, `http://localhost:3000/*`, `http://localhost:3005/*`
- **Dozwolone API:** Maps JavaScript API, Maps Embed API
- **Dark/Light styles:** Analogiczne do mobilnych (ukryte POI business, desaturacja, ciemne tło w dark mode)
- **Custom markery:** SVG pin generowany w JavaScript (funkcja `createMarkerSvg()`) — kolor kategorii + emoji, analogicznie do mobilnego Canvas API

### 7.11 Google Sign-In — konfiguracja web

- **Metoda:** Google Identity Services (GIS) — nie `google_sign_in` Flutter
- **Client ID:** `200274591700-jptqm86318od93eukrg0ajccpt87gfmu.apps.googleusercontent.com` (ten sam OAuth client co mobile)
- **Authorized JavaScript Origins:** `https://alert.u235.pl` (wymaga ręcznego dodania w Google Cloud Console)
- **Authorized Redirect URIs:** `https://alert.u235.pl` (wymaga ręcznego dodania)
- **Flow:** GIS button → callback z JWT credential → decode → POST `/auth/google`

### 7.12 Ikony kategorii SVG

18 plików SVG w `public/icons/categories/`. Każda ikona:
- **Wymiary:** viewBox 64×64, render 256×256
- **Styl:** Minimalistyczny, biały bg z zaokrąglonymi rogami, cień (drop shadow), czarny rysunek + kolor akcentu kategorii, dolny pasek w kolorze kategorii
- **Kategorie:** aggression, theft, accident, fire, flood, ice, construction, animal, dark_area, drugs, police, weather, other, stranger_danger, traffic_danger, playground_hazard, water_hazard, school_zone
- **Użycie:** Landing page (grid kategorii), potencjalnie w aplikacji

### 7.13 `package.json` — Zależności webowe

```json
{
  "dependencies": {
    "@googlemaps/react-wrapper": "^1.2.0",
    "@react-google-maps/api": "^2.20.8",
    "js-cookie": "^3.0.5",
    "next": "16.2.4",
    "react": "19.2.4",
    "react-dom": "19.2.4",
    "socket.io-client": "^4.8.3"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "^4",
    "@types/node": "^20",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "eslint": "^9",
    "eslint-config-next": "16.2.4",
    "tailwindcss": "^4",
    "typescript": "^5"
  }
}
```

---

## 8. Strona marketingowa (Landing Page)

**URL:** `https://alert.u235.pl/landing`
**Plik:** `web/src/app/landing/page.tsx`
**Layout:** `web/src/app/landing/layout.tsx` (SEO metadata)

Pełna strona marketingowa w języku polskim z animacjami scroll (FadeIn), dark mode support, responsywny design.

### 8.1 Sekcje landing page

1. **Navbar** — logo "be:Safe", linki do sekcji (#features, #sos, #family, #categories), przyciski "Zaloguj się" + "Pobierz APK"
2. **Hero** — "Wiedz o zagrożeniach zanim do Ciebie dotrą", CTA: pobierz APK (Android) + otwórz web app
3. **Map mockup** — symulacja okna przeglądarki z mapą, rozrzuconymi markerami i przyciskiem SOS
4. **Features** (6 kart) — mapa real-time, 18 kategorii, głosowanie, powiadomienia, zdjęcia, komentarze
5. **SOS** — animowany pulsujący przycisk SOS z opisem funkcji
6. **Family Tracking** (4 karty) — grupy, geofencing, historia lokalizacji, zagrożenia dziecięce
7. **Kategorie zagrożeń** — grid 18 kategorii z ikonami SVG (`/icons/categories/*.svg`)
8. **Statystyki** — animowane liczniki (18 kategorii, 24/7, <1s, 2 platformy)
9. **Jak to działa** — 3 kroki (zainstaluj, zgłoś, bądź bezpieczny)
10. **CTA końcowe** — przyciski pobierania APK + web app
11. **Footer** — be:Safe, rok, link polityka prywatności

### 8.2 SEO Metadata

```typescript
export const metadata: Metadata = {
  title: 'be:Safe — System ostrzeżeń o zagrożeniach',
  description: 'Community-driven system bezpieczeństwa...',
  openGraph: { /* ... */ },
}
```

### 8.3 Linki CTA

- **Pobierz APK:** `https://alert.u235.pl/download`
- **Otwórz web app:** `/` (strona główna aplikacji)

---

## 9. Konfiguracja Google Cloud

### Projekt GCloud

| Parametr | Wartość |
|---|---|
| Nazwa projektu | `kasbrykiet` |
| Project ID | `kasbrykiet-1534756858402` |
| Konto | `ptrmenes@gmail.com` |

### Google Maps

| Parametr | Wartość |
|---|---|
| API (Android) | Maps SDK for Android — **włączone** |
| API Key (Android) | `<USUNIĘTO — wartość w menedżerze haseł>` (nazwa: "AlertMap Android") |
| API Key (Web) | `<USUNIĘTO — wartość w menedżerze haseł>` (nazwa: "AlertMap Web") |
| Web Key ograniczenia | HTTP referrer: `https://alert.u235.pl/*`, `http://localhost:3000/*`, `http://localhost:3005/*` |
| Web Key dozwolone API | Maps JavaScript API, Maps Embed API |
| Konfiguracja Android | `AndroidManifest.xml` → `com.google.android.geo.API_KEY` |
| Konfiguracja iOS | `AppDelegate.swift` → `GMSServices.provideAPIKey(...)` |
| Konfiguracja Web | `web/src/lib/constants.ts` → `GOOGLE_MAPS_API_KEY` |

### Google Sign-In (OAuth 2.0)

| Parametr | Wartość |
|---|---|
| Web Client ID | `200274591700-jptqm86318od93eukrg0ajccpt87gfmu.apps.googleusercontent.com` |
| Android Client ID | `200274591700-tftojb0t6v6hapjpt9dps3np2he05t8o.apps.googleusercontent.com` |
| Debug SHA-1 | `85:C3:BB:B3:93:2B:A2:0E:1F:EA:8D:D6:BA:2F:17:DC:48:65:6D:21` |
| Package name | `pl.u235.alertmap` |
| Authorized JS Origins (web) | `https://alert.u235.pl` (wymaga ręcznego dodania w Console) |
| Authorized Redirect URIs (web) | `https://alert.u235.pl` (wymaga ręcznego dodania w Console) |

**Flow Google Sign-In (mobile):**
1. `GoogleSignIn(scopes: ['email'])`
2. `disconnect()` — wymagane przed każdym `signIn()` (workaround)
3. `signIn()` → `GoogleSignInAccount` (email, displayName, photoUrl)
4. POST `/auth/google` z danymi → backend tworzy/aktualizuje konto → JWT
5. `Navigator.pushReplacementNamed(context, '/map')` — workaround bo AuthGate nie reaguje

**Flow Google Sign-In (web):**
1. Załadowanie GIS library: `https://accounts.google.com/gsi/client`
2. `google.accounts.id.initialize({ client_id, callback })`
3. `google.accounts.id.renderButton(element, { theme, size })`
4. Callback: dekoduje JWT credential → POST `/auth/google` z email/name/avatar → JWT

### Android Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
```

**android:label** = `be:Safe`
**android:usesCleartextTraffic** = `true` (dla development)

---

## 10. Budowanie i testowanie

### Wymagania

| Narzędzie | Wersja/Ścieżka |
|---|---|
| Flutter SDK | ≥3.0.0 |
| Dart SDK | ≥3.0.0 |
| Java | JDK 17 (`JAVA_HOME=/usr/lib/jvm/java-17-temurin-jdk`) |
| Android SDK | Standardowa instalacja |
| Node.js | v22+ (VPS: v22.22.2) |
| npm | v10+ |

### Budowanie APK

```bash
# Ustaw JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-temurin-jdk

# Zbuduj release APK
cd /home/ooxo/alert/mobile
flutter build apk --release

# Wynik: build/app/outputs/flutter-apk/app-release.apk
```

### Budowanie aplikacji webowej

```bash
cd /home/ooxo/alert/web

# Instalacja zależności
npm install

# Build produkcyjny
npm run build

# Uruchomienie lokalnie (dev)
npm run dev    # http://localhost:3000

# Uruchomienie lokalnie (production)
npm start      # http://localhost:3000
```

### Deployment APK na serwer

```bash
# Skopiuj APK na VPS
scp build/app/outputs/flutter-apk/app-release.apk vps:/home/ubuntu/alertmap/AlertMap.apk

# Podbij wersję w backend/src/index.js:
# app.get('/version', ...) → { version: NOWY_NUMER, ... }

# Podbij wersję w mobile/lib/services/update_service.dart:
# const int appVersion = NOWY_NUMER;

# Restart backendu
ssh vps "pm2 restart alertmap"
```

### Deployment aplikacji webowej na VPS

```bash
# 1. Build lokalnie (opcjonalnie — można budować na VPS)
cd /home/ooxo/alert/web
npm run build

# 2. Rsync na VPS
rsync -avz --delete \
  --exclude=node_modules --exclude=.next --exclude=.git \
  /home/ooxo/alert/web/ vps:/home/ubuntu/alert-web/

# 3. Install + build na VPS
ssh vps "cd /home/ubuntu/alert-web && npm install && npm run build"

# 4. Restart PM2
ssh vps "pm2 restart alert-web"

# 5. Zweryfikuj
curl -sI https://alert.u235.pl
```

### Wireless debugging (telefon Android)

```bash
# 1. Na telefonie: Ustawienia → Opcje programisty → Debugowanie bezprzewodowe → Paruj
# 2. Na komputerze:
adb pair <ip>:<port_parowania>    # wpisz kod parowania
adb connect <ip>:<port_debugowania>

# 3. Uruchom apkę
cd /home/ooxo/alert/mobile
flutter run

# Hot reload: naciśnij 'r' w terminalu
# Hot restart: naciśnij 'R'
```

### Uruchomienie backendu lokalnie

```bash
cd /home/ooxo/alert/backend
# Utwórz .env z: DATABASE_URL, JWT_SECRET, JWT_EXPIRES_IN, PORT
npm install
npm run dev   # node --watch src/index.js
```

---

## 11. Znane problemy i TODO

### Znane problemy

| Problem | Platforma | Opis | Workaround |
|---|---|---|---|
| **Google Sign-In + AuthGate** | Mobile | Po zalogowaniu przez Google, AuthGate nie przebudowuje się automatycznie | `Navigator.pushReplacementNamed(context, '/map')` w LoginScreen |
| **Google Sign-In disconnect** | Mobile | Bez `disconnect()` przed `signIn()`, Google zwraca poprzednie konto | Zawsze wywołuj `disconnect()` przed `signIn()` |
| **Avatar z Google** | Mobile | `avatar_url` jest wysyłany do backendu ale nie jest wyświetlany w ProfileScreen | ProfileScreen używa pierwszej litery username zamiast avatara |
| **PNG ikony z game-icons.net** | Mobile | Ikony PNG nie ładują się w custom markerach Canvas | Używamy emoji jako fallback (działa) |
| **Brak FCM push** | Mobile | `FCM_SERVER_KEY` nie jest ustawiony na serwerze | WebSocket + polling co 60s + local notifications |
| **Brak background execution** | Mobile | Location tracking działa tylko gdy apka jest w foreground | Brak — wymaga implementacji foreground service |
| **Brak email verification** | Obie | Rejestracja nie wymaga potwierdzenia email | Brak |
| **Wersja w SettingsScreen** | Mobile | Hardcoded `'4'` zamiast `appVersion` | Zmienić na `'$appVersion'` z update_service.dart |
| **Google OAuth origins (web)** | Web | Google Sign-In wymaga ręcznego dodania `https://alert.u235.pl` jako Authorized JS Origin i Redirect URI w Google Cloud Console | Skonfigurować ręcznie w Console (projekt: kasbrykiet) |

### TODO

#### Mobile
- [ ] Implementacja FCM push notifications (ustawić FCM_SERVER_KEY, dodać firebase_messaging do Flutter)
- [ ] Background location tracking (foreground service Android, significant location changes iOS)
- [ ] Email verification przy rejestracji
- [ ] Wyświetlanie avatara Google w ProfileScreen
- [ ] Dynamiczna wersja w SettingsScreen
- [ ] Geofence notifications po stronie klienta (nie tylko WebSocket)
- [ ] Zdjęcia w komentarzach
- [ ] Edycja/usuwanie komentarzy
- [ ] Mapa cieplna (heatmap) w UI (endpoint istnieje)
- [ ] Historia lokalizacji dziecka na mapie (endpoint istnieje)
- [ ] iOS build i testowanie
- [ ] Testy jednostkowe i integracyjne

#### Web
- [ ] Dodać Authorized JavaScript Origins w Google Cloud Console dla Google Sign-In
- [ ] Mapa cieplna (heatmap) w UI
- [ ] Historia lokalizacji dziecka na mapie
- [ ] Mapa z członkami rodziny (interaktywna, jak w mobile FamilyGroupScreen)
- [ ] Geofence wizualizacja na mapie (kółka na mapie w /family)
- [ ] Edycja/usuwanie komentarzy
- [ ] Powiadomienia przeglądarkowe (Web Notifications API)
- [ ] PWA (manifest, service worker, offline support)
- [ ] Testy (unit, e2e)
- [ ] Zamiana ikon SVG kategorii na profesjonalne (AI-generated lub custom design)

---

## 12. Wytyczne dla kontynuacji przez AI

### Połączenie z VPS

```bash
ssh vps
# Alias zdefiniowany w ~/.ssh/config:
# Host vps
#   HostName 57.128.237.254
#   User ubuntu
```

### Połączenie telefonu (wireless debugging)

```bash
adb pair <ip>:<port>     # kod z telefonu
adb connect <ip>:<port>  # port debugowania (inny niż parowania!)
flutter devices           # sprawdź czy widzi telefon
cd /home/ooxo/alert/mobile
flutter run               # uruchom apkę
```

### Deployment zmian

```bash
# Backend:
scp backend/src/index.js vps:/home/ubuntu/alertmap/src/
scp backend/src/routes/*.js vps:/home/ubuntu/alertmap/src/routes/
ssh vps "pm2 restart alertmap"

# Wersja: podbij numer w index.js (GET /version) i update_service.dart (appVersion)

# APK:
cd /home/ooxo/alert/mobile
export JAVA_HOME=/usr/lib/jvm/java-17-temurin-jdk
flutter build apk --release
scp build/app/outputs/flutter-apk/app-release.apk vps:/home/ubuntu/alertmap/AlertMap.apk

# Web app:
cd /home/ooxo/alert/web
npm run build
rsync -avz --delete --exclude=node_modules --exclude=.next --exclude=.git \
  /home/ooxo/alert/web/ vps:/home/ubuntu/alert-web/
ssh vps "cd /home/ubuntu/alert-web && npm install && npm run build && pm2 restart alert-web"
```

### PM2 procesy na VPS

| Nazwa | Port | Ścieżka | Komenda |
|---|---|---|---|
| `alertmap` | 3001 | `/home/ubuntu/alertmap/src/` | `node index.js` |
| `alert-web` | 3005 | `/home/ubuntu/alert-web/` | `next start -p 3005` |

```bash
# Status PM2
ssh vps "pm2 list"

# Logi
ssh vps "pm2 logs alertmap --lines 20"
ssh vps "pm2 logs alert-web --lines 20"

# Restart
ssh vps "pm2 restart all"
```

### Nginx — konfiguracja na VPS

Plik: `/etc/nginx/sites-available/alert.u235.pl`

Reguły proxy (w kolejności):
1. `/api/*` → `localhost:3001` (Backend API)
2. `/socket.io/*` → `localhost:3001` (WebSocket z upgrade)
3. `/uploads/*` → `localhost:3001` (Uploadowane pliki)
4. `/_next/*` → `localhost:3005` (Next.js static, cache 30d)
5. `/*` (reszta) → `localhost:3005` (Next.js app)

### Konwencje kodu

**Dart (Flutter):**
- Styl: standardowy Dart style (flutter_lints)
- State management: Provider + ChangeNotifier
- Serwisy jako singletony przekazywane przez Provider.value
- Ekrany: StatefulWidget z `_load()` w initState
- API calls: `context.read<ApiService>().get/post/patch/delete()`
- Nawigacja: `Navigator.pushNamed()` / `Navigator.push(MaterialPageRoute(...))`

**TypeScript/React (Web):**
- Next.js App Router — `"use client"` dla komponentów z hookami
- State management: React Context + useState/useEffect
- API calls: `api.get/post/patch/delete()` (singleton z `lib/api.ts`)
- Routing: Next.js file-based (`app/*/page.tsx`)
- Styling: Tailwind CSS (mobile-first, `dark:` prefix dla dark mode)
- Tłumaczenia: `t('key')` z `lib/i18n.ts`

**Node.js (Backend):**
- Express Router per moduł
- Async/await z try/catch
- Parametryzowane zapytania SQL (pg)
- Middleware chain: auth → memberOf → parentOnly
- Odpowiedzi: `res.json({...})` z odpowiednim status code

### ⚠️ Ważne zasady

1. **NIE używać `flutter_map` ani `latlong2`** — projekt używa `google_maps_flutter`. Spec wspomina o flutter_map ale został zmieniony na Google Maps.

2. **`ApiService._decode()` obsługuje non-JSON responses** — nie zakładaj że backend zawsze zwraca JSON. Metoda sprawdza czy body zaczyna się od `{` lub `[`. (mobile)

3. **Web ApiService** (`web/src/lib/api.ts`) — analogiczna logika: obsługuje non-JSON, zwraca T lub rzuca error.

4. **Google Sign-In wymaga `disconnect()` przed `signIn()`** — bez tego Google zwraca cached konto. (mobile only; web używa GIS)

5. **Nazwa aplikacji to `be:Safe`** (nie AlertMap). Package name to `pl.u235.alertmap` (historyczny).

6. **Lokalna ścieżka projektu:** `/home/ooxo/alert`
   - Mobile: `/home/ooxo/alert/mobile`
   - Backend: `/home/ooxo/alert/backend`
   - Web: `/home/ooxo/alert/web`

7. **Backend na VPS jest w `/home/ubuntu/alertmap/src/`** (NIE `/backend/src/`). Struktura na VPS jest płaska — pliki z `backend/src/` trafiają bezpośrednio do `/home/ubuntu/alertmap/src/`.

8. **Web app na VPS jest w `/home/ubuntu/alert-web/`** — pełna kopia z rsync.

9. **PostGIS:** Wszystkie zapytania geolokalizacyjne używają `ST_MakePoint(lng, lat)::geography` — uwaga na kolejność (longitude, latitude)!

10. **WebSocket auth:** Token w query string, nie w headers. (zarówno mobile jak i web)

11. **Rate limiting:** `validate: { xForwardedForHeader: false }` — wyłączona walidacja X-Forwarded-For (za Nginx).

12. **Cron w index.js:** `setInterval` co 60s wygasza alerty — nie ma osobnego cron joba.

13. **Google Maps API keys:** Mobile i web mają osobne klucze. Web klucz (`<USUNIĘTO — wartość w menedżerze haseł>`) ma ograniczenia HTTP referrer.

14. **Porty na VPS:** 3001 (backend), 3005 (Next.js web). Porty 3000/3002/3003/3004 są zajęte przez inne procesy.
