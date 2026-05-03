# AlertMap — API Endpoints

Base URL: `https://<vps-ip>/api/v1`
Auth: Bearer JWT token (oprócz rejestracji/logowania)
Format: JSON

---

## Auth

### `POST /auth/register`
Rejestracja nowego użytkownika.
```json
// Request
{ "email": "jan@example.com", "password": "secret123", "username": "jan" }
// Response 201
{ "token": "jwt...", "user": { "id": "uuid", "email": "...", "username": "..." } }
```

### `POST /auth/login`
```json
// Request
{ "email": "jan@example.com", "password": "secret123" }
// Response 200
{ "token": "jwt...", "user": { ... } }
```

### `POST /auth/refresh`
Odświeżenie tokena JWT.
```json
// Response 200
{ "token": "new-jwt..." }
```

---

## User

### `GET /users/me`
Profil zalogowanego użytkownika.

### `PATCH /users/me`
Aktualizacja profilu.
```json
// Request (dowolne pola)
{ "username": "nowy", "alert_radius_m": 1000, "avatar_url": "..." }
```

### `PUT /users/me/location`
Aktualizacja lokalizacji użytkownika (wywoływane przez apkę w tle).
```json
// Request
{ "lat": 52.2297, "lng": 21.0122 }
// Response 200
{ "nearby_alerts": [ ... ] }  // opcjonalnie zwraca nowe alerty w promieniu
```

### `PUT /users/me/fcm-token`
Rejestracja tokena FCM do push notifications.
```json
{ "fcm_token": "firebase-token..." }
```

---

## Alerts

### `GET /alerts/nearby`
Pobierz aktywne alerty w okolicy.
```
Query params:
  lat (required) - szerokość geograficzna
  lng (required) - długość geograficzna
  radius_m (optional, default 1000) - promień szukania
  category (optional) - filtr kategorii
```
```json
// Response 200
{
  "alerts": [
    {
      "id": "uuid",
      "category": "aggression",
      "title": "Agresywna grupa w parku",
      "description": "3-4 osoby zaczepiają przechodniów",
      "lat": 52.2297,
      "lng": 21.0122,
      "radius_m": 100,
      "confirms": 5,
      "denies": 0,
      "distance_m": 230,
      "expires_at": "2026-04-30T22:00:00Z",
      "created_at": "2026-04-30T19:00:00Z",
      "author": { "username": "jan", "reputation_score": 95 }
    }
  ]
}
```

### `POST /alerts`
Zgłoś nowe zagrożenie.
```json
// Request
{
  "category": "aggression",
  "title": "Agresywna grupa w parku",
  "description": "3-4 osoby zaczepiają przechodniów przy fontannie",
  "lat": 52.2297,
  "lng": 21.0122,
  "radius_m": 100,
  "duration_hours": 3
}
// Response 201
{ "id": "uuid", ... }
```

### `POST /alerts/:id/photo`
Upload zdjęcia do zgłoszenia (multipart/form-data).

### `GET /alerts/:id`
Szczegóły pojedynczego alertu.

### `DELETE /alerts/:id`
Usunięcie własnego zgłoszenia.

### `POST /alerts/:id/vote`
Potwierdź lub odrzuć zgłoszenie.
```json
// Request
{ "vote": "confirm" }  // lub "deny"
// Response 200
{ "confirms": 6, "denies": 0 }
```

---

## Family

### `POST /family/groups`
Utwórz grupę rodzinną.
```json
// Request
{ "name": "Kowalscy" }
// Response 201
{ "id": "uuid", "name": "Kowalscy", "invite_code": "AB12CD34" }
```

### `GET /family/groups`
Lista grup użytkownika.

### `POST /family/groups/join`
Dołącz do grupy kodem zaproszenia.
```json
// Request
{ "invite_code": "AB12CD34" }
```

### `GET /family/groups/:id/members`
Lista członków grupy.
```json
// Response 200
{
  "members": [
    {
      "user_id": "uuid",
      "username": "dziecko1",
      "role": "child",
      "tracking_enabled": true,
      "last_location": { "lat": 52.23, "lng": 21.01 },
      "last_location_at": "2026-04-30T19:05:00Z"
    }
  ]
}
```

### `PATCH /family/groups/:id/members/:user_id`
Zarządzanie członkiem (tylko parent).
```json
// Request
{ "tracking_enabled": false }
// lub
{ "role": "child" }
```

### `DELETE /family/groups/:id/members/:user_id`
Usuń członka z grupy (tylko parent).

### `DELETE /family/groups/:id`
Usuń grupę (tylko owner).

---

## Geofences

### `POST /family/groups/:id/geofences`
Utwórz bezpieczną strefę.
```json
// Request
{ "name": "Dom", "lat": 52.2297, "lng": 21.0122, "radius_m": 200 }
// Response 201
{ "id": "uuid", ... }
```

### `GET /family/groups/:id/geofences`
Lista geofence'ów grupy.

### `PATCH /family/groups/:id/geofences/:gid`
Edycja geofence'a.

### `DELETE /family/groups/:id/geofences/:gid`
Usunięcie geofence'a.

---

## Location (family tracking)

### `GET /family/groups/:id/members/:user_id/location`
Aktualna lokalizacja członka (tylko parent).
```json
// Response 200
{ "lat": 52.23, "lng": 21.01, "recorded_at": "2026-04-30T19:05:00Z" }
```

### `GET /family/groups/:id/members/:user_id/location/history`
Historia lokalizacji członka.
```
Query params:
  from (optional) - ISO datetime
  to (optional) - ISO datetime
  limit (optional, default 100)
```

---

## WebSocket Events

Połączenie: `wss://<vps-ip>/ws?token=jwt...`

### Server → Client

| Event | Payload | Opis |
|---|---|---|
| `alert:new` | `{ alert }` | Nowy alert w promieniu użytkownika |
| `alert:updated` | `{ alert }` | Zmiana statusu/głosów alertu |
| `alert:expired` | `{ alert_id }` | Alert wygasł |
| `family:location` | `{ user_id, lat, lng, recorded_at }` | Aktualizacja lokalizacji członka rodziny |
| `family:geofence_exit` | `{ user_id, username, geofence_name }` | Dziecko opuściło bezpieczną strefę |

### Client → Server

| Event | Payload | Opis |
|---|---|---|
| `location:update` | `{ lat, lng }` | Aktualizacja pozycji użytkownika |

---

## Kody błędów

| HTTP | Znaczenie |
|---|---|
| 400 | Nieprawidłowe dane wejściowe |
| 401 | Brak/nieprawidłowy token |
| 403 | Brak uprawnień (np. child próbuje zarządzać grupą) |
| 404 | Zasób nie znaleziony |
| 409 | Konflikt (np. duplikat głosu) |
| 429 | Rate limit exceeded |

## Rate Limiting

| Endpoint | Limit |
|---|---|
| `POST /auth/*` | 5 req/min |
| `POST /alerts` | 10 req/h |
| `PUT /users/me/location` | 60 req/min |
| Pozostałe | 100 req/min |
