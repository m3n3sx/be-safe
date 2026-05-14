# be:Safe v2 — Map & Iconography Stitch Prompts

> **Cel:** wygenerować spójny zestaw map markers, ikon kategorii zagrożeń
> i pomocniczych elementów graficznych w stylu **Serenity Guard**.
>
> **Workflow:** wkleić **Prompt A** jako prompt główny w nowym projekcie Stitch
> (lub w istniejącym projekcie be:Safe). Następnie iterować używając
> Promptów B-E jako per-asset zmian (one prompt = one change).
>
> **Wymagania designu:** Stitch musi mieć dostępny `DESIGN.md` z paletą
> Serenity Guard. Jeśli nie — wkleić zawartość `design/stitch_v2/DESIGN.md`
> jako pierwszy upload.

---

## 🎯 Prompt A — Master (Asset Library Screen)

Skopiuj poniższe i wklej jako **główny prompt** nowego ekranu w Stitch.
Generuje to "design system showcase" w którym widać wszystkie ikony i markery
na jednym ekranie — łatwy do iteracji i screenshotowania.

```
Create a mobile design system showcase screen titled "be:Safe — Mapa & Ikony"
for the be:Safe community safety app. The design must follow the Serenity Guard
design system: airy whitespace, near-white background #FCF8F9, navy primary
#1A2027, mint accent #9DF4CB, alert coral #FF7A7A, calm aqua #9EEBEC.
Inter typography, 24dp card radii, soft 4% opacity shadows.

The screen is a long scrollable showcase divided into FIVE sections, each with
an uppercase 12px label-caps title (#44474B) and a 1px hairline divider above:

SECTION 1 — "MARKERY ZAGROŻEŃ" (alert markers, 18 categories)
A 6-column grid of 18 round markers, each 64x64dp, on the white surface card.
Every marker is a circle with:
  - A 56dp inner core in alert-coral (#FF7A7A) at 90% opacity
  - A 64dp radial glow halo in #FF7A7A fading from 40% to 0% opacity (creates a
    "soft danger ring" without harsh outlines)
  - A white monoline icon (Material Icons style, 26dp, weight 300) centered
  - Below each marker: a 11px label in label-caps for the category name

Categories (left-to-right, top-to-bottom):
1. Agresja — icon: person_off
2. Kradzież — icon: front_hand
3. Wypadek — icon: car_crash
4. Pożar — icon: local_fire_department
5. Powódź — icon: waves
6. Oblodzenie — icon: severe_cold
7. Niebezpieczna budowa — icon: construction
8. Niebezpieczne zwierzę — icon: pets
9. Ciemna strefa — icon: dark_mode
10. Narkotyki — icon: vaccines
11. Akcja policji — icon: local_police
12. Pogoda — icon: thunderstorm
13. Inne — icon: more_horiz
14. Podejrzana osoba — icon: visibility
15. Niebezpieczne przejście — icon: traffic
16. Niebezpieczny plac zabaw — icon: child_friendly
17. Zbiornik wodny — icon: water
18. Strefa szkolna — icon: school

SECTION 2 — "SPECJALNE PINY" (special pins)
A horizontal row of 5 distinct map pins, each labeled below in 11px caps:

a) "TWOJA POZYCJA" — 24dp navy (#1A2027) solid circle inside a 56dp aqua
   (#9EEBEC) radial glow at 50% center opacity fading to 0%
b) "RODZINA" — 48dp white circle with photo placeholder (gradient mint→navy
   silhouette), wrapped in a 4dp mint (#9DF4CB) solid ring with very subtle
   outer glow
c) "DZIECKO" — same as RODZINA but with the Material icon "child_care" centered
   instead of photo, mint ring + soft glow
d) "GRUPA (5)" — 48dp navy (#1A2027) circle with white text "5" (16px weight 500),
   no glow but with strong elevation shadow (40px blur, 15% opacity)
e) "SOS" — 64dp coral (#FF7A7A) solid circle with white "SOS" text
   (12px weight 500, letter-spacing 0.05em), animated pulsing radial halo

SECTION 3 — "WYBRANY MARKER (state variants)" (selected/active states)
Three variants of the same alert marker (use category "Pożar" — fire), each
72x72dp, side by side, labeled below:

a) "DOMYŚLNY" — standard marker as in Section 1
b) "WYBRANY" — same marker but the inner core scaled up 110%, glow halo
   intensified to 60% opacity, and a thin 2dp navy (#1A2027) ring appears
   around the core
c) "POTWIERDZONY" — same marker but with a small 18dp mint (#9DF4CB) circle
   with white check icon attached to bottom-right (like a verified badge)

SECTION 4 — "STREFY I PROMIENIE" (zones & radii)
Show three example circles overlayed on a stylized map background tile (light
gray streets, no labels):

a) "PROMIEŃ ALERTU" (300m) — semi-transparent coral (#FF7A7A) fill at 12%
   opacity, soft 1.5dp coral stroke at 50% opacity
b) "STREFA BEZPIECZNA" (geofence "Dom") — semi-transparent mint (#9DF4CB)
   fill at 15% opacity, dashed 2dp mint stroke at 80% opacity, label "Dom"
   centered in 12px caps
c) "ZASIĘG POWIADOMIEŃ" (user radius) — semi-transparent aqua (#9EEBEC) fill
   at 8% opacity, very subtle 1dp aqua stroke

SECTION 5 — "KLASTRY" (cluster markers)
A row of 4 cluster markers showing density progression, each labeled below:

a) "2-9" — 48dp navy circle, white number "5" 16px weight 500
b) "10-49" — 56dp navy circle with subtle outer ring, white number "23"
c) "50-99" — 64dp navy with mint glow halo at 30%, white "78"
d) "100+" — 72dp navy with strong coral glow halo at 40%, white "200+"

LAYOUT NOTES:
- Section spacing: 48dp vertical between sections
- Card containers: white surface (#FFFFFF), 24dp radius, internal 24dp padding,
  soft shadow (40dp blur, 4% opacity, navy #1A2027)
- All labels use Inter 11-12px weight 500 letter-spacing 0.05em uppercase
- Marker labels below assets in 12px regular, color #44474B
- The screen has a generous 32dp top margin and 96dp bottom margin
- Top app bar: transparent, centered "be:Safe — Mapa & Ikony" in 22px
  Inter weight 300, with shield icon to the left

The aesthetic should feel meditative and high-end, like a wellness app, not a
typical safety/security app. Avoid any gradients with red/orange that feel
"emergency-like" — coral is non-aggressive. No drop shadows on icons; rely on
glow halos and soft surface shadows for depth.
```

---

## 🎨 Prompt B — Refine alert markers (per-category iteration)

Po wygenerowaniu Promptu A można iterować pojedyncze ikonki kategorii.
Wklej jako **edycję** (zmianę istniejącego ekranu) gdy chcesz np. ulepszyć
konkretną kategorię.

```
For the alert markers in section 1, refine the icons to be more pictographic
and less generic. Specifically:

- "Kradzież" — replace front_hand with a hand reaching for a wallet/bag silhouette
- "Agresja" — replace person_off with two stylized figures, one raised arm
- "Akcja policji" — keep local_police but ensure the badge shape is visible at
  26dp size
- "Strefa szkolna" — replace school with a backpack icon for clarity
- "Niebezpieczna budowa" — keep construction but emphasize the cone

All icons must remain monoline weight 300, white, 26dp, centered in the marker.
Maintain the coral fill + glow halo aesthetic. Do not change the marker shape
or palette. Reduce visual complexity if any icon becomes too detailed at 26dp.
```

---

## 🎨 Prompt C — Refine special pins (user/family/SOS)

Po Prompcie A — gdy specjalne piny wymagają poprawek.

```
For the special pins in section 2, refine the visual treatment:

- "TWOJA POZYCJA" — make the inner navy dot 16dp instead of 24dp so the aqua
  glow feels more spacious. Add a 2dp white outer stroke around the navy dot
  for contrast on darker map tiles.
- "RODZINA" — the photo placeholder should be a soft mint (#9DF4CB) gradient
  to navy (#1A2027) ellipse silhouette, not a hard portrait. Pulsing mint ring
  intensity should be subtle (3-4dp ring, 60% opacity, very soft outer glow).
- "DZIECKO" — same refinement as RODZINA but child_care icon should be navy
  (#1A2027) on white background, not white-on-mint.
- "GRUPA" — add a tiny mint (#9DF4CB) "+1" indicator on bottom-right when
  applicable, like a notification badge but in mint instead of red.
- "SOS" — the pulsing animation must be visible as 3 concentric coral rings
  fading outward at 90%, 60%, 30% opacity, each 8dp larger than the core.

Keep dimensions and label styles unchanged.
```

---

## 🎨 Prompt D — Cluster marker density variants

Iteracja markerów klastra (Section 5) jeśli grupy alertów wymagają lepszej
wizualizacji gęstości.

```
For the cluster markers in section 5, refine the density visualization:

Replace the static glow halos with a "thermal map" feel:

- 2-9 alerts: navy circle with subtle 1dp outline (no glow), white text
- 10-49: navy circle with single mint (#9DF4CB) glow halo (30% opacity, 16dp blur)
- 50-99: navy circle with mint glow + an inner mint ring (1.5dp, 60% opacity)
  inside the navy circle, and a "+" indicator
- 100+: navy circle with coral (#FF7A7A) glow halo (40% opacity, 24dp blur),
  bold "+" inside the number

Numbers always white, Inter weight 500, scale with marker size:
- 48dp marker: 14px text
- 56dp marker: 16px text
- 64dp marker: 18px text
- 72dp marker: 22px text

Add a subtle 100ms easing scale transition placeholder note: "scale 1.0 →
1.05 on tap" but render as static.
```

---

## 🎨 Prompt E — Map base style (light/dark Google Maps style)

Osobny prompt dla stylu mapy — jeśli chcesz dopracować jak wygląda sama
warstwa Google Maps pod markerami. Można wkleić jako nowy ekran "Map Style
Reference" w Stitchu.

```
Create a single-screen showcase titled "be:Safe — Styl Mapy" showing two
Google Maps-style frames side by side (or stacked on mobile):

LEFT/TOP: "Tryb dzienny" (Light mode)
A 320x480dp rounded rectangle (24dp radius) representing a phone-sized map
view. Map content:
- Background landscape: #FCF8F9 (matches Serenity surface)
- Roads: arterial #FFFFFF, local #F0EDED, highway #F5D142 (warm yellow accent)
  with subtle #E8C430 stroke
- Water: #C9E8F5 (pale aqua)
- Parks: #E5F5E0 (very pale mint)
- POIs: hidden (visibility: off)
- Road labels: #7B7B7B with 3dp white stroke
- Place labels: #616161

Overlay 4 sample alert markers from section 1 + 1 user-position pin to show
how they appear on the actual map. Add a search bar mock at top "Szukaj
adresu lub miejsca" and a filter pill "Filtruj kategorie" below it.

RIGHT/BOTTOM: "Tryb nocny" (Dark mode)
Same map frame but inverted:
- Background: #212121
- Roads: #2C2C2C with #3A3A3A stroke
- Water: #000000
- Parks: #1B2D1F (dark muted green)
- Labels: #757575 with #212121 stroke

Overlay same markers — verify they remain visible. Adjust marker glow halos
to be slightly brighter (60% instead of 40%) for dark mode visibility.

LAYOUT:
- 24dp padding around map frames
- Map frames have subtle 1dp outline in #C5C6CB at 30% opacity
- Below each map, label "TRYB DZIENNY" / "TRYB NOCNY" in 12px caps
- Title at top "Styl Mapy" in 32px Inter weight 300
- Background: #FCF8F9
```

---

## 📦 Po wygenerowaniu w Stitchu

1. Pobierz wszystkie 5 ekranów jako PNG (lub HTML+PNG przez `download_assets`)
2. Wytnij pojedyncze markery i ikony z grid view (Figma plugin albo ręcznie)
3. Zapisz w `mobile/assets/icons/` jako:
   ```
   assets/icons/markers/alert_aggression.png  (i 17 więcej kategorii)
   assets/icons/markers/marker_user.png
   assets/icons/markers/marker_family.png
   assets/icons/markers/marker_child.png
   assets/icons/markers/marker_cluster_sm.png
   assets/icons/markers/marker_cluster_md.png
   assets/icons/markers/marker_cluster_lg.png
   assets/icons/markers/marker_cluster_xl.png
   ```
4. Wymagaj 3 rozdzielczości (1x/2x/3x) lub jednego @3x i niech Flutter skaluje
5. W kodzie zamień `BitmapDescriptor.defaultMarkerWithHue(...)` na
   `BitmapDescriptor.fromAssetImage(...)` w `map_screen.dart` i `_createAlertPin`

---

## 🎯 Bonus: prompt do generowania pojedynczych ikon SVG

Jeśli chcesz mieć ikony jako SVG (resolution-independent), zamiast bitmap:

```
Generate 18 SVG icons in flat monoline style, weight 300, viewBox 24x24,
single color #FFFFFF (will be tinted in app). Each icon represents one
alert category (full list in section 1 of the master prompt). Icons should
be visually consistent — similar visual weight, similar level of detail,
all centered in viewBox with 2dp padding from edges.

Output each as standalone SVG with title, e.g.:
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <title>Pożar</title>
  <path d="..." fill="currentColor"/>
</svg>

This allows tinting via fill color (coral for default, mint for safe states).
```
