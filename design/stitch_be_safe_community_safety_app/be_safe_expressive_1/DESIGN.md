---
name: be:Safe Expressive
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
  secondary: '#885200'
  on-secondary: '#ffffff'
  secondary-container: '#fd9d06'
  on-secondary-container: '#653c00'
  tertiary: '#4f4ccd'
  on-tertiary: '#ffffff'
  tertiary-container: '#a6a5ff'
  on-tertiary-container: '#302aaf'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#72fe88'
  primary-fixed-dim: '#53e16f'
  on-primary-fixed: '#002107'
  on-primary-fixed-variant: '#00531c'
  secondary-fixed: '#ffddbb'
  secondary-fixed-dim: '#ffb868'
  on-secondary-fixed: '#2b1700'
  on-secondary-fixed-variant: '#673d00'
  tertiary-fixed: '#e2dfff'
  tertiary-fixed-dim: '#c2c1ff'
  on-tertiary-fixed: '#0c006a'
  on-tertiary-fixed-variant: '#3631b4'
  background: '#fcf8fb'
  on-background: '#1b1b1d'
  surface-variant: '#e4e2e4'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 57px
    fontWeight: '800'
    lineHeight: 64px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  title-lg:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.1px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  base: 8px
  margin-mobile: 20px
  margin-desktop: 64px
  gutter: 16px
  container-padding: 24px
  stack-gap: 12px
---

## Brand & Style

The design system is engineered to evoke a sense of immediate protection paired with high-energy reliability. The brand personality is "The Proactive Guardian"—someone who is vigilant and technical, yet approachable and warm. 

The visual style is **Modern Tactile**, utilizing Material Design 3's expressive foundations. It blends the clarity of high-contrast functionalism with the softness of organic, hyper-rounded shapes. This creates a "soft-shell" aesthetic: rigid and dependable in logic, but friendly and human in presentation. The interface prioritizes oversized touch targets and bold information hierarchy to ensure usability during high-stress safety scenarios.

## Colors

The color palette is anchored by **Vibrant Safety Green**, symbolizing "Go/Safe" and vitality. The secondary palette introduces warm, protective tones like amber and deep orange to signal caution or active monitoring without inducing panic.

In **Light Mode**, we use crisp white surfaces with subtle cool-grey shadows to maintain a clean, clinical air of competence.
In **Dark Mode**, we utilize "Deep Surfaces"—pure black (#000000) or near-black backgrounds—to make the vibrant primary green pop with high luminosity, ensuring critical safety information is legible in low-light environments. 

Accessibility is paramount; all text-on-background combinations meet a minimum WCAG AA contrast ratio, with critical alerts hitting AAA.

## Typography

This design system utilizes **Inter** exclusively to maintain a systematic, highly legible feel, but leans into its heavier weights (Bold and ExtraBold) to provide the "Expressive" character. 

The type scale is intentionally oversized. Display and Headline styles use tight letter-spacing and heavy weights to create "blocks" of information that are instantly recognizable. For body text, we maintain a generous 18px base for the `Large` role to ensure readability while in motion. In dark mode, font weights for body text should be slightly reduced (e.g., from 400 to 300) if necessary to prevent "glow" blurring on high-contrast screens.

## Layout & Spacing

This design system employs a **Fluid Grid** with an 8px base unit. The layout logic is centered around "Safety Containers"—grouped information modules that expand to fill the horizontal width on mobile, while centering in a max-width 1200px container on desktop.

- **Mobile:** 4-column grid, 20px side margins.
- **Tablet:** 8-column grid, 32px side margins.
- **Desktop:** 12-column grid, adaptive margins.

Spacing between functional elements (buttons in a group) should be tight (8px-12px), while spacing between conceptual sections should be expansive (32px-48px) to reduce cognitive load.

## Elevation & Depth

Depth is conveyed through **Tonal Layering** and **Ambient Glows** rather than traditional drop shadows. 

1.  **Surfaces:** In Light mode, we use `Surface-Container` levels to differentiate between the background and floating cards. In Dark mode, higher elevation is indicated by slightly lighter charcoal tones against a pure black base.
2.  **Shadows:** When used for primary actions, shadows should be "Ambient Green"—a soft, diffused glow using the primary color at 15% opacity to make the button appear as if it is emitting safety light.
3.  **Active State:** Interacting with a card or button should result in a "Press-In" effect, where the element physically scales down (98%) and the shadow disappears, simulating a tactile physical switch.

## Shapes

The shape language is defined by **Extreme Roundness**. We use `Round_Full` (pill-shaped) for all interactive components like buttons and chips. 

Containers and Cards use a variable radius of 24px to 32px. This high degree of rounding removes "sharpness" from the UI, reinforcing the brand's friendly and safe atmosphere. Icons should follow this logic, utilizing a rounded "capsule" style and thick strokes (2px minimum) to match the bold typography.

## Components

- **Primary Action Buttons:** Pill-shaped, using the primary safety green with White/Black text. Use a 64px height for main "Emergency" or "Safe" toggles to maximize hit area.
- **Status Cards:** High-roundness containers (28px). Use "Secondary Container" colors for background status (e.g., a soft amber background for a 'Warning' state).
- **Input Fields:** Fully rounded (32px radius) with a thick 2px border that turns vibrant green on focus. Label text is placed inside the border's top-left curve.
- **Chips:** Used for filtering safety categories. These should be pill-shaped with a 1px outline in the neutral-variant color, filled with Primary when selected.
- **Safe-Status Indicator:** A large, pulsing circular component in the center of the dashboard that uses the primary green glow.
- **Lists:** Items separated by generous vertical padding (16px) with rounded corners on individual list-item backgrounds to keep them distinct.