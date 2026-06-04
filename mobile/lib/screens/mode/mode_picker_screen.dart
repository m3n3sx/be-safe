import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mode_provider.dart';
import '../../theme/design_tokens.dart';

/// F33: Mode picker — choose KIDS / SENIOR / NORMAL app layout.
///
/// Shown:
/// - Once after onboarding (before login) → calls `ModeProvider.setLocal()`
///   so the choice is persisted to SharedPreferences and synced to backend
///   right after the next successful login.
/// - Anytime from Settings → "Tryb aplikacji" → calls `ModeProvider.setMode()`
///   which optimistically updates the user record and syncs via PATCH /me.
///
/// Design source: Stitch screen `aca4f8f9b43746119aba9efc515f075d`
/// + `design/new/.../tryb_aplikacji_be_safe/code.html`.
class ModePickerScreen extends StatefulWidget {
  const ModePickerScreen({
    super.key,
    this.allowSkip = true,
    this.onDone,
  });

  /// When true, shows the "Pomiń wybór" link at the bottom.
  /// Hidden on the first run (we want a deliberate choice).
  final bool allowSkip;

  /// Called after a successful mode change. If null, the screen pops itself.
  final VoidCallback? onDone;

  @override
  State<ModePickerScreen> createState() => _ModePickerScreenState();
}

class _ModePickerScreenState extends State<ModePickerScreen> {
  AppMode? _submitting;

  Future<void> _select(AppMode mode) async {
    if (_submitting != null) return;
    HapticFeedback.selectionClick();
    setState(() => _submitting = mode);

    final modeProvider = context.read<ModeProvider>();
    final auth = context.read<AuthProvider>();

    bool ok = true;
    if (auth.isLoggedIn) {
      ok = await modeProvider.setMode(mode, auth);
    } else {
      // Pre-login: persist locally; will be synced on first PATCH /me
      // after successful login via _AuthGate._handleAuth.
      await modeProvider.setLocal(mode);
    }

    if (!mounted) return;
    setState(() => _submitting = null);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Nie udało się zapisać trybu. Spróbuj ponownie.',
          ),
          backgroundColor: SerenityColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final done = widget.onDone;
    if (done != null) {
      done();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SerenityColors.background,
      body: Stack(
        children: [
          // Decorative top-right glow orb (matches Stitch design).
          const Positioned(
            top: -100,
            right: -100,
            child: IgnorePointer(
              child: _GlowOrbDecoration(),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    SerenitySpacing.xl,
                    SerenitySpacing.xxl,
                    SerenitySpacing.xl,
                    SerenitySpacing.xxxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: SerenitySpacing.xl),
                      _BeSafeWordmark(),
                      const SizedBox(height: SerenitySpacing.xxl),
                      Text(
                        'Wybierz tryb',
                        textAlign: TextAlign.center,
                        style: SerenityText.headlineHeroMobile.copyWith(
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: SerenitySpacing.xs),
                      Text(
                        'Możesz to zmienić w dowolnym momencie',
                        textAlign: TextAlign.center,
                        style: SerenityText.labelButton.copyWith(
                          color: context.iosSecondaryLabel,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: SerenitySpacing.xxxl),
                      _ModeCard(
                        mode: AppMode.kids,
                        title: 'Dla dziecka',
                        description:
                            'Duże kafelki, krótkie napisy, max 4 akcje. '
                            'Wielki czerwony przycisk SOS. Bez ustawień i '
                            'ukrytych funkcji.',
                        badge: 'POLECANE DLA: 7–12 LAT',
                        icon: Icons.child_friendly,
                        iconBackground: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            SerenityColors.glowSafeMint,
                            SerenityColors.glowCalmAqua,
                          ],
                        ),
                        submitting: _submitting == AppMode.kids,
                        onTap: () => _select(AppMode.kids),
                      ),
                      const SizedBox(height: SerenitySpacing.lg),
                      _ModeCard(
                        mode: AppMode.senior,
                        title: 'Dla seniora',
                        description:
                            'Duża czcionka, wysokie kontrasty, sound + haptic '
                            'feedback. Codzienny check-in. Numery alarmowe '
                            'zawsze pod ręką.',
                        badge: 'POLECANE DLA: 60+',
                        icon: Icons.elderly,
                        iconBackground: const LinearGradient(
                          colors: [
                            SerenityColors.primaryContainer,
                            SerenityColors.primaryContainer,
                          ],
                        ),
                        submitting: _submitting == AppMode.senior,
                        onTap: () => _select(AppMode.senior),
                      ),
                      const SizedBox(height: SerenitySpacing.lg),
                      _ModeCard(
                        mode: AppMode.normal,
                        title: 'Standardowy',
                        description:
                            'Pełna funkcjonalność: mapa, alerty, rodzina, '
                            'statystyki, SOS, czat sąsiedzki. Wszystkie '
                            'ustawienia dostępne.',
                        badge: 'POLECANE DLA: 13–59 LAT',
                        icon: Icons.shield,
                        iconBackground: const LinearGradient(
                          colors: [
                            SerenityColors.glowAlertCoral,
                            SerenityColors.glowAlertCoral,
                          ],
                        ),
                        submitting: _submitting == AppMode.normal,
                        onTap: () => _select(AppMode.normal),
                      ),
                      const SizedBox(height: SerenitySpacing.xxl),
                      if (widget.allowSkip) ...[
                        TextButton(
                          onPressed: _submitting != null
                              ? null
                              : () => _select(AppMode.normal),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                SerenityColors.onSurfaceVariant,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          child: const Text(
                            'Pomiń wybór — zdecyduję później',
                          ),
                        ),
                        const SizedBox(height: SerenitySpacing.md),
                      ],
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SerenitySpacing.md,
                            vertical: SerenitySpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: context.iosBackground,
                            border: Border.all(
                              color: context.iosSeparator,
                            ),
                            borderRadius: SerenityShapes.pill(),
                          ),
                          child: Text(
                            'Wybór możesz zmienić w Ustawienia → Tryb aplikacji',
                            textAlign: TextAlign.center,
                            style: SerenityText.labelCaps.copyWith(
                              color: context.iosSeparator,
                              fontSize: 11,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrbDecoration extends StatelessWidget {
  const _GlowOrbDecoration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Color(0x269DF4CB), // mint 15%
            Color(0x00FCF8F9), // surface 0%
          ],
          stops: [0, 0.7],
        ),
      ),
    );
  }
}

class _BeSafeWordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: SerenityColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.shield,
            color: SerenityColors.glowSafeMint,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'be:Safe',
          style: SerenityText.headlineHeroMobile.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.title,
    required this.description,
    required this.badge,
    required this.icon,
    required this.iconBackground,
    required this.submitting,
    required this.onTap,
  });

  final AppMode mode;
  final String title;
  final String description;
  final String badge;
  final IconData icon;
  final Gradient iconBackground;
  final bool submitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.iosCardSurface,
      borderRadius: SerenityShapes.card(),
      child: InkWell(
        onTap: submitting ? null : onTap,
        borderRadius: SerenityShapes.card(),
        child: Container(
          padding: const EdgeInsets.all(SerenitySpacing.xl),
          decoration: BoxDecoration(
            borderRadius: SerenityShapes.card(),
            boxShadow: [
              BoxShadow(
                color: SerenityColors.primaryContainer.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: iconBackground,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: SerenitySpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SerenityText.headlineHeroMobile.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: SerenitySpacing.xs),
                    Text(
                      description,
                      style: SerenityText.labelButton.copyWith(
                        color: context.iosSecondaryLabel,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: SerenitySpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SerenitySpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: SerenityColors.surfaceContainerLow,
                        borderRadius: SerenityShapes.pill(),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: context.iosSecondaryLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SerenitySpacing.xs),
              SizedBox(
                width: 24,
                height: 64,
                child: Center(
                  child: submitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.iosLabel,
                          ),
                        )
                      : Icon(
                          Icons.chevron_right,
                          color: context.iosSeparator,
                          size: 24,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
