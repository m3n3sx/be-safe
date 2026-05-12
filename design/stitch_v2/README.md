# be:Safe v2 — Serenity Guard Design System

> **Status:** design kompletny (28 ekranów + system design).
> **Źródło:** Google Stitch (projekt Calm Safety App, serenity_guard).
> **Data:** 2026-05-12

---

## 📐 System Design

Pełny design system opisany w [`DESIGN.md`](./DESIGN.md).

**Najważniejsze tokeny** (do przepisania do `mobile/lib/theme/design_tokens.dart`):

### Paleta "Serenity"

```dart
// Core
const primary          = Color(0xFF03080E);  // deep almost-black
const primaryContainer = Color(0xFF1A2027);  // deep navy (dark pills, nav)
const onPrimary        = Color(0xFFFFFFFF);

// Secondary (safe-mint)
const secondary          = Color(0xFF006C4C);
const secondaryContainer = Color(0xFF9DF4CB);
const onSecondaryContainer = Color(0xFF0F7252);

// Tertiary (alert-coral) — warning bez agresji
const tertiary          = Color(0xFF190001);
const tertiaryContainer = Color(0xFF480008);
const onTertiaryContainer = Color(0xFFDB5F60);

// Error
const error          = Color(0xFFBA1A1A);
const errorContainer = Color(0xFFFFDAD6);

// Surface (near-white, calm)
const surface            = Color(0xFFFCF8F9);
const surfaceContainer   = Color(0xFFF0EDED);
const surfaceContainerLowest = Color(0xFFFFFFFF);
const onSurface          = Color(0xFF1C1B1C);
const onSurfaceVariant   = Color(0xFF44474B);

// Outlines
const outline         = Color(0xFF75777B);
const outlineVariant  = Color(0xFFC5C6CB);
```

### Typography (Inter, weight contrasts > size contrasts)

| Token | Size | Weight | Line | Letter | Użycie |
|---|---|---|---|---|---|
| display-lg | 80px | **100** | 96 | -0.04em | Big stat numbers (9/10) |
| display-md | 64px | **200** | 72 | -0.02em | Hero messages |
| headline-hero | 32px | **300** | 40 | -0.01em | Screen titles desktop |
| headline-hero-mobile | 28px | **300** | 36 | — | Screen titles mobile |
| body-main | 16px | 400 | 24 | — | Default text |
| label-button | 14px | 500 | 20 | — | Buttons |
| label-caps | 12px | 500 | 16 | +0.05em | Tiny labels |

### Shape

- **Cards:** 24px corner radius (1.5rem)
- **Pills (buttons, nav):** fully rounded (9999px)
- **Inputs:** 24px radius, no hard bounding box

### Elevation

1. **Base:** #FCF8F9 surface
2. **Cards:** white, 24px radius, shadow `0 40px 40px rgba(26,32,39,0.04)`
3. **Floating glass widgets:** backdrop-blur 20px, 80% transparency
4. **Nav pill:** primaryContainer #1A2027 with blur + stronger shadow

### Signature: Glow Orb

Central home screen element — 280×280dp radial gradient:
- Core: secondaryContainer #9DF4CB (safe-mint) 100% opacity
- Fade: to 0% at 70% radius
- Animation: subtle pulse 90%↔110% scale (4s duration)

```css
background: radial-gradient(circle, rgba(157, 244, 203, 1) 0%, rgba(157, 244, 203, 0) 70%);
```

---

## 📱 Mapa ekranów → aktualne pliki Flutter

| # | Stitch screen | Aktualny plik (lib/screens/) | Status |
|---|---|---|---|
| 1 | onboarding_start | `onboarding/onboarding_screen.dart` page 1 | 🔄 |
| 2 | onboarding_powitanie | j.w. page 2 | 🔄 |
| 3 | onboarding_alerty | j.w. page 3 | 🔄 |
| 4 | onboarding_sos | j.w. page 4 | 🔄 |
| 5 | onboarding_rodzina | j.w. page 5 | 🔄 |
| 6 | logowanie | `auth/login_screen.dart` | 🔄 |
| 7 | sukces_weryfikacji | `auth/verify_email_screen.dart` success | 🔄 |
| 8 | blad_weryfikacji | j.w. error | 🔄 |
| 9 | reset_hasla | webapp `/reset-password` (nie mobile) | ⏭ |
| 10 | **ekran_glowny_status_okolicy** ⭐ | `home_screen.dart` | 🔴 PRIORYTET |
| 11 | **mapa_status_okolicy** ⭐ | `map/map_screen.dart` | 🔴 PRIORYTET |
| 12 | mapa_widok_szczegolowy | j.w. detail sheet | 🔄 |
| 13 | szczegoly_alertu | `alerts/alert_detail_screen.dart` | 🔄 |
| 14 | zglos_zagrozenie | `alerts/create_alert_screen.dart` | 🔄 |
| 15 | alerty_bezpieczenstwa | `alerts/my_alerts_screen.dart` | 🔄 |
| 16 | sos | `sos/sos_screen.dart` | 🔄 |
| 17 | numery_alarmowe | `emergency/emergency_numbers_screen.dart` | 🔄 |
| 18 | rodzina | `family/family_screen.dart` | 🔄 |
| 19 | lokalizacja_rodziny | `family/family_map_screen.dart` | 🔄 |
| 20 | trasa_janka | `family/location_history_screen.dart` | 🔄 |
| 21 | profil_uzytkownika | `profile/profile_screen.dart` | 🔄 |
| 22 | profil_uzytkownika_anna_kowalska | `profile/user_profile_screen.dart` | 🔄 |
| 23 | odznaki | `profile/badges_screen.dart` | 🔄 |
| 24 | statystyki | `alerts/stats_screen.dart` | 🔄 |
| 25 | aktualnosci | `community/news_screen.dart` | 🔄 |
| 26 | artykul | `community/article_detail_screen.dart` (nowy?) | 🆕 |
| 27 | ustawienia | `settings/settings_screen.dart` | 🔄 |
| 28 | regulamin | `legal/terms_screen.dart` | 🔄 |

---

## 🚀 Plan implementacji (screen-per-PR)

### Etap 1 — fundament (1 PR)
- [ ] `mobile/lib/theme/design_tokens.dart` — nowa paleta "Serenity"
- [ ] `mobile/lib/theme/app_theme.dart` — Material 3 theme z nowymi kolorami + Inter typography
- [ ] `mobile/lib/widgets/glow_orb.dart` — reusable widget z radial gradient + pulse animation
- [ ] `mobile/lib/widgets/pill_nav_bar.dart` — nowa bottom nav (primaryContainer, pill, glassmorphic)
- [ ] `mobile/lib/widgets/card_container.dart` — spójny Card z 24px radius + soft shadow
- [ ] `mobile/pubspec.yaml` — dodać font Inter (weights 100, 200, 300, 400, 500)

### Etap 2 — core screens (3-5 PR-ów, kolejność wg impact)

1. **HomeScreen** z Glow Orb + "Poziom bezpieczeństwa 9/10" + activity cards (3×)
2. **MapScreen** z floating nav + status chip overlay
3. **SosScreen** z centralnym orb w alert-coral
4. **FamilyScreen** z member cards
5. **ProfileScreen** z stat counters (display-md)

### Etap 3 — pozostałe (batch, 1 PR)

- Wszystkie pozostałe ekrany — update tylko theme application (jeśli używają design_tokens), ale layout zostaje
- Drobne adjustments: zmiana padding, radius, shadows na nowe tokeny

### Etap 4 — polish
- Animacje pulse dla glow orb na home + SOS
- Glassmorphic overlay dla map detail sheet
- Haptic feedback na wszystkie primary actions
- Dark mode (inverseSurface + inversePrimary już w palecie)

### Etap 5 — deploy
- APK v24 build + scp na EC2
- Webapp — docelowo też refactor, ale priorytet = mobile

---

## 🖼️ Index ekranów (screenshots)

Wszystkie ekrany w `screens/<nazwa>/screen.png` + `screens/<nazwa>/code.html`.

HTML używa Tailwind CDN — można otworzyć lokalnie `open screens/<nazwa>/code.html` w przeglądarce jeśli jest internet.
