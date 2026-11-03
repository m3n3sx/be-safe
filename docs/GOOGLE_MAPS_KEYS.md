# Klucze Google Maps — konfiguracja w czasie builda

Klucze **nie są commitowane** do repo. Każda platforma dostaje swój klucz w czasie builda.
Projekt GCP: `besafe-maps-513511` (billing włączony).

| Platforma | Klucz (nazwa w GCP) | API | Restrykcja | Skąd brany przy buildzie |
|---|---|---|---|---|
| Web (Next.js) | BeSafe Maps Web | Maps JavaScript, Places, Places (New), Geocoding | HTTP referrer: `besafe.org.pl`, `www.besafe.org.pl`, `localhost:3000` | `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` (`.env` → build arg w `docker-compose.yml`) |
| Android | BeSafe Maps Android | Maps SDK for Android | `pl.u235.alertmap` + SHA-1 certyfikatu podpisującego | env `GOOGLE_MAPS_ANDROID_API_KEY` **lub** `mobile/android/local.properties`: `MAPS_API_KEY=...` |
| iOS | BeSafe Maps iOS | Maps SDK for iOS | bundle `pl.u235.alertmap` | `mobile/ios/Flutter/Secrets.xcconfig`: `GOOGLE_MAPS_IOS_API_KEY=...` |

## Web
`web/src/lib/constants.ts` czyta wyłącznie `process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` (bez fallbacku).
Zmienna jest wbudowywana w bundle podczas `next build`, więc po zmianie klucza trzeba przebudować obraz `web`.

## Android
`mobile/android/app/build.gradle.kts` ustawia `manifestPlaceholders["mapsApiKey"]`,
a `AndroidManifest.xml` ma `com.google.android.geo.API_KEY = ${mapsApiKey}`.
Kolejność: env `GOOGLE_MAPS_ANDROID_API_KEY` → `android/local.properties` (`MAPS_API_KEY`, plik jest w `.gitignore`).
Brak klucza = ostrzeżenie Gradle i pusta (biała) mapa w aplikacji.

```bash
cd mobile
GOOGLE_MAPS_ANDROID_API_KEY="$(cat ~/secrets/maps-android.txt)" flutter build apk --release --no-tree-shake-icons
```

## iOS
`Runner/Info.plist` ma `GMSApiKey = $(GOOGLE_MAPS_IOS_API_KEY)`; `AppDelegate.swift` czyta go przez
`Bundle.main.object(forInfoDictionaryKey: "GMSApiKey")`. Wartość pochodzi z
`ios/Flutter/Secrets.xcconfig` (gitignored), dołączanego opcjonalnie (`#include?`) przez `Debug.xcconfig` i `Release.xcconfig`.

Lokalnie:
```bash
printf 'GOOGLE_MAPS_IOS_API_KEY=%s\n' "$(cat ~/secrets/maps-ios.txt)" > mobile/ios/Flutter/Secrets.xcconfig
```

### Codemagic
Aplikacja `be-safe` w Codemagic (id `6a0d7b0b13fc93afd5219716`) jest obecnie skonfigurowana przez **UI** (Workflow Editor, „Default Workflow”).

* **UI / Default Workflow**: secure variable `GOOGLE_MAPS_IOS_API_KEY` jest już dodana do „Default Workflow”
  (obok `SENTRY_DSN`). W Workflow Editor dodaj przed buildem iOS skrypt pre-build:
  ```bash
  [ -n "${GOOGLE_MAPS_IOS_API_KEY:-}" ] && \
    printf 'GOOGLE_MAPS_IOS_API_KEY=%s\n' "$GOOGLE_MAPS_IOS_API_KEY" > "$CM_BUILD_DIR/mobile/ios/Flutter/Secrets.xcconfig"
  ```
* **codemagic.yaml (workflow `ios-unsigned`)**, po przełączeniu aplikacji na konfigurację z pliku:
  1. Codemagic → be-safe → **Environment variables** → zmienna `GOOGLE_MAPS_IOS_API_KEY` (**Secure**) w grupie **`google_maps`**.
  2. `codemagic.yaml` importuje grupę `google_maps`, a krok *Google Maps iOS key → Secrets.xcconfig*
     zapisuje ją do `ios/Flutter/Secrets.xcconfig` przed `flutter build ios`. Wartość nie jest logowana.
  3. Ten sam krok (i `groups: [google_maps]`) trzeba dodać do każdego innego workflow iOS budującego tę aplikację.

Bez zmiennej build przechodzi, ale mapa na iOS będzie pusta (ostrzeżenie w logu).
