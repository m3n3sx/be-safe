# be:Safe — Brief dla nowej sesji AI

> Czytaj W KOLEJNOŚCI: ten plik → `RELEASE_v61.md` → `AGENTS.md` (root)
> Aktualizacja: v61 LIVE na produkcji + Realme RMX3151 SSEUK7GACYIFHU4T (USB)

## TL;DR — w 30 sekund

**be:Safe** to polski community safety app (alerty bezpieczeństwa lokalne, tryb rodzinny). Stack: Flutter 3.29 + Node.js Express + PostgreSQL 16 PostGIS + Socket.io + FCM. Domena https://besafe.org.pl. Hosting AWS EC2 t3.xlarge.

W ciągu ostatnich kilkudziesięciu sesji (z (b1)-(b90) compressed blocks) zrobiono pełną Fazę A + B + C + sesje końcowe — **17 funkcji + F33 tryby + 4 fix krytyczne = 21 zmian produkcyjnych**. Aktualnie v61 LIVE.

## Co aktualnie LIVE w v61

### F33 Tryby aplikacji (KIDS/SENIOR/NORMAL)
3 odrębne layouty, `ModePickerScreen` po onboardingu, kolumna `users.app_mode`.

### Wszystkie funkcje per faza
- **Faza A** (v52): F11 AED · F20 Tryb szkolny · F21 Senior check-in · F26 Mental Health SOS · F27 Poradnik
- **Faza B** (v53-54): F01 Fake Call · F03 Eskorta · F12 KPP · F31 Trust score
- **Faza C** (v56-57): F04 Crash detection · F05 Moderacja tekstu · F14 Family chat · F08 Smart routing banner · F15 Verified · F19 Family planner
- **Sesja końcowa** (v58): F25 Pet mode · F28 Cyber-bezpieczeństwo · F29 Ultra offline (CacheService już ma)
- **Bonus sesja** (v59): F07 Shake-to-SOS · F17 Anonimowe · CI/CD fix
- **Bonus sesja** (v60): F02 Audio SOS RODO · F23 paczka tłumaczeń
- **Bonus sesja** (v61): F24 Biometria · F32 Parental controls · F17 AQI GIOŚ · GPS spoofing

### Krytyczne bug fixes
- v51 — P0 auto-login fix (`_SessionCheckScreen`, race condition)
- v55 — Profile bottom padding (PillNavBar zasłaniał logout)
- v59 — CI/CD workflow ścieżki + `--no-tree-shake-icons`
- login_helper.dart — auto-login fallback (z (b78), b90)

## Decyzje strategiczne (z (b51))

### Świadomie ODŁOŻONE (kandydaci na osobne sesje)
- **F13 mObywatel KWIE** — pominięte na życzenie użytkownika (m2110)
- **F10 Wear OS native** — wymaga osobnego Kotlin module + tygodnia
- **F30 Mesh P2P** — POC only, huge effort
- **F06 AI image moderation** — wymaga Google Cloud Vision setup
- **F08 Smart Route Recommender** (dynamic routing) — wymaga Mapbox/OSRM avoid zones

### ODRZUCONE
- Voice activation w tle (niemożliwe na iOS/Android bez ciągłej notyfikacji)
- Pełne parental controls Screen Time blocking (Family Link dominuje — F32 linkuje do tych narzędzi)
- Live Audio/Video SOS streaming (RODO ryzyko, odłożone do Fazy C)

## Kolejka rzeczy do zrobienia (jeśli "lecimy dalej")

### Quick wins
- **F18 City hazards** — dodać 3-4 nowe kategorie alertów (pothole/dark_passage/broken_lights) + filtr mapy
- **F23 Ghost mode** — granularna widoczność lokalizacji (per-osoba, harmonogram, "ghost na 1h")
- **F14 Geofence chat sąsiedzki** — Nextdoor-style chat oparty na ST_DWithin (radius ~1km od centrum miasta)

### Średnia złożoność
- **F16 RSO/RCB bridge** — public RSS feed RCB, alerty rządowe jako osobna warstwa
- **F06 AI image moderation** — Google Cloud Vision z safe-search detection na zdjęciach alertów
- **Refaktor i18n** — 591 hardcoded polskich stringów na `S.get()` po otrzymaniu paczki EN/UA z Perplexity

### Duże
- **F08 Smart Route Recommender** dynamic — Mapbox Directions API z `exclude` parametrem dla aktywnych alertów
- **F09 AI anomaly rutyny dziecka** — ML model na `location_history` (wykrywanie nietypowych godzin/lokalizacji)
- **E2E Patrol pełny re-run** — login_helper fixed, można testować v61

## Schema DB (kluczowe tabele)

### users (24+ kolumn)
- `is_test` (BOOLEAN) — flagi testowe
- `phone` (VARCHAR 20)
- `last_seen_at`, `last_battery_level`, `last_battery_at`
- `alert_radius_m` (default 500)
- `app_mode` (kids/senior/normal)
- `reputation_score` (1-200)
- `is_kpp`, `kpp_certificate` (F12)
- `is_verified`, `verified_role`, `organization` (F15)
- `last_location` GEOGRAPHY(POINT, 4326)

### Pozostałe
- `alerts` — author_id, category enum, location GEOG, radius_m, status, confirms, denies, **trust_score**, **is_anonymous**
- `family_groups` — `owner_id` (NIE `created_by`!), invite_code VARCHAR(8)
- `family_members` — role enum 'parent'|'child', tracking_enabled, **school_hours_silent**
- `alert_reports.reporter_id` (NIE user_id!)
- `safe_routes` — polyline LINESTRING, threshold_m 30-1000
- `family_pings` — sender_id+recipient_id, response_status 'ok'|'not_ok'|'expired'
- `family_messages` — group_id, author_id, body 1-2000ch (F14 chat rodzinny)
- `family_events` — title 1-200ch, starts_at, reminder_minutes_before, reminder_sent (F19)
- `pets` — group_id, owner_id, species enum, status home|walking|lost|found
- `escort_sessions` — requester_id+watcher_id, status active|completed|expired|panic
- `aeds` — GEOGRAPHY POINT z OSM source_id (F11)
- `air_quality_stations` + `air_quality_readings` — GIOŚ stacje (F17 v61)

## FCM payload types

| type | Routing |
|---|---|
| `new_alert`, `child_in_alert_area`, `family_alert_near_child` | `/alert-detail` |
| `family_sos` | `/family-sos` |
| `family_ping` | `/ping-response` |
| `ping_response` | SnackBar + nav `/family` |
| `geofence_exit/enter`, `route_exit/return` | `/family` |
| `escort_invite/panic/completed` | `/escort` |
| `family_message` | `/family` |
| `family_event_reminder` | `/family` |
| `pet_lost/lost_nearby/found/sighting` | `/family` |
| `child_low_battery` | `/family` |
| `kpp_responder_call` | `/alert-detail` |
| `checkin_reminder` | `/home`, `checkin_missing` → `/family` |

## Skille i agenci dostępni

W `/home/ooxo/alert/.opencode/agents/`:
- `performance-optimizer.md` — login speed, ApiService retry, FCM blocking
- `e2e-test-author.md` — Patrol patterns
- `e2e-runner.md` — orchestracja istniejących suit
- `backend-engineer.md` — Node.js, schema, FCM
- `mobile-engineer.md` — Flutter, Serenity, map_markers Canvas

W systemie globalne skille opencode (w katalogu `~/.config/opencode/skills/`):
gcloud, nextjs, medusa-js, system-admin, debug, code-review, refactor, security-audit, tailwind-css, performance, project-init, documentation, marketing, seo, ecommerce, business, google-analytics, google-ads, git-workflow, commit-message, customize-opencode.

## Pliki do przeczytania w nowej sesji

1. **`/home/ooxo/alert/AGENTS.md`** (główne reguły, automatycznie ładowane)
2. **`/home/ooxo/alert/docs/SESSION_BRIEF.md`** (ten plik — strategiczny overview)
3. **`/home/ooxo/alert/docs/RELEASE_v61.md`** (changelog v51-v61)
4. **`/home/ooxo/alert/docs/E2E_TEST_PLAN.md`** (matryca testowa)
5. **`/home/ooxo/alert/docs/analizy/`** — 2 raporty AI (TOP 30 ROI + mapowanie)

## Komenda startowa dla nowej sesji

```
Czytaj AGENTS.md w root oraz docs/SESSION_BRIEF.md + docs/RELEASE_v61.md.
Aktualny stan: v61 LIVE. Telefon Realme RMX3151 SSEUK7GACYIFHU4T podłączony USB (lub nie).

Co dalej w kolejce: <wybierz z listy w SESSION_BRIEF "Kolejka rzeczy do zrobienia"
albo powiedz "lecisz dalej" = realizuj kolejkę po kolei>.
```

## Telefony testowe

- **Realme RMX3151** USB SSEUK7GACYIFHU4T (Android 13) — przeważnie aktualnie podłączony
- **Realme RMX3741** USB SK4D5X7P45ZTGIIR (Android 15) — alternatywny
- **Moto G84 5G** USB ZY32HKMT45 — archiwalny

```bash
# Instalacja APK
adb -s SERIAL install -r /home/ooxo/alert/mobile/build/app/outputs/flutter-apk/app-release.apk
adb -s SERIAL shell am force-stop pl.u235.alertmap
adb -s SERIAL shell am start -n pl.u235.alertmap/.MainActivity
```

## Mostek do skompresowanej historii

Wszystkie wcześniejsze sesje skompresowane w blocks `(b1)` do `(b90)` — pełen kontekst implementacji v36-v61. Jeśli potrzebujesz szczegółów konkretnej funkcji — pyt agent w terminalu może tego nie mieć w obecnym kontekście, ale jest w git historii commitów lub w `/home/ooxo/alert/docs/RELEASE_v*.md`.

W nowej sesji ten brief + AGENTS.md + RELEASE_v61.md powinny wystarczyć do natychmiastowej kontynuacji bez ponownego briefingu.
