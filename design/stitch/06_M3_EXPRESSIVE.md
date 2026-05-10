# 06 — Material 3 Expressive Refactor

> Google wprowadził **M3 Expressive** na I/O 2025 — ewolucję Material 3 z naciskiem
> na emocje, wyrazistość i hierarchię wizualną. Oparte na 46 badaniach i 18 000
> użytkowników. Kluczowe elementy: **color, shape, size, motion, containment**.
>
> Ten prompt refaktoruje cały projekt Stitch do M3 Expressive w jednym "dużym"
> prompcie. Potem są **per-screen touch-upy** do ostatecznego dostrojenia.

---

## Jak użyć

1. Otwórz swój projekt be:Safe w Stitch
2. **Zrób screenshoty** wszystkich screenów (backup jakbyś chciał wrócić)
3. Wklej **"Prompt A"** poniżej — jedna duża zmiana theme'u na M3 Expressive
4. Dla konkretnych screenów, które wyszły słabiej — użyj **"Prompts B1-B5"**
5. Nie łącz B-promptów — jeden prompt = jedna zmiana (regułka Stitcha)

---

## Prompt A — główny refactor całego projektu

```
Refactor the entire be:Safe app to follow Material 3 Expressive design language (Google I/O 2025). Apply the change across all existing screens. Keep all Polish UI text intact. Keep alert red (#FF1744) as the primary color but apply it through the M3 Expressive system.

Five design dimensions to apply everywhere:

1. Color with Emphasis
Use bold saturated primary color only where user action or attention is needed: SOS button, Zgłoś button, new alert pins on the map, floating action buttons. For everything else use quieter tonal palettes derived from the primary. Use the full M3 tonal role tokens: primary, onPrimary, primaryContainer, onPrimaryContainer, secondary (safe green #00C853), secondaryContainer, tertiary (info blue #2979FF), tertiaryContainer, surface, surfaceContainer, surfaceContainerHigh, surfaceDim, outline, outlineVariant. Backgrounds are no longer flat white but use the tonal surface variants that create soft layered feel.

2. Shape Expressiveness
Replace uniform rounded corners with expressive shape sizes from the M3 shape scale: extra small 4dp, small 8dp, medium 12dp, large 16dp, extra large 28dp, extra extra large 48dp. Primary CTA buttons become fully pill shaped with 32dp height. Cards use 24dp radius. Floating action buttons are squircle style (not circle, not rounded square) with 28dp morphing corners. Segmented controls have extra rounded pill ends. Icon buttons get a soft square container with 12dp corners when pressed.

3. Size Hierarchy
Make the most important elements visually dominant. The SOS button in the bottom nav becomes a hero 64dp circle with deeper shadow. Primary headings use display-small 36sp. Section headings use headline-small 24sp. Screen hero elements like the report button take more space. Reduce visual weight of secondary actions by using smaller text and less saturated colors. Use big numbers for counts in statistics screen: 44sp bold.

4. Motion and Flow hints
While Stitch cannot animate, the layout must suggest motion. Use directional spacing: let screen transitions feel like they slide from the right. Show collapsed and expanded states of the same component on different screens to hint that the app uses morphing animations. FAB menu should show the expanded state in at least one screen with small secondary actions fanning out.

5. Containment and Grouping
Wrap related content into clearly bounded containers with their own tonal surface. Each section has its own rounded container with subtle tonal background (surfaceContainerLow or surfaceContainerHigh) instead of loose items floating on a single background. Lists get inner card wrappers. Form fields are grouped into a card with one outer border rather than individual bordered inputs. Bottom navigation bar has a pill-shaped container around its items.

Typography: switch to Google Sans or Roboto Flex variable font. Use the M3 type scale: display-large 57sp, display-medium 45sp, display-small 36sp, headline-large 32sp, headline-medium 28sp, headline-small 24sp, title-large 22sp, title-medium 16sp, title-small 14sp, body-large 16sp, body-medium 14sp, label-large 14sp bold, label-medium 12sp bold. Section headings switch to headline-small weight 500, not just bold body text.

Keep all functionality the same. Keep Polish text. Keep the app in Material You dynamic color harmony with alert red as brand color.
```

> Znaków: ~3000 — w safe zone (< 5000).

---

## Prompty B — per-screen touch-upy po głównym refactorze

Użyj tych tylko dla screenów, które po Prompcie A wymagają dopracowania.
**Jeden prompt = jeden screen.**

### B1 — Map screen (wyraziste markery i FAB)

```
On the Map screen apply full M3 Expressive treatment. The red Zgłoś button becomes an extended FAB with a bold squircle shape, elevated shadow, and a warning triangle icon followed by the "Zgłoś" label. Alert map pins become rounded triangular drops with a bright expressive red fill and a solid white center icon for the category. Cluster markers become squircle containers with large bold count numbers inside. Bottom navigation bar is a floating pill-shaped bar with 32dp container radius, floating 16dp above the bottom edge with a soft shadow. The center SOS item rises above the bar as a 64dp hero circle. Keep the map background clean.
```

### B2 — Alert Detail (big hero containment)

```
Redesign the Alert Detail screen in M3 Expressive. Top map preview becomes a large rounded container with 28dp corners. Below it, wrap category icon, title, and time in a single hero card with tonal surface container background. The two voting buttons become large segmented-control style pills with strong color differentiation: confirm button in filled secondary-container green, deny in outlined tertiary grey. Comments section is its own distinct rounded container with 24dp radius, not floating items. Input field at bottom becomes a pill-shaped search-style field with a filled send button inside.
```

### B3 — Onboarding (expressive illustrations)

```
Refactor the 5 onboarding slides in M3 Expressive style. Each slide hero illustration sits in a large organic blob-shaped background container using a tonal primary color variant. The illustration itself uses M3 iconography thickness (2dp stroke, rounded caps). Pagination dots at the bottom become elongated pill indicators — the active one stretches horizontally while inactive ones are small circles. The primary CTA Dalej button is a fully expressive pill with 56dp height and large 20sp label. Skip button stays understated as text only.
```

### B4 — Profile and Badges (size hierarchy)

```
Apply M3 Expressive size hierarchy to the Profile screen. The user avatar becomes a 112dp hero circle with a thin outlined ring around it. Username uses display-small 36sp weight 500. Reputation score is a large expressive chip with bold 28sp number and a star icon. The Jestem bezpieczny button grows to a full-width extra-large pill with 64dp height and label-large bold text. The menu list groups items into 3-4 tonal containers (Aktywność, Społeczność, System) each with their own surface background and 16dp inner padding, rather than a flat single list. On Badges screen, earned badges are 40% larger than locked ones, with the most recent badge doubled in size and placed at the top as a hero card.
```

### B5 — Lists screens (containment rework)

```
For all list-based screens (My Alerts, News, Ranking, Family, Emergency Numbers) apply M3 Expressive containment. Each list item sits inside its own rounded card with 20dp radius, separated by 8dp vertical gap, on a surfaceContainerLowest background. Avoid flat list dividers — use tonal surface variations instead. Section headings use headline-small 24sp with generous top padding. Filter chips at the top become expressive pill rows with strong selected state (filled primary-container tint) and subtle unselected state (outlined).
```

---

## Fallback — jeśli Prompt A zepsuje layout

Jeżeli Stitch po Prompt A zresetuje screeny lub zniszczy nawigację, wklej
osobno ten recovery (ze `03_RECOVERY_PROMPTS.md` adaptowane do M3E):

```
Restore the original screen structure and all Polish labels. Keep M3 Expressive color, shape, size and containment from the previous prompt, but bring back the original layout of bottom navigation (5 items with SOS in center), the Zgłoś button above the nav, and the full-screen map. Only update the visual style, not the structure.
```

---

## Materiały referencyjne dla Stitcha (wklejaj w potrzebie)

Gdy Stitch pyta o precyzje, wspieraj się tymi linkami i hasłami:

- **Color roles M3:** https://m3.material.io/styles/color/the-color-system/color-roles
- **Shape scale:** https://m3.material.io/styles/shape/shape-scale-tokens
- **Type scale:** https://m3.material.io/styles/typography/type-scale-tokens
- **Expressive announcement (blog):** https://blog.google/products/android/material-3-expressive-android-wear-os/
- **Key terms:** `surfaceContainer`, `squircle`, `pill-shape`, `tonal elevation`,
  `expressive FAB`, `variable font`, `display-small`, `hero sizing`
