# be:Safe v58 — Release Notes

**Status:** LIVE na produkcji (`https://besafe.org.pl/version` → 58)
**Data wydania:** 17 maja 2026
**APK:** 66.8 MB (`https://besafe.org.pl/download`)

## Pełna lista wdrożonych funkcji

### F33 — Tryby aplikacji (3 odrębne layouty)
- **KIDS** 🧒 (7-12 lat): wielkie kafelki, 3 zakładki, triple-tap POMOC, mint+coral
- **SENIOR** 👴 (60+): font 22px+, touch 64dp, "ZAMELDUJ SIĘ" jako #1 akcja, brak gestów
- **NORMAL** 🧑 (13-59): pełny UI Serenity Guard z 5 zakładkami
- Wybór: po onboardingu PRZED rejestracją (`ModePickerScreen`), zmiana w Ustawienia
- Backend: `ALTER users.app_mode CHECK kids/senior/normal`, GET/PATCH /me z polem

### Faza A — Quick Wins (5 funkcji)
| # | Funkcja | Status |
|---|---------|--------|
| F11 | AED Locator (16 600 defibrylatorów PL, daily Overpass sync, warstwa mapy z mint sercem, modal Navigate/Call) | ✅ |
| F20 | Tryb szkolny (silent push pn-pt 8-15 dla dziecka, toggle w family_group, banner CISZA SZKOLNA w HomeKids) | ✅ |
| F21 | Senior daily check-in (przycisk "ZAMELDUJ SIĘ" w HomeSenior, cron 20:00, badge w karcie family) | ✅ |
| F26 | Mental Health SOS (116 123, 116 111, 800 70 22 22, 112, link do psycholodzy.pl) | ✅ |
| F27 | Poradnik bezpieczeństwa (12 ExpansionTile: numery, RKO, dom, burza, oszustwa, jazda, dzieci…) | ✅ |

### Faza B — Differentiators (4 funkcje)
| # | Funkcja | Status |
|---|---------|--------|
| F01 | Fake Call (`FakeCallSetupScreen` + `FakeCallIncomingScreen` z pulsem, hapticiem, immersive mode) | ✅ |
| F03 | Eskorta Follow Me (sesja z ETA + countdown + live tracking + cron panic 30s + FCM alarm watchera) | ✅ |
| F12 | KPP Responder (flaga `users.is_kpp`, push FCM w 2km radius dla SOS, opt-in w Settings z disclaimerem) | ✅ |
| F31 | Trust score alertów (weighted vote po reputation, chip 'zaufany' aqua przy reputation ≥120) | ✅ |

### Faza C — Bezpieczeństwo i komunikacja (6 funkcji)
| # | Funkcja | Status |
|---|---------|--------|
| F04 | Crash detection (sensors_plus akcelerometr, threshold 2.5g/200ms, 30s grace dialog + auto-SOS) | ✅ |
| F05 | Text moderation (heurystyka: profanity, all_caps, troll patterns, only_emoji → block/flag/allow, SOS bypass) | ✅ |
| F08 | Smart routing (banner ostrzeżenia gdy aktywny alert blisko zapisanej safe_route, GET /alerts-near) | ✅ |
| F14 | Family chat (tabela family_messages, GET/POST, Socket.io stream, FCM type=family_message) | ✅ |
| F15 | Verified instytucje (badge mint w `_AlertListItem` z label 'Policja'/'Straż'/'Ratownictwo' gdy author zweryfikowany) | ✅ |
| F19 | Family planner (tabela family_events, 4 endpointy CRUD, cron reminderów, FamilyPlannerScreen z FAB) | ✅ |

### Sesja końcowa (2 funkcje)
| # | Funkcja | Status |
|---|---------|--------|
| F25 | Pet mode (tabela pets, 8 endpointów, `PetsScreen` z markowaniem ZAGUBIONY/ZNALEZIONO, FCM push do members + nearby 3km) | ✅ |
| F28 | Cyber-bezpieczeństwo (`CyberSafetyScreen`: mObywatel/CERT.pl/HIBP/Bezpiecznedane/8080 + 6 zasad higieny + sekcja "Padłeś ofiarą?") | ✅ |

### Bug fixes w sesji
- **P0 Login auto-login fix (v51)**: tryAutoLogin z 6s timeout + `_SessionCheckScreen` (brak flash LoginScreen)
- **Profile padding (v55)**: SizedBox 96px + safe area zamiast 48px (PillNavBar przestał zasłaniać "Wyloguj się")
- **login_helper.dart**: `.first` na `$('Zaloguj się')` (Bad state: No element fix), `dragUntilVisible` dla auto-logout
- **Geolocator 12 API**: `desiredAccuracy: LocationAccuracy.high` (NIE locationSettings, znikło w nowszej wersji)

### Pominięte z (b51) świadomie
- **F02 Audio recording przy SOS** — RODO ryzyko, odrożone
- **F22 Accessibility mode** — POKRYTE przez F33 SENIOR (font 22px+, touch 64dp, brak gestów)
- **F30 Mesh P2P** — 'huge effort, POC only'
- **F10 Wearables** — wymaga native Kotlin/Swift, nie Flutter
- **F06 AI image moderation** — Vision API, scope-wise duzo

## Infrastruktura

- **Backend prod**: AWS EC2 t3.xlarge (i-0190e269475198b84, IP 16.192.31.100, eu-north-1), PM2 (besafe-backend:3001 + besafe-web:3000), Node.js Express + Socket.io
- **DB**: PostgreSQL 16 + PostGIS, db `alertmap` (NIE besafe!), user `alertmap`
- **Mobile**: Flutter 3.29, pakiet `pl.u235.alertmap`, pubspec name `alertmap`
- **FCM**: zsynchronizowane (gcloud --clear-restrictions w b29), tokeny zapisują się w DB
- **Domain**: besafe.org.pl (Cloudflare DNS)
- **SSH**: `~/.ssh/besafe_key.pem`

## Komendy referencyjne

```bash
# Build APK
cd /home/ooxo/alert/mobile
JAVA_HOME=/usr/lib/jvm/temurin-17-jdk \
  /home/ooxo/flutter/bin/flutter build apk --release --no-tree-shake-icons

# Deploy
scp -i ~/.ssh/besafe_key.pem build/app/outputs/flutter-apk/app-release.apk \
  ubuntu@16.192.31.100:/home/ubuntu/besafe/backend/AlertMap.apk
ssh -i ~/.ssh/besafe_key.pem ubuntu@16.192.31.100 \
  "sudo sed -i 's/version: [0-9]*/version: 58/' /home/ubuntu/besafe/backend/src/index.js && pm2 restart besafe-backend"

# DB
ssh -i ~/.ssh/besafe_key.pem ubuntu@16.192.31.100 "sudo -u postgres psql -d alertmap"

# E2E Patrol
export JAVA_HOME=/usr/lib/jvm/temurin-17-jdk
export PATH=/home/ooxo/flutter/bin:/home/ooxo/.pub-cache/bin:$PATH
export ANDROID_HOME=/home/ooxo/Android/Sdk
bash /home/ooxo/alert/mobile/scripts/run_e2e_suite.sh <SERIAL>
python3 /home/ooxo/alert/mobile/scripts/generate_report.py /tmp/be_safe_metrics/<latest>/

# Test endpointy (admin)
export SECRET=2441ee9f8c9682dfd47c9cc20744ddaa6a0dbadfc515db371f39bb866572316d
curl -X POST https://besafe.org.pl/api/v1/test/reset-persona \
  -H "X-Test-Secret: $SECRET" -H "Content-Type: application/json" \
  -d '{"username":"parent_tech"}'
```

## ⚠ Krytyczne reminders dla przyszłych sesji

1. **Double-source-of-truth wersji** — ZAWSZE bumpuj OBA:
   - `/home/ooxo/alert/mobile/lib/services/update_service.dart:7`
   - `/home/ubuntu/besafe/backend/src/index.js:86`
2. **Build flag**: `--no-tree-shake-icons` ZAWSZE (Canvas markery dynamicznie używają IconData)
3. **DB name**: `alertmap` NIE `besafe`
4. **Route order**: `/test` PRZED `/api/v1` community catch-all w `index.js`
5. **LoginScreen**: używa `TextField` (NIE TextFormField!), 2 pola idx 0 (email) + idx 1 (pass)
6. **Patrol**: package 3.15.2 + patrol_cli 3.6.0 (jedyna kompat z Flutter 3.29), NIE 4.x
7. **GRANT na nowych tabelach**: `GRANT ALL ON <table> TO alertmap;` po każdym CREATE TABLE

## Konta testowe (is_test=TRUE)

bcrypt 'Test123!' (cost=10): `$2a$10$0gLrBg8QBQjpH2MnsA/UM.EUY/LFPPWP8pKL6tvdjt6Js535KNp5q`

| Username | Email | Rola | Grupa |
|----------|-------|------|-------|
| parent_tech | parent.tech@test.besafe.org.pl | Parent | Rodzina Testowa E2E (E2ETEST) |
| parent_easy | parent.easy@test.besafe.org.pl | Parent (verified firefighter) | Rodzina Testowa E2E |
| kid_anna | kid.anna@test.besafe.org.pl | Child | Rodzina Testowa E2E |
| senior_jadwiga | senior.jadwiga@test.besafe.org.pl | Owner solo | Babcia Solo (BABCIA1) |

Lokalizacja: Września rynek (17.5667, 52.3247).

## Następne kroki (poza scope v58)

- Pełen E2E Patrol re-run v58 (poprzedni run zawiesił się po smoke healthCheck — wymaga debugowania login_helper z auto-login state)
- F02 Audio recording SOS (RODO compliance)
- F10 Wearable companion (Wear OS Kotlin native module)
- F06 AI image moderation (Cloud Vision API)
- F30 Mesh P2P POC (Bluetooth/Wi-Fi Direct, eksperymentalne)
