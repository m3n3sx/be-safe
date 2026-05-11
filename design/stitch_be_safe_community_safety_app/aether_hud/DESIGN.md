---
name: Aether HUD
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#b9cacb'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#849495'
  outline-variant: '#3b494b'
  surface-tint: '#00dbe9'
  primary: '#dbfcff'
  on-primary: '#00363a'
  primary-container: '#00f0ff'
  on-primary-container: '#006970'
  inverse-primary: '#006970'
  secondary: '#d0bcff'
  on-secondary: '#3c0091'
  secondary-container: '#571bc1'
  on-secondary-container: '#c4abff'
  tertiary: '#fff2f5'
  on-tertiary: '#620040'
  tertiary-container: '#ffcbe0'
  on-tertiary-container: '#a43173'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#7df4ff'
  primary-fixed-dim: '#00dbe9'
  on-primary-fixed: '#002022'
  on-primary-fixed-variant: '#004f54'
  secondary-fixed: '#e9ddff'
  secondary-fixed-dim: '#d0bcff'
  on-secondary-fixed: '#23005c'
  on-secondary-fixed-variant: '#5516be'
  tertiary-fixed: '#ffd8e7'
  tertiary-fixed-dim: '#ffafd3'
  on-tertiary-fixed: '#3d0026'
  on-tertiary-fixed-variant: '#85145a'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  display-lg:
    fontFamily: Playfair Display
    fontSize: 48px
    fontWeight: '400'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Playfair Display
    fontSize: 32px
    fontWeight: '400'
    lineHeight: '1.2'
  headline-md:
    fontFamily: Playfair Display
    fontSize: 24px
    fontWeight: '400'
    lineHeight: '1.3'
    letterSpacing: 0.02em
  body-lg:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '200'
    lineHeight: '1.6'
    letterSpacing: 0.01em
  body-sm:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '200'
    lineHeight: '1.5'
  label-caps:
    fontFamily: Space Mono
    fontSize: 12px
    fontWeight: '400'
    lineHeight: '1'
    letterSpacing: 0.15em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 4px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 64px
  glass-padding: 24px
---

## Brand & Style

This design system is built upon a high-fidelity, futuristic "Heads-Up Display" (HUD) aesthetic. It targets advanced technology interfaces, data-heavy dashboards, and immersive digital environments where information density is high but visual weight remains light. 

The brand personality is sophisticated, clinical, and ethereal. By combining the precision of technical instrumentation with the elegance of editorial typography, the system evokes a sense of "quiet intelligence." The core style is **Glassmorphism**, characterized by deep background blurs, multi-layered translucency, and vibrant neon accents that simulate light-emitting surfaces rather than physical materials.

## Colors

The palette is anchored in a deep, nocturnal neutral base to allow neon accents to resonate. 

- **Primary (Electric Cyan):** Used for critical data points, active states, and focus indicators. It mimics a laser-etched glow.
- **Secondary (Vivid Violet):** Used for depth, secondary actions, and gradient transitions.
- **Backgrounds:** Never pure black; instead, use deep midnight blues with high transparency (60-80%) and significant backdrop-blur (20px-40px).
- **Gradients:** Linear and radial gradients should transition from the primary Cyan to the secondary Violet at 45-degree angles to simulate shifting light sources.

## Typography

This design system employs a high-contrast typographic pairing to reinforce the "Futuristic Editorial" theme.

- **Titles & Headings:** Use **Playfair Display**. The thin weights of this serif provide an elegant, high-fashion contrast to the technical HUD elements. It should be used sparingly for major section headers.
- **Body Text:** Use **Geist** at its lightest weight (200). The ultra-light stroke weight maintains the "etched on glass" feel.
- **Data & Metadata:** Use **Space Mono** for all numerical data, status labels, and technical readouts. This ensures a mono-spaced, machine-readable aesthetic that aligns with the HUD concept.

## Layout & Spacing

The layout follows a **Fluid Grid** model with generous margins to allow the background gradients and blurs to breathe. 

- **Grid:** A 12-column system is used for desktop, reducing to 4 columns on mobile. 
- **Rhythm:** All spacing is based on a 4px baseline unit. 
- **Air:** Elements should feel "floating." Use wide internal padding (24px+) within glass cards to prevent content from touching the luminous borders.
- **Parallax:** On desktop, implement a subtle mouse-follow parallax effect where the background layers move at 5% of the scroll speed relative to the foreground cards.

## Elevation & Depth

Depth is conveyed through transparency and "light-bleed" rather than traditional drop shadows.

- **Surface Tiers:** 
  - **Tier 1 (Base):** Subtle noise texture over a dark gradient.
  - **Tier 2 (Mid-ground):** Frosted glass panels with a 20px backdrop-blur and a 1px solid border at 10% white opacity.
  - **Tier 3 (Floating):** Elements like buttons or tooltips use a 40px backdrop-blur and a secondary "Outer Glow" shadow (Primary color, 15% opacity, 20px blur).
- **Shadows:** Avoid black shadows. Use colored "glow" shadows that match the primary or secondary color of the element to simulate light emission onto the surface below.

## Shapes

The shape language is "Soft-Technical." We avoid the friendly, bubbly nature of high-rounded corners in favor of a precision-engineered look. 

Standard components use a **0.25rem (4px)** corner radius. This provides a subtle hint of refinement while maintaining the structural integrity of a technical interface. Larger glass containers may use up to 0.75rem to distinguish themselves as primary structural elements.

## Components

- **Buttons:** Ghost-style by default. Use a 1px border with a subtle gradient stroke. On hover, the background fill increases in opacity from 5% to 15% with a primary-colored glow.
- **Glass Cards:** The signature component. Must include `backdrop-filter: blur(24px)`, a semi-transparent background, and a "Top-Left" directional highlight on the border to simulate a light source.
- **Input Fields:** Bottom-border only or very thin 1px frames. Use the `label-caps` typography for floating labels.
- **Icons:** Use ultra-thin (1px stroke) SVG icons. Avoid filled icons unless indicating an "active" or "selected" state.
- **Chips/Status:** Small, pill-shaped elements with a high-saturation glow of the status color (e.g., Green for "Online").
- **HUD Readouts:** Add a "Scanning" animation—a thin, horizontal line of light that periodically passes over data-heavy cards.