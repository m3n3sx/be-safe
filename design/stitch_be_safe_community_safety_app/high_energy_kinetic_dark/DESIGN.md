---
name: High-Energy Kinetic Dark
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#b9cacb'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#849495'
  outline-variant: '#3a494b'
  surface-tint: '#00dce6'
  primary: '#e3fdff'
  on-primary: '#00373a'
  primary-container: '#00f3ff'
  on-primary-container: '#006b71'
  inverse-primary: '#00696f'
  secondary: '#ffb778'
  on-secondary: '#4c2700'
  secondary-container: '#fd9000'
  on-secondary-container: '#613400'
  tertiary: '#fff6f6'
  on-tertiary: '#680012'
  tertiary-container: '#ffd1cf'
  on-tertiary-container: '#c3002b'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#6ff6ff'
  primary-fixed-dim: '#00dce6'
  on-primary-fixed: '#002022'
  on-primary-fixed-variant: '#004f53'
  secondary-fixed: '#ffdcc1'
  secondary-fixed-dim: '#ffb778'
  on-secondary-fixed: '#2e1500'
  on-secondary-fixed-variant: '#6c3a00'
  tertiary-fixed: '#ffdad8'
  tertiary-fixed-dim: '#ffb3b2'
  on-tertiary-fixed: '#410008'
  on-tertiary-fixed-variant: '#92001e'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  display-lg:
    fontFamily: Anton
    fontSize: 64px
    fontWeight: '400'
    lineHeight: '1.1'
    letterSpacing: 0.02em
  headline-lg:
    fontFamily: Anton
    fontSize: 32px
    fontWeight: '400'
    lineHeight: '1.2'
    letterSpacing: 0.04em
  headline-md:
    fontFamily: Anton
    fontSize: 24px
    fontWeight: '400'
    lineHeight: '1.2'
    letterSpacing: 0.04em
  body-lg:
    fontFamily: Archivo Narrow
    fontSize: 18px
    fontWeight: '500'
    lineHeight: '1.5'
    letterSpacing: 0.01em
  body-md:
    fontFamily: Archivo Narrow
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
    letterSpacing: 0.01em
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: '1.2'
    letterSpacing: 0.05em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1.2'
    letterSpacing: 0.05em
  headline-lg-mobile:
    fontFamily: Anton
    fontSize: 28px
    fontWeight: '400'
    lineHeight: '1.2'
spacing:
  unit: 4px
  gutter: 12px
  margin-desktop: 24px
  margin-mobile: 16px
  container-max: 100%
---

## Brand & Style

This design system is engineered for high-stakes, real-time environments where speed of data ingestion is critical. The brand personality is aggressive, technical, and alert, evoking the atmosphere of a command center or a high-performance racing telemetry suite.

The design style sits at the intersection of **High-Contrast Bold** and **Cyberpunk Industrial**. It prioritizes immediate visual hierarchy through luminous accents against a void-like background. The aesthetic is intentionally "hard-edged"—rejecting soft curves in favor of sharp, precision-machined geometry. Every element should feel energized, as if powered by the data it displays.

## Colors

The palette is anchored by a deep charcoal neutral base to maximize the "pop" of neon functional colors. 

- **Primary (Electric Cyan):** Used for information, primary actions, and active states. It represents the "flow" of standard operations.
- **Secondary (Radioactive Orange):** Reserved strictly for warnings, pending states, or mid-level priority data.
- **Tertiary (Pulse Red):** Used exclusively for critical failures, emergency alerts, and destructive actions.
- **Neutrals:** The background is near-black (#0A0A0A) to provide infinite depth, while surfaces sit at #121212 to create a subtle lift. Borders are slightly elevated to define structure without losing the dark aesthetic.

## Typography

This design system utilizes a high-impact typographic stack to manage high information density.

- **Headings:** Anton provides a bold, condensed, and urgent feel. All headings should be set in Uppercase to enhance the "command center" aesthetic.
- **Body:** Archivo Narrow is used for data readouts and descriptions. Its condensed nature allows for more characters per line, supporting the dense layout requirement.
- **Monospace Labels:** JetBrains Mono is used for technical labels, timestamps, and small data points to ensure every character is distinct and aligned.

## Layout & Spacing

The layout philosophy is a **Fluid Grid** with high density. Spacing is tight (based on a 4px scale) to pack as much information onto a single screen as possible, minimizing the need for scrolling in monitoring scenarios.

- **Grid:** 12-column system for desktop, 4-column for mobile.
- **Gaps:** 12px gutters between cards to maintain a sense of compartmentalization without wasting space.
- **Density:** Padding within cards and list items should be kept to a minimum (8px to 12px) to prioritize data visibility.

## Elevation & Depth

Depth is conveyed through **Luminous Glows** and **Tonal Borders** rather than traditional shadows.

- **Surfaces:** Use a solid #121212 background. Instead of soft shadows, use a 1px solid border (#2A2A2A).
- **Glow Effects:** Critical cards or active states use an outer `drop-shadow` or `box-shadow` that matches the accent color (Cyan, Orange, or Red). This shadow should have a small spread (2px) and a medium blur (12px) to create a "neon tube" effect.
- **Active State:** When an element is focused or active, the border color should switch from the neutral grey to the Primary Cyan, accompanied by the glow effect.

## Shapes

The shape language is strictly **Sharp (0px)**. 

Every UI element—from primary buttons and input fields to large dashboard cards—must have 90-degree corners. This reinforces the industrial, precise, and aggressive nature of the design system. Do not use border-radius for any component, including icons and avatars.

## Components

- **Buttons:** High-contrast blocks. Primary buttons use a solid Electric Cyan background with black text. Secondary buttons are ghost-style with a 2px Cyan border and Cyan text.
- **Cards:** Sharp-edged containers with #121212 background. High-priority cards feature a top-border "accent bar" in the relevant color (Cyan/Orange/Red) with a matching glow.
- **Data Visuals:** Charts and graphs should use the Primary, Secondary, and Tertiary colors. Grid lines in charts should be kept at very low opacity (#FFFFFF at 5%).
- **Inputs:** Darker background than the card (#080808), sharp corners, with a Cyan bottom-border that illuminates when focused.
- **Alerts/Toasts:** Full-bleed background color (Red or Orange) with black Anton typography for maximum urgency.
- **Status Indicators:** Small square pips (no circles). A pulsing animation effect should be applied to Pulse-Red status pips to indicate live critical issues.