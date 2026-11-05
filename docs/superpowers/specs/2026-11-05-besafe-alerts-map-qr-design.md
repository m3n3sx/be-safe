# be:Safe — mapa, powiadomienia, SOS i QR

Status: zatwierdzony kierunek, wdrożony na gałęzi roboczej. To nie jest wdrożenie produkcji.

## Cel

Cztery obszary mają działać tak samo na backendzie, Androidzie, iOS i webie:

1. Nachodzące pinezki pokazują licznik i listę. SOS jest pierwsze. Prawdziwe współrzędne zostają.
2. Sygnał i SOS mają skrzynkę, licznik, odczyt pojedynczego wpisu, deduplikację i uczciwy wynik dla nadawcy.
3. SOS idzie do pozostałych członków grupy niezależnie od wieku nadawcy. Ekran jest czerwony i podpisany be:Safe.
4. Dołączenie ma skaner QR, link https, kod ręczny, podgląd grupy i jawne potwierdzenie. Nie da się samemu zostać rodzicem ani opiekunem.

## Rozstrzygnięcia przyjęte jako domyślne

- Nowy kod zaproszenia ważny 7 dni. Istniejące kody dostają 30 dni od chwili migracji. Po rotacji stary kod przestaje działać od razu.
- Błędny i wygasły kod dają ten sam komunikat: „Kod jest nieprawidłowy lub wygasł”.
- Podgląd zwraca nazwę grupy i jej identyfikator, bez listy osób, telefonów i lokalizacji.
- Samodzielne role: `family_member` (domyślna), `child`, `senior`, `partner`, `friend`, `other`. `parent` i `guardian` nadaje właściciel.
- Ciche godziny szkolne nie dotyczą `family_sos`. Nadal nie omijają wyciszenia systemu, Focus ani zgody na powiadomienia.
- „Zamknij” obowiązuje do końca procesu aplikacji. „Widzę ten alarm” jest zapisem na serwerze i gasi alarm na wszystkich urządzeniach konta.
- Przy następnym zimnym starcie niepotwierdzony, nadal aktywny SOS wraca.
- Stare aplikacje, które wysyłają kategorię `aggression` i tytuł z 🆘, są jeszcze rozpoznawane jako SOS. Nowe wysyłają `kind: "sos"`. Heurystyka znika w osobnej zmianie, gdy bieżące buildy mobilne i webowe już wysyłają `kind`.
- Web Push (service worker, VAPID) jest poza zakresem. Powiadomienie przeglądarki działa tylko przy otwartej karcie, w tle karty i po osobnej zgodzie.
- Push iOS w tle na darmowym sideloadzie nie jest obietnicą tej zmiany. Brak plistu albo entitlementu APNs tego nie naprawia.

## Kontrakt zdarzeń

Źródłem prawdy jest wiersz `notifications`. Socket i FCM są dostawą.

| Typ | `source_id` | Kto dostaje |
|---|---|---|
| `family_sos` | id alertu | inni aktualni członkowie grup nadawcy |
| `family_ping` | id pinga | inni członkowie grupy |
| `ping_response` | id pinga | nadawca sygnału |
| `new_alert` | id alertu | osoby w promieniu, poza odbiorcami `family_sos` tego alertu |

`notifyUser` zwraca `{ notificationId, fcmAccepted, duplicate }`. `fcmAccepted` oznacza, że FCM przyjęło zgłoszenie. Nie oznacza doręczenia ani odczytu.

Tekst nadawcy pochodzi z `signalReceipt`. Przy zerze odbiorców nic nie jest zapisywane dla innych. Przy N osobach i M przyjętych zgłoszeniach tekst mówi „Zapisano” i „Usługa push przyjęła”. Zakazane sformułowania: „pomoc w drodze”, „dostarczono”, „Alert RCB”, obietnica obejścia wyciszenia.

Widoczny tytuł SOS: `be:Safe · SOS od {imię}`. Treść nie zawiera współrzędnych ani telefonu. Stare aplikacje nadal dostają `lat` i `lng` w danych FCM. Nowy ekran ich nie rysuje, dopóki `GET /alerts/:id/sos-context` nie potwierdzi członkostwa.

Odczyt jednego wpisu: `POST /notifications/:id/read`. Potwierdzenie alarmu: `POST /notifications/:id/ack`. `POST /notifications/read` zostaje tylko dla świadomego „oznacz wszystkie”. Otwarcie skrzynki nie czyści licznika hurtowo.

`GET /notifications/unacked-sos` zwraca aktywne, niepotwierdzone SOS.

Deduplikacja: unikalny indeks `(user_id, type, source_id)` gdy `source_id` nie jest puste. Klient dodatkowo zwija kopię socketu i pusha po `notification_id`, `ping_id` albo `sos:{alert_id}`.

## Tokeny

`PUT /users/me/fcm-token` przyjmuje stary `{ fcm_token }` oraz opcjonalne `platform` i `device_id`. Zapisuje wiersz `user_push_tokens` i nadal ustawia `users.fcm_token` na ostatni token. Wysyłka idzie na wszystkie niewyłączone tokeny użytkownika, najwyżej 10. Nieważny token jest wyłączany i, jeśli był w kolumnie legacy, czyszczony. Web nie rejestruje tokenu w tym zakresie.

## Lokalizacja

`family:location` dostają członkowie, dla których widoczność `location` jest przyznana i nadawca nie jest w ghost mode. To nie poszerza danych względem listy członków. Jawny punkt SOS jest osobną zgodą: członek grupy widzi miejsce wysłania alarmu, nie pasywny ślad. Osoba usunięta z grupy dostaje 404 z `sos-context` i nie dostaje już zdarzeń. Telefon jest w odpowiedzi tylko, gdy widoczność `phone` na to pozwala.

Emisja pozycji jest dławiona: rzadziej niż co 5 s, chyba że przesunięcie ma co najmniej 20 m.

## Mapa

Elementy w odległości poniżej 15 m albo bliżej niż 48 px na ekranie tworzą jedną odznakę. Identyczny punkt zawsze się grupuje. Kotwica odznaki nie jest zapisywana. Lista pokazuje prawdziwe współrzędne, SOS przed zagrożeniem, osobą i AED. Na webie mapa zagrożeń i mapa rodziny pozostają osobnymi widokami i używają tej samej reguły.

## QR

Kanoniczny link nowego kodu: `https://besafe.org.pl/family/join?code=XXXXXXXX`. Parser przyjmuje też ścieżkę `/family/join/XXXXXXXX` oraz `besafe://family/join/...`. Inne hosty są odrzucane. Skaner jest w aplikacji. Brak zgody na kamerę zostawia pole ręczne. Universal Links i associated domains są poza zakresem.

## Dowód i niewiadome

Udowodnione testem `node --test` w `backend/test/safetyContracts.test.js`: rodzaj SOS, tekst nadawcy, ack kontra odczyt i zamknięcie, deduplikacja, parser zaproszeń, TTL, role, widoczność pozycji, plan tokenów, kolizje.

Niewiadome do sprawdzenia na urządzeniu: rysunek odznaki na Google Map, zgoda na powiadomienia Androida 13+, faktyczny push FCM, iOS przy darmowym podpisie, skaner przy słabym świetle, karta przeglądarki w tle. Tych ścieżek ta zmiana nie uruchamia na produkcji i nie uznaje za zaliczone.

## Wdrożenie i cofnięcie

Najpierw migracja, potem proces API, potem klienty. Sam kod bez migracji psuje tworzenie grup, bo zapisuje `invite_expires_at`.

```bash
psql "$DATABASE_URL" -f db/migrations/2026-11-05_alerts_inbox_invites.sql
```

Nie ma nowych zmiennych środowiskowych. Dalej używane, jeśli już są: `DATABASE_URL`, `FIREBASE_SERVICE_ACCOUNT`, `GOOGLE_SERVICES_JSON`, `GOOGLE_SERVICE_INFO_PLIST`, `GOOGLE_MAPS_ANDROID_API_KEY`, `GOOGLE_MAPS_IOS_API_KEY`.

Cofnięcie kodu do poprzedniego wydania jest możliwe bez usuwania kolumn: stary kod ignoruje `alerts.kind` i `invite_expires_at`, a push czyta `users.fcm_token`, który nowy kod nadal uzupełnia. `user_push_tokens` można zostawić. Nie wolno obiecywać, że po cofnięciu stare aplikacje pokażą nowy czerwony ekran.

Android: `minSdk` 23. iOS deployment target projektu i Codemagic to 14.0. Skaner to `mobile_scanner` 7.0.1 (Apple Vision, bez GoogleMLKit, CameraX 1.4.2). 5.2.3 ciągnie GoogleDataTransport &lt; 10 i kłóci się z Firebase 11.15. Linia 6 wymaga iOS 15.5 przez MLKit 7. Od 7.1 CameraX wymaga compileSdk 36, którego AGP 8.7 z Fluttera 3.29 nie składa. Entitlement APNs nie został dodany. Darmowy sideload nadal nie dostarcza pushy w tle.
