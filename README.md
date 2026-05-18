# be:Safe

Społecznościowa aplikacja bezpieczeństwa — mapa zagrożeń w czasie rzeczywistym, moduł rodzinny (śledzenie, geofence) i SOS.

| Warstwa | Katalog | Stack |
|---------|---------|--------|
| API | [`backend/`](backend/) | Node.js, Express, Socket.IO, PostgreSQL + PostGIS |
| Mobile | [`mobile/`](mobile/) | Flutter |
| Web | [`web/`](web/) | Next.js, React, TypeScript |

## Dokumentacja

| Dokument | Opis |
|----------|------|
| [**Analiza aplikacji**](docs/ANALIZA_APLIKACJI.md) | Przegląd architektury, działania i rekomendacji (start tutaj) |
| [**Plan bezpieczeństwa**](docs/PLAN_BEZPIECZENSTWA.md) | Priorytetyzowane naprawy luk |
| [**Rodzina, czat i UX**](docs/PLAN_RODZINA_CZAT_I_UX.md) | Czat grupy rodzinnej, uproszczenie nawigacji |
| [Pełna dokumentacja techniczna](docs/FULL_DOCUMENTATION.md) | API, ekrany, deploy, znane problemy |
| [API](docs/API.md) | Kontrakt REST |
| [Baza danych](docs/DATABASE.md) | Tabele i relacje |
| [Infrastruktura](docs/INFRASTRUCTURE.md) | Hosting, domeny, integracje (uwaga: może zawierać sekrety — nie publikować) |
| [Runbook operacyjny](docs/OPS_RUNBOOK.md) | Procedury na produkcji |

Instrukcje dla agentów AI: [`AGENTS.md`](AGENTS.md).

## Szybki start (dev)

### Wymagania

- Node.js 18+
- PostgreSQL 14+ z rozszerzeniami **PostGIS** i **uuid-ossp**
- Flutter 3.x (tylko mobile)
- Klucze Google Maps / Firebase — poza repozytorium (patrz `docs/FULL_DOCUMENTATION.md`)

### 1. Baza danych

```bash
createdb alertmap
psql -d alertmap -f db/schema.sql
```

### 2. Backend

```bash
cd backend
cp .env.example .env   # uzupełnij DATABASE_URL, JWT_SECRET
npm install
npm run dev            # domyślnie http://localhost:3000
```

### 3. Web

```bash
cd web
npm install
```

Utwórz `.env.local` (przykład):

```env
NEXT_PUBLIC_API_URL=http://localhost:3000/api/v1
NEXT_PUBLIC_SOCKET_URL=http://localhost:3000
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=<twój_klucz>
```

```bash
npm run dev            # http://localhost:3000
```

### 4. Mobile

```bash
cd mobile
flutter pub get
flutter run
```

Domyślnie aplikacja łączy się z produkcją (`besafe.org.pl`). Do pracy z lokalnym API zmień `baseUrl` w `mobile/lib/services/api_service.dart` lub wprowadź konfigurację przez `--dart-define`.

## Walidacja przed commitem

```bash
# Backend — brak skryptu test; ręcznie: health + smoke API
curl http://localhost:3000/health

# Web
cd web && npm run lint && npm run build

# Mobile
cd mobile && flutter analyze
```

## CI

Push na `main` z zmianami w `mobile/**` lub `backend/**` uruchamia [build i deploy APK](.github/workflows/build-deploy.yml). Warstwa `web/` nie jest objęta pipeline CI.

## Licencja

Zobacz pliki licencyjne w repozytorium (jeśli dodane).
