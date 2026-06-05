# be:Safe — Wytyczne dla nowej sesji: przebudowa Web + PowerAdmin

> **Cel sesji:** (1) przebudować i rozbudować **wersję webową** (charakter wizualny jak apka, ale dopasowana do przeglądarki/desktopu, skalowalna), (2) zbudować **PowerAdmin** — panel administracyjny zarządzający totalnie wszystkim, z danymi zasobów serwera, RBAC (wielu adminów, różne uprawnienia) i nową szatą wizualną (inspiracja [nextadmin.co](https://nextadmin.co/)).
>
> **Wersja na starcie:** v119 LIVE (GCP Cloud Run). Czytaj najpierw `AGENTS.md` (root) + ten plik.
> **Autor wytycznych:** sesja dark-mode (2026-06-05), na podstawie audytu realnego kodu.

---

## 0. Zasady operacyjne (NIE zapomnij)

- Stack/hosting/komendy: zob. `AGENTS.md`. Deploy ręcznie przez `gcloud run deploy --source` (backend `besafe-backend`, web `besafe-web`, region `europe-central2`).
- **Double-source-of-truth wersji** — bump `mobile/lib/services/update_service.dart:7` + `backend/src/index.js` (`/version`) przy każdym deployu (nawet jeśli zmiana tylko web/backend — żeby nie rozjechać dialogu aktualizacji w apce).
- **Migracje DB na Cloud SQL** przez `cloud-sql-proxy` (zob. `docs/OPS_RUNBOOK.md` § "Migracje DB na Cloud SQL"). **UWAGA dług:** tabele `users`/`alerts` + typ `alert_category` należą do roli `postgres`, nie `alertmap` → DDL owner-only wymaga `GRANT postgres TO alertmap` → `SET ROLE postgres` → DDL → `REVOKE`. Nowe tabele (`CREATE TABLE`) działają jako `alertmap` bez tego.
- Route order w `backend/src/index.js`: nowe routery PRZED `app.use('/api/v1', require('./routes/community'))`.
- Reguła weryfikacji: `cd web && npm run build` (lub `npx tsc --noEmit`) musi przejść; backend `node --check`.

---

## 1. Stan obecny (audyt 2026-06-05)

### 1a. Web (`web/`)
- **Stack:** Next.js 16.2.4 (App Router), React 19, Tailwind 4, TypeScript. Cloud Run standalone (`web/Dockerfile`).
- **Layout:** `components/ui/AppLayout.tsx` (Sidebar + main z `pt-14 lg:pt-0 pb-16 lg:pb-0` — czyli **mobile-mirror**: dolna nawigacja na mobile, sidebar na desktop). `components/ui/Sidebar.tsx`.
- **Strony** (`web/src/app/`): page (mapa), alerts, alerts/mine, family + [groupId]/{chat,planner,members}, stats, ranking, profile, settings, landing, sos, pets, aed, aqi, emergency, cyber, guide, escort, fakecall, badges, referral, news, permissions, parental-controls, onboarding, mode, terms, privacy, verify-email, forgot-password, reset-password. **Admin:** admin/{page,users,alerts,reports,groups,audit}.
- **Design:** kolory Serenity inline (mint `#9DF4CB`, navy `#1A2027`, coral `#FF7A7A`, aqua `#9EEBEC`), `dark:` warianty już są. Mapy: `lib/constants.ts` `LIGHT_MAP_STYLES`/`DARK_MAP_STYLES` (zgodne z apką). `contexts/ThemeContext.tsx`.
- **API klient:** `lib/api.ts`, `lib/i18n.ts`, `contexts/{Auth,Socket,Theme}Context.tsx`.
- **Problemy:** layout to lustro mobile (wąska kolumna + dolny pasek), nie wykorzystuje szerokości przeglądarki; brak desktop-first wzorców (toolbary, tabele, multi-panel); design rozsypany inline zamiast w tokenach.

### 1b. Admin (backend `backend/src/routes/admin.js` + middleware `requireAdmin.js`)
- **Auth:** pojedynczy boolean `users.is_admin` (sprawdzany w DB real-time przez `requireAdmin`). **BRAK ról i granularnych uprawnień.**
- **Endpointy:** `/admin/` → `ping`, `stats` (users/alerts/groups/pets/reports liczniki), `backup-status` (czyta `/home/ubuntu/backups/last_backup.json` — **PRZESTARZAŁE**, to ścieżka ze starego VPS, na Cloud Run nie istnieje!), `audit-log`, `users` (list/get/patch: is_admin/is_banned/ban_reason/is_verified/verified_role/is_kpp/reputation_score), `alerts` (list/delete/patch), `reports` (list/resolve), `groups` (list/delete).
- **Audyt:** tabela `admin_audit_log` (admin_id, action, target_type, target_id, payload, created_at) — `audit()` helper.
- **Web admin UI:** `admin/page.tsx` dashboard (StatCard grid + backup banner + 6 AdminTile), podstrony users/alerts/reports/groups/audit. Styl: rounded-2xl cards, `dark:` warianty. Funkcjonalny ale podstawowy.
- **Problemy:** brak danych zasobów serwera (CPU/RAM/dysk/DB/GCS/koszty), brak RBAC, backup-status oparty o nieistniejący plik VPS, brak zarządzania "nad apką" (feature flags, wersje, konfiguracja, broadcast, kolejki, integracje GIOŚ/IMGW/Mailgun/Vertex), brak wykresów/analityki czasowej.

---

## 2. Cele i zakres

### 2a. Web — przebudowa
1. **Charakter wizualny jak apka** (Serenity Guard): te same kolory, font Inter, zaokrąglenia 24dp, halo/orb akcenty, ale **dopasowane do przeglądarki** — desktop-first responsive (max-width content, multi-column, sticky top bar, hover states, klawiatura/skróty).
2. **Tokeny designu** — wyciągnąć Serenity do CSS variables / Tailwind theme (`globals.css` + `tailwind.config`), przestać hardcodować hexy inline. Jedno źródło prawdy = parytet z `mobile/lib/theme/design_tokens.dart`.
3. **Skalowalność** — komponenty współdzielone (Card, Table, Button, Badge, Modal, EmptyState, Toast), spójny `AppShell` desktop (sidebar zwijalny + topbar + breadcrumbs) i mobile.
4. Zachować istniejące funkcje (mapa, alerty, rodzina, czat, profil, ustawienia) — to refactor wizualny + responsywność, nie przepisywanie logiki API.

### 2b. PowerAdmin — rozbudowa
Panel zarządzający **wszystkim**, dla wielu adminów z **różnymi uprawnieniami**:

1. **RBAC** (kluczowe — patrz §3): role + uprawnienia granularne, przypisania per-admin, egzekwowane w backendzie (middleware) i UI (ukrywanie/wyłączanie akcji).
2. **Dane zasobów serwera** (patrz §4): Cloud Run (CPU/RAM/instancje/RPS/latencja/błędy), Cloud SQL (połączenia/rozmiar/CPU), GCS (rozmiar bucketów), koszty/billing (link), stan API zewnętrznych (GIOŚ/IMGW/Mailgun/Vertex/FCM).
3. **Zarządzanie "nad apką"**:
   - **Feature flags** (włącz/wyłącz funkcje globalnie lub per-segment).
   - **Wersje** (podgląd/edycja `/version`, wymuszenie update, link do APK w GCS).
   - **Broadcast** (wyślij powiadomienie/alert systemowy do segmentu userów — używa istniejącego FCM `notifyUser`).
   - **Konfiguracja runtime** (progi moderacji, radiusy, cron interwały) — tabela `app_config`.
   - **Kolejki/crony** (status IMGW/IMGW-hydro/AQI/GDDKiA sync, ostatni run, ręczny trigger).
   - **Integracje** (status + test: Mailgun, Vertex moderation, Vision, FCM, GIOŚ).
4. **Analityka czasowa** — wykresy wzrostu userów/alertów/DAU, mapa cieplna zgłoszeń, retencja. (Dane z DB + ewentualnie `events` table.)
5. **Moderacja rozbudowana** — kolejka AI-flagged (text+image), bulk actions, historia decyzji, szczegóły usera (alerty, grupy, urządzenia, logi).
6. **Wizualna przebudowa** — patrz §5 (nextadmin.co).

---

## 3. RBAC — projekt (zacznij od tego, to fundament skalowania)

### Schemat DB (migracja `db/migrations/<data>_rbac.sql`, idempotentna)
```sql
-- Role adminów (seedowane: superadmin, moderator, support, analyst, ...)
CREATE TABLE IF NOT EXISTS admin_roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key VARCHAR(32) UNIQUE NOT NULL,        -- 'superadmin','moderator','support','analyst'
  name VARCHAR(64) NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Uprawnienia granularne (klucze: 'users.ban','users.role','alerts.delete',
--   'reports.resolve','config.write','broadcast.send','system.read','rbac.manage', ...)
CREATE TABLE IF NOT EXISTS admin_permissions (
  role_id UUID NOT NULL REFERENCES admin_roles(id) ON DELETE CASCADE,
  permission VARCHAR(48) NOT NULL,
  PRIMARY KEY (role_id, permission)
);

-- Przypisanie roli do użytkownika (admin może mieć >1 rolę)
CREATE TABLE IF NOT EXISTS admin_role_assignments (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES admin_roles(id) ON DELETE CASCADE,
  granted_by UUID REFERENCES users(id),
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, role_id)
);
```
- **Kompatybilność wstecz:** zachowaj `users.is_admin`. Migracja: każdy `is_admin=TRUE` dostaje rolę `superadmin` (wszystkie uprawnienia). `superadmin` = wildcard `*`.
- **Backend:** nowy middleware `requirePermission('users.ban')` — ładuje uprawnienia usera (suma ról) i sprawdza. Cache per-request. Zachowaj `requireAdmin` jako "ma jakąkolwiek rolę admina".
- **Wektor uprawnień w `/users/me`** lub `/admin/me` → UI wie co pokazać.
- **Audyt:** każda akcja z permission → `admin_audit_log` (już jest helper).
- **Lista permission keys (start):** `system.read`, `users.read/ban/role/edit`, `alerts.read/edit/delete`, `reports.read/resolve`, `groups.read/delete`, `config.read/write`, `broadcast.send`, `flags.write`, `rbac.manage`, `audit.read`, `integrations.test`.

---

## 4. Dane zasobów serwera — skąd brać (realne źródła na GCP)

- **Cloud Run metryki** (CPU, pamięć, liczba instancji, request count, latencje p50/p95/p99, 5xx): **Cloud Monitoring API** (`monitoring.googleapis.com`, metryki `run.googleapis.com/container/*`). Backend (compute SA ma `roles/monitoring.viewer`? — sprawdzić/nadać) odpytuje Monitoring API i zwraca w `/admin/system`. Alternatywnie `gcloud monitoring` z poziomu ops, ale w panelu lepiej API.
- **Cloud SQL** (połączenia, rozmiar bazy, CPU): metryki `cloudsql.googleapis.com/database/*` + `SELECT pg_database_size('alertmap')`, `SELECT count(*) FROM pg_stat_activity`.
- **GCS** (rozmiar bucketu `besafe-uploads`, liczba obiektów): `@google-cloud/storage` `bucket.getMetadata()` lub Monitoring `storage.googleapis.com/storage/total_bytes`.
- **Proces backendu** (lekkie, bez API): `process.memoryUsage()`, `process.uptime()`, `os.loadavg()`, `os.freemem()` — szybki self-report w `/admin/system/self`.
- **Billing/koszty:** brak prostego API w czasie rzeczywistym → link do GCP Billing console + ewentualnie BigQuery billing export (osobny temat). Na start: link.
- **Integracje:** endpoint `/admin/integrations/health` testujący: GIOŚ (`api.gios.gov.pl`), IMGW (`danepubliczne.imgw.pl`), Mailgun (status API), Vertex (ping), FCM (firebase-admin init), Vision (init). Każda zwraca ok/latency/last_error.
- **Backup-status:** OBECNY czyta plik z VPS — **do przepisania**. Na GCP: backup Cloud SQL to automatyczne backupy GCP (sprawdzalne `gcloud sql backups list` / API) — pokazać ostatni automatyczny backup zamiast pliku.

> **Wymaga IAM:** compute SA (`1098119585965-compute@developer.gserviceaccount.com`) prawdopodobnie potrzebuje `roles/monitoring.viewer` (+ `cloudsql.viewer`). Nadać przez `gcloud projects add-iam-policy-binding`. Udokumentować.

---

## 5. Wizualna przebudowa admina — nextadmin.co

- **nextadmin.co** = komercyjny szablon admina Next.js + Tailwind (jest darmowy wariant "Free" i płatny "Pro"). **SPRAWDŹ LICENCJĘ** przed użyciem kodu 1:1 (płatny wymaga zakupu seatu; free MIT-podobny ale zweryfikuj).
- **Rekomendacja:** NIE wciągać całego szablonu (ryzyko licencyjne + ciężar). Użyć go jako **wzorca layoutu/komponentów**: zwijalny sidebar z grupami, sticky topbar (search + profil + powiadomienia + dark toggle), karty KPI z mini-wykresami, gęste tabele z sortowaniem/filtrem/paginacją, modale, drawer szczegółów, breadcrumbs. Odtworzyć w naszym Tailwind + tokenach Serenity (spójność z resztą).
- **Wykresy:** lekka biblioteka (np. `recharts` lub `visx`) — dodać do `web/package.json`.
- **Spójność:** admin używa tych samych tokenów co web/apka (mint/navy/coral/charcoal), ale gęstszy layout (desktop-first, data-dense).

---

## 6. Proponowana kolejność (fazy)

**Faza 0 — fundament (1 sesja):**
1. RBAC: migracja + seed ról (superadmin/moderator/support/analyst) + `requirePermission` middleware + `/admin/me` (zwraca role+permissions) + migracja is_admin→superadmin. Test: superadmin widzi wszystko, moderator tylko reports/alerts.
2. Wyciągnięcie tokenów Serenity do `web/src/app/globals.css` (CSS vars) + Tailwind theme. Komponenty bazowe (Card/Table/Button/Badge/Modal/EmptyState).

**Faza 1 — PowerAdmin backend:**
3. `/admin/system` (Cloud Run + Cloud SQL + GCS + proces) + IAM monitoring.viewer.
4. `/admin/integrations/health`. Naprawa `backup-status` (Cloud SQL backups API).
5. `app_config` (tabela) + `/admin/config` (read/write, permission `config.write`). Feature flags `feature_flags` + endpoint.
6. `/admin/broadcast` (wyślij push do segmentu — reużyj FCM).

**Faza 2 — PowerAdmin UI (nextadmin-style):**
7. Nowy `AdminShell` (sidebar+topbar+breadcrumbs, RBAC-aware menu).
8. Dashboard z KPI + wykresami (recharts) + system health + integracje.
9. Przebudowa podstron: users (tabela+filtry+drawer szczegółów+bulk), alerts, reports (kolejka AI text+image), groups, audit, config/flags, broadcast, system.

**Faza 3 — Web (publiczny) redesign:**
10. Desktop-first `AppShell`, responsywność, parytet wizualny z apką, tokeny.
11. Per-strona refactor (mapa najpierw — wykorzystać szerokość; potem rodzina/profil/ustawienia).

**Faza 4 — polish + testy:** dark mode (web już ma `dark:`), `npm run build` czysty, smoke E2E, deploy.

---

## 7. Pliki / miejsca do dotknięcia (mapa)

| Obszar | Pliki |
|---|---|
| RBAC backend | `backend/src/middleware/requirePermission.js` (nowy), `backend/src/routes/admin.js`, `backend/src/routes/users.js` (`/me` + permissions), migracja `db/migrations/` |
| System metryki | `backend/src/services/gcp_metrics.js` (nowy — Monitoring/SQL/GCS), `backend/src/routes/admin.js` (`/system`, `/integrations/health`) |
| Config/flags | migracja `app_config` + `feature_flags`, `backend/src/routes/admin.js` |
| Web tokeny | `web/src/app/globals.css`, `web/tailwind.config.*`, nowy `web/src/components/ui/*` (Card/Table/...) |
| Web shell | `web/src/components/ui/AppLayout.tsx`, `Sidebar.tsx`, nowy `AdminShell.tsx` |
| Admin UI | `web/src/app/admin/**` (przebudowa + nowe: config, broadcast, system) |
| Wykresy | `web/package.json` (+recharts) |

---

## 8. Ryzyka i ostrożność (PowerAdmin = ogromny blast radius)

- **Bezpieczeństwo:** PowerAdmin może "zarządzać totalnie wszystkim" → KAŻDA akcja destrukcyjna (ban, delete, config write, broadcast) MUSI: (a) sprawdzać permission, (b) trafiać do `admin_audit_log`, (c) mieć potwierdzenie w UI, (d) least privilege (moderator ≠ superadmin).
- **Broadcast** do wszystkich userów = potężne narzędzie → ogranicz do `broadcast.send`, wymagaj potwierdzenia + podglądu odbiorców, rate-limit.
- **Config/feature flags na żywo** → walidacja wartości, audyt, możliwość rollbacku (trzymaj poprzednią wartość).
- **Metryki GCP** → tylko odczyt (`monitoring.viewer`), nie nadawaj compute SA uprawnień zapisu.
- **Nie psuj apki mobilnej** — zmiany web/admin/backend nie mogą zmienić kontraktów API używanych przez Flutter (jeśli zmieniasz `/users/me`, dodawaj pola, nie usuwaj). Bump wersji ostrożnie.
- **Skalowanie:** paginacja wszędzie (jest częściowo), indeksy DB pod nowe zapytania admina, cache metryk GCP (TTL ~30-60s, nie odpytuj Monitoring co render).

---

## 9. Konta testowe / dostęp

- Konta testowe (Test123!) w `AGENTS.md`. Aby testować admina: nadaj `is_admin=TRUE` wybranemu testowemu userowi przez DB (proxy) albo przez `test/verify-user`-podobny mechanizm. Po RBAC: przypisz role przez `admin_role_assignments`.
- Telefon do testów mobilnych (że nic nie zepsute): Realme RMX3741 (A15) / RMX3151 (A13) — `adb devices`.
- Narzędzie weryfikacji zrzutów (bo podgląd obrazów w czacie bywa zawodny): `mobile/scripts/verify_screenshot.py` (pikselowe asercje). Dla web: `npm run build` + ewentualnie Playwright (do rozważenia).

---

## 10. Definition of Done

- [ ] RBAC działa: ≥2 role z różnymi uprawnieniami, egzekwowane backend+UI, migracja is_admin→superadmin, audyt.
- [ ] PowerAdmin pokazuje realne metryki serwera (Cloud Run/SQL/GCS/proces) + zdrowie integracji.
- [ ] Zarządzanie nad apką: config/flags/broadcast/wersje działają i są audytowane.
- [ ] Admin wizualnie przebudowany (nextadmin-style, tokeny Serenity), responsywny.
- [ ] Web publiczny: desktop-first, parytet wizualny z apką, tokeny zamiast inline hexów.
- [ ] `cd web && npm run build` czysty, backend `node --check` czysty, dark mode OK.
- [ ] Apka mobilna nieuszkodzona (kontrakty API zachowane), smoke na urządzeniu.
- [ ] Deploy: migracje na prod → push → `gcloud run deploy besafe-web` + `besafe-backend` → bump wersji.

---

## 11. Szybki kontekst techniczny (skrót)

- Web: Next 16 / React 19 / Tailwind 4 / TS. API `https://besafe.org.pl/api/v1`. Socket `https://besafe.org.pl`.
- Backend: Node 22 / Express / pg / Cloud Run `besafe-backend` (port 8080). DB Cloud SQL `besafe-pg` (`alertmap`).
- Admin auth dziś: `users.is_admin` + `requireAdmin`. Audyt: `admin_audit_log`.
- GCP: projekt `project-1674d55f-90e0-4e1a-884`, region `europe-central2`, compute SA `1098119585965-compute@developer.gserviceaccount.com` (ma aiplatform.user, storage.objectAdmin, cloudsql.client — **brakuje monitoring.viewer**).
