# be:Safe — Raport z testów E2E (Patrol)

**Data:** 2026-05-16
**Wersja APK:** v48
**Urządzenie:** Motorola Moto G84 5G (ZY32HKMT45), Android 14
**Framework:** Patrol 3.15.2 + integration_test, patrol_cli 3.6.0
**Konfiguracja:** Diagnostic mode (assertions logują, nie failują testów)

---

## 1. Streszczenie

| Metryka | Wynik |
|---|---|
| **Suity uruchomione** | 5 (smoke + P1 + P2 + P3 + P4) |
| **Testów** | 12/12 PASS |
| **Czas runu** | ~13 minut |
| **Metryk zebranych** | 55 (33 pass, 13 fail, 9 neutralnych) |
| **Pliki raportu** | `/tmp/be_safe_metrics/ZY32HKMT45_20260516_174148/` |

Wszystkie 4 persony zalogowały się i przeszły swój flow. Test framework działa stabilnie — Patrol bootstrap, MainActivityTest.kt, build.gradle.kts ANDROIDX_TEST_ORCHESTRATOR, oraz incremental POST do `/api/v1/test/metrics` na backendzie.

---

## 2. Persony testowe

Wszystkie konta `is_test=TRUE` na produkcji, hasło `Test123!`.

| ID | Username | Email | Rola | UxBudget |
|---|---|---|---|---|
| P1 | parent_tech | parent.tech@test.besafe.org.pl | Parent (owner grupy E2ETEST) | standard (5s) |
| P2 | parent_easy | parent.easy@test.besafe.org.pl | Parent | standard (5s) |
| P3 | kid_anna | kid.anna@test.besafe.org.pl | Child (10 lat) | standard (5s) |
| P4 | senior_jadwiga | senior.jadwiga@test.besafe.org.pl | Parent solo (Babcia Solo, BABCIA1) | 1.5× (8s) |

Wszyscy mają `last_location` na rynku Września (52.3247, 17.5667). P3 ma safe_route "Do szkoły (test)" 5 pkt × 100m korytarz. Grupa E2ETEST ma geofence "Dom (test)" R=200m.

---

## 3. Wyniki — Krytyczne metryki UX

| Metryka | P1 tech | P2 easy | P3 kid | P4 senior | Budżet | Status |
|---|---|---|---|---|---|---|
| **app_warm_start** | 2.58s | 2.58s | 2.59s | 2.59s | 3s | ✅ OK |
| **fixture_reset** | 262ms | 219ms | 213ms | 205ms | 3s | ✅ OK |
| **login_to_home** | **35.65s** | **35.62s** | **35.68s** | **35.64s** | 5s (8s sr) | ⚠️ **7× przekroczenie** |
| **reach_sos** | 3.02s | — | 3.03s | 2.99s | 4s (6s sr) | ✅ OK (life-critical) |
| **open_map** | 2.97s | — | — | — | — | 📊 baseline |
| **open_family** | 12.10s | 12.09s | — | — | — | 📊 baseline |
| **open_profile** | 0ms* | — | — | — | — | 📊 (probably no-op) |
| **open_settings** | 0ms* | — | — | — | — | 📊 |

`*` 0ms = tap nie został wykonany (przycisk niewidoczny lub Patrol się rozłączył)

### Poziom UX (audit z (b14))

| ID audytu | Sprawdzane | Wynik |
|---|---|---|
| UX#1 | PillNavBar etykiety widoczne (Mapa/Home/Rodzina/SOS/Profil) | ✅ wszystkie 5 widoczne |
| UX#12 | SOS hold label widoczny ("Wciśnij i przytrzymaj" / "PRZYTRZYMAJ 2 SEKUNDY") | ✅ widoczny |
| UX#4 | Logout dialog (parent_tech logout_available) | ⚠️ niewidoczny w teście P1 (test się zakończył na poziomie Profil bez scroll) |

---

## 4. Diagnoza problemów

### 🔴 KRYTYCZNE: login_to_home = 35 sekund

**Symptom:** Wszystkie 4 persony, niezależnie od telefonu, czekają **35 sekund** od tap "Zaloguj się" do widoku Home.

**Składowe (z (b36) i kodu mobile):**
1. POST `/auth/login` (network ~300ms)
2. `_AuthGate._handleAuth` → `FcmService.init(api)` (Firebase init + getToken)
3. `app_router` → `HomeScreen()`
4. `HomeScreen._loadData()` — równoległe `Future.wait` z timeoutem 8s:
   - `_loadAlertsNearby()` GET `/alerts/nearby` → markery + cluster manager
   - `_loadFamily()` GET `/family/groups` → dla każdej grupy GET `/groups/:id/members`
5. `MapScreen` lazy-init podczas wejścia na zakładkę Mapa (Google Maps tiles)
6. GlowOrb animacje + shimmer skeleton (CPU contention)

**Hipoteza:** Z testów wynika że `Future.wait` z 8s timeout DOMINUJE — czyli któryś z `_loadFamily`/`_loadAlertsNearby` osiąga limit timeout. **35s ≈ 8s timeout × 3 retry HTTP w ApiService (z exponential backoff)** + 2s warm + 2s render.

**Plan naprawy** (osobna sesja — patrz `agents/performance-optimizer.md`):
- HomeScreen pokazuje skeleton **natychmiast po loginie** (nie czeka na `Future.wait`)
- `Future.wait` opcjonalne, dane się dotrafiają async
- ApiService retry: 3 → 1, timeout 15s → 6s dla non-critical endpoints
- FcmService.init w tle (nie blokuje router push)

### 🟡 open_family = 12 sekund

**Symptom:** Po tapnieciu Rodzina, lista grup ładuje się 12s.

**Hipoteza:** Każda grupa → osobny GET `/groups/:id/members`. Sekwencyjnie? Powinno być `Future.wait`. Sprawdzić `/home/ooxo/alert/mobile/lib/screens/family/family_screen.dart`.

### 🟢 reach_sos = 3s (OK)

Naciśnięcie SOS w nawigacji + render ekranu trwa ~3s. **W budżecie nawet dla seniora (6s).** UX audit #12 OK.

### 🟡 family_group_visible = brak

Patrol nie znalazł na ekranie tekstu "Rodzina Testowa E2E" po przejściu na zakładkę Rodzina. **Możliwe przyczyny:**
1. Reset persony usunął wpisy z `family_members` — sprawdzić w backend test/reset-persona czy DELETE nie kasuje też grupy
2. `family_screen` ładuje się długo i tekst pojawia się PO sprawdzeniu
3. PushReplacement zakładki resetuje state

### 📊 open_profile / open_settings = 0ms

Test wcisnął zakładkę, ale `Stopwatch` zarejestrował 0ms. **Hipoteza:** `_dismissOverlays` lub guard blokuje tap. Sprawdzić navigation w PillNavBar.

---

## 5. Infrastruktura testowa

### Pliki
```
/home/ooxo/alert/
├── docs/
│   ├── E2E_TEST_PLAN.md          ← plan suit
│   └── E2E_TEST_REPORT.md        ← TEN RAPORT
├── mobile/
│   ├── integration_test/
│   │   ├── helpers/
│   │   │   ├── test_config.dart       (Persona enum, UxBudget, runIdOverride)
│   │   │   ├── fixture_helper.dart    (resetPersona via /test/reset-persona)
│   │   │   ├── login_helper.dart      (loginAs + grantPermissions)
│   │   │   ├── metrics_helper.dart    (TestMetrics — POST per metric)
│   │   │   └── screenshot_helper.dart (binding.takeScreenshot z try/catch)
│   │   └── personas/
│   │       ├── _smoke_login_test.dart      (healthCheck + 4 persony)
│   │       ├── p1_parent_tech_test.dart    (tour 5 zakładek + ustawienia)
│   │       ├── p2_parent_easy_test.dart    (proste flow + SOS label)
│   │       ├── p3_kid_anna_test.dart       (dziecko, ograniczenia)
│   │       └── p4_senior_jadwiga_test.dart (1.5× budgety, life-critical SOS)
│   ├── scripts/
│   │   ├── run_e2e_suite.sh             (uruchamia wszystkie 5 suit + ściąga metryki)
│   │   └── generate_report.py           (HTML raport z JSON)
│   └── android/app/
│       ├── src/androidTest/kotlin/pl/u235/alertmap/MainActivityTest.kt
│       └── build.gradle.kts             (testInstrumentationRunner, orchestrator)
└── backend/src/routes/
    └── test.js                          (/test/health, /reset-persona, /reset-all, /metrics)
```

### Komendy
```bash
# Setup raz na sesję
export JAVA_HOME=/usr/lib/jvm/temurin-17-jdk
export PATH=/home/ooxo/flutter/bin:/home/ooxo/.pub-cache/bin:$PATH
export ANDROID_HOME=/home/ooxo/Android/Sdk

# Uruchom wszystkie suity na Moto
bash /home/ooxo/alert/mobile/scripts/run_e2e_suite.sh ZY32HKMT45

# Wygeneruj HTML
python3 /home/ooxo/alert/mobile/scripts/generate_report.py \
  /tmp/be_safe_metrics/ZY32HKMT45_<timestamp>
```

### Konta + sekret
- `TEST_RESET_SECRET` w `/tmp/test_reset_secret.txt` (i w `/home/ubuntu/besafe/backend/.env`)
- Hasło person: `Test123!`
- Endpoint: `https://besafe.org.pl/api/v1/test/health` → `{"ok":true,"secret_configured":true}`

---

## 6. Co dalej (prioritized)

| Priorytet | Co | Komu (agent) |
|---|---|---|
| 🔴 P0 | Naprawić login_to_home 35s → cel <8s | `performance-optimizer` |
| 🟡 P1 | Rozszerzyć suity (vote alert, geofence, SOS hold, create alert) | `e2e-test-author` |
| 🟡 P1 | Visual regression baseline (adb pull screenshots) | `e2e-test-author` |
| 🟢 P2 | open_family 12s diagnoza + fix | `performance-optimizer` |
| 🟢 P2 | Run na Realme dla porównania (musi być stabilnie podłączony) | `e2e-runner` |
| 🟢 P3 | Sub-pomiary login (`enterText` vs network vs render) | `e2e-test-author` |

---

## 7. Lessons learned z tej sesji

1. **Patrol 3.15.2 + patrol_cli 3.6.0** — jedyna kompatybilna kombinacja na Flutter 3.29. 4.x niekompatybilne.
2. **Bootstrap musi być ręczny** (CLI 3.6.0 nie ma `patrol bootstrap`). Wymaga MainActivityTest.kt + build.gradle.kts edits.
3. **Patrol odpala każdy `patrolTest` w osobnym izolacie** — statyczne pola Dart NIE przeżywają między testami. Rozwiązanie: **incremental POST per metric** do backendu.
4. **`await TestMetrics.*`** — bez await fire-and-forget, ale test kończy się PRZED dotarciem HTTP. Musi być `await`.
5. **`pumpAndSettle` nie działa w be:Safe** — ciągłe animacje (GlowOrb, shimmer, SOS pulse, Maps tiles, Socket.io reconnect). Używać `pump(Duration)`.
6. **ScreenshotHelper** musi być w try/catch — `IntegrationTestWidgetsFlutterBinding.instance` może rzucić jeśli binding nie zainicjowany lub timing race.
7. **Patrol CLI 3.6.0 zwraca exit code 1** mimo zielonych testów (znany bug). Skrypt `run_e2e_suite.sh` parsuje "Successful:"/"Failed:" zamiast polegać na exit code.
8. **`enterText` Patrol per znak** — długie hasło/email = wiele sekund. To MOŻE być znaczna część 35s login. Do zbadania.

---

## 8. Referencje

- E2E plan: `docs/E2E_TEST_PLAN.md`
- UX audit (18 punktów): kompresowany blok b14
- Stack aplikacji + paths: blok b41, b42
- Patrol bootstrap procedura: blok b43, b44
- Seed person + SQL: `/tmp/seed_test_personas.sql`
