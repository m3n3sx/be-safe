---
name: Raw Industrial
colors:
  surface: '#f9f9f9'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f3'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1b1b1b'
  on-surface-variant: '#4c4546'
  inverse-surface: '#303030'
  inverse-on-surface: '#f1f1f1'
  outline: '#7e7576'
  outline-variant: '#cfc4c5'
  surface-tint: '#5e5e5e'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#1b1b1b'
  on-primary-container: '#848484'
  inverse-primary: '#c6c6c6'
  secondary: '#5e604d'
  on-secondary: '#ffffff'
  secondary-container: '#e1e1c9'
  on-secondary-container: '#636451'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#1b1b1b'
  on-tertiary-container: '#848484'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e2e2e2'
  primary-fixed-dim: '#c6c6c6'
  on-primary-fixed: '#1b1b1b'
  on-primary-fixed-variant: '#474747'
  secondary-fixed: '#e4e4cc'
  secondary-fixed-dim: '#c8c8b0'
  on-secondary-fixed: '#1b1d0e'
  on-secondary-fixed-variant: '#474836'
  tertiary-fixed: '#e2e2e2'
  tertiary-fixed-dim: '#c6c6c6'
  on-tertiary-fixed: '#1b1b1b'
  on-tertiary-fixed-variant: '#474747'
  background: '#f9f9f9'
  on-background: '#1b1b1b'
  surface-variant: '#e2e2e2'
typography:
  display-xl:
    fontFamily: Space Mono
    fontSize: 80px
    fontWeight: '700'
    lineHeight: '1.0'
    letterSpacing: -0.04em
  display-lg:
    fontFamily: Space Mono
    fontSize: 56px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Space Mono
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
  headline-lg-mobile:
    fontFamily: Space Mono
    fontSize: 24px
    fontWeight: '700'
    lineHeight: '1.2'
  body-lg:
    fontFamily: JetBrains Mono
    fontSize: 18px
    fontWeight: '500'
    lineHeight: '1.5'
  body-md:
    fontFamily: JetBrains Mono
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
  label-bold:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '700'
    lineHeight: '1.0'
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '400'
    lineHeight: '1.0'
spacing:
  unit: 4px
  gutter: 24px
  margin-desktop: 48px
  margin-mobile: 16px
  border-width: 4px
  overlap-offset: -12px
---

## Brand & Style

This design system is rooted in **Neo-Brutalism**, emphasizing honesty in structure and a rejection of traditional digital "politeness." It is designed for developers, technical creatives, and avant-garde brands who value transparency and bold functionality over aesthetic comfort.

The UI should evoke a sense of digital "work-in-progress," utilizing raw structural elements, heavy lines, and a deliberate lack of depth. It prioritizes information density and clarity through blunt, monospaced typography and high-contrast visuals. The emotional response is one of urgency, confidence, and technical authority.

## Colors

The palette is anchored by a high-contrast foundation of **Pitch Black** and **Cream**. This combination provides better readability than pure white while maintaining a stark, industrial feel.

- **Primary & Neutral:** Pitch black is used for all structural elements, borders, and primary text.
- **Surface:** Cream serves as the universal background and container color.
- **Accents:** Bright Yellow and Harsh Magenta are used sparingly for calls to action, status indicators, or to highlight critical data points. These colors should clash with the cream background to demand immediate attention.
- **Interaction:** State changes (hover, active) should invert colors or swap with an accent color rather than using subtle tonal shifts.

## Typography

This design system uses monospaced typefaces exclusively to reinforce its technical, raw aesthetic. 

- **Headlines:** Use **Space Mono** for all display and headline levels. It should be set with tight line-height and occasionally negative letter spacing for a "blocky" appearance. 
- **Body & Labels:** Use **JetBrains Mono** for its superior legibility in dense technical contexts. 
- **Tone:** Copy must be direct, blunt, and devoid of marketing fluff. Use all-caps for labels and small UI elements to create a sense of mechanical urgency.

## Layout & Spacing

The layout is built on an **Asymmetrical Grid** that rejects traditional centered balance. Elements should feel "anchored" to the edges or purposefully misaligned to create visual tension.

- **Grid Model:** A 12-column fluid grid where containers often span irregular column counts (e.g., a 7-column main area and a 5-column sidebar).
- **Overlapping:** Components should frequently overlap their parent containers or neighboring elements using negative margins (specified as `overlap-offset`).
- **Margins & Gutters:** Large, generous gutters contrast with the heavy 4px borders of the components themselves.
- **Responsiveness:** On mobile, the overlap is reduced but the 4px border remains constant to preserve the "heavy" aesthetic.

## Elevation & Depth

Depth is conveyed through **Structural Stacking** rather than lighting or shadows. 

- **No Shadows:** Shadows are strictly prohibited. 
- **Heavy Borders:** All containers, buttons, and inputs must use a 4px solid black border.
- **Layering:** Hierarchy is established by physically overlapping elements. Higher-priority items are placed "on top" of others, often obscuring small portions of the element below to emphasize the stack. 
- **Hard Offsets:** Instead of a shadow, an element may have a "duplicate" black box offset behind it by 4px or 8px to simulate a hard, 2D extrusion.

## Shapes

The shape language is strictly **Geometric and Sharp**. 

- **Corners:** All corners must be 0px (sharp). This applies to buttons, cards, input fields, and even selection indicators.
- **Lines:** Use horizontal and vertical rules (4px thickness) to separate content sections instead of whitespace alone.
- **Angles:** While most elements are orthogonal, occasional 45-degree cuts or "dog-ear" corners can be used on decorative elements to break the grid.

## Components

### Buttons
Buttons are rectangular with 4px black borders. They use `label-bold` (uppercase) text.
- **Default:** Cream background, black text.
- **Hover/Active:** Background swaps to Bright Yellow or Harsh Magenta. The button may "shift" 2px down and right to simulate a physical press without using shadows.

### Inputs
Text fields are Cream with a 4px black border. Use `body-md` for user input. Placeholder text is black at 50% opacity. Focused states must use a Bright Yellow background.

### Cards & Containers
Cards are defined by their 4px border. They do not have padding-bottom in some cases—content can bleed directly into the bottom border. Cards should often be positioned with a slight asymmetrical offset from the grid.

### Selection (Checkboxes/Radios)
These are 24px x 24px squares. A "checked" state is indicated by a solid black fill or a large "X" character in Space Mono.

### Lists
Lists are separated by 4px horizontal lines. Each list item should feel like a distinct row in a ledger. Use monospaced numbers (01, 02, 03) for ordered lists to maintain the technical aesthetic.

### Tags / Chips
Tags are small black boxes with Cream text, or vice-versa. No rounded corners. They are used for metadata and should look like "stamps" on the interface.