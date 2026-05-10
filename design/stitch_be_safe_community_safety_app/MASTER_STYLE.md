# be:Safe — Master Design System (sklej z 8 stylów)

> Ten dokument sklejam z **ośmiu eksperymentów Stitcha** trzymanych w
> `/home/ooxo/alert/design/stitch_be_safe_community_safety_app/`:
> `be:Safe`, `be:Safe Core`, `be:Safe Expressive v1`, `be:Safe Expressive v2`,
> `Raw Industrial`, `Aether HUD`, `High-Energy Kinetic Dark`, `Aetheris Explorer`.
>
> Z każdego wziąłem to, co w praktyce wygląda dobrze, **odrzuciłem** to, co
> koliduje z naturą apki bezpieczeństwa społeczności. Nazwa wybranego kierunku:

## **be:Safe Community Modern**

> Material 3 Expressive w brand-red, z ciepłymi pastelami tintowanymi pierwszym,
> floating glass bottom nav z hero SOS, i przemyślane tonal containment. Kombinuje
> wyrazistość czerwieni z ciepłem różowych pasteli — wygląda nowocześnie, ale
> budzi zaufanie, nie strach.

---

## 1. Co skąd bierzemy

### ✅ Zachowujemy

| Element | Źródło | Dlaczego |
|---|---|---|
| **Paleta primary** | `be:Safe Expressive v2` | Alert red `#BA002C` + pełna M3 tonal scale — to tożsamość brand |
| **Pastelowe tinted surfaces** | `be:Safe Expressive v2`, `be:Safe` | `surface: #fff8f7`, `surface-container: #ffe9e8` — ciepłe, ufne |
| **Stat tiles (3-row)** | `profil_m3_expressive_1`, `profil_be_safe` | Punkty / Alerty / Ranking w tintowanych pill-cardach |
| **Floating pill bottom nav** | `mapa_m3_expressive_1`, `profil_nowy_styl` | Glass/floating z zaokrągleniem 28dp, cień |
| **SOS as hero button** | `mapa_m3_expressive_2`, `profil_m3_expressive_1` | 56-64dp czerwony diamond/asterisk w środku nav |
| **Alert pins z tekstową label** | `mapa_m3_expressive_2` | "Wypadek", "Pożar (2)" — label kapsułka nad pinem |
| **Child avatar pin z imieniem** | `mapa_m3_expressive_2` | "Janek" + zielony border — family feel |
| **Segment control pill** | `moje_zg_oszenia_m3_expressive` | "Aktywne / Wygasłe / Wszystkie" pełna pill |
| **Category colored icon tiles** | `moje_zg_oszenia_nowy_styl` | Lewa ikona w tintowanym kwadracie koloru kategorii |
| **Status chips** | `moje_zg_oszenia_be_safe` | "W toku" (blue), "Rozwiązane" (green), "Nowe" (red) |
| **"Zgłoś" extended FAB** | `mapa_m3_expressive_2`, `mapa_be_safe_nowy_styl` | Pill czerwony, ikona + label, bottom-right |
| **Grouped list cards** | `profil_m3_expressive_1` | Ikonki kolor-coded (red/green/blue/grey) per pozycja menu |
| **Shimmer loading** | `profil_adowanie` | Zamiast CircularProgressIndicator |

### ❌ Odrzucamy

| Element | Źródło | Dlaczego |
|---|---|---|
| ~~Neo-brutalism 4px borders~~ | `Raw Industrial` | Zbyt agresywne dla safety app, stresujące |
| ~~Monospace typography~~ | `Raw Industrial`, `Kinetic Dark`, `Aether HUD` | Niższa czytelność dla starszych userów, cold feeling |
| ~~Pure black backgrounds~~ | `Kinetic Dark`, `Aether HUD` | Command-center vibe odpycha community users |
| ~~Cyberpunk neon glows~~ | `Kinetic Dark`, `Aether HUD` | Nie pasuje do "family/neighborhood" |
| ~~Playfair Display serif~~ | `Aether HUD` | Elegant ale nieczytelne na małych ekranach |
| ~~Orange primary~~ | `Aetheris Explorer`, mixed "M3E" tint | Nie alert-red — tracimy brand tożsamość |
| ~~Anton heavy uppercase~~ | `Kinetic Dark` | "COMMAND CENTER" — alarmujące, nie uspokajające |
| ~~English labels~~ | parę screenów | Docelowy rynek PL |

---

## 2. Design Tokens

### 2.1 Paleta kolorów (light mode)

```yaml
# Primary — Alert Red
primary: '#BA002C'
on-primary: '#FFFFFF'
primary-container: '#FFDAD9'
on-primary-container: '#400009'

# Secondary — Safe Green (family, check-in, confirmations)
secondary: '#006E2A'
on-secondary: '#FFFFFF'
secondary-container: '#5CFD80'
on-secondary-container: '#00732C'

# Tertiary — Info Blue (share location, neutral info)
tertiary: '#0056C5'
on-tertiary: '#FFFFFF'
tertiary-container: '#D9E2FF'
on-tertiary-container: '#001945'

# Surfaces — warm pink-tinted (to nie pure grey!)
surface: '#FFF8F7'
surface-dim: '#F5D2D1'
surface-bright: '#FFF8F7'
surface-container-lowest: '#FFFFFF'
surface-container-low: '#FFF0EF'
surface-container: '#FFE9E8'           # głównie na kartach ogólnych
surface-container-high: '#FFE1E0'      # na kartach wyróżnionych
surface-container-highest: '#FEDAD9'

# On-surfaces
on-surface: '#291616'
on-surface-variant: '#5E3F3E'

# Outlines
outline: '#936E6D'
outline-variant: '#E8BCBB'

# Error (duplikuje primary — używamy primary dla błędów)
error: '#BA1A1A'
on-error: '#FFFFFF'
error-container: '#FFDAD6'
on-error-container: '#93000A'

# Category accents (per-kategoria alertu)
cat-aggression: '#FF1744'    # agresywne osoby, kradzież, SOS
cat-fire: '#FF3D00'          # pożar
cat-accident: '#FF6D00'      # wypadek, zwierzę, zagrożenie drogowe
cat-construction: '#FFAB00'  # niebezpieczna budowa, zniszczone mienie
cat-flood: '#2979FF'         # powódź, policja
cat-ice: '#00B0FF'           # oblodzenie
cat-dark: '#78909C'          # ciemny teren
cat-drugs: '#AA00FF'         # narkotyki
```

### 2.2 Dark mode

```yaml
primary: '#FFB3B3'
on-primary: '#5C0010'
primary-container: '#920021'
on-primary-container: '#FFDAD9'

secondary: '#3CE36A'
secondary-container: '#00531E'

surface: '#1A0F0F'
surface-container: '#2A1A1A'
surface-container-high: '#342020'
on-surface: '#FFEDEC'
outline: '#A88887'
```

### 2.3 Typography

**Font family:** `Inter` (uniwersalny, świetny PL diacritics, dobre na wszystkich rozmiarach).
**Fallback:** `-apple-system, BlinkMacSystemFont, "Segoe UI"` dla native feel.

```
display-large   48sp / 56lh / 800 / -0.02em    # hero numerki (1,240)
display-small   36sp / 44lh / 700 / -0.01em    # wielkie screen headings ("Moje zgłoszenia")
headline-large  32sp / 40lh / 700 / -0.01em    # sekcje
headline-small  24sp / 32lh / 600 /  0em       # card titles
title-large     22sp / 28lh / 600
title-medium    16sp / 24lh / 500              # list item title
body-large      16sp / 24lh / 400 /  0.15px
body-medium     14sp / 20lh / 400
label-large     14sp / 20lh / 600 /  0.10px    # button text (pill CTA)
label-medium    12sp / 16lh / 600 /  0.50px    # status chip, meta
```

### 2.4 Shape scale (M3 Expressive — zróżnicowane!)

```
xs   =  4dp   # małe chipy, segment indicators
sm   =  8dp   # małe cardy, input fields
md   = 12dp   # standard inputs, outlined buttons
lg   = 16dp   # standard content cards
xl   = 24dp   # hero cards, stat tiles, bottom sheets (top)
2xl  = 28dp   # pill buttons, floating nav bar, category icon squares
3xl  = 48dp   # XXL pill (primary CTAs), SOS hero
full = 9999px # pill shapes (chips, primary buttons)
```

### 2.5 Spacing (8dp base)

```
base-unit    = 8dp
margin-mobile = 16dp     # screen side
margin-tablet = 24dp
margin-card   = 16dp     # card internal padding
gap-list      = 12dp     # między kartami list
gap-section   = 24dp     # między sekcjami
gap-tight     =  4dp     # między powiązanymi tytułem i subtitle
```

### 2.6 Elevation & depth

| Level | Use case | Style |
|---|---|---|
| 0 | Canvas / background | `surface` (pastel pink #FFF8F7) |
| 1 | Cards, list items | `surface-container` bez shadow |
| 2 | Floating nav bar, bottom sheets | `surface-container-high` + shadow `0 2 16 rgba(0,0,0,0.08)` |
| 3 | FAB / Zgłoś / SOS | `primary` + **ambient red glow** `0 0 24 rgba(186,0,44,0.25)` |
| 4 | Modals / alert dialogs | `surface-container-highest` + shadow `0 8 32 rgba(0,0,0,0.18)` |

**Zasada:** unikamy twardych czarnych shadowów. Cień koloruje się lekko na
tint primary (różowy ambient). Na FAB/SOS — "safety glow" (ambient red).

---

## 3. Komponenty — jak wyglądają

### 3.1 Bottom Navigation (floating pill)

Layout:
- Floating 16dp nad dolną krawędzią, w pill-shaped `surface-container-high` kontener z radius `28dp`, padding 8dp, shadow Level 2.
- 5 items z ikoną (28sp) + label (`label-medium` 12sp).
- Aktywny item: ikona + label w `primary`, okrągłe tło `primary-container` pod ikoną (tonal badge 40dp).
- **SOS w środku:** wyróżniony jako 56dp hero circle wystający **6dp ponad bar**, wypełniony `primary`, biały asterisk/SOS tekst, z ambient red glow shadow.

### 3.2 Top App Bar

Minimalny, transparent gdy nad mapą. Gdy nad contentem:
- Wysokość 64dp, padding 16dp.
- **Lewo:** user avatar 32dp (okrągły, border 1.5dp `outline-variant`) LUB hamburger ikona.
- **Środek:** logo "be:Safe" w `primary`, `title-large` 22sp weight 600 (opcjonalnie z shield ikoną).
- **Prawo:** bell ikona w circle container `surface-container-high` (40dp).

### 3.3 Mapa (hero screen)

- **Tło:** pełen ekran Google Maps (style standard, bez custom tint — tak jak `mapa_m3_expressive_2`).
- **Search bar:** floating top 12dp z krawędzi, pill `surface-container-lowest` (czyli white), radius full, padding 16dp, shadow Level 2. Ikony search + filter tune.
- **Alert pins:** 44dp okrągła ikonka w `cat-*` kolorze z białym stroke 3dp. **Label kapsułka** nad pinem: tło kategorii (np. `cat-fire` 80% + white text), radius full, padding 6x12dp, `label-medium`.
- **Cluster pin:** 56dp circle `primary` + biały stroke 3dp, białą liczbą w środku `title-large`.
- **Child pin:** 56dp avatar w okrągłym green border 3dp (`secondary-container` stroke + `secondary` outline), label kapsułka z imieniem nad nim (`secondary-container`).
- **Zgłoś FAB:** extended pill 56dp height, `primary`, ikona warning_amber + tekst "Zgłoś" `label-large`, bottom-right 16dp od krawędzi + 88dp od bottom (nad nav).
- **My-location FAB:** 56dp squircle `surface-container-highest`, ikona my_location `primary`, bottom-right 16dp nad Zgłoś.

### 3.4 Cards (content container)

Standard card:
- Tło: `surface-container` (różowy pastel #FFE9E8).
- Radius: `lg` 16dp (zwykła) lub `xl` 24dp (hero).
- Padding: 16dp.
- **Bez borderów** — używamy tonal differentiation.
- Hover/pressed: przechodzi do `surface-container-high`, lekkie scale 98%.

Kompozycja karty alertu:
```
┌─────────────────────────────────────┐
│ ┌────┐                              │
│ │ 🔥 │  Pożar samochodu    [Nowe]  │
│ │cat │  ul. Kwiatowa 12            │
│ └────┘  Gęsty dym, utrudnienia...   │
│                                     │
│ 👍 24  👎 2  💬 8            →      │
└─────────────────────────────────────┘
```
- Lewa ikona: 48dp rounded square (`md` 12dp), tło `cat-*-container` kolor (np. light orange), ikona `cat-*` (intense).
- Tytuł: `title-medium` bold.
- Lokacja: `body-medium` `on-surface-variant`.
- Meta row: `label-medium` + ikony outline 16sp.
- Status chip prawo-górnie: kapsułka `secondary-container`/`tertiary-container`/`primary-container` z `label-medium`.

### 3.5 Stat tiles (3-column row)

Trzy pill-cardy w rzędzie (każdy `flex: 1`, gap 12dp):
- Tło: `surface-container` / `primary-container` dla wyróżnionego.
- Radius: `xl` 24dp.
- Padding: 16dp vertical, center content.
- Wiersz górny: **Wielki numer** `display-small` 36sp w `primary`.
- Wiersz dolny: **Label uppercase** `label-medium` 12sp `on-surface-variant`.

Przykład Profile:
```
[  12k  ]  [   3   ]  [  #4   ]
[ Punkty]  [ Alerty]  [Ranking]
```

### 3.6 Segment control (pill)

```
┌───────────────────────────────────┐
│ (Aktywne)  Wygasłe   Wszystkie   │
└───────────────────────────────────┘
```
- Zewnętrzny pill `surface-container-low` full radius, padding 4dp.
- Aktywny segment: pill full `surface` biały, tekst `primary` bold.
- Nieaktywne: tekst `on-surface-variant`.

### 3.7 Filter chips row

Pill chips horizontally scrollable, gap 8dp.
- Nieselected: outlined `outline-variant` (1.5dp), `surface` background, tekst `on-surface`.
- Selected: filled `primary-container`, tekst `on-primary-container`, checkmark prepend ikona 16sp.

### 3.8 Primary button (CTA)

- Pill shape full radius.
- `primary` background, `on-primary` tekst.
- Height: **56dp** (standard), **64dp** dla hero actions ("Jestem bezpieczny/a", "Opublikuj zgłoszenie").
- Label `label-large` 14sp weight 600.
- Opcjonalnie ikona left 20sp.
- Full-width jak nie ma bratniego buttona, inaczej equal flex w row.

### 3.9 Secondary button

- Outlined pill, 2dp border `outline`.
- Transparent background.
- Tekst `on-surface`.
- Height: 48dp.

### 3.10 Input field

- Filled style, `surface-container-low` background.
- Radius: `md` 12dp.
- Bottom stroke 1dp `outline` (focused: 2dp `primary`).
- Label floats up po focus.
- Error: stroke + helper text `primary` (alert red).

### 3.11 Status chip

Mała kapsułka w prawym-górnym rogu karty. 24dp height, padding 4x8dp, `label-medium` bold. Typy:
- **Nowe** — `primary-container` bg, `on-primary-container` text.
- **W toku** — `tertiary-container` bg, `on-tertiary-container` text.
- **Rozwiązane** — `secondary-container` bg, `on-secondary-container` text.
- **Wygasłe** — `surface-container-high` bg, `outline` text.

### 3.12 Avatar

- Circle, 32dp list / 48dp header / 80dp profile.
- Border: 1.5dp `outline-variant` zwykle.
- Border: 3dp `secondary` dla family members.
- Status dot 12dp bottom-right: `secondary` online / `outline` offline / `primary` SOS.

---

## 4. Screen-by-screen — z których eksperymentów wziąć bazę

Gdy będziesz generował/wklejał kod Flutter, najbliższe designy do
wizualnego odwzorowania (patrz odpowiednie `screen.png` + `code.html`):

| Ekran | Najlepszy base z | Touch-up z |
|---|---|---|
| **Map** | `mapa_m3_expressive_2` | marker label z `mapa_m3_expressive_2`, glass nav z `mapa_m3_expressive_1` |
| **Onboarding (5 slajdów)** | `onboarding_m3_expressive`, `onboarding_1_powitanie` – `onboarding_5_start` | pill pagination z M3E |
| **Login / Register** | brak dedykowanego — bazuj na `profil_m3_expressive_2` style + forms | |
| **Create Alert (Zgłoś)** | `zg_o_zagro_enie_m3_expressive` | category chips row |
| **Alert Detail** | `szczeg_y_alertu_m3_expressive` | `szczeg_y_alertu_be_safe` komentarze |
| **Profile** | `profil_m3_expressive_1` (stat tiles) | `profil_m3_expressive_2` check-in sekcja, `profil_edycja` edit form |
| **My Alerts** | `moje_zg_oszenia_m3_expressive` (gradient cards) | `moje_zg_oszenia_be_safe` status chips |
| **Stats** | `statystyki_m3_expressive` | `statystyki_nowy_styl` charts |
| **Family** | `rodzina_m3_expressive` | `rodzina_brak_grup` empty state |
| **Family Group** | `grupa_rodzinna_mapa`, `grupa_rodzinna_cz_onkowie` | |
| **Location History** | `historia_lokalizacji` | polyline + markers OK |
| **Badges** | `odznaki_m3_expressive` (locked/unlocked) | |
| **News** | `aktualno_ci_m3_expressive` | |
| **Ranking** | `ranking_m3_expressive` (podium top-3) | |
| **Referral** | `zapro_znajomych` (QR code + copy) | |
| **Emergency Numbers** | `numery_alarmowe_m3_expressive` | |
| **Settings** | `ustawienia_m3_expressive` | |
| **Legal** | `regulamin_m3_expressive`, `polityka_prywatno_ci` | |
| **SOS Dialog** | `sos_m3_expressive_2` (full-bleed red confirm) | `sos_m3_expressive_1` jako alt |
| **Alerty list** | `alerty_m3_expressive_2` | |
| **Loading state** | `profil_adowanie` (shimmer) | użyj pakietu `shimmer` |
| **Tablet** | `mapa_tablet` | NavigationRail + side pane |

---

## 5. Co dalej

### Opcja A — z powrotem do Stitcha
Wklej jeden master-prompt (`07_MASTER_PROMPT.md` — stworzę osobny, jeśli
chcesz) i wygeneruj nowy projekt z wszystkimi screenami w spójnym stylu.

### Opcja B — implementacja w Flutter (rekomendowane)
Mając już screeny referencyjne + kod HTML, przepisujemy je na Flutter
widgety używając istniejącego `ThemeProvider`. Tokens z sekcji 2 trafiają
do `mobile/lib/theme/design_tokens.dart`. Każdy screen to jeden pull request
z reference do `screen.png` w opisie.

### Opcja C — Figma
Eksportuj screeny do Figma przez Stitch ("Export to Figma") — dostaniesz
components + design tokens. Potem projektant dopracowuje, my implementujemy
z Figma specs.

---

**Podsumowanie w jednym zdaniu:**

**be:Safe Community Modern = Material 3 Expressive + alert-red brand + ciepłe
różowe pastele + floating glass nav + hero SOS + tonal containment.**

Nowoczesne, ale budzi zaufanie. Wyraziste, ale nie stresujące. Community,
nie command center.
