---
name: Serenity Guard
colors:
  surface: '#fcf8f9'
  surface-dim: '#dcd9da'
  surface-bright: '#fcf8f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f3'
  surface-container: '#f0eded'
  surface-container-high: '#eae7e8'
  surface-container-highest: '#e5e2e2'
  on-surface: '#1c1b1c'
  on-surface-variant: '#44474b'
  inverse-surface: '#313031'
  inverse-on-surface: '#f3f0f0'
  outline: '#75777b'
  outline-variant: '#c5c6cb'
  surface-tint: '#595f67'
  primary: '#03080e'
  on-primary: '#ffffff'
  primary-container: '#1a2027'
  on-primary-container: '#828790'
  inverse-primary: '#c1c7d0'
  secondary: '#006c4c'
  on-secondary: '#ffffff'
  secondary-container: '#9df4cb'
  on-secondary-container: '#0f7252'
  tertiary: '#190001'
  on-tertiary: '#ffffff'
  tertiary-container: '#480008'
  on-tertiary-container: '#db5f60'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dde3ed'
  primary-fixed-dim: '#c1c7d0'
  on-primary-fixed: '#161c23'
  on-primary-fixed-variant: '#41474f'
  secondary-fixed: '#9df4cb'
  secondary-fixed-dim: '#81d7b0'
  on-secondary-fixed: '#002115'
  on-secondary-fixed-variant: '#005138'
  tertiary-fixed: '#ffdad8'
  tertiary-fixed-dim: '#ffb3b1'
  on-tertiary-fixed: '#410007'
  on-tertiary-fixed-variant: '#862026'
  background: '#fcf8f9'
  on-background: '#1c1b1c'
  surface-variant: '#e5e2e2'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 80px
    fontWeight: '100'
    lineHeight: 96px
    letterSpacing: -0.04em
  display-md:
    fontFamily: Inter
    fontSize: 64px
    fontWeight: '200'
    lineHeight: 72px
    letterSpacing: -0.02em
  headline-hero:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '300'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-hero-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '300'
    lineHeight: 36px
  body-main:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-button:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  container-padding: 24px
  gutter: 16px
  card-gap: 20px
  section-margin: 48px
---

## Brand & Style

The design system is rooted in the "Premium Wellness" aesthetic, pivoting away from the high-stress visual language typically associated with safety and security. It prioritizes emotional regulation through an airy, high-fidelity interface that feels more like a meditative space than a digital tool.

The brand personality is **vigilant yet calm**. It aims to reduce cortisol levels during use, employing a minimalist philosophy that values negative space over density. The visual style is a hybrid of **Glassmorphism** and **Modern Minimalism**, utilizing soft radial gradients ("Glow Orbs") to represent community presence and safety status without the need for intrusive alerts or harsh borders.

## Colors

The palette is anchored by a deep, authoritative navy used for primary actions and text, providing a grounded contrast to the ethereal background. 

- **Background:** A cool, near-white tint (#F8F9FB) that suggests openness and clarity.
- **Surfaces:** Pure white (#FFFFFF) used for elevated cards to create subtle depth without shadows.
- **Status Orbs:** These are used as soft radial gradients. 
    - **Safe-Mint (#7DD3AC):** Indicates community stability.
    - **Calm-Aqua (#9EEBEC):** Used for passive monitoring and "all-clear" states.
    - **Alert-Coral (#FF7A7A):** A non-aggressive red used for urgent notifications, designed to be visible without inducing panic.

## Typography

This design system utilizes **Inter** exclusively to maintain a clean, geometric, and utilitarian foundation that balances the softer visual elements. 

The typographic hierarchy relies on extreme weight contrasts rather than size alone. Large-scale display numbers (e.g., active community members or time elapsed) use ultra-thin weights (100-200) to feel sophisticated. Hero titles remain light at 300 weight, ensuring the interface feels "breathable." Functional labels and buttons use a 500 weight for immediate legibility, while body text remains at 400 for optimal reading comfort.

## Layout & Spacing

The layout follows a **fluid grid** model with generous internal margins to support the "airy" aesthetic. On mobile devices, a single-column layout is preferred, utilizing 24px side margins to prevent content from touching the screen edges.

Structure is defined by **whitespace and color washes** rather than lines. Elements are grouped within cards or floating widgets, with a consistent 20px vertical gap between related modules. The design system leverages large, purposeful gaps (48px+) between distinct sections to guide the user's eye and prevent cognitive overload.

## Elevation & Depth

Depth is achieved through **Glassmorphism** and soft ambient shadows. 

1.  **Base Layer:** The #F8F9FB background.
2.  **Surface Layer:** Pure white cards with a 24dp corner radius. These use a very soft, high-diffusion shadow (Blur: 40px, Opacity: 4%, Color: #1A2027) to appear as if they are resting just above the surface.
3.  **Floating Layer:** Glassmorphic widgets (Backdrop Blur: 20px, Transparency: 80%) used for secondary information or persistent controls.
4.  **Navigation Layer:** The dark navy navigation pill, which sits at the highest elevation with a more pronounced, darker shadow to indicate its permanence and accessibility.

## Shapes

The shape language is dominated by **large, friendly radii**. 

- **Cards & Containers:** A consistent 24px radius (approx 1.5rem) is applied to all primary surfaces to soften the interface.
- **Navigation & Buttons:** Pill-shaped (fully rounded) containers are used for the primary navigation bar and main action buttons, emphasizing a tactile, modern feel.
- **Status Indicators:** Perfect circles are used for the "Glow Orbs," often with a 40-80px radial blur to create a "breathing" effect that feels organic rather than digital.

## Components

### Buttons
- **Primary:** Deep Navy (#1A2027) pill-shaped buttons with white Inter (Weight 500) text. No borders.
- **Secondary/Ghost:** Transparent background with a subtle 1px stroke in #1A2027 (10% opacity) or simply a text-link style with 500 weight.

### Floating Navigation
The primary navigation is a **Dark Navy Pill Bar** that floats at the bottom of the viewport. Icons should be monolinear and white, with enough horizontal padding to allow for comfortable thumb interaction.

### Cards & Widgets
Cards must use #FFFFFF background with 24px corner radii. Use internal padding of 24px. For "Live" data, use a Glassmorphic overlay widget that sits partially inside or floating above the card.

### Glow Orbs
The central anchor of the home screen. A large (120dp+) radial gradient. The core color (e.g., Safe-Mint) should be at 100% opacity at the center, fading to 0% at the edges. For an "active" state, the orb should subtly pulse between 90% and 110% scale.

### Input Fields
Soft, light-gray washes or pure white with a 24px radius. Use weight 500 for labels floating above the input. Avoid hard bounding boxes; prefer a subtle change in background tint to define the field area.