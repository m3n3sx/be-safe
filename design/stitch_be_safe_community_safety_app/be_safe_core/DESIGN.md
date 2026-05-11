---
name: be:Safe Core
colors:
  surface: '#fcf8fb'
  surface-dim: '#dcd9dc'
  surface-bright: '#fcf8fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f5'
  surface-container: '#f0edef'
  surface-container-high: '#eae7ea'
  surface-container-highest: '#e4e2e4'
  on-surface: '#1b1b1d'
  on-surface-variant: '#3d4a3c'
  inverse-surface: '#303032'
  inverse-on-surface: '#f3f0f2'
  outline: '#6d7b6b'
  outline-variant: '#bccbb8'
  surface-tint: '#006e28'
  primary: '#006e28'
  on-primary: '#ffffff'
  primary-container: '#34c759'
  on-primary-container: '#004d1a'
  inverse-primary: '#53e16f'
  secondary: '#5d5e63'
  on-secondary: '#ffffff'
  secondary-container: '#dfdfe4'
  on-secondary-container: '#616267'
  tertiary: '#c0000a'
  on-tertiary: '#ffffff'
  tertiary-container: '#ff8e80'
  on-tertiary-container: '#890005'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#72fe88'
  primary-fixed-dim: '#53e16f'
  on-primary-fixed: '#002107'
  on-primary-fixed-variant: '#00531c'
  secondary-fixed: '#e2e2e7'
  secondary-fixed-dim: '#c6c6cb'
  on-secondary-fixed: '#1a1c1f'
  on-secondary-fixed-variant: '#45474b'
  tertiary-fixed: '#ffdad5'
  tertiary-fixed-dim: '#ffb4aa'
  on-tertiary-fixed: '#410001'
  on-tertiary-fixed-variant: '#930005'
  background: '#fcf8fb'
  on-background: '#1b1b1d'
  surface-variant: '#e4e2e4'
typography:
  display-bold:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 30px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
  body-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  margin-page: 20px
  gutter-card: 12px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
  safe-area-bottom: 34px
---

## Brand & Style

The design system is rooted in the "Safe & Seamless" philosophy, blending the familiarity of iOS human interface patterns with the urgency and clarity required for personal safety. The brand personality is calm, authoritative, and responsive. It avoids the clinical coldness of traditional security apps by using soft, organic shapes and a vibrant, life-affirming green.

The aesthetic follows a **Modern iOS/Minimalist** approach. It prioritizes high-legibility typography and an intuitive "layered" mental model. The core experience revolves around a bottom-sheet oriented layout that keeps primary controls within thumb-reach, allowing the background (typically a map or environmental context) to remain visible yet secondary to the user's immediate safety actions.

## Colors

The color palette is functional and semantic, designed to reduce cognitive load during high-stress moments.

- **Action Green (#34C759):** Used exclusively for "Go," "Safe," and primary affirmative actions. It signals security and progress.
- **Critical Red (#FF3B30):** Reserved for alerts, SOS triggers, and immediate dangers. Use sparingly to maintain its psychological impact.
- **System Grays:** Pure White (#FFFFFF) is the base for all cards and interactive surfaces to ensure maximum contrast. Soft Light Grey (#F2F2F7) is utilized for background containers and non-interactive structural elements to provide subtle separation without using heavy lines.
- **Typography:** Deep Charcoal (#1C1C1E) is used for primary text to ensure high legibility while appearing softer than pure black.

## Typography

This design system utilizes **Inter** as the primary typeface, chosen for its exceptional legibility on mobile screens and its resemblance to the system-standard San Francisco.

- **Hierarchy:** Bold, prominent headlines are used to communicate status quickly. Large display sizes should use negative letter-spacing to feel tight and professional.
- **Readability:** Body text is set at 17px to align with iOS standards, ensuring it is accessible for all age groups.
- **Labels:** Use the `label-caps` style for metadata or non-critical secondary information to differentiate from actionable body text.

## Layout & Spacing

The layout follows a **fluid, bottom-up model**. Content is housed within expansive bottom sheets that slide over the background map.

- **The Map View:** Acts as the base layer. Content should never fully obscure the map unless the user is deep within a settings sub-menu.
- **Safe Margins:** A standard 20px horizontal margin is applied to all card content and buttons.
- **Rhythm:** An 8px linear scale guides vertical rhythm. Most cards and interactive elements are separated by 12px to 16px to maintain a sense of airiness and reduce accidental taps.
- **Tap Targets:** No interactive element should be smaller than 44x44px.

## Elevation & Depth

Visual depth in this design system is used to signify "interactivity" and "stacking order."

- **Layer 0 (Base):** The background map or clean light-grey surface.
- **Layer 1 (Bottom Sheet):** Large surfaces with a 24-32px top-corner radius. They utilize a subtle, wide-spread shadow (0px 4px 20px rgba(0,0,0,0.08)) to appear physically lifted above the map.
- **Layer 2 (Floating Cards):** Cards within the bottom sheet or floating buttons (like the profile or menu icons) use a more pronounced shadow to indicate they are the primary interaction point.
- **Glassmorphism:** Use backdrop blurs (20px to 30px) on the bottom sheet handle area and navigation bars to provide a sense of place and depth while maintaining focus.

## Shapes

The shape language is defined by extreme friendliness and safety. 

- **Containers:** Large-scale components like bottom sheets and primary feature cards use a corner radius of **24px to 32px**. This makes the UI feel approachable and modern.
- **Buttons:** All primary and secondary buttons are **pill-shaped** (fully rounded ends). This clearly distinguishes buttons from informational cards.
- **Selection States:** Small chips and input fields use a standard 12px to 16px radius to maintain a consistent visual language with the larger containers.

## Components

- **Primary Button:** Pill-shaped, #34C759 background with white text. High-contrast and bold.
- **The "Safety Sheet":** The signature component. A large white sheet with 32px top radii, featuring a subtle grey "grab handle" at the top center.
- **Map Pins:** Circular, using the Action Green for safe zones and Critical Red for incidents. They should have a white border and a soft drop shadow.
- **Quick Action Cards:** Horizontal cards within the bottom sheet for common tasks (e.g., "Check In", "SOS"). These should feature a prominent icon on the left, a bold title, and a clear chevron on the right.
- **Input Fields:** Rounded-pill or 16px radius containers with #F2F2F7 backgrounds. The focus state uses a 2px stroke of the primary green.
- **Status Chips:** Small, semi-transparent overlays on the map or within cards to indicate live status (e.g., "Live Tracking Active").