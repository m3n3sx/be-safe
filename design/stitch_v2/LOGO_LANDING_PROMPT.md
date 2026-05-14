# be:Safe — Logo & Landing Page Stitch Prompts

---

## 🎯 Prompt A — Logo (warianty)

```
Create a mobile design system showcase screen titled "be:Safe — Logo"
for the be:Safe community safety app. Follow the Serenity Guard design
system: background #FCF8F9, navy primary #1A2027, coral accent #FF7A7A,
mint #9DF4CB, aqua #9EEBEC. Inter typography.

The screen shows the be:Safe logo in 8 VARIANTS arranged in a 2-column
grid on white cards (24dp radius, soft shadow). Each variant is labeled
below in 12px uppercase Inter weight 500.

LOGO CONCEPT:
The be:Safe logo combines a SHIELD shape with a subtle LOCATION PIN hint.
The shield is modern and minimal — not a traditional heraldic shield but
a rounded, soft shape (think Apple's shield icon meets a map pin silhouette).
Inside the shield: a stylized lowercase "b" that doubles as a person
silhouette (the ascender is the head, the bowl is the body in a protective
stance). The colon in "be:Safe" is represented by two small dots that
suggest connection/community.

DESIGN PRINCIPLES:
- Calm, not aggressive. This is a wellness-safety brand, not military.
- Geometric, clean lines. No gradients in the mark itself.
- Works at 16dp (app icon) and 200dp (splash screen) equally well.
- The shield shape has rounded corners (8dp radius at logo scale).

VARIANT 1 — "PEŁNE KOLOROWE" (full color, horizontal)
Shield mark in navy (#1A2027) + wordmark "be:Safe" to the right.
Wordmark: "be:" in Inter weight 300 + "Safe" in Inter weight 500.
Both navy. Colon dots in coral (#FF7A7A).
Total width ~200dp, height ~48dp.

VARIANT 2 — "PEŁNE KOLOROWE PIONOWE" (full color, vertical/stacked)
Shield mark centered above wordmark. Mark ~64dp, wordmark below at 24px.
Same color treatment as variant 1.

VARIANT 3 — "MARK ONLY" (symbol only, no text)
Just the shield mark, 80x80dp. Navy fill.
Inside: the "b"/person silhouette in white.

VARIANT 4 — "MARK ONLY — CORAL" (for dark backgrounds)
Same shield mark but coral (#FF7A7A) fill, white interior.
Show on a dark navy (#1A2027) background card.

VARIANT 5 — "BIAŁE NA CIEMNYM" (white on dark)
Full horizontal logo (mark + wordmark) in white on navy card.
Colon dots in coral.

VARIANT 6 — "MONOCHROMATYCZNE" (single color)
Full horizontal logo entirely in navy. No coral accent.
For formal/print use.

VARIANT 7 — "APP ICON" (Android adaptive icon format)
Square with rounded corners (20% radius), navy background.
White shield mark centered, sized at 66% of the icon area.
Show at 108x108dp (the Android adaptive icon safe zone).
Below it show the same at 48dp and 24dp to prove scalability.

VARIANT 8 — "SPLASH SCREEN"
Full phone frame (390x844dp) with #FCF8F9 background.
Centered: shield mark at 120dp with a subtle mint (#9DF4CB) radial
glow behind it (like the Glow Orb from the app, 40% opacity center
fading to 0%). Below mark: wordmark "be:Safe" at 32px Inter.
Below wordmark: tagline "Bezpieczeństwo w Twoich rękach" at 14px
Inter weight 400 color #44474B.

LAYOUT:
- 2-column grid, cards 170dp wide each
- 24dp gap between cards
- Each card: white #FFFFFF, 24dp radius, 24dp internal padding,
  soft shadow (40dp blur, 4% opacity)
- Below each logo variant: label in 11px caps #44474B
- Screen title: "Logo" in 32px Inter weight 300, centered
- Top bar: shield icon + "be:Safe" 22px weight 300

CRITICAL:
- The shield mark must be SIMPLE enough to work as a favicon (16x16px).
- No thin lines that disappear at small sizes.
- The "b" inside should be recognizable but abstract — not literally
  a letter, more of a human-in-shield pictogram.
- Coral (#FF7A7A) is used ONLY for the colon dots and the dark-bg variant.
  Primary mark color is always navy (#1A2027) or white.
```

---

## 🎯 Prompt B — Landing Page

```
Create a DESKTOP landing page design (1440x900 viewport, scrollable) titled
"be:Safe — Landing Page" for the be:Safe community safety app.
Follow the Serenity Guard design system: background #FCF8F9, navy #1A2027,
coral #FF7A7A, mint #9DF4CB, aqua #9EEBEC, Inter font, 24dp card radii.

The page is a single long scroll with these sections:

═══════════════════════════════════════════════════════════════════════════
SECTION 1 — HERO (viewport height, centered content)
═══════════════════════════════════════════════════════════════════════════

Navigation bar (sticky top, transparent bg, blur on scroll):
- Left: shield logo mark (24dp) + "be:Safe" wordmark (18px weight 300)
- Right: links "Funkcje" "Bezpieczeństwo" "Pobierz" in 14px weight 500
  + navy pill button "Pobierz APK" (padding 12x24)

Hero content (centered, max-width 800px):
- Headline: "Twoja okolica." first line, "Pod kontrolą." second line.
  64px Inter weight 200, navy, letter-spacing -0.02em.
- Subheadline: "Społeczność, rodzina i Ty — razem tworzycie bezpieczne
  miasto. Darmowa aplikacja na Androida." 18px weight 400, #44474B,
  max-width 560px, centered.
- Two buttons side by side:
  - Primary: "Pobierz na Android" navy pill (#1A2027 bg, white text,
    Android icon left)
  - Secondary: "Zobacz demo" outline pill (1px navy border, navy text)
- Below buttons (40dp gap): a phone mockup frame showing the Home Screen
  (glow orb "9/10" design from the app). Phone frame is a 280x560dp
  rounded rectangle with 40dp radius, subtle shadow, showing the actual
  app screenshot inside.

Background: large mint (#9DF4CB) glow orb at 15% opacity behind the phone
mockup, 400dp diameter, creates depth without distraction.

═══════════════════════════════════════════════════════════════════════════
SECTION 2 — FEATURES (3-column grid)
═══════════════════════════════════════════════════════════════════════════

Section title: "Wszystko czego potrzebujesz" 40px weight 300, centered.
Subtitle: "Jedno miejsce dla bezpieczeństwa Twojego i bliskich" 16px #44474B.

3 feature cards in a row (white, 24dp radius, 32dp padding, soft shadow):

Card 1: "Mapa zagrożeń"
- Icon: coral circle (48dp) with white map icon inside
- Title: 20px weight 500
- Description: "Alerty w czasie rzeczywistym od społeczności.
  Zobacz co się dzieje w okolicy zanim wyjdziesz z domu." 14px #44474B

Card 2: "Rodzina"
- Icon: mint circle with white family_restroom icon
- Title: "Lokalizacja bliskich"
- Description: "Wiedz gdzie są Twoi bliscy. Bezpieczne strefy,
  historia tras, powiadomienia gdy dziecko opuści szkołę."

Card 3: "SOS"
- Icon: coral circle with white sos icon
- Title: "Jeden gest, cała pomoc"
- Description: "Przytrzymaj 2 sekundy — powiadamiamy rodzinę,
  społeczność i służby ratunkowe."

═══════════════════════════════════════════════════════════════════════════
SECTION 3 — HOW IT WORKS (alternating left-right)
═══════════════════════════════════════════════════════════════════════════

Section title: "Jak to działa" 40px weight 300, centered.

3 rows, alternating image-left/text-right and text-left/image-right:

Row 1 (image left):
- Phone mockup showing Map Screen (filter chips + pins on map)
- Right text: "Zgłaszaj i sprawdzaj" 28px weight 300
  + "Widzisz zagrożenie? Jedno kliknięcie. Społeczność potwierdza
  lub odrzuca — fałszywe alerty znikają." 16px #44474B

Row 2 (image right):
- Phone mockup showing Family Screen (glow orb "4/4" + member cards)
- Left text: "Rodzina pod opieką" 28px weight 300
  + "Utwórz grupę rodzinną. Widzisz lokalizację bliskich w czasie
  rzeczywistym. Bezpieczne strefy powiadamiają automatycznie."

Row 3 (image left):
- Phone mockup showing SOS Screen (coral orb + toggles)
- Right text: "SOS gdy potrzebujesz" 28px weight 300
  + "Przytrzymaj przycisk — alarm idzie do rodziny i społeczności
  w promieniu 500m. Opcjonalnie dzwoni na 112."

═══════════════════════════════════════════════════════════════════════════
SECTION 4 — STATS / SOCIAL PROOF
═══════════════════════════════════════════════════════════════════════════

Navy (#1A2027) full-width background section. White text.

3 large stats in a row (centered):
- "500+" — "Aktywnych użytkowników" (display-lg 64px weight 100 + 14px label)
- "2,400+" — "Zgłoszonych zagrożeń" (same style)
- "98%" — "Potwierdzeń społeczności" (same style)

Below stats: a single testimonial quote in 18px italic weight 300:
"Dzięki be:Safe wiem że moje dzieci bezpiecznie wracają ze szkoły."
— Anna K., Września

═══════════════════════════════════════════════════════════════════════════
SECTION 5 — CTA + FOOTER
═══════════════════════════════════════════════════════════════════════════

Back to #FCF8F9 background.

CTA block (centered, max-width 600px):
- Headline: "Dołącz do bezpiecznej społeczności" 36px weight 300
- Subtitle: "Darmowa aplikacja. Bez reklam. Twoje dane są bezpieczne." 16px
- Large navy pill button: "Pobierz be:Safe" with Android icon, 18px
- Below button: "Dostępne na Android • iOS wkrótce" 13px #44474B

Footer (full width, navy bg, white text 13px):
- Left: "© 2026 be:Safe. Wszystkie prawa zastrzeżone."
- Center: links "Regulamin" "Prywatność" "Kontakt"
- Right: "info@besafe.org.pl"

═══════════════════════════════════════════════════════════════════════════

LAYOUT NOTES:
- Max content width: 1200px, centered
- Section vertical padding: 120px top/bottom
- Phone mockups: use a simple rounded rectangle frame (navy border 2dp,
  40dp radius) with a gradient placeholder inside suggesting the app screen
- All animations noted as comments (e.g. "fade-in on scroll") but rendered static
- The overall feel: premium, calm, trustworthy. Like a fintech or health app
  landing page, NOT a typical "download our app" page with stock photos.
- No stock photography. Only geometric shapes, glow orbs, and phone mockups.
- Typography hierarchy: display (64px w100) > headline (40px w300) >
  title (28px w300) > body (16px w400) > label (13px w500)
```

---

## 📦 Po wygenerowaniu

### Logo
1. Wyeksportuj wariant 7 (App Icon) jako PNG 1024×1024 → `mobile/android/app/src/main/res/`
2. Wariant 3 (Mark Only) jako SVG → favicon + webapp
3. Wariant 1 (Full Horizontal) → README, docs, email header

### Landing Page
1. Użyj jako reference do przepisania `web/src/app/page.tsx`
2. Phone mockups → screenshoty z apki v35 (Home, Map, Family, SOS)
3. Stats → dynamiczne z API (`/alerts/stats/global`)
