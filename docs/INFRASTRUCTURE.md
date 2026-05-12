# be:Safe — Infrastructure Map

> **Ostatnia aktualizacja:** 2026-05-12
> **Cel dokumentu:** pełna mapa "gdzie co jest" — konta, klucze, serwisy, domeny,
> żeby każda kolejna sesja AI lub developer wiedziała gdzie szukać.

---

## 🌐 Domena i DNS

**Główna domena:** `besafe.org.pl` — zarejestrowana, DNS hostowany w Cloudflare.

**Cloudflare account ID:** `67331522a994392df125e103b013b703`
**Zone ID:** `4914d507a5a27a66b0d151cd1367a36b` (besafe.org.pl)
**Token (wygasa 2026-05-18):** `cfut_YUTstC36PSm4mNRBCh7UpmC6V3WEoQvIIdT5qkQef359bb95`

**Aktywne rekordy DNS (11):**

| Typ | Nazwa | Wartość | Cel |
|---|---|---|---|
| A | `@` | `16.192.31.100` | główna apka + backend |
| A | `www` | `16.192.31.100` | alias |
| A | `mail` | `16.192.31.100` | SMTP/IMAP server |
| A | `webmail` | `16.192.31.100` | Roundcube |
| MX | `@` | `mail.besafe.org.pl` prio 10 | odbiór maili |
| TXT | `@` SPF | `v=spf1 mx include:amazonses.com ~all` | antyspam |
| TXT | `mail._domainkey` | DKIM własny (Postfix/OpenDKIM) | podpis wychodzących |
| CNAME | 3× `*._domainkey` | `*.dkim.amazonses.com` | SES Easy DKIM |
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=postmaster@besafe.org.pl` | |

**Stara domena** `alert.u235.pl` — nadal aktywna na starym VPS (`57.128.237.254`) jako fallback; do wyłączenia po potwierdzeniu że wszyscy userzy zmigrowali do v23.

---

## ☁️ AWS

**Konto:** `852329031566`
**Nazwa:** besafe (personal)
**Billing account:** aktywny
**Primary user (IAM):** `besafe-admin` (AdministratorAccess)
**SES user:** `besafe-ses-smtp` (tylko SES SendEmail)

### Credentials (pliki lokalne)

- Profile CLI: `~/.aws/credentials` sekcja `[besafe]`
  - `aws_access_key_id = AKIA4M4WE46HIRSSZJP5`
  - `aws_secret_access_key = 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`
- Region: `eu-north-1` (Stockholm) — default dla EC2/Bedrock/Claude Platform
- SES region: `eu-central-1` (Frankfurt)
- SSH do EC2: `/home/ooxo/Pobrane/besafe_key.pem` (chmod 400)

### EC2

- **Instance:** `i-0190e269475198b84`, `t3.xlarge`, Ubuntu 24.04 LTS, 4 CPU, 15 GB RAM, 484 GB disk, AZ `eu-north-1c`
- **Elastic IP:** `16.192.31.100` (alloc `eipalloc-0827f8f180494d260`) — statyczny
- **Security Group:** `sg-055ce8ad8d32f45d8` — porty 22, 25, 80, 143, 443, 465, 587, 993
- SSH: `ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100`
- **⚠️ Port 25 outbound zablokowany przez AWS** (mail sending przez SES), PTR nie ustawiony (AWS odmówił)

### AWS Bedrock — zablokowany w praktyce

- Daily token quota = 0.0 dla Anthropic Claude we wszystkich modelach (policy AWS dla nowych kont)
- Zastąpione przez **Claude Platform on AWS** (zob. niżej)

### Claude Platform on AWS (opencode)

- **API key:** `AEAAQWVhQXBpS2V5LWduenE3c2tjLWF0LTg1MjMyOTAzMTU2NjpXSmlMTnZRS0xhSFlKQnNqSWZ2ZEFaU2hmL0w5R0JpNUV4MHAxa0tPV3dJWnZjWnBVQ3RjdGFHdjJ2MD0=` (wygasa 2027-05-11)
- **Endpoint:** `https://aws-external-anthropic.us-east-1.api.aws/v1`
- **Workspace ID:** `wrkspc_01F6CibEnUj9uWWirJFz6r8k`
- Config w `~/.config/opencode/opencode.json` provider `anthropic`

### AWS SES (mail outgoing relay)

- **Region:** `eu-central-1`
- **Status:** sandbox (200 emails/day, verified recipients only)
- **Verified identities:** `besafe.org.pl` (domain, DKIM SUCCESS), `besafeorgpl@gmail.com`
- **SMTP endpoint:** `email-smtp.eu-central-1.amazonaws.com:587` (STARTTLS)
- **SMTP credentials:**
  - Username: `AKIA4M4WE46HPTNY2NAO`
  - Password (SigV4-converted from IAM): `BOXUnRvhVneIu0CJtjWXlEMjvMaaWWZq473bO8C5i0P1`
- **TODO:** request production access → https://console.aws.amazon.com/ses/home?region=eu-central-1#/account

---

## 🌐 Google Cloud

**Aktywny projekt:** `project-1674d55f-90e0-4e1a-884` (nazwa: besafe-app)
**Project number:** `1098119585965`
**Primary account:** `besafeorgpl@gmail.com`
**Organization:** id `974278724226`
**Billing:** `014F49-D0D964-2DE4F8` (aktywny)

### Konta gcloud lokalnie
- `besafeorgpl@gmail.com` ✅ **aktywne**
- `meneswczesny@gmail.com` (nieaktywne, credentials nadal zalogowane)
- `ptrmenes@gmail.com` (nieaktywne, stary stack)

### APIs włączone w besafe-app
- Maps: maps-backend, maps-embed, maps-android, maps-ios
- Places: places-backend, places.googleapis.com (v1 + legacy)
- geocoding-backend
- identitytoolkit (OAuth)
- fcm.googleapis.com, firebase.googleapis.com, firebaseinstallations
- iam, cloudresourcemanager, orgpolicy

### Klucze API (w besafe-app)

| Cel | Klucz | Restriction |
|---|---|---|
| **Maps Web** | `AIzaSyCuEqShVm8H-_7rxLy6uLTq4xUbCxFg7UI` | referer: besafe.org.pl/\*, www.besafe.org.pl/\*, localhost:3000/\*, localhost:3005/\* |
| **Maps Android** | `AIzaSyDgoUs03qbRnLT-uEALplRkmRqiBKLj8Cg` | pakiet: pl.u235.alertmap, SHA-1: 85:C3:BB:B3:93:2B:A2:0E:1F:EA:8D:D6:BA:2F:17:DC:48:65:6D:21 |

### OAuth 2.0 Client IDs

| Typ | Client ID |
|---|---|
| **Web** | `1098119585965-1dmn79cgjbhsr84f1iu3dibvpilc906p.apps.googleusercontent.com` |
| **Web Secret** | `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` (tylko server-side, nie potrzebne dla GSI) |
| **Android** | `1098119585965-bp2oo16n9u6tughijdrv3j7ojd94vnth.apps.googleusercontent.com` |

**OAuth Consent Screen:** External, opublikowany, nazwa "be:Safe".

### Firebase (besafe-app)

- **Project:** `project-1674d55f-90e0-4e1a-884` (ten sam co GCP — unified)
- **Package registered:** `pl.u235.alertmap` + SHA-1 85:C3:BB:...
- **`google-services.json`** (mobile/android/app/): lokalnie w `~/Pobrane/google-services (2).json`, w repo w `.gitignore`
- **Firebase Admin SDK JSON** (backend):
  - Plik: `~/Pobrane/project-1674d55f-90e0-4e1a-884-firebase-adminsdk-fbsvc-f0e81abdc6.json`
  - Na EC2: `/home/ubuntu/besafe/backend/firebase-admin.json`
  - Service account email: `firebase-adminsdk-fbsvc@project-1674d55f-90e0-4e1a-884.iam.gserviceaccount.com`

### Stary projekt (kasbrykiet-1534756858402) — fallback

- Pod kontem `ptrmenes@gmail.com`
- Klucze Maps, OAuth, Firebase `be-safe-356cb` — nadal aktywne
- **Plan:** wyłączyć po 7 dniach (od 2026-05-12), gdy wszyscy userzy zmigrują do APK v23
- Firebase `be-safe-356cb` można zostawić na długo (zero cost)

### Stitch API (Claude Platform on AWS alternative — dla design tool)

- Projekt Stitch pod kontem besafeorgpl: `projects/5133474667399141717` (be:Safe Community Safety App)
- Design asset MASTER_STYLE.md wgrany jako screen instance `6939230070896220200`
- API key: `AQ.Ab8RN6JjhwZmrAwnOo99VQb1dMxOrEh4EI_PiC8BTvU0Q-SWEg`
- Konfiguracja MCP w Kiro: `~/.kiro/settings/mcp.json` sekcja `stitch`

---

## 🗄️ VPS (stary) — alert.u235.pl — nadal żywy do 2026-05-19

- **Host:** `57.128.237.254` (OVH)
- **SSH alias:** `vps` (w `~/.ssh/config`)
- Backend: `/home/ubuntu/alertmap/src/` (Node.js, port 3001, PM2)
- Webapp: `/home/ubuntu/alert-web/` (Next.js, port 3005, PM2)
- DB: PostgreSQL 17.7 (local), user `alertmap` hasło `AlertMap2026!`
- **Po migracji:** NIE używany w produkcji, ale trzymany jako rollback aż APK v23 rozpowszechni się

---

## 🖥️ Infrastruktura na EC2 (besafe.org.pl)

### Usługi PM2

| Nazwa | Proces | Port | Auto-start |
|---|---|---|---|
| `besafe-backend` | `node /home/ubuntu/besafe/backend/src/index.js` | 3001 | systemd |
| `besafe-web` | `npm start` w `/home/ubuntu/besafe/web/` | 3000 | systemd |

### Nginx vhosts (`/etc/nginx/sites-enabled/`)

- **besafe.conf** — besafe.org.pl + www: SSL, proxy do backendu (/api, /socket.io, /health, /version) + webapp (`/`), APK download (/download), /uploads
- **webmail.conf** — webmail.besafe.org.pl + mail.besafe.org.pl: SSL, PHP-FPM → Roundcube w `/usr/share/roundcube`

### Let's Encrypt certy

- `besafe.org.pl` + `www.besafe.org.pl` (wygasa 2026-08-08, auto-renew)
- `mail.besafe.org.pl` + `webmail.besafe.org.pl` (wygasa 2026-08-09, auto-renew)
- Deploy hook: `/etc/letsencrypt/renewal-hooks/deploy/mail-reload.sh` — reloaduje postfix+dovecot po odnowieniu mail cert

### Baza danych (PostgreSQL 16.13 + PostGIS)

- DB: `alertmap`, user `alertmap`, hasło `AlertMap2026!`
- Tabele: users, alerts, alert_votes, alert_reports, alert_comments, alert_notifications, family_groups, family_members, geofences, location_history, badges, user_badges, user_checkins, posts, analytics_events, email_verification_tokens, password_reset_tokens
- Access: `PGPASSWORD='AlertMap2026!' psql -h localhost -U alertmap -d alertmap`

### Mail Server (Postfix + Dovecot + OpenDKIM + Roundcube)

- **SMTP incoming (port 25):** działa, Postfix odbiera
- **SMTP outgoing:** via AWS SES relay (port 587 do `email-smtp.eu-central-1.amazonaws.com`)
- **IMAP:** Dovecot port 993 SSL
- **Submission:** port 587 STARTTLS + SASL (Dovecot auth)
- **SMTPS:** port 465
- **Webmail:** https://webmail.besafe.org.pl (Roundcube + MariaDB)

### Mailboxy

5 skrzynek w `/var/mail/vhosts/besafe.org.pl/`:

| Email | Hasło |
|---|---|
| info@besafe.org.pl | `54WtNgnroGcNe4` |
| wsparcie@besafe.org.pl | `ULs7tFh90fB6WQ` |
| dev@besafe.org.pl | `ul60UJs7zNt3fz` |
| payment@besafe.org.pl | `AYtxdc4EBhS3bo` |
| kontakt@besafe.org.pl | `aqBtz39LyBi3RS` |

Hashe w `/etc/dovecot/virtual_passwords` (BLF-CRYPT).
Virtual aliases (`/etc/postfix/virtual_aliases`): postmaster/abuse/root → info.

### MariaDB (tylko dla Roundcube)

- DB: `roundcube`, user `roundcube`, hasło: `1vdXbY1DZIrK`
- Nie używana do niczego innego

---

## 📁 Kod

- **Repo:** https://github.com/m3n3sx/be-safe.git
- **Branch:** `main`
- **Lokalnie:** `/home/ooxo/alert/`
- **Struktura:**
  - `backend/` — Node.js/Express, deploy na EC2 w `/home/ubuntu/besafe/backend/`
  - `web/` — Next.js 16, deploy w `/home/ubuntu/besafe/web/`
  - `mobile/` — Flutter 3.29.3, build APK lokalnie lub CI
  - `docs/` — dokumentacja
  - `design/` — materiały designu (Stitch eksperymenty + master style + Aqoir-inspired v2)

### Secrety w kodzie

- `backend/.env` — NIE w repo, na EC2:
  ```
  PORT=3001
  DATABASE_URL=postgresql://alertmap:AlertMap2026!@localhost:5432/alertmap
  JWT_SECRET=f7dc9f8b2e4640addd7680b8cd0d6be02965e449c46718b7ef236c839c272419
  JWT_EXPIRES_IN=7d
  EMAIL_FROM=info@besafe.org.pl
  EMAIL_FROM_NAME=be:Safe
  APP_URL=https://besafe.org.pl
  SMTP_HOST=localhost
  SMTP_PORT=25
  ```
- `backend/firebase-admin.json` — service account, NIE w repo, na EC2
- `mobile/android/app/google-services.json` — NIE w repo, lokalnie + GH secret `GOOGLE_SERVICES_JSON`
- Klucze hardcoded w kodzie (bo referer/package restricted):
  - `web/src/lib/constants.ts` → Maps Web API key
  - `web/src/components/auth/LoginPage.tsx` → OAuth Web Client ID
  - `mobile/android/app/src/main/AndroidManifest.xml` → Maps Android key
  - `mobile/ios/Runner/AppDelegate.swift` → Maps iOS key

### GitHub Secrets (CI/CD)

| Secret | Co zawiera | Status |
|---|---|---|
| `GOOGLE_SERVICES_JSON` | Zawartość `google-services.json` | ⚠️ **do aktualizacji po migracji Firebase** |
| `SENTRY_DSN` | `https://cc8c13028776cf0c5546a0cd6c8eb76f@o4511353096372224...` | |
| `VPS_SSH_KEY` | Klucz SSH do starego VPS | używane przez stary workflow |
| `VPS_HOST` | `57.128.237.254` | stare |
| `ANDROID_KEYSTORE_BASE64` | (nie ustawione) | brak — APK podpisany debug key |
| `ANDROID_KEYSTORE_PASSWORD` | (nie ustawione) | |

---

## 📱 APK / Mobile

- **Aktualna wersja APK:** `v23` (appVersion w `mobile/lib/services/update_service.dart`)
- **Backend /version:** `23`
- **Download:** https://besafe.org.pl/download (62.3 MB)
- **Signing:** obecnie debug key (NIE Play Store ready — wymaga upload-keystore.jks)
- **Pakiet:** `pl.u235.alertmap`
- **SHA-1 debug:** `85:C3:BB:B3:93:2B:A2:0E:1F:EA:8D:D6:BA:2F:17:DC:48:65:6D:21`

### Build lokalny

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-temurin-jdk
export PATH="/home/ooxo/flutter/bin:$JAVA_HOME/bin:$PATH"
cd /home/ooxo/alert/mobile
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

### Deploy APK na EC2

```bash
scp -i /home/ooxo/Pobrane/besafe_key.pem \
  mobile/build/app/outputs/flutter-apk/app-release.apk \
  ubuntu@16.192.31.100:/home/ubuntu/besafe/backend/AlertMap.apk
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "chmod 644 /home/ubuntu/besafe/backend/AlertMap.apk && \
   sed -i 's/version: 22/version: 23/' /home/ubuntu/besafe/backend/src/index.js && \
   pm2 restart besafe-backend"
```

---

## 🎨 Design

- **v1 (pink-tinted Material 3 Expressive):** `design/stitch/` — 8 eksperymentów Stitcha + MASTER_STYLE.md sklejenie
- **v2 (Aqoir-inspired):** `design/stitch/v2_aqoir_inspired.md` — nowy kierunek wzorowany na nagrodzonej apce wellness (Bronze A' Design Award 2026). Prompty dla Stitcha do wygenerowania 17 screenów.
- **Figma export:** `design/besafe-figma-export.zip` (12 MB) — 36 screenów HTML+PNG do wrzutu do html.to.design plugin Figma

---

## ⚙️ Inne MCPs (~/.kiro/settings/mcp.json)

- **stitch** — Google Stitch API (wymaga STITCH_API_KEY)
- **fetch** — generic web fetch (uvx)
- **GoogleAds** — Google Ads API (pipx)
- **context7**, **sequential-thinking**, **memory**, **playwright**, **git**, **gcloud**, **gcloud-storage**, **gcloud-observability** — standardowe tooling

---

## 🔑 Wszystkie cenne sekrety w jednym miejscu (przechowuj offline!)

```
# AWS
AWS_ACCESS_KEY_ID=AKIA4M4WE46HIRSSZJP5                                (besafe-admin)
AWS_SECRET_ACCESS_KEY=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
AWS_SES_SMTP_USER=AKIA4M4WE46HPTNY2NAO
AWS_SES_SMTP_PASSWORD=BOXUnRvhVneIu0CJtjWXlEMjvMaaWWZq473bO8C5i0P1

# Claude Platform on AWS
CLAUDE_API_KEY=AEAAQWVhQXBpS2V5LWduenE3c2tjLWF0LTg1MjMyOTAzMTU2NjpXSmlMTnZRS0xhSFlKQnNqSWZ2ZEFaU2hmL0w5R0JpNUV4MHAxa0tPV3dJWnZjWnBVQ3RjdGFHdjJ2MD0=
CLAUDE_WORKSPACE_ID=wrkspc_01F6CibEnUj9uWWirJFz6r8k

# Stitch (Google Cloud Stitch API)
STITCH_API_KEY=AQ.Ab8RN6JjhwZmrAwnOo99VQb1dMxOrEh4EI_PiC8BTvU0Q-SWEg

# Cloudflare (wygasa 2026-05-18)
CLOUDFLARE_TOKEN=cfut_YUTstC36PSm4mNRBCh7UpmC6V3WEoQvIIdT5qkQef359bb95

# GitHub (w .git-credentials)
GH_TOKEN=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

# Google Maps (hardcoded w kodzie - nie sekretne bo restricted)
MAPS_WEB_KEY=AIzaSyCuEqShVm8H-_7rxLy6uLTq4xUbCxFg7UI
MAPS_ANDROID_KEY=AIzaSyDgoUs03qbRnLT-uEALplRkmRqiBKLj8Cg

# OAuth (hardcoded w kodzie)
OAUTH_WEB_CLIENT_ID=1098119585965-1dmn79cgjbhsr84f1iu3dibvpilc906p.apps.googleusercontent.com
OAUTH_WEB_SECRET=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
OAUTH_ANDROID_CLIENT_ID=1098119585965-bp2oo16n9u6tughijdrv3j7ojd94vnth.apps.googleusercontent.com

# Backend .env
JWT_SECRET=f7dc9f8b2e4640addd7680b8cd0d6be02965e449c46718b7ef236c839c272419
DB_PASSWORD=AlertMap2026!
ROUNDCUBE_DB_PASSWORD=1vdXbY1DZIrK

# Mail passwords (wszystkie @besafe.org.pl)
info:     54WtNgnroGcNe4
wsparcie: ULs7tFh90fB6WQ
dev:      ul60UJs7zNt3fz
payment:  AYtxdc4EBhS3bo
kontakt:  aqBtz39LyBi3RS
```
