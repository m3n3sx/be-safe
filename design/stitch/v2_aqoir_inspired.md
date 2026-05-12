# be:Safe v2 — Aqoir-inspired (Stitch prompts)

> Styl zainspirowany **Aqoir Wellness App** (Linkup ST, Daria Ebadian — Bronze A' Design Award 2026).
> Kluczowe elementy estetyczne Aqoir: **glow orbs**, **water-blob gradients**, **very thin typography dla big numbers**,
> **near-white surfaces z subtle cyan/mint tint**, **dark navy pill buttons**, **glassmorphism floating widgets**.
>
> Adaptacja: zachowujemy emocjonalną spokojność i elegancję Aqoir, ale w kontekście community safety —
> czerwony glow dla alertów, zielony glow dla "safe/family OK", navy dla primary actions.

## Paleta "Calm Alert" (Aqoir-style dla be:Safe)

```yaml
# Primary actions (dark)
ink: '#1A2027'         # navy dla primary CTAs, text
ink-soft: '#2C3440'    # secondary text

# Accent states — 3 glow kolory
alert-coral: '#FF7A7A' # alert (softer than pure red), alarmy, SOS glow
safe-mint:   '#7DD3AC' # "safe/OK", family member OK, check-in, "fully safe"
calm-aqua:   '#9EEBEC' # info, hydration→monitoring, calm default state

# Backgrounds — very light z subtle tint
surface-bg:      '#F8F9FB' # canvas, near-white z lekkim cool tint
surface-tint:    '#E8F4F6' # subtle cyan wash (for gradient meshes)
surface-mint:    '#E8F7F0' # subtle mint wash (safe states)
surface-coral:   '#FBE8E8' # subtle coral wash (alert states)
surface-white:   '#FFFFFF' # floating cards

# On-surface (text)
on-surface:          '#1A2027' # primary text deep charcoal
on-surface-variant:  '#6B7480' # secondary text
on-surface-subtle:   '#9AA3AE' # hints, timestamps

# Outlines
outline-soft:    '#E3E8EC'
outline-faded:   '#F0F3F5'

# Button/control specials
pill-dark-bg:    '#1A2027' # dark navy pill button
pill-dark-fg:    '#FFFFFF'
circle-fab-bg:   '#1A2027' # circular FAB dark
```

## Typography "whisper + display"

```
display-huge   96sp / 104lh / weight 100 / letter-spacing -0.04em  # "4/4" big stat, "37%" progress
display-big    64sp /  72lh / weight 200 / letter-spacing -0.03em  # "1.5 L" type numbers
display-med    36sp /  44lh / weight 300 / letter-spacing -0.02em  # screen hero (“Start enhanced calibration”)
headline       24sp /  32lh / weight 500                          # section titles
title          20sp /  28lh / weight 500
body           16sp /  24lh / weight 400
label          14sp /  20lh / weight 500 / letter-spacing 0.01em  # button labels
micro          12sp /  16lh / weight 400                          # hints, meta
```

**Rule:** używamy **weight 100-300** dla display (thin and whispery — to charakterystyczny element Aqoir),
**weight 400-500** dla body/labels. Nigdy bold hero numbers.

## Shapes

- Primary pill button (dark navy): **32dp full radius**, height **56dp**, ikona + label
- Secondary/tertiary pill (light): transparent z outline `outline-soft`, 32dp radius
- Circular FAB: **56dp circle**, dark navy
- Floating cards: **24dp radius**, white bg, soft shadow `0 4 16 rgba(26,32,39,0.06)`
- Glassmorphism widget: `rgba(255,255,255,0.7)` + `backdrop-blur(20px)`, 1px border `rgba(255,255,255,0.8)`
- Glow orb: radial gradient z fading edges (see Prompt A)

## Kluczowy element wizualny — "glow orb"

To **signature** Aqoir. Używamy w be:Safe jako:
- Home screen central hydration-like indicator → **safety score orb**
- SOS screen → **large pulsing coral orb**
- Map centered on user location → **subtle aqua halo**

Jak opisać w Stitch:
> "A large circular glow orb 240dp in diameter, centered. Radial gradient from solid center color
> fading to transparent edges, creating a soft breathing aura effect. No hard edge — seamless
> blend into white background."

---

# PROMPTY

## Prompt A — Master (wklej pierwszy w nowym Stitch projekcie)

```
Design a mobile Android app called "be:Safe" — a minimalist, emotionally calm Polish community safety app that combines neighborhood threat alerts with family location tracking. Visual style is inspired by premium wellness apps: near-white surfaces with very subtle cyan/mint gradient washes, extremely thin display typography (weight 100-300) for big numbers, dark navy pill-shaped primary buttons, glow orbs with soft radial gradients as central visual anchors, and floating glassmorphism widget cards with 24dp rounded corners.

All UI text in Polish.

Palette. Primary text and dark pill buttons use deep navy #1A2027. Three accent colors used only as glow orbs and status tints: alert-coral #FF7A7A for threat alerts and SOS, safe-mint #7DD3AC for "I'm safe", family OK, check-ins, and calm-aqua #9EEBEC for info, maps, and default monitoring state. Background surface is #F8F9FB near-white with subtle cyan tint. Cards are pure white #FFFFFF with soft shadows. No hard borders — use whitespace and soft color washes for structure.

Typography. Use a thin geometric sans-serif like Inter with weight 100-200 for large display numbers (e.g. "4/4", "37%"), weight 300 for screen hero titles ("Mapa", "Moje zgłoszenia"), weight 500 for labels and section headings, weight 400 for body. Big numbers feel whispered, not shouted. Generous line-height and negative letter-spacing for display.

Bottom navigation. Floating dark navy pill bar 24dp above bottom edge. Contains 4 icon-only items (Mapa, Alerty, Rodzina, Profil) plus a large circular dark navy SOS button 56dp at the right side, slightly separated from the pill. Active item has white circular dot under the icon. Labels only appear in focus/selected state as a thin text under the icon.

Main Map screen. Minimal top app bar with "Wszystko w porządku" small title and subtitle "Twoja okolica jest bezpieczna" in medium weight. Large central glow orb 240dp diameter with radial gradient — mint-green when area is safe, coral-red when there's an active alert within radius, aqua-cyan when quiet/monitoring. Glow is soft, breathing, seamlessly blending into the white background. Below orb, a subtle "Zobacz mapę →" text link. At bottom third a floating glassmorphism widget card showing "Dzisiejsza aktywność" with two tiny stats: "3 alerty w pobliżu" and "5 potwierdzeń". The full map is an alternate view accessed by tapping through — this primary view is the calm "status" experience. A dark navy pill extended FAB "Zgłoś zagrożenie" at bottom-right-ish, sliding away when scrolled.

Vibe: calm, emotionally intelligent, premium wellness-app aesthetic, but purposeful about safety. Not childish, not corporate, not alarmist. Very generous whitespace. Thin typography whispers. Dark navy buttons feel confident. Glow orbs breathe. Phone mockup on an off-white studio background.
```

---

## Prompt B — Per-screen iterations (one at a time)

### B1. Onboarding — 5 slajdów "swipe up/down"

```
Add 5 onboarding slides for be:Safe in Aqoir-inspired style. Each slide is full-bleed on a white background with subtle cyan gradient mesh in the background (very faint, like breath on glass).

Slide 1: Hero has a large aqua water-blob-like gradient orb 340dp in the center, organic blob edges breathing softly (use radial gradient with irregular shape). Above orb, display-huge "be:Safe" in weight 100. Below orb: tiny label "Przesuń w górę aby zacząć · Przesuń w dół aby się zalogować" with thin up/down chevron icons.

Slide 2: Hero title "Zobacz zagrożenia wokół siebie" display-med weight 300. Below, an illustration-style map chip with a single coral glow dot indicating an alert. Subtitle: "Alerty sąsiadów i służb pojawiają się na mapie w czasie rzeczywistym." Continue button is a dark navy pill "Dalej" at bottom.

Slide 3: Hero title "Chroń rodzinę jednym tapnięciem". Below, two small circular avatar glows in mint green connected with a thin dashed line. Subtitle: "Widzisz gdzie są bliscy, a oni wiedzą że jesteś bezpieczny."

Slide 4: Hero title "SOS zawsze w zasięgu kciuka". Below, a large coral glow orb with subtle pulse aura, thin label "SOS" inside in weight 200. Subtitle: "Jedno przytrzymanie powiadamia rodzinę, znajomych i społeczność."

Slide 5: Hero title "Witamy w be:Safe". Below, 2 stacked dark navy pill buttons: "Zaloguj się przez Google" (with Google G icon) and "Kontynuuj jako gość" (outlined, transparent).

Every slide has 5 thin dots at the bottom as pagination, active one slightly wider like a small pill. Above slides 1-4 a subtle "Pomiń" text button top-right in weight 400.
```

### B2. Login / Register

```
Design the login screen in Aqoir style. Full-bleed white background with subtle cyan radial gradient in the upper third.

Center-top: the word "be:Safe" in display-big, weight 100, with a tiny coral drop icon above. Below: thin microcopy "Zaloguj się do swojego konta" in on-surface-variant.

Middle section: two input fields stacked with 16dp gap. Fields are borderless on a subtle surface-tint background, 56dp tall, 20dp rounded corners, thin placeholder text "Email" and "Hasło" in weight 300, on-surface-subtle color. When focused: a very thin 1.5dp calm-aqua underline appears at the bottom of the field.

Below inputs: small right-aligned text link "Zapomniałeś hasła?" in 14sp weight 400, on-surface-variant.

Below that, a large dark navy pill button "Zaloguj się" 56dp tall, full width, white label weight 500. Under it: a thin divider with "lub" label in the middle. Then an outlined pill button "Zaloguj się przez Google" with the Google G icon, same height, transparent background, 1.5dp outline-soft border.

Bottom: microcopy "Nie masz konta? Zarejestruj się" center-aligned. "Zarejestruj się" is a dark navy link (weight 500).

Tiny disclaimer at the very bottom in 12sp on-surface-subtle: "Logując się akceptujesz Regulamin i Politykę prywatności."
```

### B3. Home — status orb view

```
Design the main home screen for be:Safe in Aqoir style.

Top app bar: transparent, 64dp tall. Left side: subtle hamburger icon outline weight 300. Right side: small bell icon outline. Both on transparent background, dark navy strokes.

Below app bar, a generous 32dp padding area. Hero title on the left: display-med "Wszystko w porządku" weight 300. Below it: "Twoja okolica jest bezpieczna" in body weight 400, on-surface-variant.

Centered in the upper-middle of the screen, a huge glow orb 280dp diameter. It's a radial gradient from solid mint-green #7DD3AC at center fading to transparent at the edges. No hard border. Above the orb, tiny label "poziom bezpieczeństwa" micro weight 400. Inside the orb, a single large number in weight 100: "9/10" display-huge.

Below the orb, a small text link "Zobacz mapę →" in label size with chevron arrow.

Scroll down to a subtle horizontal divider, then a section "Dzisiejsza aktywność" headline weight 500. Below, three horizontal glassmorphism widget cards side-by-side:

Card 1: icon of an alert drop + number "3" in display-med weight 200 + microlabel "alerty w pobliżu" on-surface-variant.

Card 2: icon of a thumbs-up + number "12" + "potwierdzeń społeczności".

Card 3: icon of a family silhouette + number "2/2" + "bliscy online".

All cards are white #FFFFFF, 20dp radius, soft shadow, 16dp internal padding.

Floating at the bottom-right 24dp from edges: a dark navy extended pill FAB "Zgłoś" with an alert-triangle icon. Above the FAB at the very bottom, the floating pill navigation bar described in the master prompt.
```

### B4. Map full view

```
Design the full map screen for be:Safe in Aqoir style. A clean Google Maps tile layer in a light muted style takes most of the screen.

Floating top search bar: a white pill, 56dp tall, 28dp radius, soft shadow, subtle glassmorphism. Left: thin search icon outline. Placeholder text weight 300: "Szukaj adresu lub miejsca". Right side of the pill: a filter icon outline.

Below the search bar, a horizontal row of category filter chips with 12dp gap, scrollable. Chips are small white pills with icon + short label, 32dp tall. Selected chip has a dark navy background with white icon+label. Example chips: "Wszystkie", "Agresja", "Wypadek", "Pożar", "Powódź", "Budowa", "Ciemny teren".

On the map, alert pins are 32dp coral-colored circles (#FF7A7A) with a thin white ring outline and a soft coral glow bloom behind each. No labels — just the color-coded pin with a tiny category icon in white inside. Tapping a pin opens a bottom sheet.

Family pins use 40dp circles with the family member's avatar inside, mint-green 2dp ring around it, and a soft mint glow bloom.

The user's own position is a smaller 16dp blue dot with a soft aqua pulse aura.

Bottom: a floating white glassmorphism card 80dp tall with a soft handle at top. Content: "3 aktywne alerty w twojej okolicy" weight 500 + tiny coral chip "3". Below tap opens a sorted list.

Floating FAB at bottom-right: dark navy circle 56dp with a target/crosshair icon (re-center on me). Below it, another pill FAB "Zgłoś" with plus icon in coral.

Bottom nav bar floats above everything.
```

### B5. Alert detail with live chat

```
Design the alert detail screen in Aqoir style.

Top: small back chevron on the left, alert title on the right side is a tiny chip "Aktywny · 2h zostało" in coral pill. No top app bar beyond this.

Below, a large hero glow orb 200dp in coral (#FF7A7A), centered. Inside the orb: the category icon 40dp in white stroke weight 200 (e.g. a person-walking icon for "aggressive person"). Below the orb, alert title in display-med weight 300: "Agresywna osoba w parku". Subtitle tiny: "Park Saski · 200 m od ciebie · 15 min temu".

Below hero, three horizontal pill buttons equal width:
- "Potwierdzam" — outlined mint-green border, mint text
- "Nieaktualne" — outlined grey
- "Udostępnij" — outlined navy

Below buttons, a floating white card 24dp radius 16dp padding with description text weight 400: "Młody mężczyzna w czarnej bluzie zaczepia przechodniów w okolicy fontanny."

Below, photo if attached in a 20dp rounded rectangle.

Below, a confirmation row: a subtle mint dot + "12 osób potwierdziło" + "2 odrzuciło" + "8 komentarzy". All micro weight 400.

Large section heading "Rozmowa w okolicy" headline weight 500. Below, a scrollable conversation with comment bubbles. Each comment has a tiny circle avatar 32dp (mint/aqua/coral depending on user's status), username weight 500 14sp, a bubble 16dp radius with weight 400 body text, and a subtle time "3 min temu" below.

Fixed bottom input: full-width glassmorphism pill bar with placeholder "Napisz..." weight 300 and a dark navy circle send button on the right. Over the keyboard the pill nav stays hidden.
```

### B6. Create alert / Zgłoś zagrożenie

```
Design the create-alert form screen for be:Safe in Aqoir style.

Top: back chevron + centered title "Zgłoś zagrożenie" headline weight 500.

Body scrollable:

Section "Kategoria". A horizontal scrollable row of category chips, each is a small glassmorphism pill 40dp tall with an icon + label weight 400. Selected chip scales up slightly, has a subtle mint-green shadow glow, and the icon turns mint-green.

Section "Lokalizacja". A rounded 20dp rectangle map preview 160dp tall with a draggable red pin and a soft coral glow halo around it. Below the map: "ul. Marszałkowska 123 · 15 m" in micro weight 400 on-surface-variant, with a tiny pencil icon to edit.

Section "Opis". A minimalist text area — no bordered rectangle. Just a tiny label "Opis (opcjonalne)" and thin underline below empty space. Placeholder weight 300: "Dodaj szczegóły które mogą pomóc innym...". Below right, a character counter "0/500" on-surface-subtle.

Section "Zdjęcie". A large rounded 20dp rectangle 120dp tall with a dashed outline-soft border, centered dashed camera icon outline and label "Dodaj zdjęcie" weight 400. Tapping opens camera/gallery chooser.

Section "Jak długo?". A horizontal slider with 4 thin tick-marks labelled "1h / 3h / 12h / 24h". Active tick is filled mint-green with a small filled circle selector. Below the slider: big display-big number like "3h" weight 200 centered.

Bottom fixed: full-width dark navy pill button "Opublikuj zgłoszenie" 56dp tall with small alert-triangle icon on the left.

Vibe: no form feels heavy. Everything floats. Very airy.
```

### B7. Profile

```
Design the profile screen for be:Safe in Aqoir style.

Top: small settings gear icon right, notification bell left (both outlined, weight 300).

Hero section: a 160dp glow orb 112dp circle photo avatar in the center, surrounded by a thin mint-green ring glow. Below avatar, username in display-med weight 300: "Anna Kowalska". Below that, a small mint chip "Aktywny członek społeczności" with micro label, 24dp height.

Below, three stat cards in a row with 12dp gap. Each card is glassmorphism white, 24dp radius, 16dp padding:
- "Punkty" — display-big "1,240" weight 100 mint-green + micro label
- "Zgłoszenia" — display-big "18" weight 100 navy + "opublikowanych"
- "Ranking" — display-big "#4" weight 100 aqua + "w okolicy"

Below, a primary section "Jestem bezpieczny/a" — a huge full-width mint-green pill button 64dp tall with a check-circle icon and label in weight 500. Tapping broadcasts a check-in to family.

Below, a grouped list in three separate glassmorphism cards:

Card 1 "Konto":
- Profil + Dane osobowe (chevron right)
- Prywatność i bezpieczeństwo
- Powiadomienia

Card 2 "Społeczność":
- Moje zgłoszenia
- Odznaki (18 zdobytych)
- Ranking

Card 3 "System":
- Rodzina (2 grupy)
- Ustawienia
- Pomoc i wsparcie

Each list row has: a 32dp tinted icon square on the left (different pastel tints per row), a title weight 500 body, an optional subtitle weight 400 micro below, chevron-right on the far right. 56dp row height.

Bottom: outlined "Wyloguj się" pill button in coral border + coral text, transparent background. Full width.

Below the floating pill nav.
```

### B8. Stats

```
Design the stats / "Bezpieczeństwo w twojej okolicy" screen in Aqoir style.

Top: back chevron + title "Statystyki" + a segmented control "Tydzień / Miesiąc / Rok" in dark navy selected background with white text, inactive transparent with navy text. Segmented control is a pill, 32dp height.

Hero row: three glassmorphism stat cards stacked with 16dp gap:

Card 1 headline "Dzisiaj" weight 500. Display-huge "3" weight 100 coral. Microlabel "alerty w okolicy 500m". Below number: a tiny up-arrow + "+2 od wczoraj" micro label in on-surface-variant.

Card 2 headline "Ten tydzień". Display-huge "18" weight 100 navy. "zgłoszeń w okolicy 2 km".

Card 3 headline "Miesiąc". Display-huge "94%" weight 100 mint. "ocena bezpieczeństwa".

Below, a section "Najczęstsze zagrożenia" headline weight 500. A horizontal bar chart with rounded-end bars, each bar a different aqua-mint-coral shade. Thin numeric labels to the right of each bar in weight 400. No grid lines. Very airy.

Below, a section "Trend w 14 dni". A line chart with a soft gradient aqua line, thin 1.5dp stroke, with 3 subtle dots marking peaks. Area below the line is a fading aqua fill to transparent. No x-axis labels — just "Pon..Nd" at bottom in micro.

Below, a heatmap preview of the city with hotspots glowing in coral at varying intensities, soft edges.

Lots of whitespace. Everything calm and readable.
```

### B9. Family overview

```
Design the family groups screen for be:Safe in Aqoir style.

Top: title "Rodzina" display-med weight 300. Right: a thin "+" icon in a small circle outline for adding members.

If empty state: a central soft mint-green glow orb 200dp with a tiny family silhouette icon inside in navy stroke. Below, tiny weight 400: "Nie masz jeszcze grupy rodzinnej". Below, microcopy on-surface-variant "Utwórz grupę aby widzieć bliskich na mapie i dzielić się lokalizacją bezpiecznie." Then a dark navy pill button "Utwórz grupę rodzinną".

If has family: a large central glow orb represents overall family status (mint if everyone's OK, coral if someone needs attention). Inside the orb, a smaller number "4/4" weight 100 display-huge with "wszyscy bezpieczni" micro label below.

Below, a horizontal scrollable list of family member cards. Each card is 200dp wide, 24dp radius, white, soft shadow. Inside: large circular avatar 80dp with a status-colored ring (mint for online-safe, aqua for stationary, coral for alert state). Below avatar: name weight 500, status chip with tiny dot + "Bezpieczny/a · dom" micro weight 400. A tiny location icon + address in on-surface-variant.

Below cards, a section "Bezpieczne strefy" headline with 3-4 zone pills: "Dom", "Szkoła", "Praca", "+ Dodaj". Active zones are mint-filled, inactive transparent with outline.

Below, a "Historia lokalizacji" card showing a mini-map with recent paths in soft aqua lines.
```

### B10. SOS screen

```
Design the SOS confirmation screen for be:Safe in Aqoir style — this is the most emotionally charged screen, done with extreme restraint.

Background: surface-bg with a subtle coral radial gradient from the center fading outward — the whole screen slowly "breathes".

Center: a gigantic coral glow orb 340dp, with a soft pulsing aura (larger faint coral glow 480dp behind it). Inside the orb: the text "SOS" in display-huge weight 100 in on-surface navy. Below "SOS" inside the orb, micro label "Wciśnij i przytrzymaj" weight 400.

Above the orb, in the top portion of the screen:
- Large title display-med weight 300: "Potrzebujesz pomocy?"
- Below subtitle body weight 400 on-surface-variant: "Twoja rodzina, zaufane kontakty i społeczność w okolicy zostaną powiadomieni."

Below the orb (lower third):
- Toggle row "Powiadom społeczność" with a thin mint switch — ON by default. Micro description below: "Użytkownicy be:Safe w promieniu 500m".
- Toggle row "Powiadom rodzinę" ON by default. Micro: "3 osób dostępnych".
- Toggle row "Zadzwoń na 112" OFF by default. Micro: "Automatycznie po 30 sekundach".

Bottom: a thin cancel text link "Anuluj" in on-surface-variant, not a button — just a text affordance.

No bottom nav — full-screen modal.

The entire scene should feel like a calm, intentional moment of preparedness. Not panic. Red glow breathes, doesn't scream.
```

### B11. Badges

```
Design the badges screen for be:Safe in Aqoir style.

Top: back chevron + title "Odznaki" display-med weight 300.

Hero: a glassmorphism widget card showing progress overview: "18 / 24 odznak" display-big weight 100 navy with a thin progress ring 80dp around it (aqua fill fraction).

Below, tabs "Zdobyte" / "Do zdobycia" as a segmented control pill.

Grid of badges: 3 columns, 16dp gap. Each badge card is 24dp radius white, 16dp padding, center-aligned. Inside:
- A 60dp circular icon container with a soft colored glow (different pastel tint per badge category).
- Badge name weight 500 body below, one line.
- Progress micro: "Zdobyte 12 maja 2026" or "3/10 zgłoszeń" in on-surface-variant.

Locked badges are grayscale with 40% opacity and a thin lock icon overlay in top-right.

Unlocked badges have a subtle mint-green corner dot indicator.

No harsh colors. All badges use soft gradient orb icons (like mini glow orbs). Examples:
- "Pierwsze zgłoszenie" — coral orb
- "Strażnik społeczności" — mint orb
- "Gotowość" — navy orb
- "Rodzina w zasięgu" — aqua orb
```

### B12. News / Aktualności

```
Design the news feed screen for be:Safe in Aqoir style.

Top: title "Aktualności" display-med weight 300.

Horizontal chip filter row below title: "Wszystkie", "Bezpieczeństwo", "Ostrzeżenia", "Porady", "Społeczność". Small pills, 32dp, active = dark navy bg.

Content: vertical list of article cards with 16dp gap. Each card is 24dp radius white glassmorphism, 16dp padding. Top-left: a 32dp colored tag pill with category name in micro weight 500 (mint, coral, aqua depending on category). Below tag, article title in headline weight 500 (max 2 lines, medium navy). Below title: 2 lines of lead text weight 400 on-surface-variant. Bottom row: tiny avatar of source + source name + "3 min czytania" micro on-surface-subtle. Right side of the card: optional rounded thumbnail 80dp with a soft gradient overlay.

Tapping opens a full-bleed article reader with large typography, a soft hero image, 24dp side margins, and a floating "Wstecz" chevron top-left.
```

### B13. Settings / Ustawienia

```
Design the settings screen for be:Safe in Aqoir style.

Top: back chevron + title "Ustawienia" display-med weight 300.

Grouped settings in glassmorphism cards:

Card 1 "Wygląd":
- Row "Motyw" — on the right a small color-swatch chip showing current theme, tap opens bottom sheet with 6 theme orbs (pastel circles).
- Switch row "Automatyczny tryb ciemny" with thin mint toggle.
- Switch row "Dynamic Color".

Card 2 "Powiadomienia":
- Switch "Alerty w okolicy" ON
- Switch "Powiadomienia rodzinne" ON
- Switch "Dźwięk powiadomień"
- Switch "Wibracja"
- Row "Cicha strefa" with subtitle "22:00 - 07:00" and chevron.

Card 3 "Lokalizacja":
- Row "Promień alertów" with slider preview "500m" on right.
- Switch "Śledzenie w tle".
- Switch "Historia lokalizacji (30 dni)".

Card 4 "Prywatność i dane":
- Row "Eksport danych (RODO)"
- Row "Usuń konto" in coral

Card 5 "O aplikacji":
- Row "Regulamin"
- Row "Polityka prywatności"
- Row "Wersja 2.3.1" — disabled, right micro on-surface-subtle.

Each row: 56dp height, leading icon in a tinted 32dp square, title weight 500, optional subtitle weight 400 micro, trailing element (chevron / switch / chip).

No card borders. Let the whitespace define groups. Use tiny section labels in on-surface-variant weight 500 micro above each card.
```

### B14. Location history / Historia

```
Design the family member location history screen for be:Safe in Aqoir style.

Top: back chevron + title "Trasa Janka" (family member name) + right side a calendar icon to change date.

Under title: date pill "14 października" tappable, with a segmented control "Dzisiaj / Tydzień / Miesiąc" below.

Hero section: horizontal stat strip — glassmorphism card with 3 tiny stats side-by-side:
- "4.2 km" weight 100 display-big + "przebyte" micro
- "6 miejsc" weight 100 display-big + "odwiedzone"
- "14:30" weight 100 display-big + "ostatnia aktualizacja"

Below, a large map card with rounded 24dp corners, 320dp tall. On the map:
- A soft aqua polyline showing the day's route (thin 3dp stroke, rounded joins).
- Start pin: mint green glow orb 24dp.
- End pin: coral-red glow orb 24dp.
- Intermediate stops: small aqua circle 12dp with time labels floating next to them (e.g. "08:15").
- User's current position: a pulsing blue dot with aqua aura.

Below the map, a timeline list of stops. Each stop is a minimal row:
- Left: a thin vertical timeline dot-line.
- Middle: stop name weight 500 body + address micro weight 400 on-surface-variant.
- Right: time range "08:15 - 14:45" + duration "6h 30min" micro on-surface-subtle.

No harsh dividers — just the thin timeline line connecting stops.
```

### B15. Emergency numbers

```
Design the emergency numbers screen for be:Safe in Aqoir style.

Top: back chevron + title "Numery alarmowe" display-med weight 300.

Warning banner at the top in a soft coral-tinted glassmorphism card (24dp radius, 16dp padding). A coral exclamation icon on the left. Body weight 500: "Zagrożenie życia? Dzwoń 112". Micro weight 400: "be:Safe nie zastępuje numerów alarmowych."

Below, a large "112" call button as a huge coral pill 80dp tall, full width, white "112" display-big weight 200 centered + phone icon on the left. Pressing calls directly.

Below, a section label "Służby" micro weight 500 on-surface-variant.

A grid of 2 columns, 12dp gap, with specific service cards. Each card is 24dp radius white, 100dp tall, 16dp padding. Layout:
- Top-left: the number in display-big weight 100 (e.g. "997")
- Below number: service name weight 500 body ("Policja")
- Bottom-right: a small circular navy button 40dp with a phone icon

Cards: 997 Policja, 998 Straż pożarna, 999 Pogotowie, 986 Straż miejska, 981 Pomoc drogowa.

Below, another section "Specjalistyczne". Cards:
- 800 12 00 02 — "Telefon Zaufania dla Dzieci"
- 116 111 — "Telefon Zaufania dla Młodzieży"
- 800 100 100 — "Pomoc psychologiczna"
- 800 120 002 — "Niebieska Linia" (przemoc)

Each card has a tiny category tag chip in the top-right corner.

Very calm. No red flood.
```

### B16. Legal — terms / privacy

```
Design the legal pages screen (Regulamin / Polityka prywatności) for be:Safe in Aqoir style.

Top: back chevron + title "Regulamin" display-med weight 300 (or "Polityka prywatności").

Under title: tiny micro on-surface-variant "Ostatnia aktualizacja: 12.05.2026" + right side a share icon outline.

Below, a table of contents pill row that's scrollable horizontally: "§1", "§2", "§3"... Tapping scrolls to section.

Body: typography-focused page, 16dp margin, max-width container. 
- H1 in display-med weight 300.
- H2 (section titles §1, §2 ...) in headline weight 500 with section number in aqua.
- Body text in body weight 400 line-height 1.7.
- Lists indented with small coral bullets.
- Links in aqua underlined.

No images. No decorative elements. Pure readable typography. Very airy.

Bottom: a floating navigation widget — small pill with up/down arrows to jump between sections, and a chevron to return to top.
```

### B17. Verify email / reset password (web pages rendered in mobile)

```
Design the email verification success screen for be:Safe in Aqoir style (web page rendered in mobile viewport).

Center of screen: a large mint-green glow orb 260dp with a soft check-mark icon 80dp in weight 200 navy inside. The orb has a slow breathing animation (radial gradient fading to edges).

Above orb: display-med weight 300 "Email potwierdzony!"
Below orb: body weight 400 on-surface-variant: "Twój adres email został potwierdzony. Możesz teraz korzystać ze wszystkich funkcji be:Safe."

Below text, a dark navy pill button "Otwórz be:Safe" 56dp full width.

At the very bottom: tiny be:Safe logo wordmark and a single thin link "privacy · terms" in micro on-surface-subtle.

Generous whitespace everywhere. Full-bleed white background with a very subtle mint-green gradient from the center orb blending into the edges.

Style variants:
- For error state: use a coral glow orb with an X icon, title "Link wygasł" and subtitle about re-requesting.
- For reset password form: minimal stacked inputs below a smaller navy glow orb.
```

---

## Acceptance checklist po Prompcie A

Po wklejeniu Master promptu, sprawdź czy Stitch wygenerował:
- [ ] Near-white background #F8F9FB (NIE pure white, NIE pink)
- [ ] Cienka display typography (ekrany jak "Wszystko w porządku" nie są bold)
- [ ] Central glow orb (radial gradient, soft edges)
- [ ] Dark navy pill buttons #1A2027 (NIE red, NIE anything else)
- [ ] Floating pill bottom nav (NIE flat dock)
- [ ] Circular SOS button osobno od navi (NIE inside the pill)
- [ ] Mint/aqua/coral ONLY jako status glow (NIE as large color blocks)
- [ ] Polish text wszędzie
- [ ] No shadows heavy, no flat red, no cartoonish icons

Jeśli coś jest źle — użyj `07_RECOVERY.md` dla patching patterns (opcjonalnie stwórz później).

---

## Po wygenerowaniu — przeniesienie do be:Safe projektu

1. Eksport screenów ze Stitcha (MCP `get_screen_image` → PNG).
2. Wrzut do `design/stitch_v2/` (zamiast v1).
3. Update `mobile/lib/theme/design_tokens.dart` z nową paletą (Aqoir-inspired):
   - Primary navy zamiast red
   - Coral zamiast flat red
   - Mint zamiast pure green
   - Near-white surface z cyan tint
4. Refactor 1 screen per PR (zaczynamy od Home + Map — największy impact wizualny).
