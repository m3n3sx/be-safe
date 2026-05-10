# be:Safe — Design Brief

> Ten dokument to **kontekst referencyjny** dla Stitch. Nie wklejaj go jako prompt,
> ale używaj fragmentów gdy dajesz dodatkowe instrukcje.

---

## 1. Produkt w jednym zdaniu

**be:Safe** to społecznościowa aplikacja bezpieczeństwa łącząca alerty zagrożeń
w okolicy z trybem rodzinnym (rodzice widzą lokalizację dzieci w czasie rzeczywistym).

## 2. Target user & platforma

- **Platforma:** Android (Flutter), iOS (pending)
- **Rynek:** Polska (UI w języku polskim)
- **Użytkownicy:** dorośli (rodzice + pieszych mieszkańców), nastolatki 13+ za
  zgodą rodzica w rodzinnej grupie
- **Używają w sytuacjach:** spacer wieczorem, droga do szkoły dziecka, nagła sytuacja

## 3. Vibe & tone

> Zaufany. Profesjonalny ale nie korporacyjny. Funkcjonalny jak WhatsApp, wizualnie
> zbliżony do Google Maps + Material 3. Alert-red dla ważnych akcji (SOS, zagrożenia),
> calm neutrals dla reszty. Community-first, ale nie "game-ified".

**Przymiotniki do promptów:**
- `trustworthy`, `safety-focused`, `modern`, `clean`
- `community-driven`, `family-friendly`
- `material 3`, `rounded`, `high-contrast`
- `Polish-language`, `Poland-localized`

**NIE używaj:**
- ~~playful~~, ~~cute~~, ~~gamified~~ (to nie jest apka gry)
- ~~corporate~~, ~~sterile~~ (to nie jest enterprise)
- ~~dark / ominous~~ (nie straszyj użytkowników)

## 4. Design system

### 4.1 Kolory

**Primary (alerty, akcje podstawowe):**
- `Alert Red` — `#FF1744` — SOS, przyciski Zgłoś, ważne notyfikacje
- `Alert Red Dark` — `#D50000` — pressed states, hover

**Secondary (family, pozytywne akcje):**
- `Safe Green` — `#00C853` — check-in "Jestem bezpieczny", lokalizacja dziecka
- `Blue` — `#2979FF` — powódź, ikonka policji

**Neutrals:**
- Surface light: `#FAFAFA`
- Surface dark: `#121212`
- On-surface light: `#1A1A1A`
- On-surface dark: `#E8E8E8`
- Divider: `#E0E0E0` (light) / `#333333` (dark)

**Accent (per-category):**
- Fire `#FF3D00` | Accident `#FF6D00` | Construction `#FFAB00`
- Ice `#00B0FF` | Dark area `#78909C` | Drugs `#AA00FF`

**Motywy:** apka ma 6 alternatywnych palet (blue, green, purple, orange, pink, teal).
Dla Stitcha — zacznij od Red + Grey. Alternatywne motywy to feature ustawień.

### 4.2 Typografia

- **Font:** `Inter` (lub Google Sans Text — oba OK)
- **Display/H1:** 32 / 28 / 24 sp, weight 700
- **H2:** 20 sp, weight 600
- **Body:** 15 sp, weight 400
- **Caption:** 12 sp, weight 400
- **Button:** 14 sp, weight 600, letter-spacing 0.5

### 4.3 Layout & spacing

- **Base unit:** 8 dp
- **Margin side (mobile):** 16 dp
- **Card radius:** 16 dp
- **Button radius:** 28 dp (pill-shaped) dla primary, 12 dp dla secondary
- **Icon size:** 24 sp inline, 28–32 sp standalone
- **Tap target min:** 48 dp

### 4.4 Komponenty bazowe

- **AppBar:** flat, bez elevation, transparent gdy nad mapą
- **Bottom Nav:** 5 items — Mapa / Alerty (z badge) / **SOS (duży czerwony)** / Rodzina / Profil
- **Cards:** 16 dp radius, soft shadow (0 2 8 rgba 0 0 0 / 0.08)
- **Input:** filled style, 12 dp radius, placeholder w szarości
- **CTA primary:** filled pill-button, full-width, 56 dp high
- **CTA secondary:** outlined, 48 dp high
- **Chips:** filter chips w liście kategorii, compact density
- **Avatar:** okrągły, 40 dp w liście, 80 dp w profilu
- **Badge:** czerwony dot na ikonce "Alerty" w nav, liczba w pillu dla > 1
- **Tablet:** `width ≥ 600 dp` → NavigationRail zamiast Bottom Nav.
  `width ≥ 900 dp` → dodatkowy panel prawy z listą alertów.

## 5. Ikony

Material Symbols Rounded — font-weight 400, filled dla aktywnych.

**Core iconset:**
- Mapa: `map`
- SOS: `sos` lub tekst "SOS" w okręgu
- Alerty: `notifications_active` (gdy są), `notifications_none` (gdy brak)
- Rodzina: `family_restroom`
- Profil: `person`
- Zagrożenie: `warning_amber` (triangle)
- Check-in: `check_circle`
- Share location: `share_location`
- Badge/odznaka: `emoji_events`
- News: `article`
- Numer alarmowy: `emergency` / `call`

## 6. Ekrany (priority order)

Kolejność generowania w Stitchu (od najważniejszego):

| # | Ekran | Opis |
|---|---|---|
| 1 | **Map** (home) | Mapa + markery alertów + bottom nav + SOS |
| 2 | **Onboarding** | 5 slajdów wprowadzających |
| 3 | **Login / Register** | Google Sign-In + email |
| 4 | **Create Alert** | Formularz zgłoszenia zagrożenia |
| 5 | **Alert Detail** | Mapa + opis + głosy + komentarze |
| 6 | **Profile** | Avatar + reputacja + check-in + menu |
| 7 | **Family** | Lista grup rodzinnych |
| 8 | **Family Group** | Członkowie + mapa dzieci |
| 9 | **My Alerts** | Historia własnych zgłoszeń |
| 10 | **Stats** | Wykresy zagrożeń w okolicy |
| 11 | **Settings** | Motywy, powiadomienia, język |
| 12 | **Badges** | Grid 3xN odznak (zdobyte + do zdobycia) |
| 13 | **News / Blog** | Lista artykułów + detail w bottom sheet |
| 14 | **Ranking** | Lista userów z medalami |
| 15 | **Referral** | Kod + QR + share |
| 16 | **Emergency Numbers** | Grid/lista numerów z tel-launcher |
| 17 | **Location History** | Mapa z polyline + date picker |
| 18 | **Legal** | Scrollable tekst regulaminu/polityki |

## 7. Konkurencja & inspiracje

**Patrz, ale nie kopiuj:**
- **Citizen** (US) — alerty społeczne, ale za ciemne/militarne. Nasz = jaśniejszy.
- **Life360** — family tracking, ale corp-feel. My = bardziej casualnie.
- **Google Maps** — mapa/nawigacja. Wzorujemy się na jakości mapy.
- **Neighbors (Ring)** — community alerts. Obrzydzamy nadmiar notyfikacji.

**Czerpiemy inspirację z:**
- Material 3 (m3.material.io) — base design language
- Duolingo — gamification odznak (subtelnie, nie krzykliwie)
- Apple Find My — clean mapa z awatar rodziny

## 8. Zasady produktowe

1. **Mapa jest w centrum** — każdy ekran wraca do mapy 1 tapem.
2. **SOS zawsze dostępny** — w bottom nav, dosłownie 1 tap od dowolnego ekranu.
3. **Rodzina = trust** — zielona paleta, łagodne krawędzie, avatary zawsze widoczne.
4. **Alerty = red urgency** — ale nie gaslighting, żadnych "DANGER NEARBY!" w caps.
5. **Polski jako default** — EN jako fallback.
6. **Prywatność widoczna** — ikony przy danych, "Twoja lokalizacja jest widoczna tylko dla rodziców" jako microcopy.

## 9. Co NIE jest w scope designu

- Admin panel (tylko mobile + webapp landing)
- Animacje / micro-interactions (Stitch i tak tego nie umie generować)
- Kolaż zdjęć / hero images (używamy ikon, nie fotografii)
- Ilustracje ludzi (RODO-friendly — tylko abstrakcyjne/ikoniczne)

---

**Stitch project ID** (po utworzeniu): `__TODO_FILL_AFTER_CREATING__`
**Brand color hex dla wklejania:** `#FF1744`
