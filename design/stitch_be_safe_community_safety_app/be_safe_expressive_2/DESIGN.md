---
name: be:Safe Expressive
colors:
  surface: '#fff8f7'
  surface-dim: '#f5d2d1'
  surface-bright: '#fff8f7'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fff0ef'
  surface-container: '#ffe9e8'
  surface-container-high: '#ffe1e0'
  surface-container-highest: '#fedad9'
  on-surface: '#291616'
  on-surface-variant: '#5e3f3e'
  inverse-surface: '#412b2b'
  inverse-on-surface: '#ffedec'
  outline: '#936e6d'
  outline-variant: '#e8bcbb'
  surface-tint: '#bf002e'
  primary: '#ba002c'
  on-primary: '#ffffff'
  primary-container: '#e9003a'
  on-primary-container: '#fffbff'
  inverse-primary: '#ffb3b3'
  secondary: '#006e2a'
  on-secondary: '#ffffff'
  secondary-container: '#5cfd80'
  on-secondary-container: '#00732c'
  tertiary: '#0056c5'
  on-tertiary: '#ffffff'
  tertiary-container: '#0f6df3'
  on-tertiary-container: '#fefcff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad9'
  primary-fixed-dim: '#ffb3b3'
  on-primary-fixed: '#400009'
  on-primary-fixed-variant: '#920021'
  secondary-fixed: '#69ff87'
  secondary-fixed-dim: '#3ce36a'
  on-secondary-fixed: '#002108'
  on-secondary-fixed-variant: '#00531e'
  tertiary-fixed: '#d9e2ff'
  tertiary-fixed-dim: '#b0c6ff'
  on-tertiary-fixed: '#001945'
  on-tertiary-fixed-variant: '#00429b'
  background: '#fff8f7'
  on-background: '#291616'
  surface-variant: '#fedad9'
typography:
  display-sm:
    fontFamily: Roboto Flex
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.5px
  headline-sm:
    fontFamily: Roboto Flex
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 32px
    letterSpacing: 0px
  title-lg:
    fontFamily: Roboto Flex
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 28px
  body-lg:
    fontFamily: Roboto Flex
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.5px
  label-lg:
    fontFamily: Roboto Flex
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.1px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8dp
  margin-mobile: 16dp
  margin-tablet: 24dp
  gutter: 16dp
  hero-button-size: 64dp
---

## Brand & Style

This design system is built for high-stakes personal safety, balancing immediate urgency with a reassuring sense of protection. The brand personality is vigilant, authoritative, and responsive. 

The aesthetic follows an **Expressive Material 3** direction, characterized by exaggerated shape scales and high-contrast tonal containment. It moves away from flat minimalism into a structured, tactile layout where hierarchy is reinforced through varying corner radii and tonal depth. The UI aims to evoke confidence during emergencies and calm during routine safety monitoring, specifically optimized for Polish typography with extended Latin character support.

## Colors

The palette utilizes full Material 3 tonal roles to define functional urgency. 

- **Primary (Alert Red):** Reserved for critical actions (SOS, Cancel, Stop).
- **Secondary (Safe Green):** Used for status indicators and "All Clear" confirmations.
- **Tertiary (Info Blue):** Dedicated to auxiliary features like location sharing or safe-zone settings.

Backgrounds must not be pure white; they utilize `surfaceContainerLow` for the base canvas and `surfaceContainer` for grouped content blocks. This ensures that white cards and primary buttons pop with maximum visibility.

## Typography

The design system employs **Roboto Flex** as a variable font to maintain legibility across various viewport widths and Polish diacritics (ą, ć, ę, ł, ń, ó, ś, ź, ż). 

Large display styles are used for critical status updates, while headlines are kept tight and medium-weight to ensure they don't break across multiple lines in the character-heavy Polish language. Line heights are slightly increased for body text to maintain readability in high-stress situations.

## Layout & Spacing

The layout uses a **fluid grid** with an 8dp baseline rhythm. Content is grouped into distinct tonal containers rather than floating freely.

- **Mobile:** 4-column grid with 16dp margins.
- **Tablet:** 8-column grid with 24dp margins.

Size hierarchy is strictly enforced: the SOS button is a fixed **64dp** hero element, centered or anchored in a prominent position, ensuring it remains the most accessible touch target on any screen. Spacing between grouped elements in a container is 8dp, while the space between containers is 16dp or 24dp depending on the content density.

## Elevation & Depth

This design system uses **Tonal Layers** rather than heavy shadows to indicate hierarchy. 

Depth is communicated by color shifting:
1. **Level 0 (Canvas):** `surfaceContainerLow`.
2. **Level 1 (Containers):** `surface` or `surfaceContainerHigh`.
3. **Level 2 (Active Elements):** `primaryContainer` or `secondaryContainer`.

Shadows are only applied to the Floating Action Button (FAB) and the hero SOS button to provide a "pressable" tactile feel, using a soft, low-opacity 12% black blur.

## Shapes

The shape language is highly expressive and varied to provide clear visual affordances:

- **Cards & Major Containers:** 24dp (Large) for a friendly, approachable structure.
- **CTA Buttons:** Pill-shaped (Full radius) to distinguish them from informational cards.
- **FABs:** Squircle-style (variable corner smoothing) to stand out as primary app actions.
- **Hero SOS Button:** 48dp (Extra-large) or circular to maximize the hit area.
- **Inputs & Small Chips:** 8dp to 12dp for a more functional, precise feel.

## Components

### Buttons
- **Primary CTA:** Pill-shaped, high-contrast `onPrimary` text on `primary` background.
- **Secondary Actions:** Pill-shaped, `secondaryContainer` with `onSecondaryContainer` text.
- **Hero SOS:** 64dp squircle or circle, `primary` color, elevated.

### Cards & Containment
- All grouped content must reside within `surfaceContainerHigh` or `surfaceVariant` rounded containers (24dp radius). 
- Avoid borders; use tonal differences to separate sections.

### Input Fields
- Filled style with 12dp top-corner radii and a persistent bottom stroke.
- Error states use `primary` (Red) tokens for immediate visibility.

### Lists
- Items are housed in tonal containers with 16dp internal padding.
- Leading icons are always placed in a small 8dp rounded square container.

### Status Indicators
- **Safe:** `secondaryContainer` chips.
- **Warning:** `tertiaryContainer` chips.
- **Danger:** `primaryContainer` chips.