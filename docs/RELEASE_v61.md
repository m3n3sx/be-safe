# be:Safe — Release Notes v59 → v61

> v58 RELEASE_v58.md zawiera szczegóły do v58. Tutaj inkrementalne v59-v61.

## v61 (current LIVE) — Quick wins z raportów AI

### F24 Biometryczna blokada aplikacji
**Mobile-only.** Po włączeniu w Settings, aplikacja przy starcie wymaga odcisku palca / Face Unlock / PIN.

- `pubspec.yaml`: `local_auth`
- `AndroidManifest.xml`: `USE_BIOMETRIC` + `USE_FINGERPRINT`
- `MainActivity.kt` zmieniony z `FlutterActivity` → `FlutterFragmentActivity` (wymagane przez local_auth dla bio prompt)
- Nowy plik `lib/services/biometric_service.dart` (singleton, SharedPreferences key `biometric_enabled`)
- `main.dart`: dodany `_BiometricLockScreen` po udanym auto-login gdy biometria włączona ale niezatwierdzona w sesji
- `settings_screen.dart`: SwitchListTile po crash detection

### F32 Parental controls (linki)
**Mobile-only.** be:Safe NIE zastępuje pełnego parental control — kierujemy na sprawdzone narzędzia.

Nowy plik `lib/screens/parental_controls/parental_controls_screen.dart`:
- Hero card z wyjaśnieniem ("my zajmujemy się safety, do limitów polecamy ↓")
- 6 narzędzi: Family Link, Apple Screen Time, Qustodio, Bark, NASK/dyzurnet.pl, Fundacja Dajemy Dzieciom Siłę
- Sekcja "Pamiętaj" z 3 zasadami (rozmawiaj zamiast blokować, ustal wspólne zasady, daj przykład)

Wpięty w Settings tile pod "Bezpieczeństwo danych".

### F17 AQI GIOŚ (warstwa środowiskowa)
**Backend + Mobile.**

DB:
```sql
CREATE TABLE air_quality_stations (id INTEGER PK, name, location GEOGRAPHY, city, address, last_synced_at);
CREATE TABLE air_quality_readings (station_id PK FK, aqi_index, aqi_label, pm10, pm25, no2, so2, o3, measured_at, fetched_at);
CREATE INDEX idx_aqi_loc ON air_quality_stations USING GIST(location);
```

Backend:
- `services/aqi.js` — sync z `https://api.gios.gov.pl/pjp-api/v1/rest/station/findAll` (JSON-LD, Accept: `application/ld+json`). Daily cron + manual refresh per-request (cache 30min). 289 stacji w PL.
- `routes/aqi.js` — `GET /aqi/nearby?lat=&lng=&radius_m=30000&limit=5` (auth required, ST_DWithin)

Mobile:
- `widgets/aqi_widget.dart` — color-coded card z indeksem 0-5 (Bardzo dobry → Bardzo zły), ikona twarz, refresh button
- Wpięty w `HomeScreen` pod children card (`SliverToBoxAdapter`)

### GPS spoofing detection
**Mobile-only.** `LocationService.isSpoofed()` jako static check.

Heurystyka:
- `Position.isMocked` (geolocator API) → instant flag
- Prędkość między ostatnią a aktualną pozycją > 280 m/s (~1000 km/h) → spoof
- Skok > 50 km w < 60s → spoof

`getCurrentPosition()` zwraca null gdy spoof wykryty.

---

## v60 — F02 Audio SOS + F23 paczka tłumaczeń + login_helper fix

### F02 Audio SOS Recording z RODO consent
**Mobile-only.** Nagrywanie 30s audio TYLKO podczas `_fireSOS()`.

- `pubspec.yaml`: `record`, `permission_handler`, `path_provider`
- `AndroidManifest.xml`: `RECORD_AUDIO`, `FOREGROUND_SERVICE_MICROPHONE`
- `services/sos_audio_service.dart` (~170 linii) — AAC 64kbps 22kHz mono, ~120KB/30s, zapis w `getApplicationDocumentsDirectory()/sos_audio/`
- SharedPreferences keys: `sos_audio_enabled` + `sos_audio_consent_at`
- `settings_screen.dart`: PEŁNY RODO consent dialog (cytuje art. 6 ust. 1 lit. a RODO, "Zgadzam się"/"Nie zgadzam się"), barrierDismissible=false. 3 sub-akcje gdy zgoda: "Usuń nagrania", "Cofnij zgodę RODO" (= clear all + disable)
- `sos_screen.dart` `_fireSOS()`: fire-and-forget `audio.startRecording().catchError(...)`
- KLUCZOWE: aktywacja **tylko** podczas alarmu SOS, nigdy w tle

### F23 Paczka tłumaczeń dla Perplexity
Zob. `/home/ooxo/alert/docs/translations/`:
- `README.md` (workflow + status)
- `PROMPT_FOR_PERPLEXITY.md` (pełna instrukcja)
- `i18n_core_pl.json` (87 kluczy z istniejącego `i18n.dart`)
- `i18n_extended_pl.json` (~150 nowych z F33/F11/F21/...)
- `i18n_buttons_actions_pl.json` (~80 akcji/dialogów/kategorii)

Master format: 3-poziomowe `{pl, en, uk}`. Wystarczy wysłać Perplexity + 3 JSON → zwrócą master.

Tłumaczenia jeszcze NIE w aplikacji — refaktor 591 hardcoded stringów na `S.get()` to ~2-3 dni, zaplanowane jako v62+.

### E2E Patrol login_helper.dart fix (auto-login state)
`setupAndFillCredentials`: gdy auto-login wszedł → fallback `_waitFor($('Mapa'), homeLoaded)` zamiast hangu szukającego TextField.

---

## v59 — F07 + F17 (oryginalne) + CI/CD

### F07 Shake-to-SOS panic gesture
**Mobile-only.**

- `services/shake_detection_service.dart` (~115 linii)
- Threshold 18 m/s² (~1.8g), 3 peaki w oknie 1500ms, debounce 150ms, cooldown 30s
- SharedPreferences key `shake_to_sos_enabled`
- Po detekcji: HapticFeedback.heavyImpact ×2 + `Navigator.push(SosScreen())` — NIE auto-fire
- Settings: SwitchListTile z dialogiem ostrzegawczym ("3 wstrząśnięcia → ekran SOS, NIE wysyła automatycznie")
- Wpięte w main.dart `_handleAuth` po FcmService init

### F17 Anonimowe zgłoszenia
**Backend + Mobile.**

DB: `ALTER TABLE alerts ADD COLUMN is_anonymous BOOLEAN DEFAULT FALSE`. `author_id` zostaje (dla moderacji).

Backend `routes/alerts.js`:
- `authorJson`: `CASE WHEN a.is_anonymous AND a.author_id != $1 THEN NULL ELSE json_build_object(...) END`
- GET /nearby/:id używają nowego `authorJson`. GET /mine bez zmian.
- POST: `is_anonymous` z body normalized (`=== true|'true'|1|'1'`) + INSERT z polem

Mobile:
- `models/alert.dart`: `isAnonymous` getter z `fromJson`
- `create_alert_screen.dart`: `_buildAnonymousToggle()` SwitchListTile po duration chips

### CI/CD `.github/workflows/build-deploy.yml`
- Ścieżka APK: `/home/ubuntu/alertmap/AlertMap.apk` → `/home/ubuntu/besafe/backend/AlertMap.apk`
- pm2 process: `alertmap` → `besafe-backend`
- Backend deploy job: `/home/ubuntu/alertmap/src/` → `/home/ubuntu/besafe/backend/src/`
- Build: dodane `--no-tree-shake-icons` (Canvas markery dynamiczne IconData)
- Komentarze objaśniające double-source-of-truth wersji

---

## Kontekst: 2 raporty AI z `docs/analizy/`

Po wdrożeniu v60 zauważono że **F-numeracja w raporcie Perplexity różni się** od używanej w implementacji. Pełne mapowanie w m2160 (b90→b61 mapping section). Najważniejsze:

| Co miałem | Co znaczy w raporcie Perplexity |
|---|---|
| F05 = moderacja tekstu | F07 (AI moderacja czatu) |
| F17 = anonimowe | F23 (zaawansowana prywatność lokalizacji) — RÓŻNE rzeczy! |
| F23 = tłumaczenia | F23 w raporcie = ghost mode lokalizacji |

W przyszłości: implementuję pod naszym numerowaniem, ale referencje do raportu trzymam jako numerację raportową w komentarzach.

### Co PRZEOCZONE (z analizy m2160)
1. **F06** AI moderacja zdjęć (rank #7) — Vision API, nie wdrożone
2. **F23 Ghost mode** lokalizacji (rank #17) — granularność widoczności GPS dla nastolatków
3. **F14 Geofence chat sąsiedzki** (rank #19) — Nextdoor-style (nie rodzinny chat!)
4. **F18 City hazards** (rank #18) — potholes/dark_passage/broken_lights
5. **F16 RSO/RCB bridge** (rank #21) — Rządowy System Ostrzegania
6. **F08 Smart Route Recommender** (rank #23) — dynamic re-routing z avoid zones (nie banner!)
7. **F09 AI anomaly rutyny** (rank #24) — ML wykrywający nietypowe zachowania
8. **F10 Wear OS** (rank #25) — odłożone (osobna sesja)
9. **F13 Smart home / voice** (rank #29) — niska wartość
10. **F30 Mesh P2P** (rank #30) — huge effort

---

## Deploy v61 — komenda referencyjna

```bash
# Mobile
echo "appVersion = 61" w lib/services/update_service.dart:7
cd /home/ooxo/alert/mobile
JAVA_HOME=/usr/lib/jvm/temurin-17-jdk /home/ooxo/flutter/bin/flutter build apk --release --no-tree-shake-icons
scp -i ~/.ssh/besafe_key.pem build/app/outputs/flutter-apk/app-release.apk ubuntu@16.192.31.100:/home/ubuntu/besafe/backend/AlertMap.apk

# Backend (na prod sed-em)
ssh -i ~/.ssh/besafe_key.pem ubuntu@16.192.31.100 'sudo sed -i "s/version: [0-9]*/version: 61/" /home/ubuntu/besafe/backend/src/index.js && pm2 restart besafe-backend --silent'

# Verify
curl https://besafe.org.pl/version  # → {"version":61}
curl -I https://besafe.org.pl/download  # → 200 OK, Content-Length ~67 MB
```

---

## v61 statystyki

- APK: **67.4 MB** (release, no-tree-shake-icons)
- Backend: pid restarted po deploy, online
- Nowe pliki Flutter:
  - `lib/services/biometric_service.dart` (~85 linii)
  - `lib/screens/parental_controls/parental_controls_screen.dart` (~200 linii)
  - `lib/widgets/aqi_widget.dart` (~130 linii)
- Nowe pliki Backend:
  - `services/aqi.js` (~130 linii)
  - `routes/aqi.js` (~26 linii)
- Zmodyfikowane:
  - `lib/services/location_service.dart` (+spoofing detection)
  - `lib/main.dart` (BiometricService init + `_BiometricLockScreen`)
  - `lib/screens/settings/settings_screen.dart` (+F24 toggle, +F32 tile)
  - `lib/screens/home/home_screen.dart` (+AQI widget)
  - `android/app/src/main/AndroidManifest.xml` (+USE_BIOMETRIC, +USE_FINGERPRINT)
  - `android/app/src/main/kotlin/.../MainActivity.kt` (→FlutterFragmentActivity)
  - `backend/src/index.js` (+/api/v1/aqi route, +AQI daily cron)

Telefon nie podłączony w momencie deploy — OTA UpdateService dostarczy v61 przy najbliższym otwarciu aplikacji.
