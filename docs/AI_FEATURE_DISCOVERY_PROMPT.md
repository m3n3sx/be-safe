# Uniwersalny prompt do AI: analiza luk funkcjonalnych be:Safe

Skopiuj treść poniżej do dowolnego modelu AI (ChatGPT/Claude/Gemini/Grok/Perplexity z dostępem do internetu).

---

## PROMPT START

Jesteś doświadczonym product strategistem specjalizującym się w aplikacjach mobilnych typu safety/community/family. Twoim zadaniem jest przeanalizować obecny stan aplikacji **be:Safe** (opis poniżej), zbadać sieć pod kątem konkurencji i trendów, a następnie wygenerować **listę funkcji i opcji, których aplikacji brakuje**, posortowaną według wartości dla użytkownika.

## 1. Czym jest be:Safe

**be:Safe** to polska aplikacja społecznościowa do raportowania zagrożeń i bezpieczeństwa rodziny, działająca pod adresem `https://besafe.org.pl`.

### Stack techniczny
- **Mobile:** Flutter 3.29 (Android + iOS planowane), package `pl.u235.alertmap`
- **Web:** Next.js 16 + React 19 + TypeScript + Tailwind CSS 4
- **Backend:** Node.js + Express + Socket.io 4.8 (REST + WebSocket)
- **Baza:** PostgreSQL 16 + PostGIS (geospatial)
- **Push:** Firebase Cloud Messaging (HTTP v1)
- **Auth:** JWT + bcrypt + Google Sign-In
- **Hosting:** AWS EC2 Ubuntu, Cloudflare DNS

### Główne moduły (obecny stan v48)

#### A) Alerty społecznościowe
- 18 kategorii zagrożeń (agresja, kradzież, wypadek, pożar, powódź, oblodzenie, niebezpieczna budowa, niebezpieczne zwierzę, ciemna strefa, narkotyki, akcja policyjna, pogoda, inne, podejrzana osoba, niebezpieczne przejście, plac zabaw, zbiornik wodny, strefa szkolna)
- Tworzenie alertu z geolokalizacją, opisem, zdjęciem, promieniem oddziaływania
- System głosowania "Potwierdzam"/"Nieaktualne" z auto-ukrywaniem przy 3+ "denies"
- System raportowania nadużyć (3 strike = auto-hide)
- Live chat na alertach (Socket.io)
- Auto-expiry alertów po określonym czasie
- Heatmapa zagrożeń, statystyki, ranking użytkowników (reputation_score)
- Klastrowanie pinów na mapie (4 buckety: <10/10-49/50-99/100+)

#### B) Mapa
- Google Maps z monochromatyczną stylizacją
- Custom Canvas-rendered teardrop pins (5 wariantów: default/selected/confirmed/inactive/multi)
- Filter kategorii, lista alertów w okolicy, bell-badge
- Empty state z instrukcją

#### C) Moduł rodziny
- Grupy rodzinne z kodem zaproszenia
- Role: parent / child
- Live tracking dzieci (GPS przez Socket.io)
- Geofences (strefy bezpieczne, np. "Dom" R=200m, EXIT/ENTER detection + FCM push)
- Safe routes (rysowanie palcem na mapie, korytarz 30-1000m, alert gdy dziecko zboczy z trasy)
- Historia lokalizacji dziecka
- ChildProfileScreen: avatar, online status (<2min/15min), bateria z push przy <20%/<10%, lokalizacja, akcje: Zadzwoń, Wyślij sygnał, Historia, Bezpieczne trasy
- MemberProfileScreen dla dorosłych członków
- FamilySosScreen: gdy dziecko wysyła SOS, parent dostaje push z mapą + przyciskiem Zadzwoń + 112
- Family pings: "Wyślij sygnał" → odbiorca tap notyfikację → PingResponseScreen z 2 opcjami: "WSZYSTKO OK" (mint) / "POTRZEBUJĘ POMOCY" (coral + notatka), cron expiry 30min
- Heartbeat / last_seen_at (60s dedup w middleware)

#### D) SOS
- Hold 2s (animacja pulsująca "PRZYTRZYMAJ 2 SEKUNDY", haptic co 500ms)
- Tworzy alert kategorii "aggression" z emoji 🆘
- Opcjonalne wezwanie 112 (default ON)
- Powiadomienie sąsiadów w promieniu (default 500m, opcja 200m)
- Specjalne traktowanie SOS dziecka → FCM dla parentów + FamilySosScreen

#### E) Powiadomienia inteligentne
- I.1 Alert w moim promieniu (default 1km, edytowalny) → push
- I.2A Dziecko wchodzi w obszar aktywnego alertu → parent push z dedup
- I.2B Alert powstaje gdzie dziecko jest → parent push (niezależnie od dystansu rodzica)
- I.3 SOS w okolicy → push → tap = AlertDetailScreen
- I.4 Dziecko SOS → parent push → tap = FamilySosScreen

#### F) Profil i społeczność
- Reputation score, badges, ranking top 50
- Referral system
- Statystyki własne (alerty, głosy)
- GDPR data export (JSON)
- Avatar upload
- Tryb demo (anonymous), Google Sign-In, email verification, password reset

#### G) Bezpieczeństwo i prywatność
- JWT (7 dni), bcrypt cost=10
- Block/unblock użytkownika
- Lokalizacja temporary share link (Leaflet/OSM public page)
- Anti-enumeration na forgot-password
- Email verification token
- Rate limiting (auth 5/min, alert create 10/h, location 60/min)

#### H) Integracje zewnętrzne
- IMGW (Polish Meteorological Institute) — sync ostrzeżeń pogodowych co 15 min
- GDDKiA (Polish Road Authority) — sync incydentów drogowych co 30 min
- Nominatim (OpenStreetMap) — geocoding
- Numery alarmowe (lista PL: 112, 999, 998, 997, GOPR, WOPR...)

#### I) Wzbogacenia UX (audit 18-punktowy wdrożony w v38)
- PillNavBar z etykietami (5 zakładek: Mapa/Home/Rodzina/SOS/Profil)
- Wszystkie destrukcyjne akcje → confirmation dialog (logout, delete, vote, tracking off, geofence delete)
- ForgotPasswordScreen funkcjonalny
- PopScope na ekranach z formularzami (CreateAlert)
- Kategorie zgrupowane w 4 sekcje (PILNE/DROGOWE/DLA DZIECI/INNE)
- AddGeofenceScreen full-screen z slidem promienia 50-500m
- 29 tooltipów na IconButton (TalkBack support)
- Empty state mapy z instrukcją "Tapnij Zgłoś"

#### J) Inne moduły
- Aktualności społecznościowe (posts CRUD)
- "I'm safe" check-ins z poziomem baterii
- Background Foreground Service na Androidzie (GPS w tle, alert polling co 60s)
- Offline cache SQLite z TTL 5 min na region
- API retry z exponential backoff (3 retry)
- OTA update notification (porównanie wersji client/server)
- Dynamiczna motyw (7 motywów, Serenity Guard default)
- Wielojęzyczność (PL + EN, choć większość UI po polsku)

### Design system Serenity Guard
- Background #FCF8F9, navy primaryContainer #1A2027, mint #9DF4CB, coral #FF7A7A, aqua #9EEBEC
- Inter font, 24dp card radius, pill buttons, GlowOrb safety score animation

### Konteksty użytkowników (4 persony testowe)
1. **Rodzic techniczny** — power user, używa wszystkich funkcji
2. **Rodzic nietechniczny** — proste flow, potrzebuje wyraźnych etykiet
3. **Dziecko 10 lat** — tracking + SOS + ograniczone uprawnienia
4. **Senior 68 lat** — touch-target 56dp+, prosty UI, SOS dostępny w 3s

### Tech znajomości
- Aplikacja jest aktywnie utrzymywana, w produkcji od ~rok
- ~46 ekranów Flutter
- 18 alertów testowych kategorii live + 103 syntetycznych z bota
- Real users na produkcji, pełna izolacja accountów testowych (is_test=TRUE)
- Telemetria UX przez Patrol E2E (4 persony × 5 suit testowych)
- Znany problem: login → Home ładuje się 35s (nadmierne retry + Future.wait timeout)

---

## 2. Zadanie dla Ciebie

Wykonaj następujące kroki w tej kolejności:

### KROK 1: Research konkurencji i rynku
Przeszukaj sieć (jeśli masz dostęp) lub wykorzystaj swoją wiedzę o:
- **Bezpośrednia konkurencja:** Citizen (USA), Nextdoor, Neighbors by Ring, Life360, Find My, Google Family Link, Bark, Eyezy, RegioPolicja, ICE (Polska), 112 (UE), bSafe, Noonlight, Mamabear
- **Aplikacje rodzicielskie:** Qustodio, Google Family Link, mSpy, OurPact, Screen Time
- **Aplikacje SOS:** RedPanic, SOS Stay Safe, Personal Safety (Google), Apple Emergency SOS, Samsung SOS, bSafe
- **Aplikacje community:** Nextdoor, Trustroots, Foursquare Swarm
- **Trends 2026:** AI-driven safety, wearable integration (Apple Watch / Wear OS), federated learning, deepfake protection, mental health crisis, climate change alerts, women's safety apps (Sister Circle, Noonlight), AED finder, panic button hardware
- **Kontekst PL:** Alert RCB, RSO, mObywatel, FluMap, traffic apps (Yanosik), e-Recepta

### KROK 2: Analiza luk w be:Safe

Porównaj funkcje be:Safe z konkurencją + best practices i wskaż **co MOGŁOBY istnieć w aplikacji, a obecnie nie ma**. Skup się na:

#### Kategorie do rozważenia
- **Bezpieczeństwo osobiste:** dodatkowe scenariusze SOS (fake call, audio recording, panic gesture, smartwatch shortcut, voice activation)
- **Sztuczna inteligencja:** AI-assisted alert verification, deduplication, fake detection, image moderation, sentiment analysis komentarzy, smart routing recommendations
- **Wearables:** integracja Apple Watch / Wear OS / Galaxy Watch, mini-app na zegarku z SOS + tracking
- **Wellness/Health:** integracja z health apps (kroki, HR, fall detection), mental health crisis SOS (z linkami do telefonów zaufania), check-in for solo travelers
- **Dla rodziców:** screen time monitoring, contacts whitelist, app blocking, content filter, sleep tracker dziecka
- **Dla dzieci:** edukacyjne gry o bezpieczeństwie, kontakty do nauczycieli/zaufanych, kreator routek do szkoły, vibration zamiast push (gdy w klasie)
- **Społeczność:** lokalne grupy sąsiedzkie, lokalny chat sąsiedzki, wymiana usług (np. "podwożę dzieci do szkoły"), wolontariusze pierwszej pomocy w pobliżu
- **Integracje:** Polska Policja (RCB, ICE), Apteki dyżurujące, Defibrylator (AED) finder, Numer Pomocy Dziecku 116 111, telefony zaufania
- **Climate/Pollution:** powietrze (PM2.5), pyłki, UV, alergeny, ciepłe noce/upały, dzwonienie do ZUS przy ekstremalnych warunkach
- **Disability/Accessibility:** sign language video calls, screen reader optimized flow, dyslexia-friendly font, color blind modes, voice-first navigation
- **Privacy/Trust:** anonymous reports, time-limited locations, family vault (digital will), 2FA, biometric login, location spoofing detection
- **Performance/Reliability:** offline mode (mapy offline, kolejka alertów do wysłania), low-data mode, mesh networking gdy brak sieci, peer-to-peer alerty
- **Gamification:** zachęty do reportowania (bezpieczne tygodnie strefa), badges za pierwszą pomoc, community challenges (najczystszy park)
- **Tools dla emergency services:** view dla policji/straży, automatyczne raporty z weryfikacji, statystyki sezonowe
- **Crowd-sourced data:** zdjęcia kierowców-piratów, lokalizacje fotoradarów, drogi w remoncie, lokalne hazardy
- **Family planning:** harmonogram zajęć dzieci synchronizowany z lokalizacją, kontakty do szkoły, transport school bus tracker
- **Mental health:** stress level diary, dystans od domu jako wskaźnik niepokoju, automatyczny check-in po zdarzeniu traumatycznym

#### Format wyjścia
Dla każdej brakującej funkcji podaj:
- **Nazwa funkcji**
- **Krótki opis (1-2 zdania)**
- **Korzyść dla użytkownika** (która persona zyskuje najwięcej)
- **Szacunek wartości** (high / medium / low)
- **Szacunek złożoności implementacji** (low: <1 tydzień / medium: 1-4 tyg / high: >1 miesiąc / huge: >3 miesiące)
- **Zależności techniczne** (np. wymaga zewnętrznego API, hardware, ML model)
- **Konkurencja**: która apka już to ma + ich approach
- **Ryzyko UX/legal/privacy**: czy są pułapki

### KROK 3: Priorytetyzacja

Wygeneruj tabelę zawierającą top 30 funkcji posortowane przez **wartość / złożoność** (najlepsze ROI na górze). Format markdown.

### KROK 4: Roadmap proposal

Zaproponuj 4 fazy implementacji (każda ~3 miesiące):
- **Faza A:** Quick Wins — low complexity, high value
- **Faza B:** Differentiators — co wyróżni be:Safe od konkurencji
- **Faza C:** Platform Extensions — wearables, web extension, smart home
- **Faza D:** Advanced/Experimental — AI, mesh networking, blockchain-of-trust

### KROK 5: Wskazówki strategiczne

Na końcu napisz 5-10 obserwacji o pozycjonowaniu produktu:
- Co jest unikalną wartością be:Safe vs konkurencja?
- Gdzie są blue ocean opportunities?
- Czy są features które należałoby USUNĄĆ z apki bo psują pozycjonowanie?
- Jaki target user powinno się obrać (parents-only? whole community? seniors?)
- Jak Polska specyfika wpływa na wybór funkcji (NFC mObywatel, e-recepta, integracja z policją)?

---

## 3. Twoja odpowiedź ma być po polsku

Pisz konkretnie, technicznie, bez floweryjnych deklaracji. Tylko user value + implementation pragmatism.

Cel: dostarczyć product ownerowi praktyczną listę "co zrobić następne kwartał".

## PROMPT END
