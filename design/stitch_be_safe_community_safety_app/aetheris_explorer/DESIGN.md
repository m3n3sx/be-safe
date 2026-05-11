---
name: Aetheris Explorer
colors:
  surface: '#fff8f5'
  surface-dim: '#edd5ca'
  surface-bright: '#fff8f5'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fff1ea'
  surface-container: '#ffeadf'
  surface-container-high: '#fbe3d7'
  surface-container-highest: '#f6ded2'
  on-surface: '#251912'
  on-surface-variant: '#584235'
  inverse-surface: '#3b2d26'
  inverse-on-surface: '#ffede5'
  outline: '#8c7263'
  outline-variant: '#e0c0af'
  surface-tint: '#994700'
  primary: '#994700'
  on-primary: '#ffffff'
  primary-container: '#ff7a00'
  on-primary-container: '#5c2800'
  inverse-primary: '#ffb68b'
  secondary: '#006972'
  on-secondary: '#ffffff'
  secondary-container: '#9ff0fb'
  on-secondary-container: '#066f79'
  tertiary: '#006399'
  on-tertiary: '#ffffff'
  tertiary-container: '#00a8ff'
  on-tertiary-container: '#003a5c'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbc8'
  primary-fixed-dim: '#ffb68b'
  on-primary-fixed: '#321200'
  on-primary-fixed-variant: '#753400'
  secondary-fixed: '#9ff0fb'
  secondary-fixed-dim: '#82d3de'
  on-secondary-fixed: '#001f23'
  on-secondary-fixed-variant: '#004f56'
  tertiary-fixed: '#cde5ff'
  tertiary-fixed-dim: '#95ccff'
  on-tertiary-fixed: '#001d32'
  on-tertiary-fixed-variant: '#004a75'
  background: '#fff8f5'
  on-background: '#251912'
  surface-variant: '#f6ded2'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '800'
    lineHeight: '1.1'
    letterSpacing: -0.04em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
    letterSpacing: 0em
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
    letterSpacing: 0em
  label-bold:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1.2'
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  margin-mobile: 20px
  gutter-mobile: 12px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
  section-gap: 48px
---

## Brand & Style
The design system embodies a premium, high-octane approach to travel and adventure. It targets the sophisticated explorer who seeks both adrenaline and luxury. The aesthetic is defined by **Glassmorphism**, emphasizing high-end materiality through the use of frosted surfaces, deep layered shadows, and immersive full-bleed photography.

The emotional response is one of clarity, safety, and excitement. By utilizing tactile depth and translucent layers, the UI feels like a high-tech viewfinder, bridging the gap between the digital interface and the physical world. This system rejects flat, utilitarian patterns in favor of a textured, "living" interface that responds to light and motion.

## Colors
The palette is rooted in high-contrast clarity. The primary background is a clean, architectural white/light grey, providing a neutral stage for vibrant accents.

- **Primary (Vibrant Orange):** Reserved for high-priority calls to action and active navigation states.
- **Secondary (Deep Teal):** Used for status indicators, secondary actions, and calming informative elements.
- **Safety Accents:** Rather than harsh, flat semantic colors, the system utilizes soft, glowing hues of Mint Green and Rose Red to indicate safety and alerts, often paired with a subtle outer glow or "bloom" effect.
- **Neutral:** A deep carbon black is used for primary typography to ensure maximum legibility against light glass surfaces.

## Typography
This design system utilizes **Inter** exclusively to maintain a clean, technical, yet approachable feel. The typographic hierarchy is aggressive, featuring large, expressive headlines with tight leading to create a sense of urgency and modernity.

High-contrast weight distribution is key; headlines are predominantly Bold or ExtraBold (700-800), while body text remains regular for readability. For mobile, headline sizes scale down significantly to ensure they remain impactful without breaking across too many lines. Large display types should be used sparingly for "hero" moments or destination names.

## Layout & Spacing
The system employs a fluid, margin-based layout optimized for mobile-first experiences. The layout relies on safe margins and dynamic padding rather than a rigid column grid, allowing elements to feel like they are floating over the background.

- **Mobile:** 20px side margins with a vertical spacing rhythm based on 8px increments.
- **Layering:** Elements are often overlapped. For example, cards may partially sit atop the navigation bar or "break" the container to imply depth and continuity.
- **Photography:** Immersive, high-resolution imagery should dictate the layout, with text elements often overlaid on blurred glass panels atop the images.

## Elevation & Depth
Depth is the primary communicator of hierarchy. The system uses three distinct tiers of elevation:

1.  **Base Layer:** The light grey/white canvas or full-bleed immersive photography.
2.  **Glass Layer:** Semi-transparent panels with a 20px–40px backdrop blur (e.g., navigation bars, info overlays).
3.  **Floating Layer:** Opaque cards or buttons with deep, layered shadows. Shadows should use a multi-step approach (a tight, dark shadow for proximity and a wide, soft, low-opacity shadow for "lift").

Shadows should never be pure black; they are tinted with the primary accent color or a deep charcoal to maintain a premium, atmospheric feel.

## Shapes
The shape language is sophisticated and rounded, avoiding harsh sharp edges to maintain an "organic" feel amidst technical data.

- **Standard Elements:** 16px (0.5rem) radius for standard buttons and input fields.
- **Primary Cards:** 24px (1.5rem) radius to create a soft, friendly silhouette.
- **Floating Containers:** Extra-large 32px-40px radii for bottom sheets and featured interactive maps.
- **Icons:** Encased in circular "glass" containers or high-contrast floating circles.

## Components
- **Frosted Navigation Bars:** Fixed at the bottom or top, utilizing a `backdrop-filter: blur(24px)` with a very fine 1px white border at 20% opacity.
- **Floating Action Cards:** High-contrast white cards with a subtle inner glow and a deep external shadow. They should contain expressive photography that fills the top half of the card.
- **Status Glows:** Indicators for "Safety" (Green) or "Alert" (Red) should be rendered as soft, pulsing radial gradients behind icons rather than simple flat circles.
- **Glass Buttons:** Secondary actions should use translucent glass backgrounds with white text.
- **Primary Buttons:** Solid, vibrant orange buttons with a slight shadow "pop" on press.
- **Input Fields:** Minimalist with a light grey background and a subtle bottom border that glows when focused.
- **Immersive Lists:** Items should feature large thumbnails with rounded corners and high-contrast labels, utilizing "See all" links that use the secondary teal color.