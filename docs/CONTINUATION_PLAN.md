# be:Safe — Plan kontynuacji dla przyszłych sesji AI

> **Ostatnia aktualizacja:** 2026-05-08 (po Sesji 2: UX Polish)
> **Autor planu:** Kiro (poprzednia sesja)
> **Dla kogo:** kolejne sesje AI lub developerzy podejmujący projekt

---

## 🎯 CEL TEGO DOKUMENTU

Masz kontynuować implementację features w aplikacji **be:Safe** (community safety + family tracking).
Projekt już działa, ma APK na https://alert.u235.pl/download i webapp na https://alert.u235.pl

Czytaj też `FULL_DOCUMENTATION.md` — pełny opis architektury.

---

## 📊 STAN PROJEKTU (2026-05-08)

### Zrobione ✅

| Blok | Status | Szczegóły |
|---|---|---|
| Backend (Node/Express/PostgreSQL+PostGIS) | ✅ | 22 endpointy, WebSocket, cron |
| Mobile (Flutter) | ✅ | 18 ekranów, Google Maps, Dynamic Color |
| Webapp (Next.js) | ✅ | Landing + mapa dla zalogowanych |
| CI/CD (GitHub Actions) | ✅ | Auto build APK + deploy na push |
| Google Sign-In | ✅ | Z avatar z profilu Google |
| FCM push | ✅ | Firebase Admin SDK (HTTP v1) |
| Sentry crash reporting | ✅ | DSN w GH secrets |
| Analytics | ✅ | Własny endpoint /events (nie Firebase) |
| IMGW weather alerts | ✅ | Sync co 15 min |
| Legal (Regulamin + RODO) | ✅ | Dedykowane ekrany |
| Email verification | ✅ | Backend + tokens, Google auto-verify |
| Moderacja (flagging) | ✅ | Auto-hide po 3 reportach |
| Referral program | ✅ | Kody + UI + QR + share |
| Emergency numbers | ✅ | 10 numerów z tel: launcher |
| Onboarding | ✅ | 5 ekranów PageView |
| Age 13+ checkbox | ✅ | Przy rejestracji + Regulamin |
| GDPR data export | ✅ | GET /users/me/export (JSON) |
| Demo mode | ✅ | Bez rejestracji, gość |
| Empty states | ✅ | W my_alerts + family |
| Verified badges | ✅ | is_verified + verified_role kolumny |
| Reputation score w UI | ✅ | Kolorowy badge przy alertach |
| Check-in button | ✅ | "Jestem bezpieczny/a" w profile |
| Battery alerts | ✅ | Auto co 10min, alert rodzicom <=15% |
| Location history timeline | ✅ | Screen z polyline + date picker |
| 6 motywów kolorystycznych | ✅ | W ustawieniach |
| Community badges | ✅ | 10 odznak (user_badges table, /me/badges endpoint, BadgesScreen grid) |
| News / blog feed | ✅ | posts table + /posts endpoint + NewsScreen z ModalBottomSheet |
| Shimmer loading states | ✅ | `shimmer` pakiet + widget `ShimmerLoader/ListTile/Card/Grid`; zamiast `CircularProgressIndicator` w listach (news, badges, ranking, my_alerts, referral, stats) |
| Haptic feedback | ✅ | Wbudowany `flutter/services.HapticFeedback` — SOS (heavy+vibrate), check-in (medium), Zgłoś (medium), vote/report (light), tap markerów (selection) |
| Marker clustering na mapie | ✅ | `google_maps_cluster_manager_2` — klaster bitmap (czerwony okrąg z licznikiem) do zoom 16, powyżej indywidualne piny |
| Accessibility (Semantics) | ✅ | Wrappers na mapie, SOS, Zgłoś, filtry, my_location |
| Tablet layout | ✅ | `width >= 600` → NavigationRail zamiast BottomNavigationBar; `width >= 900` → dodatkowy 320px `_AlertSidePane` z listą alertów |

### Do zrobienia ❌ (priorytet: od góry)

**6. Integracje oficjalne (~1-2h)**
- [ ] GDDKiA — ostrzeżenia drogowe. API: brak publicznego; można scrape'ować https://www.gddkia.gov.pl/ lub RSS
- [ ] Krajowa Mapa Zagrożeń Policji — brak publicznego API (scrape tylko jeśli legal)

**7. Monetyzacja (~4h) — WYMAGA GOOGLE PLAY DEVELOPER ACCOUNT ($25 USD jednorazowo)**
- [ ] Pricing screen — ekran prezentujący Free / Premium / Business
- [ ] Google Play Billing (in_app_purchase package)
- [ ] Stripe dla Business tier
- [ ] Donations (Patronite / BuyMeACoffee link)
- [ ] Backend: tabela `subscriptions`, webhook Google Play, feature gates

**8. Community — do dokończenia (~1-2h)**
- [ ] Live chat na alertach (upgrade komentarzy do realtime przez socket.io)
- [ ] Grupy sąsiedzkie (zbyt złożone, może zostawić)

**9. Reliability (~3h)**
- [ ] Offline cache map tiles — pakiet `flutter_map_tile_caching` LUB wykorzystać Google Maps offline API (tylko Android)
- [ ] Offline cache alertów — masz już `CacheService.dart`, rozbudować: cachować per-region, TTL
- [ ] Background location tracking — pakiet `flutter_background_service` + Foreground Service notification (Android 10+)
- [ ] Auto-retry network requests — dodać `retry` policy w ApiService

---

## 🔑 DOSTĘPY I INFRASTRUKTURA

### Katalog projektu
- **Lokalny:** `/home/ooxo/alert`
- **GitHub:** https://github.com/m3n3sx/be-safe.git
- **Webapp on VPS:** `/home/ubuntu/alert-web/` (Next.js, port 3005)
- **Backend on VPS:** `/home/ubuntu/alertmap/` (Node.js, port 3001, PM2)

### SSH VPS
```bash
ssh vps  # alias w ~/.ssh/config wskazuje na 57.128.237.254
```

**Ważne:** backend na VPS nie jest w podkatalogu `backend/` tylko bezpośrednio w `/home/ubuntu/alertmap/src/`!

### Baza danych
```bash
ssh vps "PGPASSWORD='AlertMap2026!' psql -h localhost -U alertmap -d alertmap"
# dla DDL wymagających ownera:
ssh vps "sudo -u postgres psql -d alertmap"
```

### Google Cloud (projekt `kasbrykiet-1534756858402`)
- **Konto:** ptrmenes@gmail.com
- **Maps API key (Android):** `AIzaSyC5p8wjAa0s7dvuF_YzU3JHDQHpN4AdAMU`
- **OAuth Web Client ID:** `200274591700-jptqm86318od93eukrg0ajccpt87gfmu.apps.googleusercontent.com`
- **OAuth Android Client ID:** `200274591700-tftojb0t6v6hapjpt9dps3np2he05t8o.apps.googleusercontent.com`
- **Package name:** `pl.u235.alertmap`
- **Debug SHA-1:** `85:C3:BB:B3:93:2B:A2:0E:1F:EA:8D:D6:BA:2F:17:DC:48:65:6D:21`

### Firebase (projekt `be-safe-356cb`)
- **Konfiguracja mobile:** `mobile/android/app/google-services.json` (lokalnie, w .gitignore)
- **Service account backend:** `/home/ubuntu/alertmap/firebase-admin.json` (tylko VPS)
- **GitHub Secrets:**
  - `GOOGLE_SERVICES_JSON` — pełna treść google-services.json
  - `SENTRY_DSN` — https://cc8c13028776cf0c5546a0cd6c8eb76f@o4511353096372224.ingest.de.sentry.io/4511353103384656
  - `VPS_SSH_KEY` — klucz SSH do deployu
  - `VPS_HOST` — 57.128.237.254

### Sentry
- **DSN:** https://cc8c13028776cf0c5546a0cd6c8eb76f@o4511353096372224.ingest.de.sentry.io/4511353103384656
- **Konto:** ptrmenes@gmail.com (prawdopodobnie)

### HTTPS / Domeny
- **https://alert.u235.pl** → Let's Encrypt + nginx reverse proxy
  - `/` → Next.js (port 3005) — landing + webapp
  - `/api/v1/*` → backend Node (port 3001)
  - `/socket.io/*` → backend
  - `/download` → AlertMap.apk (serwowane przez nginx directly)
  - `/uploads/*` → backend (zdjęcia alertów)

---

## 🛠️ PODSTAWOWE KOMENDY

### Budowanie APK lokalnie
```bash
export JAVA_HOME=/usr/lib/jvm/java-17-temurin-jdk
export PATH="/home/ooxo/flutter/bin:$JAVA_HOME/bin:$PATH"
cd /home/ooxo/alert/mobile
flutter build apk --release --dart-define=SENTRY_DSN=https://cc8c13028776cf0c5546a0cd6c8eb76f@...
```

### Instalacja przez USB
```bash
export PATH="/home/ooxo/Android/Sdk/platform-tools:$PATH"
adb devices  # powinien pokazać SK4D5X7P45ZTGIIR
adb -s SK4D5X7P45ZTGIIR install -r mobile/build/app/outputs/flutter-apk/app-release.apk
```

### Flutter run (hot reload)
```bash
# Via WiFi (wymaga sparowania):
adb pair 192.168.1.X:PORT  # kod z telefonu
adb connect 192.168.1.X:PORT_CONNECT
flutter run -d 192.168.1.X:PORT_CONNECT

# Via USB:
flutter run -d SK4D5X7P45ZTGIIR
```

### Deploy backend na VPS
**Preferowana metoda — przez CI/CD:** po prostu `git push` i workflow automatycznie:
1. Deployuje backend files do `/home/ubuntu/alertmap/src/`
2. Buduje APK (Flutter)
3. Uploaduje APK na VPS
4. Bumpuje wersję w `/version` endpoint
5. Restartuje PM2

**Manual deploy backend:**
```bash
scp backend/src/routes/auth.js vps:/home/ubuntu/alertmap/src/routes/
ssh vps "pm2 restart alertmap"
```

**Manual deploy Next.js webapp:**
```bash
scp alert-web/src/app/page.tsx vps:/home/ubuntu/alert-web/src/app/page.tsx
ssh vps "cd /home/ubuntu/alert-web && npm run build && pm2 restart alert-web"
```

### Dodawanie demo data we Wrześni
```bash
ssh vps "PGPASSWORD='AlertMap2026!' psql -h localhost -U alertmap -d alertmap" << 'EOSQL'
DO $$
DECLARE uid UUID;
BEGIN
  SELECT id INTO uid FROM users WHERE email = 'meneswczesny@gmail.com' LIMIT 1;
  INSERT INTO alerts (author_id, category, title, description, location, radius_m, expires_at)
  VALUES (uid, 'aggression', 'Test', 'Test', ST_MakePoint(17.565, 52.325)::geography, 100, NOW() + interval '4 hours');
END $$;
EOSQL
```

### Sprawdzanie wersji i wymuszanie update w apce
```bash
ssh vps "curl -s http://localhost:3001/version"
# Żeby wymusić update w apce:
ssh vps "sed -i 's/version: [0-9]*/version: 25/g' /home/ubuntu/alertmap/src/index.js /home/ubuntu/alertmap/index.js; pm2 restart alertmap"
```

### Logi PM2
```bash
ssh vps "pm2 logs alertmap --lines 30 --nostream"
ssh vps "pm2 logs alertmap --lines 30 --nostream --err"  # tylko błędy
```

### GitHub API (dla sprawdzenia CI bez otwierania przeglądarki)
```bash
GH_TOKEN="..." # token w .git/config lub zapytaj o nowy
curl -s -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/repos/m3n3sx/be-safe/actions/runs?per_page=3" | python3 -c "
import sys,json
for r in json.load(sys.stdin)['workflow_runs']:
  print(f\"{r['status']}|{r.get('conclusion','')}|{r['run_number']}\")
"
```

---

## ⚠️ PUŁAPKI I GOTCHAS

1. **NIE używaj `flutter_map`** — projekt używa `google_maps_flutter`. Nie mieszaj.
2. **`latlong2.LatLng` ≠ `google_maps_flutter.LatLng`** — zawsze importuj z google_maps_flutter.
3. **Backend na VPS NIE jest w `backend/src/`** — jest w `/home/ubuntu/alertmap/src/`.
4. **PostGIS kolejność:** `ST_MakePoint(lng, lat)` — DŁUGOŚĆ pierwsza! Łatwo pomylić.
5. **`ApiService._decode`** obsługuje non-JSON responses — nigdy nie rzuca wyjątku. Zamiast tego zwraca `{'error': 'HTTP 4xx'}`. Zawsze sprawdzaj `res['error']` zanim użyjesz.
6. **Google Sign-In** wymaga `disconnect()` przed `signIn()` żeby pokazało okno wyboru konta (inaczej używa cached).
7. **`AuthGate` NIE przebudowuje się automatycznie po login** — login_screen musi robić `Navigator.pushReplacementNamed('/map')` po udanym logowaniu.
8. **Nazwa apki to `be:Safe`** (z dwukropkiem, `b` małe, `S` wielkie) — NIE `AlertMap`.
9. **Package name to `pl.u235.alertmap`** — stara nazwa, nie zmieniamy żeby nie psuć Google Play.
10. **`alert.md`** (244MB) i `google-services.json` są w `.gitignore` — NIE commituj.
11. **Wersja APK w `update_service.dart`** — nie zwiększaj ręcznie, CI to robi (bumpuje `version:` w `src/index.js` na VPS).
12. **PostgreSQL owner tabel to `postgres`** — do ALTER TABLE potrzeba `sudo -u postgres psql`, do SELECT/INSERT `PGPASSWORD='...' psql -h localhost -U alertmap`.
13. **Kotlin 2.1.0 jest wymagany** dla Firebase plugins — NIE zmieniaj na 1.8.x.
14. **`flutter_map` w `design/` folderze to obrazki referencyjne z konkurencji** — NIE używaj ich jako assets.

---

## 📋 KONWENCJE KODU

### Flutter
- Używaj `Theme.of(context).colorScheme.primary` zamiast hardcoded kolorów
- Wszystkie stringi UI przez `S.get('key')` z `i18n.dart` — PL + EN
- `Material 3` — `useMaterial3: true`, zaokrąglone narożniki (`BorderRadius.circular(16)`)
- `FilledButton` dla primary CTAs, `OutlinedButton` dla secondary, `TextButton` dla tertiary
- Nigdy nie używaj `print()` — `debugPrint()` (strip w release)

### Node.js
- CommonJS (`require`, nie `import`)
- Async/await, nie callbacks
- Middleware `auth` z `req.user` — nigdy nie trust client-provided `user_id`
- Parametryzowane queries (`$1, $2`) — nigdy string interpolation w SQL
- `_decode` response pattern dla błędów HTTP

### SQL
- Tabele `snake_case`, kolumny `snake_case`, indeksy z prefiksem `idx_`
- UUID jako primary keys (`uuid_generate_v4()`)
- Zawsze `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- Foreign keys z `ON DELETE CASCADE` gdzie sensowne
- `GRANT` dla usera `alertmap` po CREATE TABLE

---

## 🔄 WORKFLOW DEWELOPERSKI

**Typowa sesja pracy:**

1. **Start:** przeczytaj ten plik + `FULL_DOCUMENTATION.md`
2. **Planowanie:** wybierz blok z "Do zrobienia" (priorytet: od góry)
3. **Implementacja:**
   - Backend changes → zmień w `/home/ooxo/alert/backend/src/`
   - Mobile changes → zmień w `/home/ooxo/alert/mobile/lib/`
   - Bazę danych → `ssh vps "sudo -u postgres psql -d alertmap"`
4. **Test lokalnie:**
   - Backend: `ssh vps "pm2 logs alertmap --lines 20 --nostream"` po restarcie
   - Mobile: `flutter run -d SK4D5X7P45ZTGIIR` (USB) lub WiFi
5. **Deploy:** `git add -A && git commit -m "..." && git push` — CI zrobi resztę
6. **Weryfikacja:** `curl https://alert.u235.pl/api/v1/health` + zainstaluj APK z `/download`
7. **Dokumentacja:** zaktualizuj ten plik (sekcję "Zrobione") + `FULL_DOCUMENTATION.md`

**Jeśli coś pójdzie nie tak:**
- Build failed na CI → sprawdź logi przez `curl -H "Auth: token $GH" .../actions/jobs/$ID/logs`
- Apka nie startuje → `adb logcat | grep flutter`
- Backend crashuje → `ssh vps "pm2 logs alertmap --err --lines 30 --nostream"`
- Zmiany nie widoczne → zwiększ wersję w `/version` + rebuild APK

---

## 🎯 PRIORITY DLA NASTĘPNYCH SESJI

### ✅ Sesja 1 (done): Community
Zrobione — badges (10 sztuk, backend+UI), posts/news z bottomsheet detail, seed danych.

### ✅ Sesja 2 (done): UX Polish
Zrobione — shimmer loading states, HapticFeedback wbudowany, marker clustering (google_maps_cluster_manager_2), Semantics wrappers, responsive tablet layout (NavigationRail + side pane).

### Sesja 3 (następna): Reliability (~3h)
1. `flutter_background_service` — location tracking gdy apka killed
2. Foreground Service notification (Android wymóg)
3. Offline map cache (eksperymentuj z `flutter_map_tile_caching`)
4. `CacheService` rozbudowa z TTL per region
5. `retry` policy w `ApiService` — auto-retry dla 5xx i sieciowych błędów

### Sesja 4: GDDKiA (~1h)
- Scrapowanie RSS https://www.gddkia.gov.pl/ — sprawdzić czy jest
- Alternatywa: https://www.gddkia.gov.pl/utrudnienia (HTML parsing)
- Service `gddkia.js` obok `imgw.js`

### Sesja 5: Monetyzacja (~4h, PO zarejestrowaniu Google Play Dev)
1. Google Play Developer Account — user musi założyć ($25)
2. Utworzenie Play Console app
3. In-app products (Premium, Business)
4. `in_app_purchase` Flutter package
5. Backend webhook dla Google Play
6. Pricing screen w apce

### Sesja 6: Community enhancements
- Live chat na alertach (socket.io realtime komentarzy)
- (opcjonalnie) Grupy sąsiedzkie

### Dalej: Ekspansja
- Integracja z Policją / Strażą Miejską (wymaga kontaktów)
- Newsletter + email marketing
- ASO (screenshoty, opis na Google Play)
- Plany premium dla szkół / firm

---

## 📞 JAK SKOMUNIKOWAĆ SIĘ Z USEREM

User to właściciel projektu (Piotr, email: ptrmenes@gmail.com / meneswczesny@gmail.com).

**Styl komunikacji:**
- Odpowiedzi w języku polskim
- Krótko i konkretnie, bez filler wordów
- Pokazuj kod tylko gdy potrzebne, używaj tools do modyfikacji plików
- Jeśli coś wymaga akcji usera (np. Google Play account) — napisz to wyraźnie

**Co user lubi:**
- "lecisz dalej" / "kontynuuj" — kontynuuj bez pytania
- Konkretne liczby (ile zrobione, ile zostało)
- Commity z jasnymi opisami

**Co user nie lubi:**
- Zbyt długie wyjaśnienia
- Pytania "czy mam kontynuować" po 1 zadaniu
- Błędy i rollbacki — staraj się robić za pierwszym razem dobrze

---

## 💾 CO WAŻNE ZACHOWAĆ W BAZIE WIEDZY

1. Ten plik (`CONTINUATION_PLAN.md`)
2. `FULL_DOCUMENTATION.md`
3. `docs/SPEC.md`, `docs/API.md`, `docs/DATABASE.md`
4. Commits w git — historia zmian

Wszystkie te pliki są w repo.

---

**Powodzenia! 🚀**
