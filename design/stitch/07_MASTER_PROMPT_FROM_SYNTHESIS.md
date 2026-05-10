# 07 — Master Stitch Prompt (be:Safe Community Modern)

> Wklej to jako **jeden** prompt w nowym projekcie Stitch. ~3400 znaków
> (pod limitem 5000). Bazuje na syntezie 8 eksperymentów — patrz
> `MASTER_STYLE.md` dla reasoning.

---

## Prompt

```
Design a mobile Android app called "be:Safe" - a trustworthy Polish community safety app that blends neighborhood threat alerts with family location tracking. Generate all core screens in one consistent visual style called "be:Safe Community Modern" - Material 3 Expressive with warm pink-tinted surfaces, alert-red brand color, and a floating glass bottom navigation with a hero SOS button.

All UI text must be in Polish.

Color palette. Primary is alert red #BA002C with on-primary white and primary-container #FFDAD9. Secondary is safe green #006E2A with secondary-container #5CFD80 - used for family members, "I am safe" check-ins and confirmations. Tertiary is info blue #0056C5 with tertiary-container #D9E2FF - for location sharing and neutral info. Surfaces are warm pink-tinted: surface #FFF8F7, surface-container-low #FFF0EF, surface-container #FFE9E8, surface-container-high #FFE1E0 - never pure white, always slightly pink-warm. On-surface is deep burgundy #291616. Outline is #936E6D. Category accents: aggression/theft red #FF1744, fire #FF3D00, accident #FF6D00, construction amber #FFAB00, flood blue #2979FF, ice cyan #00B0FF, dark area grey #78909C, drugs purple #AA00FF.

Typography. Use Inter exclusively for full Polish diacritics support (ą, ć, ę, ł, ń, ó, ś, ź, ż). Scale: display-small 36sp/700 for screen heroes, headline-small 24sp/600 for section headings, title-medium 16sp/500 for list items, body-large 16sp/400 for copy, label-large 14sp/600 for buttons, label-medium 12sp/600 uppercase for meta and status chips.

Shape scale, expressive and varied. Small chips 4dp, input fields 12dp, standard cards 16dp, stat tiles and hero cards 24dp, floating bottom nav 28dp, primary CTA buttons fully pill-shaped. No 0dp sharp corners anywhere.

Bottom navigation. Floating 16dp above the bottom edge, inside a pill-shaped surface-container-high pod with 28dp radius, 8dp padding, soft tinted shadow. Five items: Mapa (map icon), Alerty (notifications icon with red dot badge for unread), a large 56dp SOS hero circle in the center that physically rises 6dp above the bar in solid primary red with bold white asterisk and a subtle ambient red glow shadow, Rodzina (family icon), Profil (person icon). Active item has its icon and label in primary red with a 40dp primary-container circle behind the icon.

Map screen. Full-screen Google Maps, standard light style, no custom tint. Floating pill search bar at top (white #FFFFFF surface, full radius, search + filter tune icons, label "Szukaj adresu lub miejsca..."). Alert pins are 44dp colored circles using the category accent color with a 3dp white stroke. Each pin has a category label capsule above it ("Wypadek", "Pożar (2)", "Pożar") in the category accent color with white bold text. Cluster pins are larger 56dp primary red circles with white count numbers. Family children appear as circular avatar pins with a 3dp green border and a green name capsule above ("Janek"). The red "Zgłoś" extended FAB sits 16dp from the right edge and 88dp from the bottom, pill-shaped 56dp tall with a warning_amber icon and bold white "Zgłoś" label. A 56dp squircle my-location FAB sits above it with surface-container-highest background.

Profile screen. Top app bar with user avatar left, centered "be:Safe" logo in primary red, bell icon right in a 40dp circle container. Hero: 80dp circular avatar with a small camera icon overlay bottom-right. Below: username in display-small 36sp bold, email in body-medium on-surface-variant. Three stat tiles in a row with 12dp gap: Punkty, Alerty, Ranking, each a pill-card with primary-container background, 24dp radius, big display-small number in primary red above, uppercase label-medium below. Then a prominent full-width 64dp pill "Jestem bezpieczny/a" in solid secondary green with check-circle icon. Below: a menu list grouped into containers. Each menu item is a full-width card with a 40dp rounded square color-coded icon tile on the left (red for account, green for privacy, blue for notifications, grey for help), bold title, subtitle grey, chevron right.

My Alerts screen. Display-small heading "Moje zgłoszenia". Pill segment control "Aktywne / Wygasłe / Wszystkie" with the active segment as a white pill inside a surface-container-low pod. List of alert cards, each 24dp radius surface-container background with: 48dp category-colored icon tile left, title + location, description two lines, stats row with 👍 👎 💬 counts and arrow right. Status chip top-right: "Nowe" primary-container, "W toku" tertiary-container, "Rozwiązane" secondary-container. No hard borders - use tonal differentiation only.

Onboarding, Login, Alert Detail, Create Alert, Family, Stats, Badges, News, Ranking, Referral, Emergency Numbers, Settings, Legal screens all follow the same system.

Vibe: modern, trustworthy, community-first, alert-focused but never scary. Never corporate-sterile, never cyberpunk-dark. Warm pinks and soft shadows. Safety shield motif subtle in brand mark.
```

---

## Check po pierwszej generacji

Po wklejeniu Stitch wygeneruje bazę. Sprawdź:

- [ ] Primary red `#BA002C` (NIE orange, NIE green-only)
- [ ] Surface jest ciepło różowy `#FFF8F7` (NIE pure white, NIE grey)
- [ ] Bottom nav **floating pill** (NIE flat na dole ekranu)
- [ ] SOS w środku nav wystaje **ponad bar** (hero circle)
- [ ] Alert pins na mapie mają **label kapsułkę nad** (nie tylko pin)
- [ ] Polska tekst wszędzie (Mapa, Alerty, Rodzina, Profil, Zgłoś, SOS)
- [ ] Cards mają warm pink tint, nie pure white

Jeśli coś nie gra → użyj promptów z `03_RECOVERY_PROMPTS.md`.

## Kolejne iteracje

Po master prompcie generuj każdy kolejny screen osobnym promptem z
`02_SCREEN_PROMPTS.md`, ale **dodaj na końcu** każdego:

> "Follow the be:Safe Community Modern design system from this project:
> pink-tinted surfaces, alert red primary, floating pill bottom nav with
> hero SOS, 24dp hero cards, warm shadows. Polish language only."

Dzięki temu Stitch trzyma spójność między screenami.
