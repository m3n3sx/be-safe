# AlertMap — Specyfikacja Projektu

## 1. Opis

AlertMap to mobilna aplikacja bezpieczeństwa działająca jako community-driven system ostrzeżeń o zagrożeniach. Użytkownicy zgłaszają niebezpieczeństwa, które pojawiają się na mapie w czasie rzeczywistym. Aplikacja proaktywnie powiadamia o zagrożeniach w okolicy użytkownika. Moduł family tracking pozwala rodzicom śledzić lokalizację dzieci i otrzymywać alerty dotyczące ich otoczenia.

## 2. Stos technologiczny

| Warstwa | Technologia | Uzasadnienie |
|---|---|---|
| Frontend | Flutter (Dart) | Cross-platform iOS + Android, darmowy |
| Mapy | OpenStreetMap + flutter_map | Darmowe, bez limitów API |
| Backend | Node.js + Express | Lekki, szybki development |
| Baza danych | PostgreSQL + PostGIS | Darmowy, natywne zapytania geolokalizacyjne |
| Push notifications | Firebase Cloud Messaging (FCM) | Darmowy tier wystarczający |
| Hosting | VPS (SSH) | Pełna kontrola, brak kosztów chmury |
| Auth | JWT + bcrypt | Proste, bezpieczne, bez zależności od 3rd party |
| Real-time | WebSocket (Socket.io) | Alerty w czasie rzeczywistym |

## 3. Kategorie zagrożeń

### Zagrożenia dla wszystkich
| ID | Kategoria | Ikona | Kolor |
|---|---|---|---|
| `aggression` | Agresywne osoby / grupy | 👊 | Czerwony |
| `theft` | Kradzieże / rozboje | 🔓 | Czerwony |
| `accident` | Wypadek drogowy | 🚗 | Pomarańczowy |
| `fire` | Pożar | 🔥 | Czerwony |
| `flood` | Powódź / zalanie | 🌊 | Niebieski |
| `ice` | Oblodzenie / śliska nawierzchnia | 🧊 | Jasnoniebieski |
| `construction` | Niebezpieczna budowa / zawalenie | 🏗️ | Żółty |
| `animal` | Niebezpieczne zwierzę | 🐕 | Pomarańczowy |
| `dark_area` | Nieoświetlony / niebezpieczny teren | 🌑 | Szary |
| `drugs` | Narkotyki / osoby pod wpływem | 💊 | Fioletowy |
| `police` | Akcja policyjna / zamknięty teren | 🚔 | Niebieski |
| `weather` | Zagrożenie pogodowe | ⛈️ | Ciemnoniebieski |
| `other` | Inne zagrożenie | ⚠️ | Żółty |

### Dodatkowe zagrożenia — ochrona dzieci
| ID | Kategoria | Ikona | Kolor |
|---|---|---|---|
| `stranger_danger` | Podejrzana osoba zaczepiająca dzieci | 🚨 | Czerwony |
| `traffic_danger` | Niebezpieczne przejście / skrzyżowanie | 🚦 | Pomarańczowy |
| `playground_hazard` | Uszkodzony plac zabaw | 🛝 | Żółty |
| `water_hazard` | Niezabezpieczony zbiornik wodny | 💧 | Niebieski |
| `school_zone` | Zagrożenie w strefie szkolnej | 🏫 | Pomarańczowy |

## 4. Architektura systemu

```
┌─────────────────────────────────────────────────┐
│                  FLUTTER APP                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │   Mapa   │ │  Alerty  │ │ Family Tracking  │ │
│  └────┬─────┘ └────┬─────┘ └───────┬──────────┘ │
│       └─────────────┼───────────────┘            │
│              ┌──────┴──────┐                     │
│              │  API Client │                     │
│              └──────┬──────┘                     │
└─────────────────────┼───────────────────────────┘
                      │ HTTPS + WebSocket
              ┌───────┴───────┐
              │   VPS Server  │
              │  Node.js API  │
              ├───────────────┤
              │  PostgreSQL   │
              │  + PostGIS    │
              ├───────────────┤
              │  FCM Push     │
              └───────────────┘
```

## 5. Flow użytkownika

### 5.1 Rejestracja / Logowanie
1. Użytkownik tworzy konto (email + hasło)
2. Weryfikacja email
3. Ustawienie promienia alertów (domyślnie 500m)
4. Opcjonalnie: utworzenie grupy rodzinnej

### 5.2 Przeglądanie mapy
1. Mapa centruje się na lokalizacji użytkownika
2. Aktywne zagrożenia wyświetlane jako piny z ikonami kategorii
3. Kliknięcie pina → szczegóły (opis, czas, liczba potwierdzeń, odległość)
4. Filtrowanie po kategoriach
5. Wyszukiwanie dowolnej lokalizacji

### 5.3 Zgłaszanie zagrożenia
1. Przycisk "Zgłoś" → wybór kategorii
2. Automatyczna lokalizacja lub wskazanie na mapie
3. Opis tekstowy (opcjonalnie zdjęcie)
4. Ustawienie szacowanego czasu trwania (1h / 3h / 6h / 12h / 24h)
5. Publikacja → widoczne dla wszystkich w okolicy

### 5.4 Powiadomienia proximity
1. Serwer co minutę sprawdza pozycje użytkowników vs aktywne zagrożenia
2. Jeśli użytkownik w promieniu alertu → push notification
3. Użytkownik może potwierdzić ("Nadal aktualne") lub odrzucić ("Już nieaktualne")

### 5.5 Family Tracking (rodzic)
1. Rodzic tworzy grupę rodzinną
2. Generuje kod zaproszenia dla dziecka
3. Dziecko instaluje apkę i dołącza kodem
4. Rodzic widzi lokalizację dziecka na mapie w real-time
5. Rodzic otrzymuje alerty gdy dziecko zbliża się do zagrożenia
6. Rodzic może ustawić geofence (bezpieczna strefa) → alert gdy dziecko ją opuści
7. Rodzic ma pełną kontrolę — może wyłączyć/włączyć śledzenie

### 5.6 Weryfikacja zgłoszeń
1. Inni użytkownicy mogą potwierdzić lub odrzucić zgłoszenie
2. Zgłoszenie z >3 odrzuceniami → automatyczne ukrycie
3. Zgłoszenia wygasają po ustawionym czasie
4. System reputacji — użytkownicy z wieloma fałszywymi zgłoszeniami tracą wiarygodność

## 6. Wymagania niefunkcjonalne

- **Prywatność**: lokalizacja dziecka widoczna TYLKO dla rodzica w grupie
- **Bateria**: optymalizacja GPS — significant location changes zamiast ciągłego trackingu
- **Offline**: cache ostatnich zagrożeń w okolicy
- **Wydajność**: zapytania geolokalizacyjne <100ms dzięki PostGIS
- **Bezpieczeństwo**: HTTPS, JWT, hashowane hasła, rate limiting
