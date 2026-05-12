# be:Safe — Plan kontynuacji dla przyszłych sesji AI

> **Ostatnia aktualizacja:** 2026-05-12 (po migracji Google stack na besafeorgpl)
> **Produkcja:** https://besafe.org.pl
> **Repo:** https://github.com/m3n3sx/be-safe.git
> **Dokumenty siostrzane:**
> - [`INFRASTRUCTURE.md`](./INFRASTRUCTURE.md) — mapa kont, kluczy, serwisów
> - [`OPS_RUNBOOK.md`](./OPS_RUNBOOK.md) — step-by-step typowe operacje
> - `FULL_DOCUMENTATION.md` — architektura (starsze, do konsolidacji)

---

## 🎯 CEL TEGO DOKUMENTU

Masz kontynuować implementację features w aplikacji **be:Safe** — polskiej
aplikacji community safety + family tracking.

Projekt **działa w produkcji**:
- Webapp: https://besafe.org.pl
- APK v23: https://besafe.org.pl/download
- Backend API: https://besafe.org.pl/api/v1

**⚠️ Zanim zaczniesz:** przeczytaj `INFRASTRUCTURE.md` — tam są wszystkie konta, klucze,
namiary na serwisy. `OPS_RUNBOOK.md` ma gotowe komendy na typowe operacje.

---

## 📊 STAN PROJEKTU (2026-05-12)

### ✅ Zakończone sesje / bloki pracy

| # | Blok | Commit | APK | Szczegóły |
|---|---|---|---|---|
| 1 | MVP backend + mobile + web | — | v17-19 | 22 endpointy, 18 ekranów, Google Maps |
| 2 | UX Polish | `da20f6f` | v20 | shimmer, haptic, clustering, NavigationRail |
| 3 | Reliability + Privacy + Live chat + GDDKiA | `2529270` | v21 | retry, cache TTL, foreground service, socket rooms |
| 4 | iOS build CI | `3d5360d` | — | .github/workflows/build-ios.yml |
| 5 | Design Stitch v1 (pink Material 3) | `f5c5970` | — | MASTER_STYLE.md + Figma export |
| 6 | Migracja VPS → EC2 | `885591b` | v21 | alert.u235.pl → besafe.org.pl |
| 7 | Mail server + SES relay | `409ac46` | v21 | Postfix+Dovecot+Roundcube, 5 mailboxów |
| 8 | Email notifications w backendzie | `409ac46` | v21 | verification, reset-password, welcome HTML |
| 9 | Webapp auth pages | `dd13e88` | v21 | verify-email, forgot-password, reset-password |
| 10 | Claude Platform on AWS (opencode) | `dd13e88` | — | endpoint us-east-1.api.aws, workspace wrkspc |
| 11 | Design Stitch v2 (Aqoir-inspired) | `7968623` | — | design/stitch/v2_aqoir_inspired.md |
| 12 | **Migracja Google stack → besafeorgpl** | `afc9dda` | **v23** | besafe-app projekt, Maps/OAuth/Firebase |

### Najważniejsze feature'y w apce (działa produkcyjnie)

- Backend (Node/Express/PostgreSQL+PostGIS) — 22+ endpointy, WebSocket, cron dla IMGW
- Mobile (Flutter 3.29) — 18 ekranów, Google Maps clustering, NavigationRail tablet
- Webapp (Next.js 16) — landing + mapa + auth pages
- CI/CD (GitHub Actions) — auto build APK + deploy
- Google Sign-In + email/password + email verification (tokens)
- Password reset via email
- FCM push notifications (HTTP v1)
- Sentry crash reporting
- Analytics (własny endpoint /events)
- IMGW weather alerts (cron co 15 min)
- Regulamin + RODO + prywatność
- Moderacja (flagging, auto-hide po 3 reportach)
- Referral program
- 10 emergency numbers z launcherem
- Onboarding (5 screenów)
- Age 13+ checkbox
- GDPR data export
- Demo mode (gość bez rejestracji)
- Empty states + shimmer loading
- Verified badges + reputation score
- Check-in "Jestem bezpieczny/a"
- Battery alerts (<15%)
- Location history timeline z polyline
- 6 motywów kolorystycznych
- Community badges (10 odznak)
- News / blog feed
- Offline cache (CacheService v2, per-region TTL)
- ApiService retry z exponential backoff
- Foreground Service Android (Android 14+ compliant)
- Live chat na alertach (socket.io rooms)
- App Bundle signing CI workflow (w oczekiwaniu na keystore)

---

## 🔴 OBECNIE WYMAGAJĄCE UWAGI USERA (manualne akcje)

### Priorytet 1 — blokujące produkcję

1. **Google Maps na webie "For development purposes only"**
   - Nowy projekt `besafe-app` MA billing aktywny ✅
   - Test: otwórz https://besafe.org.pl i sprawdź mapę
   - Jeśli nadal watermark — odśwież z Ctrl+Shift+R (cache), potem zgłoś

2. **GitHub secret `GOOGLE_SERVICES_JSON`** — do aktualizacji
   - Aktualny (stary) secret używa Firebase `be-safe-356cb`
   - Nowy plik: `~/Pobrane/google-services (2).json`
   - Where: https://github.com/m3n3sx/be-safe/settings/secrets/actions
   - Bez tego CI/CD przy kolejnym build APK wciąż będzie używać starego Firebase

3. **Test push notifications end-to-end**
   - Zainstalować APK v23 na telefonie
   - Zalogować się
   - Sprawdzić czy FCM token trafia do backendu
   - Wysłać test alert → push powinien przyjść
   - Jeśli nie działa → zob. `OPS_RUNBOOK.md` § Troubleshooting

### Priorytet 2 — security housekeeping

4. **Root AWS access key `AKIA4M4WE46HIJD7KMXJ`**
   - Stale aktywny (bez MFA)
   - Logowanie jako root: Console → Security credentials → delete access key
   - Włączyć MFA na root user

5. **AWS SES production access** (unblockuje 50k emails/day + dowolni odbiorcy)
   - Console: https://console.aws.amazon.com/ses/home?region=eu-central-1#/account
   - Request production access → description transactional use case
   - Obecnie sandbox: 200 emails/day, verified recipients only

### Priorytet 3 — rozszerzenia

6. **Play Store signing**
   - Generate upload keystore: `keytool -genkey -v -keystore upload-keystore.jks ...`
   - Dodać do GH Secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`
   - CI automatycznie zbuduje AAB do Play Store

7. **Port 25 outbound unblock (AWS)** — NIE DO ZROBIENIA
   - AWS Trust&Safety odmówił (P01KRC92B887G1Z1NJPZYFAS8QH)
   - Workaround: mail wychodzi przez SES relay na porcie 587 (działa)

8. **PTR record dla mail.besafe.org.pl** — NIE DO ZROBIENIA
   - AWS odmówił (wymaga static IP z konkretnym reverse DNS)
   - Workaround: SES relay obsługuje autentykację przez DKIM/SPF

---

## 🗓️ ROADMAP — co dalej (kolejność proponowana)

### Blok A — dokończenie migracji (pilne)
- [ ] GitHub secret `GOOGLE_SERVICES_JSON` zaktualizowany
- [ ] Test FCM na v23 APK (użytkownik)
- [ ] Po 7 dniach stabilności: wyłączyć stary `alert.u235.pl` (VPS `57.128.237.254`)
- [ ] Po 7 dniach: revoke klucze w kasbrykiet project (pod ptrmenes)

### Blok B — Aqoir v2 design (większa zmiana UX)
Plik `design/stitch/v2_aqoir_inspired.md` zawiera:
- 1 master prompt (Prompt A) + 17 per-screen prompts (B1-B17)
- Paleta "Calm Alert": navy #1A2027, coral #FF7A7A, mint #7DD3AC, aqua #9EEBEC
- Thin typography (weight 100-300), glow orbs signature

**Kroki:**
1. User wkleja Prompt A do Stitcha, iteruje
2. Potem B1-B17 każdy osobno (one prompt = one change)
3. Pobranie PNG do `design/stitch_v2/`
4. Flutter refactor: `mobile/lib/theme/design_tokens.dart` — nowa paleta
5. Screen-per-PR: Home + Map najpierw, potem reszta
6. APK v24 deploy po pierwszych screenach

### Blok C — Monetyzacja (~4h po zarejestrowaniu Google Play Dev $25)
1. Play Console app setup
2. In-app products (Premium, Business)
3. `in_app_purchase` Flutter package
4. Backend webhook dla Google Play purchases
5. Pricing screen w apce + subscription management

### Blok D — Community enhancements
- Grupy sąsiedzkie (geofenced chat rooms)
- Neighborhood events feed
- Integracja z Policją / Strażą Miejską (wymaga kontaktów)

### Blok E — Reliability extras
- Offline map tiles (`flutter_map_tile_caching` pakiet)
- End-to-end test socket.io rooms na realnych urządzeniach (obecnie tylko unit testy)
- Stress testing backendu (k6 lub artillery)

### Blok F — Marketing + ASO
- Newsletter mailing list (SES lub Mailchimp)
- Screenshots Play Store (po v2 design gotowym)
- ASO opis długi w polskim
- Plany dla szkół / firm (B2B)

---

## 🧠 WAŻNE KONTEKSTY TECHNICZNE

### User environment

- User pracuje na Linux (Fedora), directory `/home/ooxo/alert/`
- Tool: **Kiro CLI** (`kiro-cli chat`) — AI agent (Ty)
- Dodatkowo **opencode** z Claude Platform on AWS skonfigurowany (alternatywa)
- Google Stitch MCP dostępny do designu

### Infrastruktura (skrót — pełne w INFRASTRUCTURE.md)

- **Wszystko prod działa na EC2** `i-0190e269475198b84` (16.192.31.100), Ubuntu 24.04
- **Domena:** besafe.org.pl, DNS w Cloudflare
- **Mail:** Postfix + Dovecot + Roundcube + SES relay
- **DB:** PostgreSQL 16 + PostGIS
- **Google Cloud:** projekt `besafe-app` pod `besafeorgpl@gmail.com` (NIE ptrmenes!)
- **AWS:** konto `852329031566`, region `eu-north-1`
- **Firebase:** `project-1674d55f-90e0-4e1a-884` (migrated z `be-safe-356cb`)

### Styl commit messages

```
type: short summary (max 70 chars)

Detailed description:
- bullet points
- what changed
- why

Technical notes if relevant.
```

Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `ci`, `perf`, `test`, `design`

---

## 📞 JAK SKOMUNIKOWAĆ SIĘ Z USEREM

**User = Piotr**, właściciel projektu.

Aktualny primary account: **besafeorgpl@gmail.com**

Stary account: ptrmenes@gmail.com, meneswczesny@gmail.com (nadal pod nimi część starych serwisów — stary VPS, kasbrykiet project)

### Styl komunikacji

- **Odpowiedzi w języku polskim**
- Krótkie, konkretne, bez filler wordów typu "Oczywiście!", "Rozumiem"
- Używaj narzędzi do modyfikacji plików, nie pokazuj code snippets "do wklejenia" (chyba że user prosi)
- Pokazuj konkretne liczby (ile zrobione, ile zostało)

### Co user lubi

- "dawaj" / "lecisz" / "kontynuuj" / "tak" — **kontynuuj bez pytania**
- Krótkie input typu "a", "c", "ok" → traktuj jako potwierdzenie
- Jednoznaczne odpowiedzi (A czy B) — nie wielokrotnie dopytuj
- Commity z jasnymi opisami

### Co user nie lubi

- Zbyt długie wyjaśnienia
- Pytania "czy mam kontynuować" po 1 zadaniu
- Proszenie o potwierdzenie oczywistych rzeczy
- "Mixing features in one commit" (szczególnie dla Stitcha: one prompt = one change)

### Security context

- User jest OK z dzieleniem sekretów w chacie (lokalne środowisko)
- Sekrety są w `INFRASTRUCTURE.md` (w repo git — prywatny)
- Nie wysyłaj sekretów na external endpointy

---

## 💾 KLUCZOWE PLIKI W REPO

```
/home/ooxo/alert/
├── backend/                      # Node.js API
│   ├── src/
│   │   ├── index.js             # main entry (PM2: besafe-backend)
│   │   ├── routes/
│   │   ├── services/
│   │   └── email.js             # nodemailer SES relay
│   ├── firebase-admin.json      # NIE w repo, na EC2
│   └── .env                     # NIE w repo
├── web/                          # Next.js webapp
│   └── src/
│       ├── app/                  # App Router (verify-email, forgot-password, ...)
│       ├── components/auth/LoginPage.tsx  # OAuth Client ID hardcoded
│       └── lib/constants.ts      # Maps Web API key hardcoded
├── mobile/                       # Flutter app
│   ├── lib/services/update_service.dart  # appVersion const
│   ├── android/app/google-services.json  # NIE w repo
│   ├── android/app/src/main/AndroidManifest.xml  # Maps Android key
│   └── ios/Runner/AppDelegate.swift       # Maps iOS key
├── design/                       # Stitch eksperymenty + MASTER_STYLE.md + v2 Aqoir
│   └── stitch/v2_aqoir_inspired.md
├── docs/
│   ├── CONTINUATION_PLAN.md     # ten plik
│   ├── INFRASTRUCTURE.md        # mapa kont/kluczy/serwisów
│   ├── OPS_RUNBOOK.md           # step-by-step operacje
│   └── FULL_DOCUMENTATION.md    # (starsze, do konsolidacji)
└── .github/workflows/
    ├── build-deploy.yml         # CI/CD APK build + deploy na EC2
    └── build-ios.yml            # iOS CI (macos-15, unsigned .ipa artifact)
```

---

## 🆘 QUICK START DLA NOWEJ SESJI

1. **Przeczytaj:** `INFRASTRUCTURE.md` (mapa), `OPS_RUNBOOK.md` (komendy), ten plik (roadmap)
2. **Sprawdź status serwisów:** zob. `OPS_RUNBOOK.md` § I
3. **Spytaj usera** co chce zrobić — jeżeli coś z roadmap, idź po prostu (A, B, C, D, E, F)
4. **Deploy cycle** (w `OPS_RUNBOOK.md`): backend → git push + ssh pull + pm2 restart

Jeśli coś nie działa:
- Logi: `OPS_RUNBOOK.md` § D
- Troubleshooting: `OPS_RUNBOOK.md` § Troubleshooting
- Typowe źródła problemów: `INFRASTRUCTURE.md` zawiera wszystkie sekrety + adresy

---

**Powodzenia! 🚀**
