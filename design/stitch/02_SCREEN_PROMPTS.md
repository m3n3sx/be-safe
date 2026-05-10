# 02 — Screen Prompts (iteracyjne, screen po screenie)

> **Zasada żelazna:** jeden prompt = jeden ekran ALBO jedna zmiana na istniejącym ekranie.
> Stitch **resetuje layout** gdy dostanie kilka zmian naraz.
>
> Prompty uporządkowane w kolejności tworzenia. Każdy zaczyna się od `Add a new screen:` — Stitch
> wtedy zrozumie że ma dodać nowy, a nie nadpisać istniejący.

---

## 2.1 Onboarding (5 slajdów)

```
Add a new onboarding flow with 5 swipeable slides.

Slide 1: "Witaj w be:Safe". Large illustration of a friendly safety shield. Subtitle: "Twoja społeczność dba o bezpieczeństwo". "Dalej" button at bottom.

Slide 2: "Zgłaszaj zagrożenia". Illustration of a person tapping a map pin. Subtitle: "Ostrzegaj sąsiadów o niebezpieczeństwach w Twojej okolicy."

Slide 3: "Bezpieczeństwo rodziny". Illustration of a parent and child with a location beacon. Subtitle: "Zobacz gdzie są Twoje dzieci i ustaw bezpieczne strefy."

Slide 4: "SOS w jednym kliknięciu". Large red SOS circle illustration. Subtitle: "W nagłej sytuacji jedno tapnięcie powiadomi rodzinę i okolicznych użytkowników."

Slide 5: "Zaczynajmy". Illustration of a community map. Primary button: "Zaloguj się". Secondary: "Kontynuuj jako gość".

Pagination dots at bottom of each slide. "Pomiń" (Skip) button top-right on slides 1–4. Clean Material 3 style, large illustrations, white background.
```

---

## 2.2 Login / Register

```
Add a new login screen.

Header: "be:Safe" logo with a red shield icon, subtitle "Bezpieczeństwo społeczności".

Primary CTA: large filled button "Zaloguj się przez Google" with the Google G icon.

Divider: "lub" (or) with thin horizontal lines.

Email input field with placeholder "Email", password field with placeholder "Hasło" and eye toggle. Small link "Zapomniałeś hasła?" right-aligned under password.

Secondary filled red button: "Zaloguj się".

Footer: "Nie masz konta? Zarejestruj się" as a text link. Small print below: "Logując się akceptujesz Regulamin i Politykę prywatności" with two underlined links.

Pass the vibe: clean, welcoming, safety-focused. White background, form elements with rounded 12dp corners.
```

---

## 2.3 Create Alert (zgłoszenie zagrożenia)

```
Add a new "Create Alert" (Zgłoś zagrożenie) screen.

Top app bar with back arrow and title "Zgłoś zagrożenie".

A horizontally scrollable row of category chips with icon + label below each. Categories in Polish: Agresywne osoby, Kradzież, Wypadek, Pożar, Powódź, Oblodzenie, Niebezpieczna budowa, Narkotyki, Niebezpieczne zwierzę, Nieoświetlony teren, Akcja policyjna. Each chip has a distinct accent color when selected.

Below: a small inline map preview showing the user's current location with a draggable red pin. A "Dostosuj lokalizację" (adjust location) text link below the map.

Text field: "Tytuł zagrożenia" (short, one line).
Multi-line text area: "Opis (opcjonalne)" with placeholder "Podaj więcej szczegółów...".

"Dodaj zdjęcie" button with camera icon — takes a photo or picks from gallery.

A slider labeled "Jak długo alert ma być aktywny?" with values 1h / 3h / 12h / 24h.

At the bottom: large full-width primary button "Opublikuj zgłoszenie" in alert red.

All UI in Polish. Material 3 style, rounded corners, plenty of breathing room.
```

---

## 2.4 Alert Detail (szczegóły zagrożenia)

```
Add a new screen "Alert Detail" for viewing a single reported threat.

Top: a compact map showing the threat location with a red pin and a transparent red circle indicating the alert radius. Map takes about 30% of the screen height.

Below the map, a header card with:
- Big category icon in a colored circle (red for aggression, orange for fire, etc.)
- Title of the alert
- Subtitle with category name and "X min temu" (time ago)
- Small avatar and username of reporter with a verified badge if applicable, plus reputation score as a star count.

Two large voting buttons side by side: "Potwierdzam" (green with check icon) and "Nieaktualne" (grey with X icon). Show vote counts next to each.

Optional photo below the vote buttons if the alert includes a picture.

Description text.

"Komentarze" (Comments) section heading with count. List of comments with avatar, username, timestamp, text. Each comment is a compact card.

Fixed bottom bar: text input "Napisz komentarz..." with a filled send button on the right.

Top-right app bar actions: share icon and flag icon for reporting abuse.

Vibe: informative, balanced (not panic-inducing). Red accents only on category icon and important warnings.
```

---

## 2.5 Profile

```
Add a new Profile screen.

Top: large circular avatar (80dp) with camera icon overlay in bottom-right (tap to change). Below: username in bold, email in smaller grey text. Next to the name show a reputation badge: a star icon with the number (e.g. "120 ⭐").

A prominent green full-width pill-shaped button: "Jestem bezpieczny/a" with a check-circle icon. This is the family check-in action.

Section "Promień alertów" with a slider (100 m – 5 km). Current value shown as "500 m". A small "Zapisz" button below.

Menu list of items with leading icon, title, and chevron-right:
- 🏆 Ranking użytkowników
- 📊 Statystyki
- 📍 Udostępnij lokalizację
- 📋 Moje zgłoszenia
- 🎁 Zaproś znajomych
- 🥇 Odznaki
- 📰 Aktualności
- 🚨 Numery alarmowe
- 👨‍👩‍👧 Grupy rodzinne
- ⚙️ Ustawienia

Each row is a flat list tile, full-width tappable. Group dividers between logical sections.

Bottom: outlined "Wyloguj się" button in red.

Material 3, clean white/grey surfaces, plenty of padding.
```

---

## 2.6 Family (lista grup)

```
Add a new "Rodzina" (Family) screen.

Top app bar title "Rodzina" with a "+" action icon to create a new group.

If the user has no family groups: empty state centered. Large family icon, headline "Nie masz jeszcze grupy rodzinnej", subtitle "Utwórz grupę aby móc śledzić lokalizację bliskich i otrzymywać alerty.", big green CTA button "Utwórz grupę".

If the user has groups: a list of group cards. Each card shows:
- Group name in bold
- Avatar stack of members (overlapping circles)
- "X członków" under the avatars
- "Ostatnia aktywność: 5 min temu" as microcopy
- Right-side chevron

Bottom sheet FAB "+ Dodaj grupę" if there are already groups.

Material 3 style, green accent color for family sections, warm tone.
```

---

## 2.7 Family Group Detail

```
Add a new screen "Family Group Detail".

Top app bar: group name as title, 3-dot menu on the right with "Edytuj grupę", "Zaproś osoby", "Opuść grupę".

Segmented control at the top with two tabs: "Mapa" and "Członkowie".

Map tab: a full-width map with green circular avatars for each family member at their location. Tap an avatar to see a tooltip with name + last updated time. "Wróć do moich lokalizacji" fab at bottom-right.

Members tab: list of members. Each row has:
- Avatar
- Name + role badge (Rodzic / Dziecko)
- Status pill (Online / Offline)
- Last location text ("Szkoła Podstawowa nr 2, 15 min temu")
- Battery icon with percentage
- Chevron to open full history

Bottom: green full-width button "Ustaw bezpieczną strefę" (geofence).

Vibe: warm, protective, family-focused. Green as primary, soft edges.
```

---

## 2.8 My Alerts (moje zgłoszenia)

```
Add a new "Moje zgłoszenia" (My Alerts) screen.

Top app bar title "Moje zgłoszenia" with a back button.

Segmented control "Aktywne / Wygasłe / Wszystkie".

List of the user's own alert cards. Each card shows:
- Category icon in a colored circle on the left
- Alert title (bold, ellipsis if long)
- Chip row with category name and time left ("3h 12min")
- Row with stats: 👍 X · 👎 Y · 💬 Z
- 3-dot menu on the right (Szczegóły / Przedłuż o 3h / Edytuj opis / Usuń)

Empty state: "Nie masz jeszcze żadnych zgłoszeń" with a large CTA "Zgłoś pierwsze zagrożenie".

Material 3, list with subtle card elevation.
```

---

## 2.9 Stats (statystyki okolicy)

```
Add a new "Statystyki" screen.

Top: three number tiles in a row: "Dziś / Tydzień / Wszystkie" with large count numbers and coloured accents (red / orange / blue).

Below: section "Najczęstsze zagrożenia w Twojej okolicy (30 dni)". A horizontal bar chart where each row shows an icon, category label in Polish, and a proportional colored bar with the count on the right.

Below that: a line/area chart "Aktywność w ostatnich 14 dniach" with day labels on x-axis.

Below: a heatmap thumbnail of the user's city area with bright spots indicating hotspots.

All charts have rounded corners, soft shadows, minimal gridlines. Stats cards use the matching category colors.
```

---

## 2.10 Settings

```
Add a new "Ustawienia" screen.

Top app bar title "Ustawienia".

Grouped sections:

Section "Wygląd":
- Row "Motyw kolorystyczny" with a preview swatch, opens a bottom sheet showing 6 color themes (Red, Blue, Green, Purple, Orange, Teal) as color circles to pick from. Current one has a checkmark.
- Switch row "Automatyczny tryb (jasny/ciemny)".
- Switch row "Dynamiczne kolory (Material You)".

Section "Powiadomienia":
- Switch row "Alerty zagrożeń"
- Switch row "Powiadomienia rodzinne"
- Switch row "Dźwięk"
- Switch row "Wibracje"

Section "Lokalizacja":
- Row "Promień alertów" with current value, opens slider
- Switch row "Tryb tła (pozwala apce działać gdy jest zamknięta)"
- Switch row "Historia lokalizacji"

Section "Konto":
- Row "Eksport danych (GDPR)"
- Row "Usuń konto" in red

Section "Informacje":
- Row "Regulamin"
- Row "Polityka prywatności"
- Row "Wersja 2.0.0" (disabled, grey)

Material 3 tall list with leading icons.
```

---

## 2.11 Badges (odznaki)

```
Add a new "Odznaki" screen.

Top app bar title "Odznaki" with a back button.

Section header "Zdobyte odznaki (3)". Grid of 3 columns. Each badge is a rounded 16dp square with:
- Large emoji or icon (🏆 🎖 🥇) top-center
- Badge name in bold below ("Strażnik miasta")
- Subtle colored border in a category color

Section header "Do zdobycia (7)". Same grid, but badges are greyed-out (50% opacity) with a lock overlay. Tapping opens a dialog showing progress ("8 / 10 zgłoszeń").

Empty state if none: emoji-trophy illustration with headline "Twoje pierwsze zgłoszenie odblokuje pierwszą odznakę".
```

---

## 2.12 News / Blog

```
Add a new "Aktualności" (News) screen.

Top app bar title "Aktualności".

Horizontal filter chips at the top: Wszystkie / Bezpieczeństwo / Rodzina / Porady / Ostrzeżenia.

List of article cards. Each card has:
- Small category pill at the top (e.g. "BEZPIECZEŃSTWO")
- Article title in bold (max 2 lines)
- Two lines of lead text in grey
- Row at bottom: date + reading time ("5 min czytania") + optional thumbnail on the right

Tapping opens a bottom sheet that expands to full-screen with the article body, a handle bar at top, and swipe-down to close.

Material 3 card layout, white surfaces, subtle shadows.
```

---

## 2.13 Ranking

```
Add a new "Ranking użytkowników" screen.

Top app bar title "Ranking" with a back button.

Segmented "Mój miasto / Wszyscy / Znajomi" at the top.

A podium section for top 3: gold / silver / bronze with avatars, usernames, and reputation scores. The gold (1st) is centered and slightly bigger.

Below: a sorted list starting from rank 4. Each row has:
- Rank number on the left (bold)
- Avatar
- Username
- Small medal emoji if top 10
- Reputation score on the right with a star icon
- Subtitle with "X zgłoszeń · Y potwierdzeń"

The current user's row has a highlighted background (primary tint).

Clean, gamified but not childish. Medal colors match their metal.
```

---

## 2.14 Referral

```
Add a new "Zaproś znajomych" screen.

Top: a friendly illustration of hands exchanging a gift box. Headline "Zapraszaj i zdobywaj punkty!". Subtitle "Za każdą zaproszoną osobę otrzymujesz 10 punktów reputacji".

Box with the user's referral code, large letters "MENES2026", with a tap-to-copy icon on the right.

A QR code roughly 200x200dp centered below the code.

Stats card below: two columns "Poleconych: 5" | "Zdobyte punkty: 50".

Bottom: full-width primary button "Udostępnij zaproszenie" with a share icon.

Small footer text: "Polecaj be:Safe znajomym i rodzinie — razem tworzymy bezpieczniejsze miasto."
```

---

## 2.15 Emergency Numbers

```
Add a new "Numery alarmowe" screen.

Top app bar title "Numery alarmowe".

Large warning banner at the top: "W sytuacji zagrożenia życia dzwoń pod 112 — apka NIE zastępuje numerów alarmowych.". Soft red background, white text.

A grid (or list on small screens) of emergency number cards. Each card has:
- Large number (112, 997, 998, 999, 986, etc.) in bold
- Name below ("Numer alarmowy", "Policja", "Straż pożarna", "Pogotowie", "Straż miejska")
- A phone call icon top-right
- Full card is tappable and triggers the native tel: launcher

Categories visually separated: "Ogólne" / "Służby" / "Specjalistyczne" / "Infolinie" (z. np. Telefon Zaufania dla Dzieci).

Polish.
```

---

## 2.16 Location History

```
Add a new "Historia lokalizacji" screen for a family member.

Top app bar: title "Trasa: [imię dziecka]". Calendar icon action to change the date.

Stats strip under app bar: "Punkty: 124" | "Przeszłe: 4.2 km" | "Data: 09.05.2026".

Map fills the rest of the screen. A blue polyline traces the day's path. Green pin at the start (morning location), red pin at the end (last position). Small clock markers along the route every hour.

Bottom sheet (collapsible) with a scrollable list of notable stops: each stop has time range ("08:15 – 14:45"), address, duration.

Vibe: informative, parent-focused, blue/green palette (not alarming).
```

---

## 2.17 Legal (Regulamin / Polityka)

```
Add a new "Regulamin" screen (and a sibling "Polityka prywatności").

Top app bar title, back button, share icon action.

Body is a long scrollable text with:
- H1 "Regulamin aplikacji be:Safe"
- Small grey "Ostatnia aktualizacja: 2026-05-09"
- Headings §1, §2, ... for sections
- Numbered lists with 1.5 line height
- Inline links to alert.u235.pl underlined in primary color

Typography-focused screen, plenty of padding, max line length for readability, no decorative images.
```

---

## 2.18 Tablet landscape variant

```
Create a tablet (landscape, width 1024dp+) variant of the Map screen.

Left side: a vertical navigation rail (NavigationRail Material 3 style) with 5 icons aligned with their labels: Mapa, Alerty (badge), SOS (big red circle), Rodzina, Profil.

Center: the Google-style map takes the remaining width minus the right panel.

Right side (320 dp): a persistent "Alerty w okolicy" panel with header showing count, and a scrollable list of compact alert cards. Each card: category icon + title + distance. Tap focuses map on the alert.

Search bar floats at the top of the map section. "Zgłoś" red button floats at bottom-right of the map area.

Balanced three-column layout, rail on left is about 80dp wide, map fills middle, alerts list on right.
```

---

## Co dalej

Jeśli **jakiś screen wyszedł nie tak** — idź do `03_RECOVERY_PROMPTS.md` dla promptów naprawczych.

Gdy masz już wszystkie screeny — użyj Stitch MCP w Kiro żeby:
1. `list_projects` — znajdź projekt ID
2. `get_screen_code` per screen — pobierz HTML/CSS (jeśli chcesz referencji)
3. `get_screen_image` — pobierz PNG screenshotów do `design/` w repo

Szczegóły w `05_MCP_WORKFLOW.md`.
