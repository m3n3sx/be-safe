---
name: be:Safe
colors:
  surface: '#f9f9f9'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f3'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#5e3f3e'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f1f1f1'
  outline: '#936e6d'
  outline-variant: '#e8bcbb'
  surface-tint: '#bf002e'
  primary: '#ba002c'
  on-primary: '#ffffff'
  primary-container: '#e9003a'
  on-primary-container: '#fffbff'
  inverse-primary: '#ffb3b3'
  secondary: '#1b6d24'
  on-secondary: '#ffffff'
  secondary-container: '#a0f399'
  on-secondary-container: '#217128'
  tertiary: '#00685d'
  on-tertiary: '#ffffff'
  tertiary-container: '#008376'
  on-tertiary-container: '#f4fffb'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad9'
  primary-fixed-dim: '#ffb3b3'
  on-primary-fixed: '#400009'
  on-primary-fixed-variant: '#920021'
  secondary-fixed: '#a3f69c'
  secondary-fixed-dim: '#88d982'
  on-secondary-fixed: '#002204'
  on-secondary-fixed-variant: '#005312'
  tertiary-fixed: '#88f5e3'
  tertiary-fixed-dim: '#6ad9c8'
  on-tertiary-fixed: '#00201c'
  on-tertiary-fixed-variant: '#005047'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-lg:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.5px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  margin-mobile: 16px
  margin-desktop: 24px
  gutter: 16px
  stack-sm: 4px
  stack-md: 12px
  stack-lg: 24px
---

## Brand & Style

The design system is engineered to provide a sense of absolute security and community-driven protection for the Polish market. It balances the urgency of safety alerts with a professional, non-alarmist aesthetic to ensure users feel empowered rather than anxious.

The visual narrative follows a **Modern Material 3** approach, utilizing tonal surfaces and meaningful motion. The brand is anchored by a subtle safety shield icon—a geometric, softened shield with a central "check" or "heart" motif—symbolizing both protection and community care. All interface copy is presented in Polish, utilizing clear, direct, and supportive language.

## Colors

The palette is strategically split between urgency and tranquility. 
- **Alert Red (#FF1744):** Reserved strictly for critical actions, SOS buttons, and active danger alerts (*Zagrożenie*).
- **Forest Green (#2E7D32):** Used for family tracking (*Śledzenie rodziny*), safe zones, and "I am safe" confirmations (*Jestem bezpieczny*).
- **Neutrals:** A range of calm greys derived from Material 3 logic to provide a clean, high-legibility canvas.

**Dark Mode:** When active, surfaces shift to deep charcoal (#1B1B1F), maintaining the same Primary Red and Forest Green but adjusting their luminance for high-contrast accessibility in low-light environments.

## Typography

This design system utilizes **Inter** for its exceptional legibility and neutral, functional character. The type scale is optimized for rapid information processing during stressful situations.

- **Headlines:** Bold and clear for immediate identification of safety status.
- **Body Text:** Ample line-height (1.5x) to ensure readability for all age groups in Poland.
- **Labels:** Uppercase letter-spacing is applied to small labels for better clarity on status indicators.
- **Language Support:** Full support for Polish diacritics (ą, ć, ę, ł, ń, ó, ś, ź, ż) is mandatory.

## Layout & Spacing

The layout follows a **fluid grid** model with a base-8 rhythmic system. 
- **Mobile:** 4-column grid with 16px side margins.
- **Tablet/Desktop:** 12-column grid with 24px margins.

Spacing is used to group related safety information. For instance, a "Safety Contact" card uses `stack-sm` for the name and status, but `stack-md` between the contact group and the action buttons. The layout prioritizes "thumb-zone" accessibility for emergency features.

## Elevation & Depth

Visual hierarchy is achieved through **Tonal Layers** rather than heavy shadows, consistent with modern Material 3 principles.

1.  **Level 0 (Surface):** The lowest layer, using the neutral background color.
2.  **Level 1 (Cards):** Low-contrast surfaces used for secondary information, separated by a subtle 1px border (#E1E2EC) or a faint tint.
3.  **Level 2 (Active States):** Subtle ambient shadows with a 10% opacity black tint and 8px blur, used only for interactive elements like floating action buttons (FABs).
4.  **Level 3 (Modals/Alerts):** Higher elevation with a 16px blur to pull focus during critical alerts or confirmation dialogs (*Potwierdzenie*).

## Shapes

The shape language is friendly and approachable to reduce user stress.
- **Cards:** Defined by a consistent **16dp (rounded-lg)** radius. This applies to all content containers, map overlays, and community posts.
- **Buttons:** Primary actions utilize a **28dp (pill-shaped)** radius, making them highly tactile and distinct from content containers.
- **Inputs:** Slightly sharper at 12px to maintain a professional, structured feel for data entry.

## Components

### Buttons (Przyciski)
- **Primary:** Pill-shaped, Primary Red background with White text. Used for "WEZWIJ POMOC" (Call for Help).
- **Secondary:** Pill-shaped, Forest Green. Used for "UDOSTĘPNIJ LOKALIZACJĘ" (Share Location).
- **Ghost:** Minimalist text buttons for low-priority actions like "Anuluj" (Cancel).

### Cards (Karty)
- **Safety Card:** White background, 16dp corners, subtle grey border. Includes a header for "Status: Bezpieczny" (Status: Safe).
- **Alert Card:** Light red container background with high-contrast red icons for "Alert lokalny" (Local Alert).

### Input Fields (Pola wprowadzania)
- Outlined style with a 12dp radius. Labels must remain visible on focus. Error states use the Primary Alert Red for the border and helper text.

### Safety Shield Icon
- A 24x24dp icon used in the top-left navigation or as a watermark in safe-zone maps. It should never be used as a primary action button to avoid confusion with the SOS trigger.

### Status Chips (Tagi stanu)
- Rounded-sm (4px) chips used for categorizing alerts: *Pożar* (Fire), *Wypadek* (Accident), *Pogoda* (Weather).