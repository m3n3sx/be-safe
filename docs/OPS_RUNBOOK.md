# be:Safe — Operations Runbook

> ⚠️ **WIĘKSZOŚĆ TEGO PLIKU JEST NIEAKTUALNA (stan AWS EC2/PM2/SSH).** Produkcja działa na
> **GCP Cloud Run** (`europe-central2`) + **Cloud SQL** (`besafe-pg`) + GCS + Mailgun + Vertex.
> Aktualne komendy deploy: `AGENTS.md` § Komendy (`gcloud run deploy --source`).
> Poniżej dodana **aktualna** sekcja "Migracje DB na Cloud SQL" — reszta (EC2 SSH, PM2, Postfix)
> jest historyczna, do przepisania.

---

## 🗄️ Migracje DB na Cloud SQL (AKTUALNE — GCP)

Baza: Cloud SQL `besafe-pg` (POSTGRES_16), db/user `alertmap`, hasło w Secret Manager
(`besafe-db-password`). Instancja nie jest publiczna — łączymy się przez **cloud-sql-proxy**
(ADC, konto `besafeorgpl@gmail.com`).

```bash
# 1. Pobierz proxy (jednorazowo)
curl -sLo /tmp/cloud-sql-proxy \
  "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.14.1/cloud-sql-proxy.linux.amd64"
chmod +x /tmp/cloud-sql-proxy

# 2. Uruchom proxy w tle (lokalny port 5433 → Cloud SQL przez socket)
/tmp/cloud-sql-proxy project-1674d55f-90e0-4e1a-884:europe-central2:besafe-pg --port 5433 &

# 3. Połącz psql (hasło z Secret Manager, NIE echo)
export PGPASSWORD="$(gcloud secrets versions access latest --secret=besafe-db-password)"
export PGHOST=127.0.0.1 PGPORT=5433 PGUSER=alertmap PGDATABASE=alertmap
psql -v ON_ERROR_STOP=1 -f db/migrations/<plik>.sql

# 4. Po wszystkim zabij proxy
pkill -f cloud-sql-proxy
```

### ⚠️ DŁUG: migracje owner-only (GRANT/REVOKE postgres)

Tabela `users` ORAZ typ `alert_category` należą do roli **`postgres`**, nie `alertmap`
(niespójność z pierwotnego ładowania schematu). Dlatego DDL typu `ALTER TABLE users ...`
albo `ALTER TYPE alert_category ADD VALUE ...` **padnie** z `must be owner` na koncie `alertmap`,
mimo że jest ono w `cloudsqlsuperuser`.

Obejście (rola `alertmap` może nadać sobie członkostwo w `postgres`):

```bash
psql -c "GRANT postgres TO alertmap;"                 # nadaj
psql -c "SET ROLE postgres; ALTER TABLE users ADD COLUMN IF NOT EXISTS ...;"
psql -c "REVOKE postgres FROM alertmap;"              # cofnij (ZAWSZE po migracji)
# weryfikacja: psql -tAc "SELECT pg_has_role('alertmap','postgres','MEMBER');"  → musi być 'f'
```

- **`CREATE TABLE`** nowych tabel (np. `neighborhood_messages`) działa jako `alertmap` bez tego —
  nowe obiekty należą do `alertmap`.
- Tylko DDL na obiektach należących do `postgres` (`users`, `alerts`, enumy) wymaga GRANT/REVOKE.
- **TODO (czysta naprawa):** `ALTER TABLE users OWNER TO alertmap;` + `ALTER TYPE alert_category OWNER TO alertmap;`
  jednorazowo, żeby pozbyć się tego długu na stałe (wymaga roli postgres).

---

## 📑 Co gdzie jest (skrót)

| Co | Gdzie |
|---|---|
| Repo lokalne | `/home/ooxo/alert/` |
| Lokalny backend/webapp | NIE uruchamiamy lokalnie — wszystko na EC2 |
| EC2 SSH | `ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100` |
| EC2 backend | `/home/ubuntu/besafe/backend/` (PM2: `besafe-backend`, port 3001) |
| EC2 webapp | `/home/ubuntu/besafe/web/` (PM2: `besafe-web`, port 3000) |
| DB | PostgreSQL 16 na EC2, DB `alertmap` |
| Mail | Postfix/Dovecot na EC2, IMAP port 993 |
| Domena | `besafe.org.pl` przez Cloudflare |

---

## 🔧 Typowe operacje

### A. Deploy zmian backendu na EC2

```bash
# Z lokalnego repo, zmiany są w backend/
cd /home/ooxo/alert
git add backend/ && git commit -m "..." && git push origin main

# Na EC2 pull + restart
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "cd /home/ubuntu/besafe && git pull && pm2 restart besafe-backend && pm2 logs besafe-backend --nostream --lines 10"
```

**Jeśli zmiany w `package.json`:**
```bash
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "cd /home/ubuntu/besafe/backend && git pull && npm install && pm2 restart besafe-backend"
```

### B. Deploy zmian webapp na EC2

```bash
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "cd /home/ubuntu/besafe/web && git pull && npm install && npm run build && pm2 restart besafe-web"
```

### C. Build + deploy nowego APK (bump version)

```bash
# 1. Bump wersji w update_service.dart
sed -i 's/const int appVersion = 23;/const int appVersion = 24;/' \
  /home/ooxo/alert/mobile/lib/services/update_service.dart

# 2. Build APK
export JAVA_HOME=/usr/lib/jvm/java-17-temurin-jdk
export PATH="/home/ooxo/flutter/bin:$JAVA_HOME/bin:$PATH"
cd /home/ooxo/alert/mobile && flutter build apk --release

# 3. Upload na EC2
scp -i /home/ooxo/Pobrane/besafe_key.pem \
  build/app/outputs/flutter-apk/app-release.apk \
  ubuntu@16.192.31.100:/home/ubuntu/besafe/backend/AlertMap.apk

# 4. Bump wersji w backend i restart
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "chmod 644 /home/ubuntu/besafe/backend/AlertMap.apk && \
   sed -i 's/version: 23/version: 24/' /home/ubuntu/besafe/backend/src/index.js && \
   pm2 restart besafe-backend && curl -s http://localhost:3001/version"

# 5. Git commit
cd /home/ooxo/alert && git add -A && git commit -m "feat: bump appVersion 24" && git push
```

### D. Odczytać logi backendu

```bash
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "pm2 logs besafe-backend --nostream --lines 50"

# Filtruj errorów
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "pm2 logs besafe-backend --nostream --lines 200 | grep -iE 'error|warn'"
```

### E. Odczytać dane z DB

```bash
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "PGPASSWORD='<USUNIĘTO — wartość w menedżerze haseł>' psql -h localhost -U alertmap -d alertmap \
   -c 'SELECT id, email, created_at FROM users ORDER BY id DESC LIMIT 10'"
```

### F. Dodać rekord DNS w Cloudflare (przez API)

```bash
CF_TOKEN="<USUNIĘTO — wartość w menedżerze haseł>"
ZONE="4914d507a5a27a66b0d151cd1367a36b"

curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"type":"A","name":"sub","content":"16.192.31.100","ttl":300,"proxied":false}'
```

### G. Wysłać test email

```bash
# Z EC2 przez backend
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 <<'EOF'
cd /home/ubuntu/besafe/backend
node -e "
  const { sendEmail } = require('./src/services/email');
  sendEmail({
    to: 'besafeorgpl@gmail.com',
    subject: 'Test from be:Safe',
    html: '<h1>Test</h1><p>If this arrives, SES works.</p>'
  }).then(r => console.log('OK', r)).catch(e => console.error('ERROR', e));
"
EOF
```

### H. Uruchomić opencode z Claude Platform on AWS

```bash
# Konfiguracja już w ~/.config/opencode/opencode.json
opencode
# lub dla jednego requestu:
opencode run "napisz funkcję..."
```

### I. Sprawdzić stan wszystkich serwisów na EC2

```bash
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 <<'EOF'
echo "=== PM2 ==="; pm2 list
echo ""; echo "=== Nginx ==="; systemctl is-active nginx
echo ""; echo "=== Postfix ==="; systemctl is-active postfix
echo ""; echo "=== Dovecot ==="; systemctl is-active dovecot
echo ""; echo "=== OpenDKIM ==="; systemctl is-active opendkim
echo ""; echo "=== PostgreSQL ==="; systemctl is-active postgresql
echo ""; echo "=== MariaDB ==="; systemctl is-active mariadb
echo ""; echo "=== Cert expiry ==="; certbot certificates 2>&1 | grep -E 'Domain|Expiry'
EOF
```

### J. Reload nginx po zmianach konfiguracji

```bash
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "sudo nginx -t && sudo systemctl reload nginx"
```

### K. Restart cały stack na EC2

```bash
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 <<'EOF'
pm2 restart all
sudo systemctl restart nginx postfix dovecot
EOF
```

### L. Backup DB

```bash
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "PGPASSWORD='<USUNIĘTO — wartość w menedżerze haseł>' pg_dump -h localhost -U alertmap alertmap > /tmp/alertmap-$(date +%F).sql && \
   ls -la /tmp/alertmap-*.sql"

# Pobrać lokalnie
scp -i /home/ooxo/Pobrane/besafe_key.pem \
  ubuntu@16.192.31.100:/tmp/alertmap-2026-05-12.sql .
```

---

## 🚨 Troubleshooting

### Backend nie startuje

```bash
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "pm2 logs besafe-backend --nostream --lines 100 --err"
```

Typowe przyczyny:
- Brakuje `firebase-admin.json` → sprawdź `ls /home/ubuntu/besafe/backend/firebase-admin.json`
- Port 3001 zajęty → `ss -tlnp | grep 3001`
- DB nie działa → `systemctl status postgresql`
- `.env` nie ma wszystkich kluczy → porównaj z `INFRASTRUCTURE.md`

### Email nie wysyła

```bash
# Test SES SMTP bezpośrednio
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "echo 'Subject: Test\n\nHello' | sendmail -v besafeorgpl@gmail.com 2>&1 | tail -30"

# Logi postfixa
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "sudo tail -50 /var/log/mail.log"
```

Typowe przyczyny:
- SES sandbox → adresat nie zweryfikowany → dodaj w AWS Console
- SMTP credentials stale → przerobić SES SMTP user na nowo
- Port 25 localnie blocked → sprawdź `postconf | grep relayhost`

### Cert HTTPS wygasa za <30 dni

```bash
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "sudo certbot renew --dry-run"

# Force renew
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "sudo certbot renew --force-renewal && sudo systemctl reload nginx"
```

### Google Maps na webie pokazują "For development purposes only"

**Przyczyna:** billing disabled dla starego projektu kasbrykiet ALBO nowego besafe-app.

**Fix:**
- Sprawdź: https://console.cloud.google.com/billing?project=project-1674d55f-90e0-4e1a-884
- Nowy projekt ma billing `014F49-D0D964-2DE4F8` aktywny
- Jeśli stary klucz jeszcze używany — reopen billing w kasbrykiet (pod ptrmenes)

### OAuth Google Sign-In: "redirect_uri_mismatch" albo "origin_mismatch"

**Przyczyna:** dodany nowy domain do frontend, ale nie zaktualizowany Authorized JavaScript origins w OAuth Client.

**Fix:**
- https://console.cloud.google.com/auth/clients/1098119585965-1dmn79cgjbhsr84f1iu3dibvpilc906p?project=project-1674d55f-90e0-4e1a-884
- Dodaj nowy origin
- Save

### Push notifications nie działają mimo FCM migration

**Test:** sprawdź czy user ma token w DB.
```bash
ssh -i /home/ooxo/Pobrane/besafe_key.pem ubuntu@16.192.31.100 \
  "PGPASSWORD='<USUNIĘTO — wartość w menedżerze haseł>' psql -h localhost -U alertmap -d alertmap \
   -c \"SELECT id, email, fcm_token IS NOT NULL as has_token FROM users WHERE email='besafeorgpl@gmail.com'\""
```

Jeśli `has_token = false` → user musi zainstalować APK v23+ i zalogować się ponownie (stare tokeny Firebase są invalid po migracji).
