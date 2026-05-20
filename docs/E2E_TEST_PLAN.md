# be:Safe — Plan testów E2E (persona-based)

> **Wersja:** v48 (production)
> **Framework:** Patrol 4.5.0 (integration_test + native automation)
> **Device farm:** 2 fizyczne telefony (Moto G84 5G USB + Realme RMX3741 WiFi-TLS)
> **Backend:** prod `https://besafe.org.pl` z dedykowanymi kontami testowymi

## Cele

1. **Pokrycie funkcjonalne** — każdy z 28 ekranów + każda akcja użytkownika.
2. **Pokrycie persona-based** — 4 typowe profile użytkowników z różnymi oczekiwaniami.
3. **Audyt UX** — mierzymy czas dotarcia do funkcji, liczbę tapów, miss-rate, czytelność.
4. **Audyt wizualny** — screenshot po każdym kroku, golden compare per theme.
5. **Regression** — uruchamiane przed każdym release’em (v49+).

## Persony

| ID | Persona | Wiek | Tech | Kontekst |
|---|---|---|---|---|
| **P1** | **Rodzic techniczny** | 35 | high | Konfiguruje grupę, geofences, bezpieczne trasy, ustawienia FCM. Korzysta z każdej zaawansowanej funkcji. |
| **P2** | **Rodzic nietechniczny** | 42 | low-mid | Chce zainstalować, dołączyć do grupy zaproszeniem QR, dostać powiadomienie o dziecku, kliknąć zadzwoń. Wszystko musi być max 2 tapy. |
| **P3** | **Dziecko** | 10 | low | Otwiera apkę z onboardingu, klika SOS, odpowiada na ping rodzica „WSZYSTKO OK / POTRZEBUJĘ POMOCY”. Nie powinno mieć dostępu do parental controls. |
| **P4** | **Senior (babcia)** | 68 | very low | Loguje się, ogląda mapę alertów w okolicy, klika „Zadzwoń 112” w SOS, opcjonalnie dołącza do rodzinnej grupy. Touch-targety ≥48dp, etykiety tekstowe wszędzie. |

## Konta testowe (do zaseedowania)

| Username | Email | Hasło | Rola | Telefon |
|---|---|---|---|---|
| `parent_tech` | parent.tech@test.besafe.org.pl | Test123! | parent | +48500100001 |
| `parent_easy` | parent.easy@test.besafe.org.pl | Test123! | parent | +48500100002 |
| `kid_anna` | kid.anna@test.besafe.org.pl | Test123! | child | +48500100003 |
| `senior_jadwiga` | senior.jadwiga@test.besafe.org.pl | Test123! | parent | +48500100004 |

**Fixtury startowe:**
- Grupa „Rodzina Testowa” (owner: parent_tech), członkowie: parent_easy (parent), kid_anna (child)
- Senior_jadwiga jest w osobnej grupie „Babcia Solo” (jako sole owner)
- 1 geofence „Dom” wokół 52.3247, 17.5667 (Września, R=200m)
- 1 safe_route „Do szkoły” (kid_anna, 5 pkt, threshold 100m)
- 10 świeżych alertów AlertBot w radiusie 2km (różne kategorie)

## Matryca pokrycia funkcji × persona × złożoność UX

Skala złożoności (subiektywnie ocenia tester):
- **L1 (proste)** — 1-2 tapy, oczywisty cel, ikona z etykietą
- **L2 (średnie)** — 3-5 tapów, wymaga zrozumienia layoutu lub kontekstu
- **L3 (zaawansowane)** — wymaga zaznajomienia z aplikacją, niestandardowych gestów (rysowanie palcem), formularzy

| Funkcja | Ekran | P1 | P2 | P3 | P4 | UX |
|---|---|---|---|---|---|---|
| Onboarding 5 ekranów | `onboarding_screen` | ✓ | ✓ | ✓ | ✓ | L1 |
| Rejestracja (email + hasło + zgody) | `login_screen` | ✓ | ✓ | ✗ | ✓ | L2 |
| Login email/hasło | `login_screen` | ✓ | ✓ | ✓ | ✓ | L1 |
| Login Google | `login_screen` | ✓ | ✓ | ✗ | ✗ | L1 |
| Login demo | `login_screen` | ✗ | ✗ | ✗ | ✓ | L1 |
| Zapomniałem hasła (forgot) | `forgot_password_screen` | ✓ | ✓ | ✗ | ✓ | L2 |
| HomeScreen — Glow Orb, karty | `home_screen` | ✓ | ✓ | ✓ | ✓ | L1 |
| Mapa — zoom, scroll, filter kategorii | `map_screen` | ✓ | ✓ | ✓ | ✓ | L1/L2 |
| Mapa — lista alertów (bell) | `map_screen` | ✓ | ✓ | ✓ | ✓ | L2 |
| Tap alert na mapie → InfoWindow | `map_screen` | ✓ | ✓ | ✓ | ✓ | L1 |
| Zgłoś nowy alert (kategoria, opis, foto) | `create_alert_screen` | ✓ | ✓ | ✗ | ✓ | L2 |
| Szczegóły alertu | `alert_detail_screen` | ✓ | ✓ | ✓ | ✓ | L1 |
| Głosowanie potwierdz./neguj | `alert_detail_screen` | ✓ | ✓ | ✓ | ✓ | L2 |
| Komentarze | `alert_detail_screen` | ✓ | ✓ | ✗ | ✓ | L2 |
| Zgłoś nadużycie | `alert_detail_screen` | ✓ | ✗ | ✗ | ✗ | L2 |
| Moje alerty (edycja / usuń) | `my_alerts_screen` | ✓ | ✗ | ✗ | ✗ | L2 |
| Statystyki | `stats_screen` | ✓ | ✗ | ✗ | ✗ | L2 |
| **SOS — hold 2s** | `sos_screen` | ✓ | ✓ | ✓ | ✓ | L2 |
| **SOS — call 112** | `sos_screen` | ✗ | ✓ | ✓ | ✓ | L1 |
| **SOS odebrane → tap push → mapa** | FCM `family_sos` | ✓ | ✓ | ✗ | ✓ | L1 |
| **Wyślij sygnał (ping)** | `family_screen` → ping | ✓ | ✓ | ✓ | ✗ | L1 |
| **Odpowiedź na ping** | `ping_response_screen` | ✓ | ✓ | ✓ | ✓ | L1 |
| **Notatka przy „nie OK”** | `ping_response_screen` | ✓ | ✓ | ✓ | ✗ | L2 |
| Family — utworzenie grupy | `family_screen` | ✓ | ✗ | ✗ | ✓ | L2 |
| Family — dołączenie przez kod | `family_screen` | ✗ | ✓ | ✓ | ✓ | L2 |
| Family — kod QR | `family_screen` | ✓ | ✓ | ✗ | ✗ | L1 |
| Family group — lista członków | `family_group_screen` | ✓ | ✓ | ✓ | ✓ | L1 |
| Family group — toggle tracking | `family_group_screen` | ✓ | ✗ | ✗ | ✗ | L2 |
| Family group — dodaj geofence | `add_geofence_screen` | ✓ | ✗ | ✗ | ✗ | L2 |
| Family group — bezpieczne trasy lista | `safe_routes_screen` | ✓ | ✗ | ✗ | ✗ | L2 |
| **Family group — rysowanie trasy palcem** | `draw_safe_route_screen` | ✓ | ✗ | ✗ | ✗ | **L3** |
| Family group — historia lokalizacji | `location_history_screen` | ✓ | ✓ | ✗ | ✗ | L2 |
| ChildProfile / MemberProfile | `child_profile_screen` `member_profile_screen` | ✓ | ✓ | ✗ | ✓ | L1 |
| Profile — wszystkie tile’y | `profile_screen` | ✓ | ✓ | ✓ | ✓ | L1 |
| Profile — wyloguj (z dialogiem) | `profile_screen` | ✓ | ✓ | ✓ | ✓ | L1 |
| Profile — odznaki | `badges_screen` | ✓ | ✓ | ✓ | ✗ | L1 |
| Profile — ranking | `ranking_screen` | ✓ | ✓ | ✓ | ✗ | L1 |
| Profile — referral | `referral_screen` | ✓ | ✗ | ✗ | ✗ | L1 |
| Settings — theme | `settings_screen` | ✓ | ✓ | ✓ | ✓ | L1 |
| Settings — telefon | `settings_screen` | ✓ | ✓ | ✗ | ✓ | L2 |
| Settings — zmiana hasła | `settings_screen` | ✓ | ✗ | ✗ | ✓ | L2 |
| Settings — usuń konto | `settings_screen` | ✗ | ✗ | ✗ | ✗ | — (skip destructive) |
| Aktualności | `news_screen` | ✓ | ✓ | ✓ | ✓ | L1 |
| Numery alarmowe | `emergency_numbers_screen` | ✓ | ✓ | ✓ | ✓ | L1 |
| Regulamin/Privacy | `legal_screen` | ✓ | ✓ | ✗ | ✓ | L1 |

**Razem:** ~45 funkcji × 4 persony, ale każda persona pokrywa swój podzbiór. Łącznie estymowane ~80-100 atomowych testów.

## Reguły scenariuszy persona-specific

### P1 — Rodzic techniczny (pełny flow administracyjny)
1. Login email
2. Utworzenie grupy „Test E2E”
3. Zaproszenie partnera (parent_easy) i dziecka (kid_anna) przez QR
4. Dodanie geofence „Szkoła” (R=200m)
5. Rysowanie bezpiecznej trasy palcem (>=3 pkt, threshold 100m)
6. Toggle tracking dziecka — z confirmation dialogiem
7. Zgłoszenie alertu (kategoria police, opis, foto z galerii)
8. Edycja własnego alertu (extend duration)
9. Zmiana motywu na ciemny
10. Logout z confirmation

### P2 — Rodzic nietechniczny
1. Onboarding → rejestracja
2. **Bez tworzenia grupy** — dołączenie do istniejącej przez kod (od P1)
3. Otwarcie mapy, scroll, klik na alert, odczyt info
4. **Czytanie powiadomienia** — symulacja FCM `family_sos` → tap → FamilySosScreen → klik „Zadzwoń”
5. Wyślij sygnał do dziecka → otrzymanie odpowiedzi → reakcja na SnackBar
6. Otwórz profil dziecka → tap „Historia lokalizacji”
7. Wpisanie numeru telefonu w Ustawieniach (Faza 2.1)

### P3 — Dziecko
1. Login (kid_anna) — istniejące konto z fixtury
2. Pierwsze otwarcie aplikacji → onboarding seen (lub bez)
3. SOS — pełen flow hold 2s → broadcast
4. Odpowiedź na ping od rodzica „WSZYSTKO OK”
5. Odpowiedź na drugi ping „POTRZEBUJĘ POMOCY” + notatka „Boję się”
6. **Test ograniczeń**: próba toggle tracking innego dziecka → powinno być niedostępne
7. Próba dodania safe_route → niedostępne (parent-only)
8. Sprawdzenie własnej widoczności na profilu

### P4 — Senior (babcia)
1. Login demo (najprostszy) lub email
2. Otwarcie mapy — czy widoczny dzwoneczek z badge?
3. Czy każda ikona ma etykietę w PillNavBar?
4. Próba zgłoszenia alertu — czy submit button pokazuje konkretną podpowiedź dlaczego nieaktywny?
5. SOS — czy podpowiedź „PRZYTRZYMAJ 2 SEKUNDY” jest widoczna i pulsuje?
6. „Zadzwoń 112” z SOS — czy duży zielony przycisk?
7. Wszystkie touch-targety ≥ 48dp (assertion w teście)
8. Numery alarmowe — czy wszystko ma 14+ tooltip’y?
9. Wylogowanie z confirmation

## Metryki sukcesu

### Funkcjonalne (pass/fail)
- Każdy test ma binarny status pass/fail
- Zielony pasek = release-ready

### UX (mierzone w teście)
- **TTI (time-to-interactive)** dla każdej funkcji — różnica między tapnięciem CTA a stable widget tree
- **Liczba tapów do celu** — dla każdego flow persona-specific
- **Touch-target size** — assertion przez `Finder.evaluate().bounds.size >= Size(48,48)`
- **Czas dotarcia do SOS** — krytyczna metryka (cel: <3s od dowolnego ekranu)

### Wizualne (golden screenshots)
- Po każdym kroku screenshot zapisywany do `test_results/{persona}/{step}.png`
- Porównywanie z baseline (golden master) — różnica >5% pikseli = fail
- Matryca: light theme × dark theme × Inter font scale 1.0/1.3

## Struktura katalogów (proponowana)

```
mobile/
├── integration_test/
│   ├── personas/
│   │   ├── p1_parent_tech_test.dart        # 10 testów
│   │   ├── p2_parent_easy_test.dart        # 7 testów
│   │   ├── p3_child_test.dart              # 8 testów
│   │   └── p4_senior_test.dart             # 9 testów
│   ├── functional/
│   │   ├── auth_test.dart                  # all auth screens
│   │   ├── map_test.dart                   # mapa + filtry + cluster
│   │   ├── alerts_test.dart                # CRUD alertów
│   │   ├── family_test.dart                # groups + geofences + routes
│   │   ├── sos_test.dart                   # SOS + ping
│   │   └── settings_test.dart              # ustawienia + profile
│   ├── visual/
│   │   ├── golden_test.dart                # screenshoty per ekran
│   │   └── ux_metrics_test.dart            # touch-targets, TTI
│   └── helpers/
│       ├── test_config.dart                # API URL, accounts
│       ├── login_helper.dart               # login(persona)
│       ├── fixture_helper.dart             # reset state przez API
│       ├── screenshot_helper.dart          # capture + compare
│       └── persona.dart                    # enum + metadata
└── pubspec.yaml                            # +patrol, +integration_test
```

## Skrypty pomocnicze (backend)

Backend dodatkowo dostarcza:
- `POST /api/v1/test/reset-persona/{username}` (auth admin only) — wymaga `TEST_RESET_SECRET` env var
  - Czyści alerty użytkownika, geofences, routes
  - Resetuje fcm_token, last_location
  - Re-seed fixtury

## Plan czasowy (~tydzień, 5 dni roboczych)

| Dzień | Zadanie |
|---|---|
| **D1** | Audyt + ten plan + accept. Seed kont testowych + fixtur. Dodanie Patrol do pubspec. |
| **D2** | Test helpers (login, fixture cleanup, screenshot). Test smoke pierwszej persony (P1). |
| **D3** | P2 + P3 suity. Funkcjonalny auth_test + map_test. |
| **D4** | P4 (senior) suity + funkcjonalny family_test + sos_test. |
| **D5** | Visual regression (golden snapshots) + UX metrics + raport HTML + run na obu telefonach. |

## Otwarte pytania (do akceptacji przed startem)

1. **Czy dodać endpoint admin `/test/reset-persona`?** Alternatywa: skrypt SSH+SQL przy każdym teście (wolniejszy, ale nie wymaga release’u backendu).
2. **Czy testy mogą wysyłać prawdziwe FCM**? (Tak = realny test, ale wiadomości do realnych telefonów testowych podłączonych przez ADB; Nie = mock)
3. **Czy testy mogą wykonywać POST/PATCH na produkcyjnym DB** (przez konta `_test`)? (Tak = rzeczywiste E2E z DB writes, ale konta muszą być oznaczone żeby filtrować z metryk produkcji)
4. **Visual regression baseline** — komputerowi powiedz najpierw rzeczywiste screenshoty z 2 telefonów, potem te są baseline. Z czasem update przy intencjonalnych zmianach UI.
5. **Czy puścić testy w pipeline CI** (GitHub Actions z emulatorem) czy tylko lokalnie z fizycznymi telefonami? (Wpływa na strukturę helpers.)
