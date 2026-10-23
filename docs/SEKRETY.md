# Sekrety i klucze — jak je podawać (bez trzymania w repo)

Repozytorium jest **publiczne**. Żadne hasła, tokeny ani klucze nie trafiają do plików w repo.
Prawdziwe wartości trzymamy w menedżerze haseł, w Secret Manager (GCP) albo w GitHub Secrets.

| Co | Gdzie to ustawić lokalnie | Gdzie w CI |
|---|---|---|
| Backend: `DATABASE_URL`, `JWT_SECRET`, `MAILGUN_API_KEY`, `TEST_RESET_SECRET` itd. | `backend/.env` (wzór: `backend/.env.example`) | nie potrzebne do testów — testy używają atrap |
| Docker Compose: `POSTGRES_PASSWORD`, `JWT_SECRET`, `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` | `.env` w katalogu głównym (wzór: `.env.example`) | — |
| Web: klucz Google Maps | `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` w `.env` / `web/.env.local` albo `--build-arg` przy `docker build` | — |
| Android: klucz Google Maps | `mobile/android/local.properties` → `MAPS_API_KEY=...` albo zmienna środowiskowa `MAPS_API_KEY` | GitHub Secret `MAPS_API_KEY` |
| iOS: klucz Google Maps | `mobile/ios/Flutter/Secrets.xcconfig` (wzór: `Secrets.xcconfig.example`) | Codemagic, grupa `maps` |
| Sentry (aplikacja) | `flutter build ... --dart-define=SENTRY_DSN=...` | GitHub Secret `SENTRY_DSN` |
| Firebase (`google-services.json`) | `mobile/android/app/google-services.json` (w `.gitignore`) | GitHub Secret `GOOGLE_SERVICES_JSON` |
| Hasło kont testowych E2E | `--dart-define=TEST_PASSWORD=...` / env `TEST_PASSWORD` | — |

Uwaga: **build release Androida bez `MAPS_API_KEY` zostanie przerwany** (żeby nie wypuścić aplikacji z pustą mapą).
Build debug przechodzi, tylko mapa się nie załaduje.

Klucze Google Maps w aplikacjach mobilnych i na stronie są z natury widoczne dla użytkowników (da się je
wyciągnąć z APK/strony). Ochroną jest **ograniczenie klucza w Google Cloud Console**: do nazwy pakietu + SHA-1
(Android), bundle ID (iOS), domeny (web) oraz tylko do potrzebnych API.

Przed commitem warto puścić skaner: `gitleaks dir .`
