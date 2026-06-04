import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../community/notifications_screen.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../safety/safety_guide_screen.dart';
import '../family/family_screen.dart';
import '../settings/settings_screen.dart';
import '../sos/sos_senior_screen.dart';

/// Tryb SENIOR (F33) – uproszczony Home dla użytkowników 60+.
///
/// Kluczowe założenia UX (z designu Stitch Senior_2):
/// - duże touch-targety (≥64dp, krytyczne 80–88dp),
/// - wysokie kontrasty, brak gestów swipe,
/// - F21 (daily check-in) jako #1 akcja u góry,
/// - 4 pionowe akcje skrótów (pomoc / rodzina / lekarz / poradnik),
/// - dolny pasek 4 zakładki z dużymi etykietami.
class HomeSeniorScreen extends StatefulWidget {
  const HomeSeniorScreen({super.key});

  @override
  State<HomeSeniorScreen> createState() => _HomeSeniorScreenState();
}

class _HomeSeniorScreenState extends State<HomeSeniorScreen> {
  bool _checkingIn = false;
  bool _checkedInToday = false;
  DateTime? _lastCheckinAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTodayStatus());
  }

  Future<void> _loadTodayStatus() async {
    try {
      final res = await context.read<ApiService>().get('/users/me/checkin/today');
      if (!mounted) return;
      if (res['checked_in_today'] == true) {
        setState(() {
          _checkedInToday = true;
          final raw = res['last_at'] as String?;
          _lastCheckinAt = raw != null ? DateTime.tryParse(raw) : null;
        });
      }
    } catch (_) {
      // ignore - retry przy następnym checkinie
    }
  }

  String _firstName(String? username) {
    if (username == null || username.trim().isEmpty) return 'Witaj';
    return username.trim().split(RegExp(r'\s+')).first;
  }

  String get _checkinTimeLabel {
    if (_lastCheckinAt == null) return 'ZAMELDOWANO ✓';
    final hh = _lastCheckinAt!.hour.toString().padLeft(2, '0');
    final mm = _lastCheckinAt!.minute.toString().padLeft(2, '0');
    return 'ZAMELDOWANO o $hh:$mm';
  }

  String get _nowHHMM {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _checkIn() async {
    if (_checkingIn) return;
    setState(() => _checkingIn = true);
    HapticFeedback.mediumImpact();
    try {
      await context.read<ApiService>().post(
        '/users/me/checkin',
        {'status': 'safe'},
      );
      if (!mounted) return;
      setState(() {
        _checkedInToday = true;
        _lastCheckinAt = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: SerenityColors.secondaryContainer,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
          ),
          content: Text(
            '✓ Powiadomiono rodzinę – wszystko w porządku',
            style: SerenityText.bodyMain.copyWith(
              color: SerenityColors.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: SerenityColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
          ),
          content: const Text(
            'Nie udało się wysłać. Spróbuj jeszcze raz.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  void _openSos() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SosSeniorScreen()),
    );
  }

  void _openFamily() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FamilyScreen()),
    );
  }

  Future<void> _callDoctor() async {
    HapticFeedback.mediumImpact();
    // Telefon do lekarza – w produkcji pobierany z profilu/kontaktów seniora.
    // Tymczasowo otwiera dialer 112 jako bezpieczny fallback gdy brak numeru.
    final uri = Uri.parse('tel:112');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie można otworzyć dialera')),
      );
    }
  }

  void _openGuide() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SafetyGuideScreen()),
    );
  }

  void _openSettings() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openNotifications() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = _firstName(user?.username);

    return Scaffold(
      backgroundColor: SerenityColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(firstName),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 24),
                    _SeniorActionButton(
                      label: 'WEZWIJ POMOC',
                      subtitle: 'Naciśnij gdy potrzebujesz',
                      icon: Icons.local_hospital,
                      iconBg: Colors.white,
                      iconColor: SerenityColors.glowAlertCoral,
                      backgroundColor: SerenityColors.glowAlertCoral,
                      foregroundColor: Colors.white,
                      onTap: _openSos,
                      elevated: true,
                    ),
                    const SizedBox(height: 16),
                    _SeniorActionButton(
                      label: 'MOJA RODZINA',
                      subtitle: 'Zobacz bliskich',
                      icon: Icons.family_restroom,
                      iconBg: SerenityColors.secondaryContainer,
                      iconColor: SerenityColors.onSecondaryContainer,
                      backgroundColor: SerenityColors.surfaceContainerLowest,
                      foregroundColor: SerenityColors.primaryContainer,
                      onTap: _openFamily,
                      bordered: true,
                    ),
                    const SizedBox(height: 16),
                    _SeniorActionButton(
                      label: 'TELEFON DO LEKARZA',
                      subtitle: 'Szybki kontakt',
                      icon: Icons.phone_in_talk,
                      iconBg: SerenityColors.glowCalmAqua,
                      iconColor: SerenityColors.primaryContainer,
                      backgroundColor: SerenityColors.surfaceContainerLowest,
                      foregroundColor: SerenityColors.primaryContainer,
                      onTap: _callDoctor,
                      bordered: true,
                    ),
                    const SizedBox(height: 16),
                    _SeniorActionButton(
                      label: 'PORADNIK BEZPIECZEŃSTWA',
                      subtitle: 'Ważne numery i wskazówki',
                      icon: Icons.menu_book,
                      iconBg: SerenityColors.glowAlertCoral.withValues(
                        alpha: 0.20,
                      ),
                      iconColor: SerenityColors.glowAlertCoral,
                      backgroundColor: SerenityColors.surfaceContainerLowest,
                      foregroundColor: SerenityColors.primaryContainer,
                      onTap: _openGuide,
                      bordered: true,
                    ),
                  ],
                ),
              ),
            ),
            _SeniorBottomNav(
              onFamily: _openFamily,
              onHelp: _openSos,
              onSettings: _openSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(String firstName) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'DZIEŃ DOBRY',
                  style: SerenityText.labelCaps.copyWith(
                    color: SerenityColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    color: SerenityColors.primary,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Powiadomienia',
            child: Material(
              color: SerenityColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _openNotifications,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: SerenityColors.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    size: 32,
                    color: SerenityColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: SerenityColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chip status
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: SerenityColors.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: SerenityColors.onSecondaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'WSZYSTKO W PORZĄDKU',
                    style: SerenityText.labelCaps.copyWith(
                      color: SerenityColors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Twoja okolica jest bezpieczna',
            style: TextStyle(
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: SerenityColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ostatnia aktualizacja: $_nowHHMM',
            style: TextStyle(
              fontSize: 16,
              color: SerenityColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          // Wielki przycisk Zamelduj się (F21 daily check-in)
          SizedBox(
            height: 80,
            child: Material(
              color: _checkedInToday
                  ? SerenityColors.secondary
                  : SerenityColors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              elevation: 0,
              child: InkWell(
                onTap: _checkingIn ? null : _checkIn,
                borderRadius: BorderRadius.circular(20),
                child: Center(
                  child: _checkingIn
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _checkedInToday
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _checkedInToday ? _checkinTimeLabel : 'ZAMELDUJ SIĘ',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
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

class _SeniorActionButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;
  final bool elevated;
  final bool bordered;

  const _SeniorActionButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.elevated = false,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: bordered
                ? Border.all(
                    color: SerenityColors.surfaceContainerHigh,
                    width: 2,
                  )
                : null,
            boxShadow: elevated
                ? [
                    BoxShadow(
                      color: SerenityColors.glowAlertCoral.withValues(
                        alpha: 0.25,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: foregroundColor,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: elevated
                                ? Colors.white.withValues(alpha: 0.92)
                                : SerenityColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeniorBottomNav extends StatelessWidget {
  final VoidCallback onFamily;
  final VoidCallback onHelp;
  final VoidCallback onSettings;

  const _SeniorBottomNav({
    required this.onFamily,
    required this.onHelp,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SerenityColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: SerenityColors.surfaceContainerHigh, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            children: [
              Expanded(
                child: _SeniorNavItem(
                  icon: Icons.play_circle,
                  label: 'Start',
                  active: true,
                  onTap: () {},
                ),
              ),
              Expanded(
                child: _SeniorNavItem(
                  icon: Icons.group,
                  label: 'Rodzina',
                  onTap: onFamily,
                ),
              ),
              Expanded(
                child: _SeniorNavItem(
                  icon: Icons.emergency,
                  label: 'Pomoc',
                  onTap: onHelp,
                ),
              ),
              Expanded(
                child: _SeniorNavItem(
                  icon: Icons.settings,
                  label: 'Ustawienia',
                  onTap: onSettings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeniorNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SeniorNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? SerenityColors.primary
        : SerenityColors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          if (active)
            Positioned(
              bottom: 8,
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: SerenityColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
