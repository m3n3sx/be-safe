# be:Safe — przeprojektowanie UX/UI web

**Etap 1: badanie kodu i projekt, bez implementacji.** Stan repozytorium: 3 listopada 2026.

## 1. Cel, zakres i najważniejsze decyzje

Zaprojektować aplikację dla osoby, która chce szybko odpowiedzieć na trzy pytania: **„Co dzieje się blisko mnie?”, „Jak to zgłosić?”, „Jak dostać pomoc?”**. Punktem wyjścia są te zadania, a nie obecny wygląd web ani układ ekranu głównego Fluttera.

- **Mapa i lista okolicy są jednym ekranem startowym.** Lista jest widoczna od razu; mapa nie jest jedynym sposobem korzystania z alertów.
- **Jedna globalna akcja „Zgłoś”**, prowadząca do formularza w maksymalnie trzech krokach. Kliknięcie pustej mapy nie otwiera formularza.
- **SOS dostępne z każdego ekranu**, także logowania, błędu i administracji. Samo wejście do SOS nie wysyła alarmu.
- **Cztery miejsca w nawigacji:** „W okolicy”, „Bliscy”, „Pomoc”, „Profil”. „Zgłoś” jest akcją pomiędzy zakładkami, a nie piątą sekcją.
- Web ma realizować wszystkie zadania dostępne w mobile, z jawnymi odpowiednikami przeglądarkowymi dla funkcji sprzętowych. Zgodność funkcji nie oznacza kopiowania gestów, atrap ani błędów.
- **Backend API pozostaje bez zmian.** Plan korzysta z istniejących metod, parametrów i odpowiedzi. Ograniczenia wymagające decyzji o backendzie zebrano w §9.
- Wszystkie istniejące adresy web pozostają osiągalne, także `/admin/*`. Pełny rejestr jest w §4.
- Cały nowy interfejs, błędy, etykiety dostępności i metadane mają polską wersję. Klucz map wyłącznie z `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY`; żadnych kluczy zapasowych w kodzie ani dokumentacji.

### Metoda i znaczenie statusów

Badanie statyczne objęło `mobile/lib/screens`, `widgets`, `services`, dostawców stanu i `main.dart`, wszystkie strony `web/src/app`, komponenty i konteksty web oraz odpowiadające im routery backendu. `mobile/lib/services/api_service.dart` i `web/src/lib/api.ts` są ogólnymi klientami HTTP — faktyczne operacje są w ich miejscach użycia. Dodatkowo sprawdzono bezpośrednie `fetch`, Socket.IO oraz integracje urządzenia.

„Jest” oznacza znaleziony interfejs i implementację wywołania, **nie potwierdzony test produkcyjny**. „Częściowe” oznacza brak elementów zadania, niezgodność kontraktu lub atrapę. „Lokalne” oznacza brak endpointu. Nie wykonywano logowania, zgłoszeń, wysyłek SOS ani mutacji API.

W tabelach endpointy są względne wobec `/api/v1`. Skróty: `G = /family/groups/:groupId`, `M = G/members/:memberId`, `R = M/safe-routes`, `A = /alerts/:alertId`. `GET/POST` oznacza dwie metody tego samego adresu, nie nowy endpoint. Identyfikatory M/W pozwalają połączyć inwentarz z tabelą zgodności.

### Najważniejsze ustalenia z kodu

1. Web ma wiele stron, lecz większość nie jest dobrze odkrywalna z głównej nawigacji; część nie używa wspólnej powłoki. `/alerts` i `/alerts/mine` dublują „Moje zgłoszenia”. Brakuje strony `/alerts/:id`, mimo że panel moderacji już do niej linkuje.
2. `MapView.tsx` łączy mapę, lokalizację, sieć, klastry, filtry, zgłaszanie i szczegóły. Kliknięcie mapy inicjuje zgłoszenie. Brakuje podstawowej listy okolicy i wyszukiwarki adresu w UI.
3. Niektóre strony wyglądają na gotowe, ale wywołują niewłaściwe endpointy lub interpretują inną strukturę danych: ustawienia konta, aktualności, odznaki, statystyki, kalendarz, udostępnianie lokalizacji i wynik głosowania. Konkretne różnice: §9.1.
4. Są dwa różne mechanizmy SOS web. `/sos` używa kontraktu rozpoznawanego przez backend: `category: aggression` i `🆘` w tytule. `SOSButton.tsx` wysyła `SOS!` bez tego symbolu. Oba mają błędne zastępcze współrzędne przy braku GPS.
5. Wybór „powiadom rodzinę / społeczność” nie jest przekazywany jako sterujące pola API. Backend sam wybiera odbiorców; specjalna ścieżka rodzinna SOS dotyczy obecnie dziecka z aktywnym śledzeniem i członków o roli `parent`. Podobne mylące obietnice występują w mobile.
6. Web nie ma centrum powiadomień, odpowiedzi na sygnał rodzinny, czatu sąsiedzkiego, edytora bezpiecznych tras ani działających wariantów dom/SOS dla dzieci i seniorów. Sam zapis `app_mode` nie realizuje tej funkcji.
7. `web/src/lib/constants.ts` ma obecnie literalny fallback klucza Google Maps. Pierwszy etap implementacji ma go usunąć; wartości nie powielamy.

## 2. Użytkownik i najważniejsze zadania

### Użytkownik podstawowy

Osoba mieszkająca w Polsce, korzystająca głównie z telefonu i przeglądarki, bez znajomości pojęć „geofence”, „ETA”, „trust score”, „foreground” czy „RBAC”. Często otwiera aplikację w drodze, jedną ręką, na słabym połączeniu. Potrzebuje adresu, odległości i prostej decyzji, nie pulpitu z wieloma wskaźnikami.

Ważne warianty: rodzic/opiekun sprawdzający bliskich, senior wymagający większych elementów i prostego meldunku, młodszy użytkownik korzystający z widoku uproszczonego, moderator korzystający z desktopu. Tryb interfejsu nie nadaje uprawnień rodzinnych ani administracyjnych.

### Ranking zadań

| Priorytet | Pytanie użytkownika | Kryterium projektowe |
|---|---|---|
| 1 | Co dzieje się blisko mnie i czy dotyczy mojej drogi? | Po otwarciu: obszar, aktualne alerty, odległość i czas; szczegóły po jednym wyborze |
| 2 | Widzę problem — jak ostrzec innych? | „Zgłoś” zawsze widoczne; maks. 3 kroki, zdjęcie i długi opis opcjonalne |
| 3 | Potrzebuję pomocy teraz | SOS w jednym przejściu; 112 bez konta i bez oczekiwania na GPS/API |
| 4 | Czy u bliskich wszystko w porządku? | Osoba, ostatnia aktualizacja, meldunek, telefon, sygnał i czat w jednym kontekście |
| 5 | Czy zgłoszenie jest nadal aktualne? | „Potwierdzam” / „Już nieaktualne” i komentarz przy szczegółach |
| 6 | Co wymaga mojej reakcji? | Dzwonek z licznikiem; powiadomienie prowadzi do właściwego alertu, sygnału lub sesji |
| 7 | Jak ustawić prywatność, okolicę i konto? | Czytelne ustawienia z rzeczywistym stanem zapisu i uprawnień |
| 8 | Gdzie są porady, AED, aktualności, osiągnięcia? | Odkrywalne sekcje Pomoc/Profil i skróty kontekstowe, bez przeciążania mapy |

Priorytet 3 opisuje częstość, nie wagę: dostępność SOS jest wymaganiem krytycznym na każdym ekranie.

## 3. Inwentarz Fluttera

Ścieżki w tej sekcji są względne wobec `mobile/lib/`. Zgrupowane w jednym wierszu pliki wymieniono jawnie; warianty zachowują odrębne zachowania.

### 3.1. Ekrany i operacje

| ID | Ekran / źródło | Funkcje użytkownika | Używane API / integracje |
|---|---|---|---|
| M01 | `screens/auth/login_screen.dart`, `providers/auth_provider.dart` | Logowanie, rejestracja, Google, kod polecający, deklaracja 13+, akceptacja regulaminu, demo, przywracanie sesji, wylogowanie | `POST /auth/login`, `/auth/register`, `/auth/google`, `/auth/demo`; `GET /users/me`; token lokalnie; Google Sign-In |
| M02 | `screens/auth/forgot_password_screen.dart` | Prośba o reset hasła e-mailem | `POST /auth/forgot-password`; reset i weryfikacja z linków mają strony web |
| M03 | `screens/onboarding/onboarding_screen.dart` | Wprowadzenie: mapa, alerty, rodzina, SOS; pomijanie/zakończenie | Lokalne `onboarding_done` |
| M04 | `screens/onboarding/setup_wizard_screen.dart` | Konfigurator po zalogowaniu: zgody, promień, tworzenie/dołączenie do grupy, strefa, dostępność; ponowne uruchomienie w ustawieniach | `GET /family/groups`, `POST /family/groups`, `/family/groups/join`; **obecnie `PUT /users/me`** dla promienia, podczas gdy backend ma `PATCH`; dodawanie stref przez M17; preferencje lokalne |
| M05 | `screens/mode/mode_picker_screen.dart`, `providers/mode_provider.dart` | Wybór Standardowy / Dla dziecka / Dla seniora i synchronizacja | `PATCH /users/me {app_mode}` przez auth provider; lokalne preferencje |
| M06 | `screens/home/home_screen.dart` | Podsumowanie okolicy, liczba alertów i potwierdzeń, umowny poziom bezpieczeństwa, bliscy z ostatnią lokalizacją/meldunkiem, AQI, dzwonek, skróty | M09; `GET /family/groups`, `GET G/members`, `GET G/checkins/today`; M28; wskaźnik `10 − liczba alertów` liczony lokalnie, nie niezależna ocena ryzyka |
| M07 | `screens/home/home_kids_screen.dart` | Duże skróty: pomoc, mapa, rodzina, wiadomości, „Jestem OK”; potrójne naciśnięcie Pomoc; podgląd aktywnej trasy, powiadomienia | `GET /family/groups`, `GET R` dla siebie; `POST /users/me/checkin {status:safe}`; M15/M27 |
| M08 | `screens/home/home_senior_screen.dart` | Dzisiejszy meldunek, proste SOS, rodzina, lekarz, poradnik, ustawienia, powiadomienia | `GET /users/me/checkin/today`, `POST /users/me/checkin`; `tel:`. **Skrót „lekarz” obecnie otwiera 112**, nie zapisany kontakt |
| M09 | `screens/map/map_screen.dart`, `providers/alert_provider.dart` | Mapa Google, lokalizacja, wyszukiwanie miejsca, klastry, filtry kategorii, lista alertów, wizualizacja obszarów zagrożeń, zgłoszenie ze wskazanego punktu, bliscy i przypięte osoby | `GET /alerts/nearby?lat&lng&radius_m`, `PUT /users/me/location`, `GET /family/groups`, `GET G/members`; Socket.IO; wyszukiwanie bezpośrednio w Nominatim; obszary zagrożeń liczone z alertów, nie `/alerts/heatmap` |
| M10 | `screens/alerts/alert_detail_screen.dart` | Szczegóły, zdjęcie, mini-mapa, autor/weryfikacja, czas ważności, potwierdzenia i zaprzeczenia, komentarze na żywo, udostępnianie, zgłoszenie nadużycia | `GET A`, `GET/POST A/comments`, `POST A/vote` z `vote: confirm` lub `deny`, `POST A/report {reason}`; `alert:join/leave`, `comment:new/deleted`; systemowe udostępnianie |
| M11 | `screens/alerts/create_alert_screen.dart` | Kategoria, edytowalna lokalizacja, tytuł, opis, kamera/galeria, czas ważności, anonimowość, ochrona przed porzuceniem formularza | Multipart `POST /alerts`, pole pliku `photo`, `is_anonymous`, `duration_hours`; Google Maps i ImagePicker |
| M12 | `screens/alerts/my_alerts_screen.dart` | Lista własnych alertów, edycja opisu, przedłużenie o 3 h, usunięcie, przejście do szczegółów | `GET /alerts/mine`, `PATCH A` z `description` lub `extend_hours`, `DELETE A` |
| M13 | `screens/alerts/stats_screen.dart` | Liczby dziś/tydzień/ogółem, kategorie, trend 14 dni w okolicy | `GET /alerts/stats?lat&lng&radius_m` |
| M14 | `screens/sos/sos_screen.dart` | Przytrzymanie 2 s, deklarowany wybór rodzina/społeczność/112, opcjonalne lokalne audio, skróty do eskorty i fałszywego telefonu | `GET /family/groups`, `GET G/members`; `POST /alerts` z `aggression` i `🆘`; `tel:112`; M36. Wybór odbiorców nie jest kontraktem API |
| M15 | `screens/sos/sos_kids_screen.dart`, `screens/sos/sos_senior_screen.dart` | Dziecko: uproszczony alarm z przytrzymaniem; senior: osobno telefon 112 i wysłanie alarmu bez gestu przytrzymania | `POST /alerts` jak M14; senior `tel:112`; opis „rodzina powiadomiona” szerszy niż gwarancje API |
| M16 | `screens/family/family_screen.dart` | Grupy, tworzenie, dołączenie kodem z rolą, zaproszenie/udostępnienie kodu, członkowie, przypięcie, czasowe ukrycie lokalizacji, sygnał do grupy, usunięcie grupy przez właściciela, skróty do mapy/czatu/planu/zwierząt/stref | `GET/POST /family/groups`, `POST /family/groups/join`, `GET G/members`, `POST G/ping`, `DELETE G`; `GET /users/me`, `PUT /users/me/ghost {hours}`, `DELETE /users/me/ghost`; lokalne przypięcia |
| M17 | `screens/family/family_group_screen.dart`, `screens/family/add_geofence_screen.dart` | Mapa rodziny, bezpieczne strefy: lista/dodanie/usunięcie; nazwa, punkt i promień; avatar, role, śledzenie, tryb ciszy w szkole | `GET G/members`, `GET/POST G/geofences`, `DELETE G/geofences/:id`, `PATCH M` z `role`, `tracking_enabled` lub `school_hours_silent`, multipart `POST /users/:id/avatar` z `avatar` |
| M18 | `screens/family/child_profile_screen.dart` | Profil dziecka: lokalizacja, telefon, bateria, ostatnia aktywność, historia, trasy, sygnał, role, usunięcie członka, prywatność względem odbiorców | `GET G/members`, `GET /family/groups`, `PATCH/DELETE M`, `GET G/visibility-matrix/:memberId`, `PUT G/visibility/:memberId`; `POST G/ping`; historia/trasy M20/M21 |
| M19 | `screens/family/member_profile_screen.dart` | Profil innego członka lub siebie, kontakt/nawigacja, dane udostępnione, zmiana roli, usuwanie, kontrola widoczności, przypięcie, sygnał | Jak M18; edycja widoczności dla siebie/dziecka zależna od roli; `tel:` i mapa zewnętrzna; problem odczytu macierzy własnej osoby dorosłej w §9 |
| M20 | `screens/family/location_history_screen.dart` | Wybór dnia z ostatnich 30 dni, ślad na mapie, lista/liczba punktów | `GET M/location/history?from&to&limit=500` |
| M21 | `screens/family/safe_routes_screen.dart`, `screens/family/draw_safe_route_screen.dart` | Lista tras dziecka, rysowanie palcem, nazwa i tolerancja zejścia, podgląd, włączenie/wyłączenie, usunięcie, alerty przy trasie | `GET/POST R`, `PATCH/DELETE R/:routeId`, `GET R/:routeId/alerts-near?buffer_m=200`; zapis `points: [[lat,lng],…]`, `threshold_m` |
| M22 | `screens/family/family_chat_screen.dart` | Odczyt, wysłanie wiadomości, autor/czas, aktualizacja na żywo | `GET G/messages?limit=100`, `POST G/messages {body}`, `family:message` |
| M23 | `screens/family/family_planner_screen.dart` | Nadchodzące wydarzenia, dodanie tytułu/opisu/miejsca/terminu/przypomnienia, usunięcie własnego | `GET G/events?upcoming=1`, `POST G/events {starts_at, reminder_minutes_before,…}`, `DELETE G/events/:eventId` |
| M24 | `screens/family/family_sos_screen.dart` | Odbiór SOS bliskiego: kto/gdzie, mapa, kontakt/dojazd, członkowie grupy, ponowny sygnał | Payload powiadomienia, `GET G/members`, `POST G/ping`; zewnętrzna nawigacja/telefon |
| M25 | `screens/family/ping_response_screen.dart` | Odpowiedź „Wszystko OK” / „Potrzebuję pomocy”, opcjonalna notatka, stan odpowiedzi/wygaśnięcia | `GET /family/pings/:pingId`, `POST /family/pings/:pingId/respond` z `status: ok` lub `not_ok` i opcjonalnym `message` |
| M26 | `screens/neighborhood/neighborhood_chat_screen.dart` | Rozmowa sąsiedzka w promieniu 2 km, wiadomości, autor/czas, odświeżanie | `GET /neighborhood/messages?lat&lng&radius_m&limit`, `POST /neighborhood/messages {body,lat,lng}`, `neighborhood:message`, polling 15 s |
| M27 | `screens/community/notifications_screen.dart`, `widgets/notification_bell.dart` | Skrzynka do 100 powiadomień, licznik, oznaczenie przeczytanych, usunięcie jednego/wszystkich, przejście do zadania | `GET /notifications?limit=100`, `GET /notifications/unread-count`, `POST /notifications/read`, `DELETE /notifications/:id`, `DELETE /notifications`; routing typu powiadomienia |
| M28 | `widgets/aqi_widget.dart`, AED w `screens/map/map_screen.dart` | Jakość powietrza GIOŚ z odświeżeniem; warstwa AED, odległość/adres/operator/godziny/wnętrze, nawigacja piesza i 112 | `GET /aqi/nearby?lat&lng&radius_m=30000&limit=1`; AED obecnie `GET /aeds/nearby?lat&lng&radius=5000` — backend oczekuje `radius_m`; zewnętrzna mapa i `tel:112` |
| M29 | `screens/escort/escort_screen.dart` | Bezpieczny powrót: osoba obserwująca, cel, przewidywany czas, aktywna sesja; widok idącego i obserwatora, lokalizacja, odliczanie, „Dotarłem”, anulowanie, telefon | `GET /escort/active`, `GET /family/groups`, `GET G/members`, `POST /escort/start`, `PATCH /escort/:id/location` co 20 s w widoku nadawcy, `PATCH /escort/:id/complete`, `DELETE /escort/:id`; geolokalizacja |
| M30 | `screens/pets/pets_screen.dart` | Zwierzęta grupy: dodanie imienia/gatunku/rasy/koloru/wieku/notatek/domowej lokalizacji, lista, zaginięcie z pozycją/opisem, odnalezienie, usunięcie | `GET /pets/mine`, `POST /pets`, `POST /pets/:id/lost`, `POST /pets/:id/found`, `DELETE /pets/:id`; GPS. Brak osobnego UI zgłoszenia zauważenia zwierzęcia |
| M31 | `screens/profile/profile_screen.dart` | Profil/avatar, liczba zgłoszeń/reputacja, „Jestem bezpieczny”, promień, link lokalizacji na godzinę, odnośniki do własnych zgłoszeń/osiągnięć/ustawień, wylogowanie | `GET /users/me`, `GET /alerts/mine`, `POST /users/me/checkin`, `PATCH /users/me {alert_radius_m}`, `POST /users/me/share-location {hours:1}` → `url,expires_at` |
| M32 | `screens/profile/badges_screen.dart`, `ranking_screen.dart`, `referral_screen.dart` | Odznaki zdobyte/do zdobycia, ranking, kod/link polecający i liczba poleceń, udostępnienie | `GET /me/badges`, `GET /users/ranking`, `GET /users/me`; Share API platformy |
| M33 | `screens/community/news_screen.dart` | Lista aktualności i odczyt treści/ilustracji | `GET /posts` |
| M34 | `screens/settings/settings_screen.dart` | Język, jasny/ciemny/systemowy motyw i kolor, tryb aplikacji, konfigurator; lokalne alerty rodzinne/okolicy/dźwięk/wibracja; e-mail/hasło/nazwa/telefon; KPP; konto/usunięcie, wersja i linki pomocy | `POST /users/me/email`, `POST /users/me/password`, `PATCH /users/me {username,phone,is_kpp}`, `POST /users/me/delete {password}`; pozostałe preferencje lokalne; funkcje urządzenia M36–M39 |
| M35 | `screens/settings/accessibility_screen.dart`, `providers/accessibility_provider.dart` | Rozmiar tekstu, wysoki kontrast, ograniczenie ruchu, pogrubienie, respektowanie ustawień systemowych | Lokalne SharedPreferences, MediaQuery; brak API |
| M36 | `services/sos_audio_service.dart`, sekcja w ustawieniach | Zgoda i włączenie 30 s nagrania przy SOS; zapis prywatnie na urządzeniu, usunięcie nagrań, cofnięcie zgody | Mikrofon i pliki lokalne; **brak uploadu audio do backendu** |
| M37 | `services/crash_detection_service.dart`, `shake_detection_service.dart` | Opt-in: wstrząs/upadek z 30 s na anulowanie i automatyczny alarm; 3 potrząśnięcia otwierają SOS | Akcelerometr; crash `POST /alerts`; shake tylko nawigacja. To implementacja czujników, nie potwierdzona niezawodność wykrywania wypadków |
| M38 | `services/biometric_service.dart`, blokada w `main.dart` | Opt-in blokady odciskiem/twarzą/PIN-em urządzenia; ponowienie, wylogowanie | `local_auth`, preferencja lokalna; brak API biometrii |
| M39 | `screens/permissions/permissions_screen.dart` | Stan i włączenie lokalizacji, kamery, mikrofonu, powiadomień, biometrii, sensorów; ustawienia systemowe | `GET /permissions`, `PUT /permissions {capability,granted}` + permission_handler. Osobny ApiService tego ekranu nie ładuje tu tokenu — wymaga sprawdzenia integracyjnego |
| M40 | `screens/fake_call/fake_call_setup_screen.dart`, `fake_call_incoming_screen.dart` | Konfiguracja rozmówcy/numeru/opóźnienia, odliczanie i anulowanie, ekran połączenia, odebranie, licznik rozmowy, zakończenie | Lokalne timery, haptyka, pełny ekran; brak połączenia telefonicznego i API |
| M41 | `screens/emergency/emergency_numbers_screen.dart`, `screens/mental_health/mental_health_sos_screen.dart` | Numery ratunkowe i wsparcie psychologiczne, połączenie telefoniczne, katalog psychologów | Statyczna treść; `tel:`, link do psycholodzy.pl; brak API |
| M42 | `screens/safety/safety_guide_screen.dart` | Numery, RKO, dom, burza/blackout, zamki, oszustwa, jazda, leki, wycieczki, cyber, dzieci, kontakt z pomocą | Statyczne rozwijane sekcje, `mailto:`; brak API |
| M43 | `screens/cyber_safety/cyber_safety_screen.dart`, `screens/parental_controls/parental_controls_screen.dart` | PESEL, wycieki, phishing/CERT/8080; odnośniki do Family Link, Screen Time, Qustodio, Bark, Dyżurnet, FDDS | Zewnętrzne WWW/`sms:`; **nie jest to wbudowana kontrola telefonu dziecka** |
| M44 | `screens/legal/legal_screen.dart` | Regulamin i prywatność | Treść lokalna; brak API |

### 3.2. Nawigacja, widgety i usługi przekrojowe

| Źródło | Funkcja widoczna dla użytkownika / zależność |
|---|---|
| `widgets/nav_routes.dart`, `pill_nav_bar.dart`, `collapsible_dock.dart` | Globalny dock: Home, Mapa, SOS, Rodzina, Profil; centralna akcja Zgłoś poza zakładkami. Home i SOS zależą od `app_mode`; dok ma stan zwinięcia i aktywnej zakładki. Bez API |
| `main.dart` | Bramka onboarding → tryb → sesja/biometria → konfigurator → home; trasy nazwane map/family/profile/settings/my-alerts/stats/ranking/login/forgot-password/terms/privacy/referral/permissions/badges/news/neighborhood/emergency/sos/mode-picker/escort/fakecall/report/checkin; trasy z payloadem alert-detail/family-sos/ping-response i `/family/:id`. Część ekranów otwierana bezpośrednio przez `MaterialPageRoute` |
| `widgets/safety_hero_xl.dart`, `map_markers.dart`, `aqi_widget.dart`, `notification_bell.dart` | Wskaźnik i komunikat okolicy, znaczniki kategorii/klastrów/osób/AED, AQI, dzwonek. Dane/API z M06/M09/M27/M28 |
| `widgets/apple_card.dart`, `serenity_card.dart`, `inset_grouped_section.dart`, `large_title_app_bar.dart` | Karty, sekcje, nagłówki; brak osobnych funkcji biznesowych/API |
| `widgets/pressable_scale.dart`, `stagger_list.dart`, `glow_orb.dart`, `shimmer_loader.dart` | Reakcja na dotyk, animacje, ozdobne halo, ładowanie; respektowanie ograniczenia ruchu w części komponentów; brak API |
| `services/location_service.dart` | GPS, żądanie zgody, kontrola `isMocked`/nierealnego skoku, strumień pozycji. Przeglądarka nie udostępnia równoważnego `isMocked` |
| `services/background_service.dart` | Lokalizacja w tle/foreground service zależnie od systemu i zgód, lokalne powiadomienia, bateria co 10 min, polling alertów. `PUT /users/me/location`, `PUT /users/me/battery {level}`, `GET /alerts/new?since`, Socket.IO `location:update` |
| `services/fcm_service.dart` | Rejestracja i odnowienie push `PUT /users/me/fcm-token`; odbiór na pierwszym planie/w tle, przejście z powiadomienia do aplikacji. Payloady: alerty, SOS/sygnały/odpowiedzi rodziny, strefy/trasy, eskorta, zwierzęta; dodatkowe typy obsługuje skrzynka M27 |
| `services/socket_service.dart` | `alert:new`, `family:location`, `family:geofence_exit`, `family:message`, `neighborhood:message`; pokoje `alert:join/leave`, `comment:new/deleted`, obsługa `alert:typing`; emit `location:update`. Dostępny handler typing nie oznacza osobnego działającego widoku „pisze…” |
| `services/cache_service.dart` | SQLite: cache alertów globalny i regionalny, TTL domyślnie 5 min; odczyt przy wolnej/brakującej sieci. Nie kolejkuje nowych zgłoszeń i nie zapewnia map Google offline |
| `services/pinned_family_service.dart` | Maks. 3 przypięte osoby, przechowywane lokalnie, wykorzystywane na mapie i w rodzinie |
| `services/widget_service.dart` | Widgety Androida: SOS, stan okolicy, bliscy, najbliższy alert, szybkie akcje, meldunek, AQI, eskorta, IMGW; dane przekazywane lokalnie i deep linki `besafe://…`. Wskaźnik IMGW nie jest dowodem osobnej trasy API/widgetu z pełnym feedem |
| `services/update_service.dart` | Sprawdzenie `GET /version` poza `/api/v1`, pobranie/instalacja APK przez kanał natywny; dostępność zależna od wdrożenia |
| `services/i18n.dart`, `providers/theme_provider.dart` | Wybór języka i wyglądu lokalnie; zestaw motywów oraz jasny/ciemny/systemowy |
| `services/analytics.dart`, `services/api_service.dart` | Zdarzenia `POST /events`, klient HTTP, token, timeout/retry; nie osobne ekrany. Uwaga: helper zwraca `{error}`, więc samo zakończenie `await` nie dowodzi sukcesu |

**Kategorie do zachowania w odczycie, filtrowaniu i formularzu:** `aggression`, `theft`, `accident`, `fire`, `flood`, `ice`, `construction`, `animal`, `dark_area`, `drugs`, `police`, `weather`, `other`, `stranger_danger`, `traffic_danger`, `playground_hazard`, `water_hazard`, `school_zone`, `pothole`, `dark_passage`, `broken_lights`. W UI można je grupować i upraszczać nazwy; wartości API pozostają identyczne. Importowane ostrzeżenia pogodowe/drogowe są prezentowane jako alerty istniejącego API, bez dodawania fikcyjnych endpointów „IMGW web”.

## 4. Inwentarz web i zachowanie istniejących adresów

Każdy adres w tabeli odpowiada istniejącemu `web/src/app/<adres>/page.tsx`; `/` to `app/page.tsx`. Ostatnia kolumna określa też wejście z nowej nawigacji. „Przepisać” oznacza nowy UX pod tym samym URL.

| ID | Istniejąca trasa | Web przed: funkcje i używane endpointy | Web po / osiągalność |
|---|---|---|---|
| W01 | `/` | Logowanie, obowiązkowy redirect do onboardingu, mapa/klastry/filtry, lokalizacja, modal zgłoszenia i szczegóły. `GET /users/me`, `GET /alerts/nearby?lat&lng&radius`; Socket.IO | Przepisać na „W okolicy”: mapa + lista + wyszukiwanie, główna zakładka |
| W02 | `/alerts` | Moje alerty i usuwanie; `GET /alerts/mine`, `DELETE A` | Zachować jako alias/przekierowanie do `/alerts/mine`, nie zmieniać po cichu w listę publiczną |
| W03 | `/alerts/mine` | Druga lista własnych alertów, statusy i usuwanie; te same endpointy | Kanoniczne „Moje zgłoszenia”, Profil → Moje zgłoszenia |
| W04 | `/family` | Grupy, utworzenie/dołączenie, lista członków, strefy dodawane formularzem współrzędnych, usuwanie stref, linki do czatu/planu/osoby; `GET/POST /family/groups`, `POST /family/groups/join`, `GET G/members`, `GET/POST G/geofences`, `DELETE G/geofences/:id` | Przepisać: zakładka „Bliscy”, wybór grupy, mapa/lista, sygnały/meldunki i dalsze narzędzia |
| W05 | `/family/[groupId]/members/[memberId]` | Kontakt, dane lokalizacji/baterii/aktywności, historia 24 h, prywatność, sygnał, usunięcie; `GET /family/groups`, `GET G/members`, `GET M/location/history`, `GET G/visibility/:id`, `GET G/visibility-matrix/:id`, `PUT G/visibility/:id`, `POST G/ping`, `DELETE M` | Przepisać, link z karty osoby; dodać role, śledzenie/ciszę, avatar i pełną historię/trasy. Sygnał dziś błędnie opisany jako indywidualny |
| W06 | `/family/[groupId]/chat` | Historia i wysyłka wiadomości, Socket.IO; `GET G/messages?limit=100`, `POST G/messages {body}`, `GET /family/groups`, `family:message` | Przepisać z zachowaniem realtime i grupy; Bliscy → grupa → Czat |
| W07 | `/family/[groupId]/planner` | Lista/dodanie/usunięcie wydarzenia; `GET/POST G/events`, `DELETE G/events/:id`; błędne `start_at` | Przepisać jako „Plan rodzinny”, poprawić kontrakt dat i przypomnienia |
| W08 | `/sos` | Przytrzymanie 3 s, przełączniki odbiorców/112, `POST /alerts`, `tel:112`; osobna strona bez AppLayout | Jeden współdzielony przepływ SOS; zawsze link globalny i Pomoc → SOS |
| W09 | `/sos/mental` | Telefony wsparcia i link do psychologa; brak API | Przepisać czytelność; Pomoc → „Wsparcie w kryzysie”, dostęp publiczny |
| W10 | `/escort` | Wybór grupy/opiekuna, nazwa celu/czas, start i anulowanie; `GET /family/groups`, `GET G/members`, `GET /escort/active`, `POST /escort/start`, `DELETE /escort/:id`. Brak wysyłania lokalizacji/zakończenia sukcesem, cel podstawiany z aktualnej pozycji | Pełny „Bezpieczny powrót”; Pomoc i Bliscy; osobny widok aktywnej sesji |
| W11 | `/fakecall` | Presety, timer, ekran połączenia; `accept()` jest pusty, brak rzeczywistego stanu odebrania; brak API | „Fałszywy telefon”: konfiguracja → dzwoni → rozmowa → koniec; Pomoc |
| W12 | `/pets` | Moje/rodzinne zwierzęta, formularz z mikroczipem, zaginięcie/odnalezienie/usuwanie, zaginione w pobliżu; `GET /pets/mine`, `GET /family/groups`, `GET /pets/lost/nearby`, `POST /pets`, `POST /pets/:id/lost`, `/found`, `DELETE /pets/:id` | Przepisać; Bliscy → Zwierzęta i Okolica → zaginione; dodać notatki/dom z mobile, zachować mikroczip |
| W13 | `/emergency` | Lista numerów 112, służb, pogotowi technicznych, WOPR/GOPR; `tel:`, brak API | Pomoc → Numery; publiczna i użyteczna bez mapy |
| W14 | `/aed` | Lista AED, odległość i zewnętrzna trasa piesza; `GET /aeds/nearby?lat&lng&radius_m&limit` | Pomoc → „Znajdź defibrylator” i warstwa mapy; wszystkie dostępne metadane |
| W15 | `/aqi` | Stacje GIOŚ, indeks, pomiary PM10/PM2.5/NO₂ i czas; `GET /aqi/nearby?lat&lng&radius_m&limit` | Okolica → Jakość powietrza; wspólna lokalizacja i powłoka |
| W16 | `/guide` | Rozwijany poradnik: 12 tematów odpowiadających M42; lokalne treści | Pomoc → Poradnik; wyszukiwanie w treści i linki do AED/numerów |
| W17 | `/cyber` | Linki PESEL/wycieki/CERT/8080 i zasady; brak API | Pomoc → „Bezpieczeństwo w sieci” oraz ustawienia |
| W18 | `/parental-controls` | Linki do zewnętrznych narzędzi i porad; brak API | Bliscy → „Ochrona dziecka w sieci” oraz Pomoc/ustawienia |
| W19 | `/profile` | Konto, promień, reputacja, udostępnienie lokalizacji; `PATCH /users/me`, **`POST /users/share-location`**, oczekuje `link` | Przepisać jako Profil; naprawić adres/odpowiedź linku, dodać meldunek i czytelne wejścia do wszystkich narzędzi |
| W20 | `/settings` | Język, motyw, lokalne przełączniki powiadomień, promień, nazwa/e-mail/hasło/usunięcie, linki; `PATCH /users/me`, **`PATCH /users/email`, `PATCH /users/password`, `DELETE /users/me`** | Profil → Ustawienia; naprawić metody/adresy, dodać telefon/KPP/dostępność/audio |
| W21 | `/permissions` | Wyświetlanie/żądanie zgód geolocation/notifications/camera/microphone; tylko API przeglądarki | Profil → Ustawienia → Uprawnienia; rozdzielić zgodę konta i uprawnienie urządzenia, połączyć z `/permissions` backendu |
| W22 | `/mode` | Zapis `PATCH /users/me {app_mode}`; brak wariantów pozostałych ekranów | Profil → Ustawienia → „Widok aplikacji”; faktyczne warianty dom/SOS |
| W23 | `/onboarding` | Slajdy, lokalny `besafe.onboarded`, pomiń/gotowe | Przepisać na opcjonalne wdrożenie + konfigurator, powrót z Ustawień; bez przechwytywania pilnego zadania |
| W24 | `/badges` | Siatka osiągnięć; **`GET /users/me/badges`**, oczekuje `badges` | Profil → Odznaki; naprawić na `/me/badges`, `earned/available` |
| W25 | `/ranking` | Ranking zgłoszeń/potwierdzeń/reputacji; `GET /users/ranking` | Profil → Społeczność → Ranking |
| W26 | `/referral` | Kod, link, liczba poleceń, kopiowanie/Web Share; `GET /users/me` | Profil → „Zaproś znajomych”; zachowanie kodu w rejestracji |
| W27 | `/news` | Lista aktualności; **`GET /community/posts`**, treść oczekiwana w `body` | Profil/Okolica → Aktualności; poprawić `/posts`, pole `content`, pełny odczyt |
| W28 | `/stats` | Liczby, trend/kategorie; `GET /alerts/stats?lat&lng&radius`; błędny kształt danych | Okolica → Statystyki; poprawny obszar i `totals/by_category/trend` |
| W29 | `/forgot-password` | Formularz prośby o reset; bezpośredni `fetch POST /api/v1/auth/forgot-password` | Publiczna; Logowanie → „Nie pamiętam hasła”; wspólny klient API |
| W30 | `/reset-password` | Token z URL, ustawienie hasła i wynik; bezpośredni `fetch POST /api/v1/auth/reset-password` | Publiczna; link e-mail → reset → logowanie; obsługa wygasłego tokenu |
| W31 | `/verify-email` | Token, potwierdzenie/wynik; bezpośredni `fetch POST /api/v1/auth/verify-email` | Publiczna; link e-mail i Profil → weryfikacja; ponowienie przez istniejące `/auth/resend-verification` |
| W32 | `/privacy`, `/terms` | Publiczne dokumenty prawne, linki/kontakt; brak API | Zachować oba URL; stopka, Profil, rejestracja |
| W33 | `/landing` | Strona informacyjna, sekcje funkcji/rodziny/kategorii/statystyk, link do web i APK; brak danych aplikacji z API | Publiczna strona informacyjna, spójna wizualnie; osiągalna z Pomoc → O aplikacji |
| W34 | `/admin` | Pulpit systemu, statystyki, zdrowie integracji, kopie, analityka; `GET /admin/me`, `/admin/stats`, `/admin/system`, `/admin/integrations/health`, `/admin/backup-status`, `/admin/analytics?days=14` | Zachować; Profil → Administracja dla uprawnionych; polskie nazwy |
| W35 | `/admin/users` | Wyszukiwanie użytkowników, blokowanie/odblokowanie z powodem, nadanie/odebranie admina; odczyt oznaczeń weryfikacji i dziecka; `GET /admin/users?q&limit`, `PATCH /admin/users/:id` | Zachować wszystkie obecne operacje i uprawnienia; Admin → Użytkownicy |
| W36 | `/admin/alerts` | Lista/filtrowanie statusu, usuwanie alertu; `GET /admin/alerts?status&limit`, `DELETE /admin/alerts/:id` | Admin → Alerty; szczegóły prowadzą do działającego URL |
| W37 | `/admin/reports` | Kolejka nadużyć z powodem/autorem, usunięcie alertu lub odrzucenie zgłoszenia, link alertu; `GET /admin/reports?status=pending`, `POST /admin/reports/:id/resolve` z `action: delete_alert` albo `dismiss` | Admin → Zgłoszenia nadużyć; zachować rozstrzyganie |
| W38 | `/admin/groups` | Lista grup/usuwanie; `GET /admin/groups`, `DELETE /admin/groups/:id` | Admin → Grupy |
| W39 | `/admin/control` | Konfiguracja wartości, flagi/segmenty, broadcast z potwierdzeniem; `GET /admin/config`, `/admin/flags`, `PUT /admin/config/:key`, `/admin/flags/:key`, `POST /admin/broadcast` | Admin → Konfiguracja; zachować pełny zakres operacji |
| W40 | `/admin/system` | Metryki systemu i odświeżanie; `GET /admin/system` | Admin → System |
| W41 | `/admin/audit` | Przegląd dziennika audytu: operacja, administrator, obiekt, payload i czas; `GET /admin/audit-log?limit=200` | Admin → Dziennik działań |

### Komponenty i stan web

| Źródło w `web/src/` | Inwentaryzowana odpowiedzialność |
|---|---|
| `components/ui/AppLayout.tsx`, `Sidebar.tsx` | Bramka logowania, desktopowy sidebar, hamburger i dolna nawigacja generowana z pierwszych pięciu linków. Home ma drugi, ręcznie złożony shell. Brak wspólnego SOS na wszystkich stronach |
| `components/map/MapView.tsx` | Mapa Google/Places library, klastry, markery i okręgi, filtry, automatyczne GPS/watchPosition, aktualizacje alertów; brak pola wyszukiwarki mimo załadowanej biblioteki Places |
| `components/alerts/CreateAlertModal.tsx` | Dwa kroki: kategoria i szczegóły; `POST /alerts` JSON, potem multipart `POST A/photo`. Brak anonimowości; błąd osobnego zdjęcia nie jest odpowiednio prezentowany |
| `components/alerts/AlertDetail.tsx` | `GET/POST A/comments`, `POST A/vote`, `PATCH A` opis/przedłużenie, `DELETE A`. Bez routowalnego ID, realtime komentarzy i zgłoszenia nadużycia; wynik głosu mylnie traktowany jako pełny Alert |
| `components/ui/SOSButton.tsx` | Osobne potwierdzenie i `POST /alerts` z tytułem `SOS!`; nie używa wspólnego flow `/sos` |
| `components/auth/LoginPage.tsx`, `contexts/AuthContext.tsx` | Przełączany formularz login/rejestracja; Google Identity Services, `POST /auth/login`, `/auth/register`, `/auth/google`, `GET /users/me`, token w localStorage, wylogowanie. Brak osobnych URL login/register, demo i kodu polecenia w rejestracji |
| `contexts/SocketContext.tsx` | `alert:new/updated/expired`, `family:location/geofence_exit/message`, emit `location:update`. Brakuje pokoi komentarzy, sąsiadów, sygnałów/meldunków i eskorty |
| `contexts/ThemeContext.tsx`, `lib/i18n.ts` | Jasny/ciemny/systemowy, lokalne języki; część stron ma literalny tekst zamiast tłumaczeń |
| `components/ui/AdminShell.tsx`, `hooks/useAdminAccess.ts`, `components/ui/Badge.tsx` | Shell administracji, role i dostęp z `GET /admin/me`, filtrowanie linków/operacji, odznaki roli/statusu. Część stron dodatkowo sprawdza `user.is_admin`; ujednolicić z uprawnieniami API, nie opierać nowego wejścia wyłącznie na tej fladze |
| `components/ui/Card.tsx`, `lib/markerIcons.ts`, `lib/constants.ts`, `types/index.ts` | Karty, wygląd mapy/ikon, konfiguracja, kategorie i typy. Typy części odpowiedzi nie odpowiadają backendowi; brakujących pól nie uzupełniać fikcyjnymi danymi |
| `app/layout.tsx`, `app/providers.tsx`, `app/landing/layout.tsx`, `app/globals.css` | Root, providerzy, font Inter, skrypt Google, publiczna strona informacyjna, globalne style. Metadane root obecnie angielskie |

## 5. Nowa architektura informacji

### 5.1. Nawigacja pierwszego poziomu

**Telefon (<1024 px):** dolny pasek z podpisami, bez hamburgera jako podstawowej nawigacji:

```text
┌─────────────────────────────────────────┐
│ be:Safe       Powiadomienia (2)    SOS   │
│ [Szukaj miejscowości lub adresu       ] │
│ [2 km ▾] [Kategorie ▾] [Warstwy ▾]       │
│                                         │
│                 MAPA                    │
│                              [Moja     ]│
│                              [pozycja  ]│
│ ┌─────────────────────────────────────┐ │
│ │ W okolicy · 4 alerty   Mapa / Lista │ │
│ │ Wypadek · 450 m · 8 min temu        │ │
│ │ Potwierdzenia: 3   Zobacz szczegóły │ │
│ └─────────────────────────────────────┘ │
│ W okolicy | Bliscy | + Zgłoś | Pomoc | Profil │
└─────────────────────────────────────────┘
```

Rysunek przedstawia hierarchię, nie finalne proporcje. Środkowe „Zgłoś” to przycisk, pozostałe elementy to linki. Wąski ekran nie ucina podpisów: krótka etykieta „Okolica” jest dopuszczalna w pasku, nagłówek strony brzmi „W okolicy”. Ekran 320 px ma układ pięciu równych pól i rosnącą wysokość, nie poziomy scroll.

**Desktop (≥1024 px):** zwarta lewa szyna 88–112 px, ikona + podpis, te same cztery sekcje. Górny pasek z wyszukaniem obszaru, dzwonkiem, jednym przyciskiem „Zgłoś” i wyraźnym SOS. Mapa zajmuje pozostały obszar, lista/szczegóły mają panel 360–420 px. Nie ma osobnego pulpitu statystyk przed mapą.

**Zgłoś:** jedna instancja globalna na danym breakpointcie. W formularzu ustępuje miejsca „Wyślij zgłoszenie”, aby nie uruchamiać drugiego formularza. **SOS:** stały link w nagłówku; przy modalnym formularzu ten sam dostęp znajduje się w aktywnej warstwie dialogu, nie za `inert` tłem. W trybie rozmowy/SOS dostępne jest widoczne wyjście i pomoc. Nawigacja nie zasłania klawiatury, przycisków ani Google attribution.

### 5.2. Drzewo funkcji

- **W okolicy `/`**
  - Mapa / Lista, obszar, promień, kategorie, sortowanie.
  - Alert `/alerts/[alertId]`, zgłoszenie `/report`.
  - Warstwy: alerty, AED, bliscy; skróty: `/aqi`, `/stats`, `/news`, `/neighborhood`, zaginione zwierzęta `/pets`.
- **Bliscy `/family`**
  - Moje grupy, utwórz/dołącz; grupa `/family/[groupId]`.
  - Osoba `/family/[groupId]/members/[memberId]`, historia, bezpieczne trasy, prywatność.
  - Czat, plan rodzinny, strefy, zwierzęta, zaproszenie, sygnał, meldunek, bezpieczny powrót.
- **Pomoc `/help`**
  - SOS `/sos`, numery `/emergency`, AED `/aed`, wsparcie `/sos/mental`.
  - Bezpieczny powrót `/escort`, fałszywy telefon `/fakecall`.
  - Poradnik `/guide`, cyber `/cyber`, narzędzia rodzicielskie `/parental-controls`, kontakt i `/landing`.
- **Profil `/profile`**
  - Moje zgłoszenia `/alerts/mine`; osiągnięcia `/badges`, ranking `/ranking`, zaproszenia `/referral`.
  - Ustawienia `/settings`, widok `/mode`, dostępność `/settings/accessibility`, uprawnienia `/permissions`, konfigurator `/onboarding`.
  - Konto, prywatność/udostępnianie lokalizacji, dokumenty `/privacy`, `/terms`, weryfikacja, wylogowanie.
  - Administracja `/admin` dla uprawnionych; wszystkie osiem istniejących stron panelu pozostaje dostępnych.
- **Dzwonek `/notifications`** — globalna skrzynka z linkami do konkretnych zadań, a nie kolejna główna zakładka.

### 5.3. Stan mapy i lista

- Oddzielić **moją pozycję**, **wybrany obszar oglądania** i **punkt zgłoszenia**. Przesunięcie mapy nigdy nie aktualizuje lokalizacji udostępnianej rodzinie.
- Po świadomym „Użyj mojej lokalizacji” pobrać GPS. Przy odmowie: „Wpisz miejscowość lub wskaż miejsce”. Nie opisywać Warszawy ani środka Polski jako pozycji użytkownika.
- Wyszukiwanie adresu przez Google Places/Geocoding w tej samej konfiguracji env; wynik można potwierdzić na mapie. Brak klucza/SDK: lista nadal działa dla znanej pozycji/obszaru; widoczny błąd mapy, bez nieskończonego spinnera.
- Lista i mapa używają jednego zestawu wyników i filtrów. Domyślnie aktywne alerty sortowane od najbliższego; opcja „Najnowsze”. Nowy alert nie przestawia nagle czytanej listy: pasek „Są nowe alerty — pokaż”.
- Promień np. 500 m / 1 / 2 / 5 / 10 km. Chwilowy zasięg przeglądania nie zmienia ustawienia powiadomień na koncie; zapis promienia konta wymaga jawnej akcji w Ustawieniach.
- Po przesunięciu: „Szukaj w tym obszarze”; nie wysyłać zapytania na każdą klatkę. Wyniki z obszaru A nie mogą nadpisać później wybranego B.
- Mobilny panel listy: zwinięty nagłówek, częściowy podgląd, pełna lista. Każdy stan dostępny także przyciskiem, bez obowiązku przeciągania. W trybie pełnej listy mapa nie zabiera miejsca treści.
- Karta: nazwa zdarzenia, miejsce, odległość od jasno określonego punktu, „8 min temu”, stan, liczba potwierdzeń; zdjęcie tylko jako pomoc. Nie pokazywać „50% wiarygodności” przy zerowej liczbie głosów ani „bezpiecznie” tylko dlatego, że nie ma zgłoszeń.
- URL może pamiętać `lat`, `lng`, `radius`, `categories`, `view`, `sort` jako stan UI; adapter mapuje promień do **`radius_m` w API**. Wstecz przywraca mapę, listę i scroll. Odpowiednik „start” mobile jest tu podsumowaniem listy, bez kopiowania jego punktacji 0–10.

## 6. Kluczowe przepływy

### 6.1. Przeglądanie okolicy

1. Po przywróceniu sesji użytkownik widzi ostatni wybrany obszar i listę. Przy pierwszym wejściu wybiera lokalizację lub wpisuje miejscowość.
2. `GET /alerts/nearby` z prawidłowym promieniem; po pierwszych danych pojawiają się karty i markery. Na wolnym połączeniu zachować ostatni odczyt z datą aktualizacji.
3. Wybór karty/pinu otwiera `/alerts/[alertId]` jako panel nad zachowaną mapą lub stronę na małym ekranie. Deep link sam pobiera `GET A`.
4. Filtry mają liczbę wyników i „Wyczyść”. Pusty wynik: „Brak aktywnych zgłoszeń w tym obszarze”, akcje zwiększenia obszaru/zmiany filtrów; nie „Tu jest bezpiecznie”.

**Gość:** obecne endpointy alertów wymagają auth. W wydaniu bez zmian backendu pokazujemy prostą stronę wejścia z logowaniem, rejestracją i publiczną pomocą, a mapę danych po zalogowaniu. Nie udajemy trybu publicznego ani nie logujemy automatycznie do współdzielonego konta demo. Publiczne przeglądanie danych jest osobną decyzją §9.2.

### 6.2. Szczegóły, potwierdzenie i komentarz

- Pierwszy ekran: co, gdzie, kiedy, aktywne/wygasłe/oczekujące na sprawdzenie, zdjęcie, dostępna informacja o autorze i potwierdzenia. Anonimowość respektuje `author: null`.
- „Potwierdzam” i „Już nieaktualne” są podpisanymi przyciskami, bez konieczności interpretowania kciuków. Krótkie potwierdzenie przed nieodwracalnym głosem; `POST A/vote`. API nie ma cofania, więc nie oferujemy „Cofnij”.
- Odpowiedź głosu zawiera liczniki, nie cały alert. Scalić ją z zachowanym `id` albo ponownie pobrać `GET A`; 409 → „Twój głos został już zapisany”.
- Komentarz: pole, „Dodaj komentarz”, stan wysyłania, tekst zachowany przy błędzie. `GET/POST A/comments`, dołączenie do pokoju alertu; deduplikacja po `id`. Nowa wiadomość nie zabiera fokusu.
- Menu „Więcej”: udostępnij link, otwórz miejsce w mapach, zgłoś nadużycie. Właściciel: edytuj opis, przedłuż o 3 godziny, usuń. Nie oferować edycji kategorii/tytułu/lokalizacji, których obecny `PATCH A` nie obsługuje.
- Usunięty/niedostępny alert ma własny stan i „Wróć do okolicy”. Nie przerzucać użytkownika na pusty ekran mapy.

### 6.3. Zgłoszenie w maksymalnie trzech krokach

**Wejście:** „Zgłoś” → `/report`; osoba zalogowana przechodzi poniższe trzy kroki. Dla gościa najpierw logowanie, z powrotem do zadania; auth nie jest ukrytym czwartym krokiem formularza i ma być komunikowane przed rozpoczęciem.

1. **„Co się stało?”** — duże wybory kategorii, wyszukanie po nazwie, „Inne”. Najczęstsze na początku, pozostałe rozwijane na tym samym kroku. Wybór podpowiada edytowalny tytuł, nie zamyka dostępu do żadnej kategorii.
2. **„Gdzie?”** — aktualna pozycja z dokładnością/czasem albo adres/punkt na mapie. „To tutaj” i „Zmień miejsce”. Nie wymaga ręcznego wpisania współrzędnych; alternatywa tekstowa dla mapy. Nie pobieramy obowiązkowo GPS, jeśli użytkownik już wskazał właściwe miejsce.
3. **„Sprawdź i wyślij”** — podsumowanie kategorii/miejsca, tytuł, opcjonalny opis i zdjęcie, czas ważności (domyślnie 3 h; opcje 1/3/6/12/24 h), „Ukryj moją nazwę przy zgłoszeniu”. Wszystkie opcje zaawansowane na tej samej stronie, bez dodatkowego obowiązkowego ekranu.

Wysłanie multipart `POST /alerts` z polami kontraktu i opcjonalnym `photo` (JPEG/PNG/WebP, do 5 MB). Lokalna kompresja i walidacja; plik można usunąć przed wysłaniem. Ukrycie nazwy nie jest zgłoszeniem bez konta: „Twoja nazwa nie będzie widoczna dla innych użytkowników”.

Po 201 aktywnym: „Zgłoszenie dodane” + szczegóły; po statusie `hidden`: „Zgłoszenie czeka na sprawdzenie”, link do Moich zgłoszeń. Przy 422 pozostawić formularz i wyjaśnić odrzucenie tekstu/zdjęcia. Przy 429 pokazać limit/czas dostępny z odpowiedzi. Sukces dopiero po odpowiedzi z `id`, nie po samym `await`.

Brak sieci: zachować szkic, „Nie wysłano — spróbuj ponownie”. Nie wysyłać automatycznie starych alarmów po powrocie połączenia. Przy niepewnym wyniku po timeout sprawdzić własne zgłoszenia przed ponowieniem; backend nie ma klucza idempotencji. Powrót do wcześniejszego kroku zachowuje dane; odejście proponuje zachowanie szkicu lub porzucenie.

### 6.4. SOS i szybka pomoc

1. Globalne **SOS** otwiera `/sos`. Na górze niezależna akcja **„Zadzwoń 112”**, numer do odczytania/skopiowania oraz **„Wyślij alarm be:Safe”**. Telefon nie czeka na logowanie, mapę, zgodę na mikrofon ani request backendu.
2. Alarm pokazuje rzeczywistą lokalizację lub prosi o wskazanie miejsca. Przy braku pozycji nadal dostępne 112 i kontakt z bliskimi; żadnego `0,0` ani automatycznej Warszawy. Wysłanie wymaga konta, ale jego brak nie zasłania numerów.
3. Domyślnie przytrzymanie 2 s z tekstowym postępem i anulowaniem po puszczeniu; równoważny przycisk **„Wyślij bez przytrzymywania”** otwiera krótkie potwierdzenie. W widoku seniora drugi sposób jest domyślny. Obsługa klawiatury i czytnika ekranu nie wymaga gestów czasowych.
4. Wspólny adapter wysyła `POST /alerts {category:'aggression', title:'🆘 SOS — Potrzebuję pomocy!', lat,lng,radius_m:500,…}`. Symbol w payloadzie jest częścią obecnej heurystyki backendu; UI może mieć zwykłą ikonę SVG.
5. Wynik: „Alarm zapisany” i czas/miejsce oraz „Zadzwoń 112” / „Skontaktuj się z bliskimi”. **Nie „Pomoc w drodze”**: API nie zwraca potwierdzenia przyjęcia przez służby ani odbiorców. Ekran nie zamyka się automatycznie po 2,5 s.

W wydaniu z niezmienionym kontraktem nie ma fikcyjnych przełączników odbiorców. Przed wysyłką krótko wyjaśnić: alarm trafia do społeczności zgodnie z ustawieniami odbiorców, backend dodatkowo obsługuje KPP i określone relacje rodzinne; samo członkostwo dorosłego w grupie nie gwarantuje osobnego alarmu dla całej rodziny. Bezpośredni telefon, czat i grupowy „Poproś o kontakt” są odrębnymi akcjami.

Audio: dobrowolne, do 30 s w aktywnej karcie przez `MediaRecorder`, lokalny zapis/usuwanie/cofnięcie zgody; nie blokuje alarmu. Brak wsparcia → jasny opis ograniczenia. Nie deklarować wysyłki dźwięku ratownikom.

Odebranie SOS rodziny: powiadomienie → `/family/[groupId]/sos/[alertId]` z osobą, czasem, ostatnią znaną lokalizacją, telefonem i dojściem. Widok pobiera dane, nie ufa aktualności samych współrzędnych w powiadomieniu.

### 6.5. Bliscy, grupa i prywatność

- Pierwsze wejście: dwie czytelne akcje „Utwórz grupę” i „Dołącz kodem”. Utworzenie wymaga nazwy; dołączenie kodu i roli. Po sukcesie od razu karta grupy i „Zaproś bliskich”.
- Role API: `parent`, `child`, `senior`, `guardian`, `family_member`, `partner`, `friend`, `other`. Etykiety po polsku: rodzic, dziecko, senior, opiekun, członek rodziny, partner/partnerka, znajomy, inna osoba. Właściciel grupy to dodatkowa relacja `owner_id`, nie nowa wartość roli.
- Karta osoby: imię, dostępny status/meldunek, „Lokalizacja sprzed 12 min”, bateria tylko jeśli otrzymana i udostępniona. Brak danych ≠ offline ≠ niebezpieczeństwo. Pozycja historyczna nie jest wyświetlana jako „na żywo”.
- „Jestem bezpieczny” zapisuje meldunek; widoczny dzisiejszy czas po potwierdzeniu API. „Poproś grupę o kontakt” wysyła `POST G/ping` i wyjaśnia, że dotyczy całej grupy. Odpowiedź `/family/pings/[pingId]` ma „Wszystko OK” / „Potrzebuję pomocy” i notatkę; stan wygasły/już obsłużony nie pozwala na pozorną ponowną odpowiedź.
- Czat i plan zachowują kontekst grupy. Daty prezentowane w `pl-PL`, dzień meldunku według `Europe/Warsaw`; plan zapisuje ISO i `starts_at`, nie `start_at`. Przypomnienie jest funkcją backendu/powiadomień, nie tylko timerem karty.
- Strefa: mapa lub wybór adresu → nazwa „Dom”/„Szkoła” i promień → zapis. Trasa: klikane punkty lub rysowanie, nazwa i tolerancja → zapis; dostępna lista punktów z „Usuń/Przesuń”, alternatywa dla przeciągania. „Bezpieczna trasa” oznacza trasę ustaloną przez opiekuna, nie gwarancję bezpieczeństwa.
- Widoczność danych: osobno „Kto widzi moje dane”, „Kto widzi dane dziecka”, „Ukryj moją lokalizację na…”. Używać `visibility`/`visibility-matrix` zgodnie z rolami. Brak odczytu macierzy własnej osoby dorosłej jest znanym ograniczeniem backendu, nie pustym przełącznikiem udającym stan.
- Zmiany roli/usunięcia członka lub grupy wyłącznie po stronie UI dla uprawnionych, z respektowaniem 403 z serwera. Nie dodawać „Opuść grupę”, jeśli nie ma wspieranej operacji dla tej roli.
- Przypięte trzy osoby zapisane na tym urządzeniu. Wstrzymanie/ukrycie lokalizacji widoczne w nagłówku grupy. Przeglądanie mapy nie może samo włączyć udostępniania pozycji.

**Bezpieczny powrót:** wybierz osobę, faktyczny punkt docelowy i czas → rozpocznij → widok nadawcy/obserwatora z ostatnią aktualizacją → „Dotarłem” (`PATCH complete`) lub „Anuluj” (`DELETE`). Lokalizacja tylko przy aktywnej karcie; przed startem: „Pozostaw tę stronę otwartą. W tle lokalizacja może przestać się aktualizować”. Zegar liczony z `started_at`, nie liczby tyknięć timera. Opóźnienie/SOS nie jest gwarantowanym wezwaniem służb.

### 6.6. Profil i ustawienia

Profil jest spisem zadań osobistych, nie dashboardem reputacji. Najpierw „Moje zgłoszenia”, „Ustawienia”, „Udostępnij lokalizację”; osiągnięcia niżej. Udostępnienie pokazuje czas wygaśnięcia i pole do skopiowania, `url` zwrócone przez API. Opcjonalna nowa strona odbiorcy `/track/[token]` korzysta z istniejącego publicznego odczytu.

Ustawienia mają sekcje: **Konto**, **Powiadomienia**, **Lokalizacja i prywatność**, **Wygląd i dostępność**, **Pomoc i dokumenty**. Promień powiadomień i telefon zapisują się na koncie; motyw/rozmiar tekstu/przypięcia to ustawienia urządzenia. Każda sekcja pokazuje, gdzie zapisano zmianę. Przełącznik dźwięku nie sugeruje obejścia wyciszenia systemowego.

Widoki Standardowy/Dla dziecka/Dla seniora zmieniają gęstość, język i ekspozycję meldunku/SOS, ale nie odbierają dostępu do funkcji ani nie zmieniają uprawnień. Zamiast powielać mylący „Telefon do lekarza → 112”, wyświetlać „Zadzwoń 112” oraz dostępne kontakty bliskich. Osobny zsynchronizowany kontakt lekarza wymaga danych, których obecne API nie ma.

Zmiana e-mail/hasła/usunięcie korzysta z właściwych metod i wymaganych haseł. Wylogowanie zatrzymuje socket, obserwację GPS i czyści prywatne cache. Eksport danych można dodać przez istniejące `GET /users/me/export`; w obu obecnych UI brak osobnego przycisku, więc to rozszerzenie użyteczności, nie nadrobienie mobile.

### 6.7. Logowanie, rejestracja i powrót do zadania

- Nowe `/login` i `/register`, wspólny formularz; e-mail + hasło, widoczność hasła, autouzupełnianie, Google, link resetu. Powrót do wewnętrznego `returnTo`, np. alertu lub formularza; nie przyjmować zewnętrznego adresu jako celu redirectu.
- Rejestracja: nazwa, e-mail, hasło, istniejące deklaracje/zgody mobile, opcjonalny kod polecenia (również z `?ref=`). Wszystkie opisy po polsku. Nie dodawać nowego modelu kont dziecka do istniejącego API; rozbieżność deklaracji 13+ i opisu trybu dziecięcego wymaga decyzji produktowej.
- Po zalogowaniu nie przechwytywać pilnego deep linku onboardingiem. Konfigurator opcjonalny, dostępny później; prośby o lokalizację, mikrofon i powiadomienia pojawiają się dopiero przy korzystaniu z funkcji.
- Reset: ogólne potwierdzenie wysłania e-maila, formularz z tokenem, stany token nieprawidłowy/wygasły, ponowna prośba. Weryfikacja analogicznie; resend przez `POST /auth/resend-verification`.
- Demo zachować jako jawnie opisany tryb demonstracyjny istniejącego `/auth/demo`, z osobnym wejściem na stronie informacyjnej/logowania; nigdy jako cichy substytut osobistego konta.
- Utrata sesji w trakcie: zachować niesekretny szkic, zalogować ponownie, wrócić. Błąd sieci podczas sprawdzania sesji nie oznacza automatycznego usunięcia tokenu.

## 7. System wizualny i dostępność

### Kierunek

Spokojny, czytelny interfejs narzędziowy. Jasne powierzchnie, mocna typografia, widoczne granice formularzy, ograniczona liczba kart. Bez ozdobnych orbów, dominujących gradientów, nieustannie pulsującego SOS i wielkich wskaźników „bezpieczeństwa”. Mapa ma pozostać rozpoznawalną mapą z czytelnymi drogami i nazwami.

### Tokeny kolorów (punkt startowy do sprawdzenia kontrastu)

| Rola | Jasny | Ciemny | Zastosowanie |
|---|---|---|---|
| Tło | `#F6F8FA` | `#101820` | Obszar aplikacji |
| Powierzchnia | `#FFFFFF` | `#192530` | Lista, panel, formularz |
| Powierzchnia drugorzędna | `#EAF0F5` | `#233340` | Sekcje, zaznaczenie neutralne |
| Tekst główny | `#142333` | `#F3F6F9` | Nagłówki i treść |
| Tekst pomocniczy | `#4B5F70` | `#B9C8D4` | Czas, opis, metadane |
| Linia dekoracyjna | `#CCD6DF` | `#415361` | Podział list |
| Granica kontrolki | `#687E90` | `#8197A8` | Formularze i obrysy przycisków |
| Akcja podstawowa | `#1559B7` | `#96C2FF` | Zgłoś, następny krok, linki; tekst odpowiednio biały / `#101820` |
| SOS / błąd | `#B42332` | `#FFB3B8` | SOS, istotny błąd; tekst odpowiednio biały / `#101820` |
| Sukces | `#176B45` | `#8FE0B7` | Potwierdzony zapis, nie gwarancja bezpieczeństwa obszaru |
| Uwaga | `#805500` | `#F3CC79` | Nieaktualne dane, ostrzeżenie; tekst/ikona, nie sam kolor |
| Focus | `#1559B7` | `#B7D5FF` | Obramowanie 3 px + odsunięcie 2 px |

Kolory kategorii nie oznaczają arbitralnie stopnia zagrożenia. Marker ma ikonę kategorii, obrys i stan zaznaczenia; klastry mają liczbę. SOS ma własny kształt/napis. Zmiana koloru akcentu w ustawieniach (parytet motywów) wybiera z ograniczonej palety spełniającej kontrast, nigdy nie zmienia semantyki czerwieni SOS.

### Typografia, odstępy, responsywność

- Inter z obsługą polskich znaków, lokalnie dostarczany przez istniejący `next/font`, fallback `system-ui`. Podstawowy tekst **16 px / 1,5**, pole formularza min. 16 px, pomocniczy 14 px, podpis nawigacji 12–14 px. Żadnych istotnych danych 8–10 px.
- Nagłówki: 24/30 px mobilnie i 28/36 px desktop; wagi 600/700, tekst 400/500. Bez całych akapitów wersalikami. Daty/liczby `Intl` z `pl-PL`, jednostki „450 m”, „1,2 km”, „3 godz.”.
- Skala odstępów 4/8/12/16/24/32/48 px; margines telefonu 16 px (12 przy 320 px), desktop 24–32 px. Formularz maks. 640 px; poradnik ok. 72 znaków w wierszu.
- Minimalny cel dotykowy **48 × 48 px**, odstęp min. 8 px; SOS/widok seniora min. 56 px. Radius kontrolek 10–12 px, panelu 16–20 px; pill tylko dla filtrów/chipów.
- Warstwy: mapa → panele → stała nawigacja → dialog; menu/bottom-sheet zarządzane wspólnie. `100dvh`, `env(safe-area-inset-bottom)`, właściwy padding dla dolnej belki, obsługa klawiatury ekranowej.
- Skeleton z ograniczonym ruchem; animacje 120–180 ms, `prefers-reduced-motion` usuwa ruch nieistotny. Ciemny motyw: system/jasny/ciemny, także mapa i portale, bez błysku jasnego tła po odświeżeniu.

### Biblioteka komponentów

`Button` (primary/secondary/quiet/danger), `IconButton` z nazwą, `TextField`, `TextArea`, `Select`, `Checkbox`, `Switch`, `FormField` (etykieta/opis/błąd), `Chip`, `SegmentedControl`, `Tabs`, `AlertCard`, `PersonCard`, `StatusBadge`, `EmptyState`, `ErrorState`, `Skeleton`, `InlineNotice`, `Toast`, `Dialog`, `BottomSheet`, `PageHeader`, `ConfirmAction`, `LocationPicker`.

Każdy komponent ma wariant loading/disabled/error i focus-visible. Toast potwierdza proste operacje; błędy formularza pozostają przy polu, SOS ma trwały ekran wyniku. Nie zastępować formularzy systemowym `prompt()` ani komunikatami `alert()`.

### Kryteria dostępności

- WCAG 2.2 AA: tekst 4,5:1 (duży 3:1), kontrolki/znaczące grafiki i focus 3:1; zmierzyć konkretne pary, nie zakładać zgodności tylko na podstawie tokenów.
- Cała lista, filtry, szczegóły i formularz dostępne klawiaturą; skip link „Przejdź do treści”, poprawne landmarki i kolejność nagłówków. Aktywny link `aria-current`.
- Dialog: nazwa, focus trap, powrót fokusu, zamknięcie Escape, przycisk zamknięcia. Modalny sheet nie zostawia aktywnych elementów za sobą. SOS osiągalne w bieżącej warstwie.
- Mapa ma równoważną listę. Ustawienie punktu/trasy możliwe bez drag-and-drop. Zdjęcia mają sensowny opis, ozdobne ikony są ukryte przed czytnikiem.
- `aria-live` tylko dla krótkich zmian stanu, bez ciągłego odczytu timera; błędy przez `role=alert`, wyniki zapisu przez `role=status`. Kolor/animacja nie są jedynym komunikatem.
- Tekst może rosnąć do 200%, zoom/reflow do 400%; formularze i nawigacja nie tracą treści. Wysoki kontrast i `forced-colors`; respektować preferencje systemowe, także gdy lokalna opcja ruchu jest wyłączona.
- Prosty język: „Bezpieczna strefa” zamiast geofence, „Przewidywany czas” zamiast ETA, „Plan rodzinny” zamiast planner, „Ostatnia aktualizacja” zamiast heartbeat.

## 8. Tabela zgodności funkcji

**J** = jest w kodzie; **C** = częściowe/usterka; **—** = brak UI; **B** = odpowiednik przeglądarkowy; **N** = funkcja natywna niedostępna w planowanym web; **K** = ograniczenie kontraktu, dokładnie opisane w §9. Planowane J oznacza pełny zakres zadania w granicach istniejącego API. Odniesienia wskazują endpointy w inwentarzu.

| Funkcja | Mobile | Web przed | Web po (plan) |
|---|---|---|---|
| Logowanie/rejestracja/sesja/wylogowanie (M01/W01) | J | J, rozproszona bramka | J, dedykowane URL i powrót do zadania |
| Google (M01) | J, obecny kontrakt profilowy | J, obecny kontrakt profilowy | J, jeden flow; uwaga kontraktowa §9.2 |
| Demo i kod przy rejestracji (M01/M32) | J | —; kod tylko do udostępnienia | J, jawne demo i `referral_code` |
| Reset hasła / weryfikacja e-mail | Prośba resetu; linki web | J | J, spójne publiczne strony i resend |
| Onboarding / konfigurator (M03/M04) | J/C zapis promienia | C, same slajdy | J, opcjonalny i możliwy do ponowienia |
| Standardowy/dziecko/senior (M05–M08/M15) | J | C, tylko zapis trybu | J, realne warianty przy zachowaniu funkcji |
| Mapa, klastry, pozycja, filtry (M09) | J | C, zły parametr promienia | J, wspólny stan listy i mapy |
| Wyszukiwanie miejsc / zmiana obszaru | J, Nominatim | — w UI | J, Google Places/Geocoding z env |
| Lista alertów w okolicy | J, przełączana | — jako pełny widok okolicy | J, domyślnie odsłonięty panel + pełna lista |
| Podsumowanie okolicy / najbliższy alert | J, umowny wynik 0–10 | C, głównie mapa | J, liczba/czas/obszar bez nieuzasadnionej oceny bezpieczeństwa |
| Wszystkie 21 kategorii i ostrzeżenia importowane | J | J | J, bez zmiany wartości API |
| Szczegóły z linku, zdjęcie, autor, ważność | J | C, tylko panel i uboższy model autora | J, `/alerts/[alertId]`, również dla linków admina |
| Potwierdzenie / nieaktualne | J/C obsługa błędów | C, błędny model wyniku | J, nieodwracalny głos, poprawne liczniki |
| Komentarze i realtime | J | C, HTTP bez pokoi | J, Socket.IO + odświeżanie awaryjne |
| Udostępnienie alertu / miejsca | J | C, brak pełnego flow linku alertu | B, Web Share → schowek → zaznaczalny link |
| Nadużycie / moderacja zgłoszenia | J | — po stronie użytkownika | J, istniejące `POST A/report` |
| Nowe zgłoszenie z tytułem/opisem/czasem | J/C obsługa wyniku | J, modal 2 kroki | J, ≤3 kroki i routowalny formularz |
| Korekta lokalizacji zgłoszenia | J | C, punkt wejścia z mapy | J, oddzielny krok „Gdzie?” |
| Kamera / zdjęcie z pliku | J | C, plik i oddzielny upload | B, file/capture, multipart, błąd zdjęcia widoczny |
| Anonimowa nazwa przy zgłoszeniu | J | — | J, `is_anonymous`; konto nadal wymagane |
| Moje zgłoszenia: lista/opis/+3 h/usuń | J | C, rozproszone listy/panel | J, jedna kanoniczna lista, stary alias zachowany |
| Odczyt ostatnich alertów przy słabej sieci | J, cache SQLite | — | B, mały cache danych z czasem odczytu; bez obietnicy map offline |
| SOS wysłanie / 112 | J/C obietnice i GPS fallback | C, dwa różne flow | J w granicach K: wspólny flow, brak fikcyjnej pozycji/odbiorców |
| Wybór odbiorców SOS / alarm całej rodziny | C/K, przełączniki nie sterują backendem | C/K | K, jawne ograniczenie; poprawne osobne kontakty, rozszerzenie §9.2 |
| Audio SOS, zgoda/usuwanie | J, lokalne | —, tylko prośba o mikrofon | B, MediaRecorder w aktywnej karcie, lokalne pliki; bez uploadu |
| Shake-to-SOS | J, otwiera SOS | — | N; stale dostępny przycisk SOS |
| Wykrywanie wypadku/upadku | J, sensor + anulowanie 30 s | — | N; brak pozornego przełącznika automatycznego wykrywania |
| Rodzinne grupy, zaproszenie, role przy dołączaniu | J | C, prostsze dołączenie | J, wszystkie role i kopiowanie kodu |
| Usuwanie grupy / członka, zmiana roli | J, właściciel | C, tylko część działań członka | J według uprawnień API |
| Mapa bliskich / przypięte 3 osoby | J | C, lista/linki | J, warstwa + lista; przypięcia lokalne |
| Avatar, śledzenie, cisza szkolna | J | C, głównie odczyt | J, upload i `PATCH M` z prawami właściciela/opiekuna |
| Historia lokalizacji z wyborem dnia | J | C, ostatnie 24 h | J, mapa + lista + data |
| Bezpieczne strefy, dodanie/usunięcie | J | C, formularz współrzędnych | J, wygodny wybór punktu/promienia |
| Bezpieczne trasy: rysuj/podgląd/włącz/usuń/alerty | J | — | J, nowe strony i edytor dostępny bez gestów |
| Widoczność pól / czasowe ukrycie lokalizacji | J/C/K | C, problem self matrix, brak czasowego ukrycia | J dla wspieranych macierzy i ghost; K dla odczytu własnej dorosłej macierzy |
| Lokalizacja na pierwszym planie | J | J przez socket na mapie | B, świadoma zgoda i aktywna karta; REST/socket zgodnie z zadaniem |
| Lokalizacja w tle, strefy/trasy przy zamkniętej aplikacji | Zależne od OS/zgód | — | B/K: zarządzanie i odbiór danych z mobile; własne śledzenie tylko aktywna karta |
| Wykrywanie podszytej lokalizacji | Heurystyka `isMocked` i skoków | — | N dla `isMocked`; walidacja czasu/dokładności, bez obietnicy równoważności |
| Bateria bliskich / własna bateria | Odczyt i `PUT battery` | Odczyt | B, odczyt wartości mobile; własny pomiar tylko jeśli wspierany, inaczej „Brak danych” |
| Sygnał do grupy i odpowiedź | J | C, wysłanie bez odpowiedzi, mylący target | J, jawnie grupowy sygnał, pending i `/family/pings/[pingId]` |
| Odbiór SOS bliskiego | J | — dedykowanego flow | J, powiadomienie → osoba/alert/mapa/telefon |
| Meldunek „Jestem bezpieczny”, stan dziś | J | — | J, profil/bliscy/widok uproszczony |
| Czat rodzinny | J | J | J, zachowanie kontekstu i stanu wysyłki |
| Plan rodzinny / przypomnienia | J | C, `start_at` zamiast `starts_at` | J, prawidłowe daty/przypomnienie/usuwanie |
| Czat sąsiedzki | J | — | J, `/neighborhood`, promień i realtime |
| Eskorta: start, obserwator, pozycja, dotarłem, anuluj | J, aktualizacje w widoku | C, start/anuluj | B, pełny cykl w aktywnej karcie, ograniczenie tła jawne |
| Fałszywy telefon | J, konfiguracja/odebranie | C, `accept()` puste | B, kompletna symulacja w aktywnej karcie, bez systemowego połączenia |
| Zwierzęta: profil, zaginięcie, odnalezienie, usuń | J | J, inne pola formularza | J, suma pól obu klientów bez utraty danych |
| Zaginione zwierzęta w okolicy | — osobnej listy | J | J, zachować przewagę web; kandydat do późniejszego wyrównania mobile |
| Zgłoszenie zauważenia zwierzęcia | — UI, API istnieje | — UI | Poza podstawowym parytetem; nie deklarować jako już istniejącej funkcji |
| Skrzynka powiadomień / licznik / usuń / odczyt | J | — | J, `/notifications`, §9 dla brakujących pobliskich wpisów bez FCM |
| Push i przejście do konkretnego zadania | J, FCM | —; tylko zgoda przeglądarki | B, in-app + Notifications API tam, gdzie działa; zamknięta karta wymaga osobnej integracji push |
| Alerty rodzinne/strefy/trasy/KPP/bateria/przypomnienia | J, odbiór FCM/inbox | C, część socketów | B, inbox + istniejące sockety/polling i linki typów |
| AED, nawigacja piesza | J, warstwa i metadane | J, lista | J, lista + mapa + dane dostępności |
| Jakość powietrza | J, widget najbliższej stacji | J, więcej stacji/pomiarów | J, zachować dane web i skrót na mapie |
| Numery / wsparcie psychiczne / poradnik | J | J | J/B, czytelne publiczne treści, `tel:` z numerem do skopiowania |
| Cyber / zewnętrzna kontrola rodzicielska | J | J | J, te same cele i jawne linki zewnętrzne |
| Reputacja / odznaki / ranking / polecenia | J | C, odznaki i niepełne polecenia | J, poprawny kontrakt, druga warstwa Profilu |
| Aktualności / statystyki | J | C, endpointy/model | J, pełna treść i poprawny zakres danych |
| Profil: nazwa/e-mail/hasło/telefon/KPP/usunięcie | J | C, błędne operacje i brak telefonu/KPP | J, właściwe API i stany błędów |
| Czasowy link lokalizacji | J, zewnętrzna strona backendu | C, zły endpoint i pole | J/B, poprawny `url`, opcjonalny nowy odbiorca `/track/[token]` |
| Motyw/kolor, język, dostępność | J | C, motyw i języki bez pełnej a11y | J, polski domyślny/kompletny, zachować istniejący wybór języka jako opcję; pełna a11y |
| Zgody konta vs uprawnienia urządzenia | J/C | C, wyłącznie browser | B, oba stany osobno, tylko obsługiwane capabilities |
| Biometryczna blokada aplikacji | J | — | N w niezmienionym kontrakcie; hasło/Google i blokada urządzenia. WebAuthn to osobne rozszerzenie |
| Widgety Androida / deep linki | J | — | B, skróty wewnątrz aplikacji i adresy URL; nie obiecywać natywnych widgetów |
| Aktualizacja APK / wersja | J, natywna | Link pobrania na landing | B, aktualizacja web przez wdrożenie/odświeżenie, link pobrania mobile |
| Analityka użycia | `POST /events` | — klienta zdarzeń | J opcjonalnie przez istniejące API, bez lokalizacji/treści alarmów w zdarzeniach UX |
| Dokumenty / kontakt / informacja o aplikacji | J | J | J, publiczne i odkrywalne |
| Administracja i wszystkie `/admin/*` | —, web jest narzędziem administratora | J | J, zachować cały zakres; nie wymaga nowego panelu Flutter |

**Granica parytetu:** przeglądarka ma pokryć zadania mieszkańca i opiekuna dostępne w Flutterze, a dodatkowe możliwości web (administracja, lista zaginionych zwierząt, strony z linków e-mail) pozostać. Funkcje N nie są „wdrożone” przez dodanie nieaktywnego przełącznika. W miejscu, gdzie użytkownik ich szuka, pokazać krótki opis i dostępny odpowiednik. Pełny audyt dwukierunkowy mobile może być kolejnym etapem, ale ten plan nie zmienia Fluttera.

## 9. Kontrakt API: korekty klienta i jawne ograniczenia backendu

### 9.1. Naprawy web bez zmiany backendu

| Obszar | Obecne wywołanie/model | Poprawny istniejący kontrakt |
|---|---|---|
| Okolica i statystyki | Parametr `radius` | `radius_m`; osobno promień przeglądania i konta |
| Statystyki | `today/week/total`, `top_categories`, `trend.date` | `totals.{today,week,total}`, `by_category`, `trend[].day` |
| Głos | `POST vote` traktowany jako pełny Alert | Zwraca `confirms,denies,trust_score,author_id`; scalić lub `GET A` |
| Autor alertu | `author_username` | `author` z danymi lub `null` dla anonimowego; zachować `is_anonymous` |
| E-mail | `PATCH /users/email` | `POST /users/me/email {email,password}` |
| Hasło | `PATCH /users/password` | `POST /users/me/password {current_password,new_password}` |
| Usunięcie konta | `DELETE /users/me` | `POST /users/me/delete {password}` |
| Udostępnienie | `POST /users/share-location`, pole `link` | `POST /users/me/share-location {hours}`, pola `url,expires_at`; publiczny `GET /track/:token` pod API |
| Aktualności | `/community/posts`, `body` | `GET /posts`, `content`, `image_url`; szczegóły `GET /posts/:id` |
| Odznaki | `/users/me/badges`, `{badges}`, `code/earned_at` | `GET /me/badges`, `{earned,available}`, `id/awarded_at` |
| Plan rodzinny | `start_at/end_at/created_by` | `starts_at/ends_at/author_id`, `reminder_minutes_before` |
| Rodzina | Typy ograniczone do `parent` i `child`, niekiedy `role` grupy | Osiem ról z §6.5; grupa zwraca `your_role`, właściciel `owner_id` |
| Sygnał | `{target_user_id,kind}` i komunikat do jednej osoby | Obecny `POST G/ping` ignoruje te pola i wysyła do grupy; wyświetlać grupowy zakres |
| SOS na mapie | Tytuł `SOS!`, fallback `0,0` | Ta sama usługa co `/sos`, `aggression` + `🆘`, faktycznie wskazane współrzędne |
| AED — korekta audytu w etapie 3 | Wcześniejsze sekcje tego planu wskazywały `radius_m` | Zamontowany `routes/aeds.js` odczytuje **`radius`**, maks. 20 km, i zwraca do 200 urządzeń; nie obsługuje `limit`. Nowy web używa `radius=5000`. Alerty i AQI nadal używają `radius_m` |
| Zwierzęta — korekta audytu w etapie 3 | `is_lost`, `lost_since`, `lost_lat/lost_lng` | Faktyczna odpowiedź: `status: home/lost`, `lost_at`, `last_seen_lat/last_seen_lng`, `last_seen_at`, `lost_description`; profil zawiera również `home_lat/home_lng`, `owner_id` |
| Zdjęcie | JSON + osobny upload bez obsługi błędu | Preferowany pojedynczy multipart `POST /alerts`; istniejący `POST A/photo` zachować do kontrolowanej próby dodania zdjęcia do istniejącego alertu |
| Auth z e-maila | `fetch('/api/v1/…')` zależny od proxy | Ten sam env-aware `api` co reszta, te same ścieżki i payloady |
| Uprawnienia | Jedynie browser permission | Istniejące `GET/PUT /permissions` jako zgoda konta, osobno rzeczywisty stan OS/przeglądarki |

Źródła weryfikacji: `backend/src/index.js`, `routes/alerts.js`, `users.js`, `family.js`, `community.js`, `auth.js`, `permissions.js`. Nie dodawać aliasów backendu, aby utrzymywać błędne wywołania web.

Nie wszystkie odpowiedzi są pełnymi modelami, a helper zwraca `error` zamiast rzucać wyjątek. Nowe adaptery mają jawnie rozpoznawać sukces/błąd, nullable pola i różnice GET/mutacji. Powiadomienie zapisane w skrzynce nie dowodzi dostarczenia push; `fcm_sent` nie dowodzi odczytu. GET-y mogą mieć ograniczony retry, mutacje SOS/głosu/zgłoszenia nie są automatycznie powtarzane.

### 9.2. Potrzebne zmiany backendu — tylko jeśli rozszerzamy wskazane obietnice

Poniższe pozycje **nie są częścią implementacji z niezmienionym kontraktem**. Każda ma jawny wariant możliwy teraz. Nie oznaczać jej jako pełnego J przed rozwiązaniem.

| ID | Ustalenie i źródło | Co można teraz | Zmiana wymagająca osobnego etapu |
|---|---|---|---|
| K01 | `alerts.js`: SOS rozpoznawane heurystycznie; osobne rodzinne odbiorniki tylko dla `child` z tracking i `parent`; brak pól zakresu | Zachować payload, opisać rzeczywiste zachowanie; bez pozornych przełączników; telefon/czat/sygnał grupowy osobno | Jawny typ SOS, odbiorcy rodzinni dla właściwych ról, wybór kanałów/zakresu i status przyjęcia. Wymaga wspólnej aktualizacji klientów |
| K02 | `services/fcm.js`: `notifyUser` zapisuje inbox bez tokenu, ale `notifyNearbyUsers` wybiera wyłącznie użytkowników z `fcm_token`; jeden token na użytkownika | Centrum istniejących powiadomień; lokalna lista nowych alertów z Socket.IO i `GET /alerts/new?since` podczas aktywnej sesji, odróżniona od serwerowego inboxu | Utrwalanie pobliskich alertów niezależne od FCM; wiele urządzeń/subskrypcji, usuwanie subskrypcji, Web Push/service worker. Nie nadpisywać tokenu mobile tokenem web |
| K03 | Routery alertów/AED/AQI/community wymagają auth | Pomoc statyczna i 112 publiczne; dane po logowaniu | Publiczny odczyt mapy bez konta, jeżeli produkt go zatwierdzi; nie obchodzić auth po stronie web |
| K04 | `family.js`: `GET visibility-matrix` dostępne parent/guardian i tylko dla targetu child; self dorosły otrzyma 403, choć `PUT visibility` dopuszcza własne udostępnianie | Pełna macierz dla dziecka, odczyt „jak widzę osobę”, czasowe ghost; nie wyświetlać domniemanych bieżących ustawień własnej macierzy | Odczyt „jak inni widzą mnie” z właściwą autoryzacją. Potrzebny do pełnego dwukierunkowego ustawienia prywatności dorosłego |
| K05 | `POST G/ping` zawsze cała grupa; `DELETE M` owner-only | „Poproś grupę o kontakt”; usuwanie przez właściciela | Sygnał indywidualny lub samodzielne opuszczenie grupy przez zwykłego członka wymaga rozszerzenia. Nie obiecywać dziś |
| K06 | API nie ma danych kontaktu lekarza; mobile „Lekarz” wybiera 112 | Uczciwy numer 112 i kontakty bliskich z telefonu profilu | Zsynchronizowany osobny kontakt alarmowy/lekarza, jeśli ma wejść do zakresu |
| K07 | Oba klienty Google przekazują dane profilu; backend przyjmuje profil, nie pełny nowy flow weryfikacji tożsamości. WebAuthn nie istnieje | Opisać i zachować bieżącą integrację jako istniejącą, nie nazywać jej passkey ani biometrią | Weryfikacja tokenu Google po stronie serwera oraz ewentualne WebAuthn wymagają osobnego projektu auth/kontraktu; nie „naprawiać” wyłącznie dekodowaniem JWT w UI |
| K08 | Brak idempotencji mutacji oraz operacji odwołania wysłanego SOS jako komunikatu do odbiorców | Blokada podwójnego submitu, jawny niepewny wynik i ponowny odczyt; zwykłe usunięcie własnego alertu nie jest odwołaniem alarmu | Idempotency key, stan i potwierdzenia alarmu/odwołania, jeśli produkt ich wymaga |
| K09 | `users.js` zwraca link lokalizacji z historyczną domeną; istnieje backendowy `/track/:token` | Pokazać zwrócony URL; nowy webowy odbiorca może odczytywać istniejące API przy poprawnym routingu wdrożenia | Konfigurowalny origin linku w backendzie, jeśli linki mają zawsze kierować do nowego web |
| K10 | `notifications.js`: `/read` oznacza **wszystkie** wpisy; brak endpointu odczytu pojedynczego wpisu | Jawna akcja „Oznacz wszystkie jako przeczytane”, usuwanie pojedynczego wpisu i całej skrzynki; otwarcie szczegółów nie udaje zapisu odczytu jednego wpisu | Endpoint odczytu pojedynczego powiadomienia, jeśli taki stan ma być synchronizowany |
| K11 | `family.js`: `PATCH safe-routes/:rid` obsługuje nazwę, tolerancję i aktywność, ale nie geometrię; brak `GET` pojedynczej trasy | Szczegóły wybierane z listy istniejącego `GET`; punkty tworzone w edytorze przed zapisem, dla zmiany przebiegu utworzenie nowej trasy | Zmiana punktów zapisanej trasy wymaga rozszerzenia `PATCH`; nie wysyłać ignorowanego `points` |
| K12 | `pets.js`: brak `GET /pets/:id` dostępnego dla obserwatora spoza grupy | Link powiadomienia otwiera właściwą listę i obszar; jeśli zwierzę nie jest już zaginione lub opuściło obszar, nie jest widoczne na liście. Członek grupy ma `/pets/mine` | Osobny odczyt statusu zwierzęcia z powiadomienia, jeżeli ma działać także po odnalezieniu dla osób spoza grupy |

**Etap 2 — uwagi implementacyjne (3 listopada 2026):** rdzeń okolicy nie wymaga nowych endpointów. Nadal obowiązują K03 (dane mapy wymagają konta), K07 (zachowany profilowy kontrakt Google) i K08 (brak idempotencji). Po niepewnym wyniku zgłoszenia klient odczytuje `/alerts/mine` i wymaga sprawdzenia listy przed ponowieniem; nie jest to gwarancja idempotencji. Zdjęcie jest częścią multipart `POST /alerts`, więc klient nie deklaruje sukcesu osobnego, niedokończonego uploadu. Nie dodano zmian do backendu.

**Etap 3 — uwagi implementacyjne:** wszystkie podstawowe funkcje wskazane w tym etapie (meldunki, sygnały i odpowiedzi, historia, strefy, trasy, sąsiedzi, eskorta, zwierzęta i skrzynka) mają istniejące endpointy. Backend i mobile pozostają bez zmian. Własna macierz udostępniania dorosłego jest jawnie niedostępna w UI (K04); dostępne są macierz dziecka dla rodzica/opiekuna i czasowe ukrycie lokalizacji. Sygnał jest zawsze grupowy (K05). Powiadomienia serwerowe odczytywane są okresowo oraz po zdarzeniach socketu; nieutrwalane zdarzenia tej sesji są oznaczone osobno. Notifications API wymaga świadomego opt-in i nie oznacza Web Push po zamknięciu karty (K02). Nagranie SOS jest dobrowolne, lokalne, do 30 s, z odtwarzaniem/pobraniem/usunięciem i zatrzymaniem po ukryciu karty; nie ma endpointu uploadu audio.

**Ograniczenia platformowe, których sam backend nie naprawi:** niezawodna lokalizacja po zamknięciu karty, shake/crash detection w tle, natywne widgety, blokada całej aplikacji biometrią. Nie są ukrytymi obietnicami kolejnego endpointu.

**Spójność produktów do rozstrzygnięcia:** deklaracja wieku w rejestracji vs opis trybu dziecięcego; zakres SOS dla seniora/opiekuna; różnice w opisach godzin infolinii między klientami. Treści pomocy powinny otrzymać wspólne źródło i datę weryfikacji w implementacji. Dokument nie stwierdza aktualności zewnętrznych numerów/godzin na podstawie samego kodu.

## 10. Konkretny plan implementacji pod `web/src`

Poniższe pliki są **planowane**, nie tworzone w etapie badawczym. Zachować Next.js 16 / React 19 / Tailwind 4 i obecny klient API. Wdrażać pionowymi przepływami z działającym końcem zadania, nie samymi pustymi stronami.

### 10.1. Powłoka, stan i prymitywy

| Działanie | Pliki | Odpowiedzialność |
|---|---|---|
| Zmienić | `app/layout.tsx`, `app/providers.tsx`, `app/globals.css` | Polskie metadata, tokeny Tailwind 4, poprawne wysokości i dark mode, wspólni providerzy |
| Dodać | `components/layout/AppShell.tsx`, `AppTopBar.tsx`, `MobileTabBar.tsx`, `DesktopRail.tsx`, `PageHeader.tsx`, `PublicShell.tsx` | Jedna responsywna powłoka; nawigacja, SOS, dzwonek, primary action; publiczna pomoc/auth |
| Zmienić | `components/ui/AppLayout.tsx`, `components/ui/Sidebar.tsx` | Migracyjne delegowanie do nowej powłoki; potem usunąć dublowanie renderowania. Żaden URL nie zależy od pozostawienia starego wyglądu |
| Dodać | `lib/navigation.ts`, `lib/routes.ts` | Jeden rejestr sekcji, polskie etykiety, linki i bezpieczny `returnTo`; jawny alias `/alerts` |
| Dodać | `components/ui/Button.tsx`, `IconButton.tsx`, `FormField.tsx`, `TextField.tsx`, `TextArea.tsx`, `Select.tsx`, `Checkbox.tsx`, `Switch.tsx` | Kontrolki z etykietą, błędem, disabled/loading/focusem |
| Dodać | `components/ui/Chip.tsx`, `SegmentedControl.tsx`, `Tabs.tsx`, `Dialog.tsx`, `BottomSheet.tsx`, `ConfirmAction.tsx` | Filtry i dostępne warstwy/akcje; jeden mechanizm fokusu i scroll-lock |
| Dodać | `components/ui/EmptyState.tsx`, `ErrorState.tsx`, `Skeleton.tsx`, `InlineNotice.tsx`, `Toast.tsx`, `StatusBadge.tsx` | Jednolite stany, bez maskowania błędu jako pustej listy |
| Zmienić | `components/ui/Card.tsx`, `Badge.tsx` | Nowe tokeny i kontrast, zachowanie odznak ról/statusów admina |
| Zmienić | `lib/constants.ts`, `lib/api.ts`, `types/index.ts`, `lib/i18n.ts` | Klucz Maps tylko env, timeout i status błędu bez zmiany kontraktu; poprawne typy odpowiedzi, kompletna polska treść |
| Dodać | `lib/api/alerts.ts`, `family.ts`, `account.ts`, `community.ts`, `notifications.ts`, `escort.ts`, `pets.ts` | Typowane operacje domenowe korzystające z obecnego transportu; poprawki z §9.1 w jednym miejscu |
| Dodać | `lib/capabilities.ts`, `lib/format.ts`, `lib/storage.ts`, `lib/alert-cache.ts` | Wykrywanie wsparcia, polskie formaty, preferencje urządzenia i cache z czasem/TTL |
| Zmienić | `contexts/AuthContext.tsx`, `ThemeContext.tsx`, `SocketContext.tsx` | Sesja i powrót do zadania, motyw; brakujące zdarzenia i cleanup; mapować payloady, nie domyślać się nowych eventów |
| Dodać | `contexts/LocationContext.tsx`, `PreferencesContext.tsx`, `NotificationsContext.tsx`, `DraftContext.tsx` | Rozdzielenie pozycji/obszaru, preferencje i app_mode, skrzynka, szkic zgłoszenia |
| Dodać | `hooks/useForegroundLocation.ts`, `useNearbyAlerts.ts`, `useAlertDetails.ts`, `useCapabilities.ts`, `useUnsavedChanges.ts` | Geolokalizacja świadoma widoczności karty, zapytania/odświeżanie, nieutracony formularz |

Ścieżki skrócone w komórce dziedziczą katalog ostatniej poprzedzającej je pełnej ścieżki w tej komórce (np. `family.ts` w wierszu adapterów oznacza `web/src/lib/api/family.ts`, a `AuthGate.tsx` po `components/auth/AuthForm.tsx` oznacza `web/src/components/auth/AuthGate.tsx`).

### 10.2. Mapa, alerty, auth i pomoc

| Działanie | Pliki pod `web/src/` | Zakres |
|---|---|---|
| Przepisać | `app/page.tsx`, `components/map/MapView.tsx`, `lib/markerIcons.ts` | Nowy map-first home i odchudzona warstwa Google Maps |
| Dodać | `components/map/NearbyExplorer.tsx`, `NearbyAlertList.tsx`, `AreaSearch.tsx`, `MapFilters.tsx`, `MapLayers.tsx`, `LocationPicker.tsx`, `MapUnavailable.tsx`, `MapProvider.tsx` | Lista/sheet, wyszukiwanie, wybór miejsca, env-only SDK, fallback |
| Dodać / przepisać | `components/alerts/AlertCard.tsx`, istniejący `AlertDetail.tsx`, nowy `AlertActions.tsx`, `AlertComments.tsx`, `ReportAbuseDialog.tsx`, `ReportWizard.tsx`, `ReportSuccess.tsx` | Wszystkie operacje alertu i formularz 3-krokowy |
| Zmienić | `components/alerts/CreateAlertModal.tsx` | Przejściowy wrapper wspólnego ReportWizard; jedna logika niezależnie od wejścia |
| Dodać | `app/report/page.tsx`, `app/alerts/[alertId]/page.tsx` | Deep link formularza/szczegółów; ten sam komponent panelu i strony |
| Przepisać | `app/alerts/mine/page.tsx`, `app/alerts/page.tsx` | Pełne własne zgłoszenia i zgodny alias |
| Dodać | `app/login/page.tsx`, `app/register/page.tsx`, `components/auth/AuthForm.tsx`, `AuthGate.tsx`, `ReturnToTask.tsx` | Czytelne auth z kontynuacją zadania |
| Zmienić | `components/auth/LoginPage.tsx`, `app/forgot-password/page.tsx`, `app/reset-password/page.tsx`, `app/verify-email/page.tsx`, `app/onboarding/page.tsx` | Wspólne formularze, właściwy klient API, kod polecenia/demo, opcjonalne wdrożenie |
| Dodać | `app/help/page.tsx`, `components/safety/SosEntry.tsx`, `SosFlow.tsx`, `SosResult.tsx`, `EmergencyCall.tsx`, `AudioRecorder.tsx`, `lib/sos.ts` | Centrum pomocy, jeden kontrakt SOS i osobny telefon 112 |
| Przepisać | `app/sos/page.tsx`, `components/ui/SOSButton.tsx` | Oba wejścia używają SosFlow/SosEntry; brak dwóch implementacji wysyłki |
| Przepisać | `app/sos/mental/page.tsx`, `app/emergency/page.tsx`, `app/aed/page.tsx`, `app/aqi/page.tsx`, `app/guide/page.tsx`, `app/cyber/page.tsx`, `app/parental-controls/page.tsx` | Użyteczność, dostęp publiczny treści statycznych, dane po auth, wspólny shell |
| Dodać | `components/safety/AedList.tsx`, `AirQualitySummary.tsx`, `HelpArticle.tsx`, `lib/content/help.pl.ts` | Wspólne treści i dane w mapie oraz stronach |
| Przepisać | `app/fakecall/page.tsx`; dodać `components/safety/FakeCallFlow.tsx` | Rzeczywiste stany konfiguracja/dzwoni/odebrane/zakończone |

### 10.3. Bliscy i brakujące strony parytetu

| Działanie | Pliki pod `web/src/` | Zakres |
|---|---|---|
| Przepisać | `app/family/page.tsx`; dodać `app/family/[groupId]/page.tsx` | Lista grup i routowalny kontekst wybranej grupy |
| Dodać | `components/family/GroupSwitcher.tsx`, `GroupOverview.tsx`, `PersonCard.tsx`, `FamilyMap.tsx`, `CreateGroupDialog.tsx`, `JoinGroupDialog.tsx`, `InviteCode.tsx` | Tworzenie/dołączenie/zaproszenie, mapowanie ról i lista |
| Przepisać | `app/family/[groupId]/members/[memberId]/page.tsx` | Profil siebie/dziecka/dorosłego z faktycznie dostępnymi danymi |
| Dodać | `components/family/MemberProfile.tsx`, `MemberActions.tsx`, `MemberPrivacy.tsx`, `GhostModeControl.tsx`, `CheckinAction.tsx`, `GroupPingAction.tsx` | Role/avatar/tracking/cisza, prywatność, meldunek, sygnał grupowy |
| Dodać | `app/family/[groupId]/members/[memberId]/history/page.tsx`, `components/family/LocationHistory.tsx` | Historia z wyborem daty, lista i mapa |
| Dodać | `app/family/[groupId]/geofences/page.tsx`, `components/family/GeofenceEditor.tsx` | Lista/dodanie/usunięcie stref; edytor jako sheet/sekcja tej strony |
| Dodać | `app/family/[groupId]/members/[memberId]/safe-routes/page.tsx`, `app/family/[groupId]/members/[memberId]/safe-routes/new/page.tsx`, `app/family/[groupId]/members/[memberId]/safe-routes/[routeId]/page.tsx` | Lista, rysowanie i szczegóły/alerty przy trasie; toggle/usuwanie |
| Dodać | `components/family/SafeRouteList.tsx`, `SafeRouteEditor.tsx`, `SafeRouteDetails.tsx` | Wspólny model punktów i dostępne operacje edytora |
| Przepisać | `app/family/[groupId]/chat/page.tsx`, `app/family/[groupId]/planner/page.tsx` | Czat i plan z właściwym kontraktem dat/przypomnień |
| Dodać | `components/family/FamilyChat.tsx`, `FamilyPlanner.tsx`, `EventForm.tsx` | Cienkie strony, wspólne stany wysyłki/wyników |
| Dodać | `app/family/pings/[pingId]/page.tsx`, `app/family/[groupId]/sos/[alertId]/page.tsx`, `components/family/PingResponse.tsx`, `FamilySosDetail.tsx` | Brakujące reakcje na powiadomienia |
| Przepisać / dodać | `app/escort/page.tsx`, `app/escort/[sessionId]/page.tsx`, `components/safety/EscortSetup.tsx`, `EscortSession.tsx`, `hooks/useEscortSession.ts` | Start → obserwowanie → complete/cancel, GET sesji i foreground GPS |
| Przepisać | `app/pets/page.tsx`; dodać `components/family/PetForm.tsx`, `PetList.tsx`, `LostPetAction.tsx` | Pola obu klientów, zaginione w pobliżu, pełny stan błędu |
| Dodać | `app/neighborhood/page.tsx`, `components/community/NeighborhoodChat.tsx` | Czat sąsiedzki z obszarem i socketem/pollingiem |
| Dodać | `app/notifications/page.tsx`, `components/notifications/NotificationBell.tsx`, `NotificationList.tsx`, `lib/notification-routes.ts`, `lib/browser-notifications.ts` | Skrzynka i mapowanie typów; Notifications API tylko przy dostępności; bez domniemanej gwarancji push w tle |

### 10.4. Profil, pozostałe strony i administracja

| Działanie | Pliki pod `web/src/` | Zakres |
|---|---|---|
| Przepisać | `app/profile/page.tsx`, `app/settings/page.tsx`, `app/permissions/page.tsx`, `app/mode/page.tsx` | Konto, preferencje i realne warianty; naprawy endpointów |
| Dodać | `app/settings/accessibility/page.tsx`, `components/settings/AccountSettings.tsx`, `NotificationSettings.tsx`, `PrivacySettings.tsx`, `AccessibilitySettings.tsx`, `PermissionSettings.tsx`, `AppearanceSettings.tsx` | Sekcje używane w ustawieniach i konfiguratorze; audio lokalne/wycofanie zgody |
| Dodać | `components/home/ModeQuickActions.tsx`, `components/profile/ShareLocationPanel.tsx`, `app/track/[token]/page.tsx` | Widok dziecka/seniora, czasowy link i odbiorca na istniejącym API |
| Przepisać | `app/badges/page.tsx`, `app/ranking/page.tsx`, `app/referral/page.tsx`, `app/news/page.tsx`, `app/stats/page.tsx` | Poprawne dane, odkrywalność i nowy system wizualny |
| Dodać | `app/news/[postId]/page.tsx` | Pełna treść aktualności i link do konkretnej wiadomości |
| Zmienić | `app/privacy/page.tsx`, `app/terms/page.tsx`, `app/landing/page.tsx`, `app/landing/layout.tsx` | Publiczna powłoka, czytelność, nawigacja, weryfikacja tekstów/domen w osobnym przeglądzie treści |
| Zmienić | `components/ui/AdminShell.tsx`, `hooks/useAdminAccess.ts` | Nowe tokeny, polskie etykiety, „Wróć do aplikacji”, SOS; wejście na podstawie `/admin/me` |
| Zmienić | `app/admin/page.tsx`, `app/admin/users/page.tsx`, `app/admin/alerts/page.tsx`, `app/admin/reports/page.tsx`, `app/admin/groups/page.tsx`, `app/admin/control/page.tsx`, `app/admin/system/page.tsx`, `app/admin/audit/page.tsx` | Migracja wyglądu/stanu błędów i działające linki, zachowanie wszystkich operacji i kontroli uprawnień |
| Dodać | `app/error.tsx`, `app/not-found.tsx`, `app/loading.tsx` | Czytelny stan globalny, powrót do mapy i dostęp do SOS |

**Nowe adresy konieczne dla wygodnego parytetu:** `/report`, `/alerts/[alertId]`, `/notifications`, `/neighborhood`, `/family/[groupId]`, historia/strefy/bezpieczne trasy rodziny, odpowiedź na ping, odbiór SOS, sesja eskorty i dostępność. `/help`, `/login`, `/register` porządkują istniejące zadania. `/news/[postId]` oraz `/track/[token]` domykają odczyt i udostępnianie przy użyciu już istniejących endpointów.

### 10.5. Kolejność wdrożenia i zależności

1. **Kontrakt i fundament:** typy/adaptery z §9.1, env-only Maps, prymitywy, shell, rejestr wszystkich URL, sesja, możliwość wejścia do SOS/112. Gotowe, gdy każda stara trasa ma osiągalne wejście i poprawny stan auth/błędu.
2. **Rdzeń okolicy:** mapa/lista/wyszukiwanie, szczegóły z URL, zgłoszenie 3-krokowe z anonimowością/zdjęciem, głosy/komentarze/nadużycia, własne alerty. Naprawić status `hidden` i odświeżanie po mutacji.
3. **Pomoc i reakcje:** jeden SOS, numery/AED/poradnik, centrum powiadomień i deep linki, proste warianty dziecko/senior. Brak uprawnień GPS lub sesji nie blokuje telefonu.
4. **Bliscy:** grupy/role/osoby, mapa i świeżość danych, strefy/historia/trasy, prywatność w granicach K04, meldunki/sygnały/odpowiedzi, czat i plan.
5. **Domknięcie parytetu:** eskorta, fałszywy telefon, audio foreground, zwierzęta, sąsiedzi, konto/uprawnienia/dostępność, odznaki/aktualności/statystyki/polecenia, odbiorca linku lokalizacji.
6. **Regresja całej aplikacji:** administracja, publiczne strony, wszystkie stare URL, jasny/ciemny/systemowy, klawiatura/czytnik, mobile/desktop, utrata sieci/sesji. K01–K09 nie mogą być zamaskowane jako „gotowe”.

Web Push po zamknięciu karty/PWA wymaga również zasobu service workera i konfiguracji wdrożenia; nie jest ukrytym plikiem do utworzenia w tym etapie. Bazowy zakres wykorzystuje in-app/Notifications API i istniejące transporty. Ewentualna praca poza `web/src` musi być jawnie dopisana w kolejnym etapie.

### 10.6. Stan implementacji — etap 2 (fundament i rdzeń okolicy)

Wdrożone w `web/`:

- Tokeny jasnego/ciemnego motywu, wspólne kontrolki i stany, natywny modalny `Dialog` z obsługą fokusu/Escape, niemodalny `BottomSheet` z przyciskami trzech wysokości, toast i skip link.
- Jedna powłoka w root providerach, dolna nawigacja mobilna, szyna 104 px i górny pasek na desktopie. SOS dostępne także przed logowaniem; w formularzu globalne „Zgłoś” ustępuje akcji wysłania. Dawne `AppLayout`/`Sidebar` nie renderują drugiej nawigacji. Huby Pomoc/Profil i rejestr tras obejmują stare adresy; trasy dynamiczne rodziny pozostają osiągalne z grup/osób, a administracja opiera wejście na `/admin/me`.
- `/`: wspólne wyniki mapy i listy, 21 kategorii, promienie 500 m / 1 / 2 / 5 / 10 km przez `radius_m`, sortowanie, wyszukiwanie adresu, jawny GPS, szukanie po przesunięciu, lista niezależna od dostępności SDK. Stan obszaru/filtrów w URL i sessionStorage; nowości z socketu nie przestawiają samoczynnie listy. Przeglądanie nie wysyła lokalizacji rodziny.
- `/alerts/[alertId]` oraz panel: odczyt szczegółów/zdjęcia/autora/statusu, potwierdzenie głosu z ponownym GET, obsługa 409, komentarze z pokojem Socket.IO i odczytem awaryjnym, udostępnienie z tekstowym fallbackiem, nadużycia i operacje właściciela. `/alerts` przekierowuje do `/alerts/mine`.
- `/report`: trzy kroki, wszystkie kategorie, wybór adresu/GPS/punktu i tekstowa alternatywa współrzędnych, tytuł z kategorii, opis, czas ważności, anonimowość, walidacja i zmniejszanie zdjęcia, pojedynczy multipart, stany moderacji/limitów/niepewnego wyniku. Szkic tekstowy zapisuje się na bieżącej karcie; zdjęcie trzeba dodać ponownie po opuszczeniu strony. Nawigacja oferuje zachowanie/porzucenie szkicu, SOS pozostaje bezpośrednio dostępne.
- `/login`, `/register` i publiczne wejście `/`, istniejący Google Sign-In, bezpieczny `returnTo`, kod polecenia, deklaracja wieku i regulamin; brak automatycznego przechwytywania przez onboarding. Reset/weryfikacja używają wspólnego klienta API i tokenów UI.
- Dzwonek ma działającą podstawową skrzynkę `/notifications` i licznik. SOS używa jednego jawnie potwierdzanego wysłania z rzeczywistym miejscem, poprawnym payloadem i niezależnym 112. Pełny etap reakcji/powiadomień (§10.5.3) pozostaje osobnym zakresem.
- Korekty klienta z §9.1 objęły również e-mail/hasło/usunięcie konta, link lokalizacji, aktualności, odznaki, statystyki oraz nazwy pól dat planu rodzinnego. Naprawiono zastane błędy lint bez wyłączania reguł.

**Weryfikacja automatyczna:** `node --test tests/core.test.mjs` sprawdza kontrakt alertów i transportu (w tym błędy/limity i brak automatycznych powtórzeń), wewnętrzne cele logowania, kompletność rejestru stron, env-only Maps oraz kontrast podstawowych par tokenów w obu motywach. Wymagane polecenia odbioru: `npm run lint` i `npm run build` w `web/`.

Wynik końcowy sesji: **7/7 testów zaliczonych**, **lint: 0 błędów, 7 ostrzeżeń**, **build: sukces**, `git diff --check`: bez błędów. Ostrzeżenia dotyczą elementów `img` oraz zastanego, nieużywanego typu Google; reguły lint pozostały włączone.

**Pozostała walidacja i następne etapy:** rzeczywiste logowanie Google, mapa z kluczem wdrożeniowym i mutacje na środowisku testowym nie zostały wykonane w tej sesji. Potrzebny jest przegląd przeglądarkowy przy 320–1440 px, z klawiaturą/czytnikiem i klawiaturą ekranową. Wnętrza starszych ekranów są objęte nową powłoką, ale ich pełne przeprojektowanie, wszystkie typy deep linków powiadomień, gest SOS/audio, funkcje rodziny z etapów 3–5 i trwały cache offline nie są deklarowane jako ukończone w etapie 2.

### 10.7. Stan implementacji — etap 3 (pomoc, reakcje i Bliscy)

- **Okolica:** kompaktowe wyszukiwanie i ikona filtrów, modalny BottomSheet dla promienia/kategorii/sortowania, mniejszy przełącznik mapy/listy i podgląd pierwszej karty. Start z Warszawą jako „wybranym obszarem”, zoom 12, promień 5 km; GPS bez pytania wyłącznie po odczycie istniejącej zgody `granted`. Jawny deep link obszaru ma pierwszeństwo; przy braku zgody działa obszar domyślny i przycisk lokalizacji. Ikona lokalizacji to inline SVG.
- **Pomoc:** duże kafle huba; jeden `SosFlow` i adapter `lib/sos.ts`, przytrzymanie 2 s z anulowaniem, równoważne potwierdzenie klawiaturą, domyślne potwierdzenie dla seniora, stale dostępny telefon 112 i trwały wynik. Numery/wsparcie/poradnik/cyber/narzędzia rodzicielskie używają tokenów i publicznej powłoki. Poradnik ma wyszukiwanie. Godziny infolinii nie są deklarowane na podstawie rozbieżnych historycznych treści; podane są linki operatorów.
- **AED i powietrze:** wybór obszaru bez wymuszania GPS, stan błędu/ponowienia/pustej listy, AED mapa + lista od najbliższego, operator/godziny/wnętrze i trasa piesza. AQI zachowuje wszystkie dostępne pomiary i datę odczytu.
- **Powrót i telefon:** faktyczny punkt docelowy, obserwator inny niż użytkownik, aktywne sesje i deep link sesji; GPS tylko po jawnym włączeniu w widocznej karcie, `PATCH location`, `PATCH complete`, osobna anulacja przez `DELETE`, odczyt obserwatora i zdarzenia socketu. Fałszywy telefon: konfiguracja → odliczanie → połączenie → rozmowa z zegarem → koniec, anulowanie i sprzątanie timerów.
- **Powiadomienia:** skrzynka, licznik dzwonka, oznacz wszystkie/usuń jedno/usuń wszystkie, reakcja na socket i polling. Mapowanie powiadomień SOS, ping, trasa, bateria, czat, plan, eskorta, zwierzęta i meldunki do kontekstu zadania. Broadcast pozostaje treścią skrzynki.
- **Bliscy:** lista grup, tworzenie i dołączanie z ośmioma rolami, grupa pod własnym URL, kod do skopiowania/zaznaczenia, mapa i karty osób z czasem pozycji/aktywności i baterią. Meldunki, pending pings, odpowiedzi/wygaśnięcie, sygnał grupowy, trzy przypięcia lokalne, świadome GPS i ghost mode. Profil osoby: role/uprawnienia, avatar, tracking/cisza, macierz dziecka i usuwanie przez właściciela. Historia z datą/mapą/listą, strefy z wyborem miejsca, tworzenie tras z punktami adres/mapa/współrzędne oraz dostępnym porządkowaniem/usuwaniem punktów, lista/szczegóły/aktywność/usuwanie i alerty przy trasie. Czat z zachowaniem tekstu po błędzie i odświeżaniem; plan z `starts_at/ends_at`, przypomnieniami i usuwaniem własnych wydarzeń.
- **Zwierzęta i sąsiedzi:** poprawne statusy zwierząt, pola obu klientów (w tym mikroczip/notatki/dom), zaginięcie ze wskazanym miejscem i opisem, odnalezienie, usuwanie przez właściciela, zaginione w okolicy na mapie/liście i zgłoszenie zauważenia. Czat sąsiedzki 2 km używa istniejącego GET/POST i socketu z odświeżaniem serwerowego obszaru.
- **Wspólne mechanizmy:** `useApiResource` ignoruje spóźnione wyniki po zmianie obszaru/ścieżki; `useMutation` blokuje podwójne wysyłanie i zachowuje błąd. `PlacesMap`, `AreaControl`, `ConfirmAction`, `GroupHeader` i istniejące prymitywy są współdzielone. Rejestr nawigacji obejmuje wszystkie nowe URL, także ochronę sesji przy deep linkach. Brak nowych zależności.

**Walidacja do wykonania na środowisku testowym:** rzeczywiste mutacje rodzinne/SOS, mapy z kluczem wdrożeniowym, uprawnienia przeglądarek, przegląd przy 320–1440 px oraz czytnik ekranu. W tej sesji nie wykonywano wysyłek do produkcyjnego API. Ograniczenia kontraktu K01–K12 nie są deklarowane jako usunięte.

**Weryfikacja końcowa etapu 3:** `npm run lint` — 0 błędów, 7 ostrzeżeń; `npm run build` — sukces; `node --test tests/core.test.mjs` — 9/9 testów zaliczonych (w tym payload SOS oraz deep linki rzeczywistych typów powiadomień); `git diff --check` — bez błędów. Testy kontraktu korzystają z atrap transportu, nie wysyłają alarmów ani mutacji na serwer.

## 11. Kryteria odbioru następnych etapów

### Sprawdzenie zadaniowe z użytkownikami

Prototyp sprawdzić na 5–8 polskojęzycznych osobach spoza zespołu technicznego, w tym seniorze i osobie używającej większego tekstu. Polecenia: „Sprawdź, co wydarzyło się przy Twojej ulicy”, „Zgłoś oblodzony chodnik”, „Potwierdź zdarzenie”, „Poproś bliskich o kontakt”, „Znajdź pomoc bez GPS”. Mierzyć samodzielne ukończenie i pomyłki; nie podpowiadać nazw przycisków. Cel zgłoszenia: większość badanych kończy bez pomocy w ≤60 s, z maksymalnie trzema ekranami formularza; cel otwarcia SOS: jeden wybór z dowolnej sekcji. To cele walidacji, nie wynik już wykonanego badania.

### Scenariusze funkcjonalne do weryfikacji przy implementacji

- Przejść wszystkie stare URL z §4 bez 404, także deep link przed logowaniem. Alias `/alerts` prowadzi do własnych zgłoszeń; `/admin/reports` otwiera działające szczegóły.
- Zalogowany/wylogowany, prawidłowy/wygasły token, brak dostępu do grupy/admina, konto o każdej wspieranej roli; `app_mode` nie zwiększa uprawnień.
- Dla każdej kluczowej mutacji: sukces, 401/403/409/422/429, timeout, offline i niepewny wynik; brak fałszywego komunikatu sukcesu.
- Rzeczywisty promień mapy/statystyk, odmowa GPS, brak SDK/klucza, zmiana obszaru w trakcie requestu, przywracanie listy przez Wstecz. Dane z mapy nie są zapisywane jako pozycja użytkownika.
- Zgłoszenie ze zdjęciem i bez, anonimowe, oczekujące na moderację, utrata sieci i odzyskanie szkicu. Głos nie gubi `id`; komentarze realtime nie dublują się.
- SOS wyłącznie na środowisku testowym: otwarcie ≠ wysłanie, 112 nie czeka na API, brak fikcyjnych współrzędnych, jeden request mimo wielokrotnego dotyku, obsługa klawiaturą i widok seniora.
- Powiadomienia: alert, rodzinne SOS/ping/odpowiedź, strefa/trasa, bateria/KPP, plan, meldunek, eskorta, zwierzęta, broadcast. Kliknięcie wraca do właściwego zadania, nie zawsze do `/family`.
- Eskorta poprawnie rozróżnia dotarcie i anulowanie; utrata widoczności karty oznacza możliwy brak aktualizacji pozycji. Fałszywy telefon faktycznie przechodzi do stanu rozmowy.
- Uprawnienia przeglądarki `granted/denied/prompt/unsupported`, Notifications API niedostępne, MediaRecorder niedostępny, brak schowka/Web Share, brak aplikacji telefonicznej; sensowny odpowiednik każdego stanu.
- Dostępność przy 320/375/768/1024/1440 px, powiększeniu tekstu, widocznej klawiaturze, ciemnym motywie, reduced motion, klawiaturze i czytniku ekranu.
- Panel admina: role/dostępy, lista i wyszukiwanie, moderacja, grupy, config/flags/broadcast, metryki i audyt; same nowe kolory nie mogą usunąć operacji.

Przy realizacji uruchamiać istniejące lint/type/build oraz testy adekwatne do zmienionych przepływów. Szczególnie potrzebne będą testy integracyjne adapterów na rzeczywistych kształtach odpowiedzi oraz E2E rdzenia użytkownika i zachowania starych tras. W tym etapie dokumentacyjnym nie uruchamiano testów aplikacji ani operacji produkcyjnych.

**Definicja zakończenia redesignu:** każde zadanie w tabeli parytetu ma działający przepływ lub jawny, użyteczny odpowiednik B/N/K; wszystkie dotychczasowe trasy są dostępne, mapa/lista/zgłoszenie/SOS są zrozumiałe bez instrukcji, a UI nie deklaruje rezultatów, których API lub przeglądarka nie potwierdzają.
