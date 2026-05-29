# be:Safe — Figma Export (44 ekranów)

Auto-wygenerowane szkielety wszystkich ekranów aplikacji **be:Safe** w formacie SVG, gotowe do importu do Figmy.

## Pliki

| Plik | Opis |
|------|------|
| `besafe_frames.svg` | **Wszystkie 44 ekrany w siatce 7×7** — jeden plik, każdy frame to nazwane `<g>` |
| `besafe_frames_individual/` | **44 osobne SVG** (jeden plik = jeden ekran) — gdy chcesz importować selektywnie |
| `index.html` | Podgląd w przeglądarce — `xdg-open index.html` |
| `generate_frames.py` | Script źródłowy — możesz re-runować po zmianach |

## Jak zaimportować do Figmy

### Opcja A — Wszystkie naraz (zalecane)

1. Otwórz Figmę (web lub desktop), w **dowolnym pliku**.
2. **File → Import** lub przeciągnij `besafe_frames.svg` na canvas.
3. Figma utworzy 44 grupy z nazwami (`01_onboarding`, `02_mode_picker`, …).
4. Zaznacz każdą grupę i **Frame Selection** (`Cmd/Ctrl+Alt+G`) jeśli chcesz zamienić na Frame.

### Opcja B — Po jednym

Zaznacz w eksploratorze pliki z `besafe_frames_individual/` i przeciągnij — Figma utworzy osobny obiekt dla każdego.

### Opcja C — Konwersja na Frames (skrót)

Po imporcie zaznacz wszystkie obiekty (`Cmd/Ctrl+A`), w prawym panelu kliknij **"Frame selection"**. Zachowuje nazwy.

## Lista 44 ekranów

| # | Nazwa frame | Sekcja | Plik Flutter |
|---|-------------|--------|-------------|
| 1 | `01_onboarding` | Onboarding | `onboarding/onboarding_screen.dart` |
| 2 | `02_mode_picker` | Onboarding | `mode/mode_picker_screen.dart` |
| 3 | `03_login` | Auth | `auth/login_screen.dart` |
| 4 | `04_forgot_password` | Auth | `auth/forgot_password_screen.dart` |
| 5 | `10_home_normal` | Home | `home/home_screen.dart` |
| 6 | `11_home_kids` | Home | `home/home_kids_screen.dart` |
| 7 | `12_home_senior` | Home | `home/home_senior_screen.dart` |
| 8 | `20_map` | Mapa | `map/map_screen.dart` |
| 9 | `21_alert_detail` | Alerty | `alerts/alert_detail_screen.dart` |
| 10 | `22_alert_create` | Alerty | `alerts/create_alert_screen.dart` |
| 11 | `23_alerts_my` | Alerty | `alerts/my_alerts_screen.dart` |
| 12 | `24_alerts_stats` | Alerty | `alerts/stats_screen.dart` |
| 13 | `30_family` | Rodzina | `family/family_screen.dart` |
| 14 | `31_family_group` | Rodzina | `family/family_group_screen.dart` |
| 15 | `32_family_chat` | Rodzina | `family/family_chat_screen.dart` |
| 16 | `33_family_planner` | Rodzina | `family/family_planner_screen.dart` |
| 17 | `34_family_sos` | Rodzina | `family/family_sos_screen.dart` |
| 18 | `35_member_profile` | Rodzina | `family/member_profile_screen.dart` |
| 19 | `36_child_profile` | Rodzina | `family/child_profile_screen.dart` |
| 20 | `37_safe_routes` | Rodzina | `family/safe_routes_screen.dart` |
| 21 | `38_draw_safe_route` | Rodzina | `family/draw_safe_route_screen.dart` |
| 22 | `39_add_geofence` | Rodzina | `family/add_geofence_screen.dart` |
| 23 | `40_location_history` | Rodzina | `family/location_history_screen.dart` |
| 24 | `41_ping_response` | Rodzina | `family/ping_response_screen.dart` |
| 25 | `50_sos_normal` | SOS | `sos/sos_screen.dart` |
| 26 | `51_sos_kids` | SOS | `sos/sos_kids_screen.dart` |
| 27 | `52_sos_senior` | SOS | `sos/sos_senior_screen.dart` |
| 28 | `60_profile` | Profil | `profile/profile_screen.dart` |
| 29 | `61_badges` | Profil | `profile/badges_screen.dart` |
| 30 | `62_ranking` | Profil | `profile/ranking_screen.dart` |
| 31 | `63_referral` | Profil | `profile/referral_screen.dart` |
| 32 | `70_settings` | Ustawienia | `settings/settings_screen.dart` |
| 33 | `71_permissions` | Ustawienia | `permissions/permissions_screen.dart` |
| 34 | `72_parental_controls` | Ustawienia | `parental_controls/parental_controls_screen.dart` |
| 35 | `80_safety_guide` | Bezpieczeństwo | `safety/safety_guide_screen.dart` |
| 36 | `81_emergency_numbers` | Bezpieczeństwo | `emergency/emergency_numbers_screen.dart` |
| 37 | `82_cyber_safety` | Bezpieczeństwo | `cyber_safety/cyber_safety_screen.dart` |
| 38 | `83_mental_health_sos` | Bezpieczeństwo | `mental_health/mental_health_sos_screen.dart` |
| 39 | `90_news` | Społeczność | `community/news_screen.dart` |
| 40 | `a0_escort` | Funkcje | `escort/escort_screen.dart` |
| 41 | `a1_fake_call_setup` | Funkcje | `fake_call/fake_call_setup_screen.dart` |
| 42 | `a2_fake_call_incoming` | Funkcje | `fake_call/fake_call_incoming_screen.dart` |
| 43 | `a3_pets` | Funkcje | `pets/pets_screen.dart` |
| 44 | `b0_legal` | Inne | `legal/legal_screen.dart` |

## Design system referencyjny

**Serenity Guard** (v83+ iOS-style):

- **Tło ekranu**: `#F2F2F7` (groupedBackground)
- **Karty**: `#FFFFFF` (groupedSurface), radius **10pt** (inset grouped) / **16pt** (inline)
- **Tekst primary**: `#1A2027` (navy)
- **Tekst secondary**: `#8E8E93` (secondaryLabel)
- **Separator**: `#C6C6C8`
- **Akcent**: `#9DF4CB` mint, `#9EEBEC` aqua
- **Destructive / SOS**: `#FF7A7A` coral
- **Font**: Inter (system fallback do SF Pro)
- **Typography**: largeTitle 34/700, iosBody 17/400, iosFootnote 13/400, iosSectionHeader 13/600 UPPERCASE +0.5

## Viewport

- **390 × 844** (iPhone 14 Pro / typowy Android)
- Każdy frame ma label pod spodem z nazwą + opisem PL
- Pod każdym ekranem zaokrąglony **dock 64pt** (5 ikon: Mapa/Home/Rodzina/SOS/Profil)

## Co dalej

1. Otwórz `index.html` w przeglądarce — zobaczysz podgląd wszystkich 44 ekranów.
2. Zaimportuj `besafe_frames.svg` do Figmy.
3. Nazwy frames zostają — możesz organizować je w sekcje wg `data-section`.
4. Po designie wystarczy że spójniesz Variants/Components w Figmie i rozwiniesz każdą stronę.

---

**Regenerowanie:** `python3 generate_frames.py`

---

## Realne dane

Frames zawierają **prawdziwe dane** użytkownika `meneswczesny@gmail.com` (m3n3s, admin, reputacja 104) pobrane z prod DB `alertmap@16.192.31.100`:

- **Profil** (`60_profile`): email `meneswczesny@gmail.com`, kod referral `M3N3S`, promień 2.5 km
- **Grupy rodzinne** (`30_family`): 6 grup które posiada — `Kasty przychlasty` (2), `Grupa1` (7), `Grupa` (2), `grupa` (2), `Rodzina Testowa E2E` (4), `Babcia Solo` (2)
- **Członkowie Grupa1** (`31_family_group`): piotr (parent), Marcin (parent), m3n3s (parent), Michael Skweres (parent), Marek Kołodziejczyk (parent), Justyna Rewers (child), Heluss Menelek (child) — z poziomami baterii
- **Profil dziecka** (`36_child_profile`): Heluss Menelek (child, bat 98%, online)
- **Profil członka** (`35_member_profile`): Marcin (parent, bat 100%, online)
- **Moje alerty** (`23_alerts_my`): 5 ostatnich z 8 zgłoszonych przez m3n3s — Agresywna grupa pod ratuszem, Krzyki w parku, Bójka przed dworcem, Zatrzymanie przy ratuszu, Patrol policji
- **Statystyki** (`24_alerts_stats`): 8 alertów, 34 potwierdzenia, +104 reputacji
- **Ranking** (`62_ranking`): top 5 — m3n3s 104pkt (Ty), Test/Dupowaty/Tadeusz/AlertBot 100pkt
- **Logowanie** (`03_login`): email `meneswczesny@gmail.com` pre-wypełnione
- **Czat** (`32_family_chat`): rozmowa z Marcin/Heluss/Justyna z Grupa1
- **Historia lokalizacji** (`40_location_history`): trasa Heluss 24h (dom→szkoła→boisko→sklep→dom)
- **Planner** (`33_family_planner`): wizyta lekarska Heluss, trening Justyny, urodziny Marcina
