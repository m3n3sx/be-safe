# be:Safe v2 — Google-Maps-Style Pin Markers Prompt

> Dodatkowy prompt dla Stitcha — generuje **klasyczne pinezki w stylu Google
> Maps** (teardrop shape) z ikoną zagrożenia w okrągłej głowie pinezki.
>
> Workflow: wkleić jako nowy ekran w Stitch (lub edycja istniejącego)
> obok wcześniejszych asset library screenów.

---

## 🎯 Prompt

```
Create a mobile design system showcase screen titled "be:Safe — Pinezki mapy"
for the be:Safe community safety app. Follow the Serenity Guard design system:
near-white background #FCF8F9, navy primary #1A2027, mint accent #9DF4CB,
alert coral #FF7A7A, calm aqua #9EEBEC. Inter typography.

Generate a 6-column grid of 18 GOOGLE-MAPS-STYLE PIN MARKERS, each 96x120dp.

PIN ANATOMY (every marker):
1. CIRCULAR HEAD (top): 56dp diameter perfect circle, filled coral (#FF7A7A)
2. POINTED TAIL (bottom): triangular tail pointing straight down, 24dp tall,
   28dp wide at base, smoothly merging with the circle so the silhouette
   is a classic teardrop / map pin (think Google Maps pin)
3. INNER ICON: white monoline Material Icon, 28dp, weight 300, perfectly
   centered in the circular head (NOT in the full pin — just the head)
4. WHITE STROKE: 2.5dp white outline around the entire teardrop silhouette
   for contrast on darker map tiles
5. SOFT GLOW: subtle radial halo behind the pin head — coral (#FF7A7A) at
   25% opacity center, fading to 0% at 80dp radius (creates "calm danger"
   not aggressive emergency feel)
6. SHADOW: soft drop shadow below the pin tail point — 8dp blur, 20% opacity,
   navy (#1A2027), offset Y +4dp (anchors the pin to the map surface)

VISUAL EXAMPLES OF PROPORTIONS:
- Total pin height: 80dp (56dp head + 24dp tail)
- Glow halo extends another 24dp around the head, total bounding box 96x120dp
- Icon must be 50% of head diameter (28dp / 56dp)
- Tail is symmetric, smooth curve into circle (NO sharp corners at junction)

CATEGORIES & ICONS (left-to-right, top-to-bottom):
1. Agresja — person_off
2. Kradzież — front_hand
3. Wypadek — car_crash
4. Pożar — local_fire_department
5. Powódź — waves
6. Oblodzenie — severe_cold
7. Niebezpieczna budowa — construction
8. Niebezpieczne zwierzę — pets
9. Ciemna strefa — dark_mode
10. Narkotyki — vaccines
11. Akcja policji — local_police
12. Pogoda — thunderstorm
13. Inne — more_horiz
14. Podejrzana osoba — visibility
15. Niebezpieczne przejście — traffic
16. Niebezpieczny plac zabaw — child_friendly
17. Zbiornik wodny — water
18. Strefa szkolna — school

Below each pin: 11px label-caps text in #44474B with category name.

ADDITIONAL VARIANTS (separate row at bottom of screen, labeled "WARIANTY"):

Show the same "Pożar" pin in 5 states, each labeled below:

a) "DOMYŚLNY" — standard coral pin as described above
b) "WYBRANY" — same pin scaled to 110%, glow halo intensified to 40%, with a
   thin 1.5dp navy ring around the inner head edge
c) "POTWIERDZONY" — standard pin + small 22dp mint (#9DF4CB) circle with white
   check icon attached to the bottom-right of the head (notification badge style)
d) "NIEAKTUALNY" — pin desaturated: head color #B8B8B8, glow at 15% gray,
   icon at 70% opacity (visually "dimmed")
e) "WIELE (3)" — standard pin but with a small 22dp navy (#1A2027) circle in
   bottom-right showing "3" in 11px white weight 500 (cluster overlap indicator)

LAYOUT:
- White surface card (#FFFFFF) wraps each grid section, 24dp radius, 24dp
  padding, soft shadow (40dp blur, 4% opacity, navy)
- 32dp gap between header card and variants card
- Header: 32px Inter weight 300 "Pinezki mapy", centered, with shield icon
- Background: #FCF8F9
- Top app bar: transparent, back arrow, "Pinezki mapy" centered

CRITICAL REQUIREMENTS:
- Pins must look like REAL Google Maps pins (you'll find references searching
  "google maps marker pin design") but with our coral palette and rounded
  proportions
- The teardrop point at the bottom is the EXACT geographic location anchor —
  it MUST be sharp, narrow, and clearly tapered (not just a rounded rectangle)
- Icons in the head are flat white monoline, NOT filled. Weight 300.
- The aesthetic is "calm safety" — coral is approachable, not alarming.
  Compare to typical red emergency pins which feel anxiety-inducing.
- Do NOT add gradients to the pin body. Solid coral fill only.
- Do NOT use drop shadows on the icons themselves.
- Maintain consistency: every pin must have the same head diameter, tail
  length, stroke width, and shadow.

OUTPUT: ready to be sliced into individual PNG assets at @1x/@2x/@3x for
Flutter BitmapDescriptor.fromAssetImage usage.
```

---

## 📦 Po wygenerowaniu

1. Pobierz screen jako HTML + PNG przez `download_assets` MCP
2. Wytnij pojedyncze pinezki (96×120dp każda, najlepiej @3x = 288×360px)
3. Zapisz w `mobile/assets/icons/pins/`:
   ```
   pin_aggression.png
   pin_theft.png
   pin_accident.png
   ... (18 plików)
   pin_selected.png        (variant b)
   pin_confirmed.png       (variant c)
   pin_inactive.png        (variant d)
   pin_overlap_badge.png   (variant e — overlay only)
   ```
4. Update `_createAlertPin()` w `mobile/lib/screens/map/map_screen.dart`:
   ```dart
   Future<BitmapDescriptor> _createAlertPin(AlertCategory cat) async {
     return await BitmapDescriptor.fromAssetImage(
       const ImageConfiguration(size: Size(48, 60)),
       'assets/icons/pins/pin_${cat.apiValue}.png',
     );
   }
   ```
5. Dodaj do `pubspec.yaml` jako asset directory:
   ```yaml
   assets:
     - assets/icons/
     - assets/icons/pins/
   ```

---

## 💡 Tips dla Stitcha

- Jeśli pierwsza generacja ma za mało detali w pinezkach (Stitch lubi
  abstrahować) — dodaj iteracyjny prompt: "Refine the pin shapes to be more
  pictographic, like real Google Maps location pins. The transition from
  circular head to triangular tail must be smooth, not abrupt."
- Jeśli ikony w środku są za małe — "Increase inner icons to 32dp (was 28dp)
  while keeping head diameter 56dp"
- Jeśli kolory zbyt agresywne — "Reduce coral saturation by 15% to feel
  calmer, less emergency-like"
