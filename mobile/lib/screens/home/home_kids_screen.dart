/// be:Safe v2 — Home screen for KIDS mode (F33)
///
/// Simplified safety dashboard for ages 7–12.
/// - Hero status: greeting + JESTEŚ BEZPIECZNA chip + mint orb
/// - 2×2 grid: POMOC (triple-tap → SOS), MAPA, RODZINA, JESTEM OK
/// - Bottom safe-route hint (when active route exists)
/// - 3-tab bottom nav (Start / Mapa / Rodzina) — no SOS/Profile tabs
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../community/notifications_screen.dart';
import '../../services/api_service.dart';
import '../sos/sos_kids_screen.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/glow_orb.dart';
import '../family/family_screen.dart';
import '../map/map_screen.dart';

class HomeKidsScreen extends StatefulWidget {
  const HomeKidsScreen({super.key});

  @override
  State<HomeKidsScreen> createState() => _HomeKidsScreenState();
}

class _HomeKidsScreenState extends State<HomeKidsScreen> {
  // Triple-tap detection for POMOC
  int _pomocTaps = 0;
  Timer? _pomocTimer;

  // Safe-route state
  Map<String, dynamic>? _activeRoute;
  bool _loadingRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadActiveSafeRoute());
  }

  @override
  void dispose() {
    _pomocTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveSafeRoute() async {
    if (_loadingRoute) return;
    setState(() => _loadingRoute = true);
    try {
      final api = context.read<ApiService>();
      final auth = context.read<AuthProvider>();
      final myId = auth.user?.id;
      if (myId == null) return;

      final groupsRes = await api.get('/family/groups');
      final groups = (groupsRes['groups'] as List?) ?? const [];
      for (final g in groups) {
        final gid = g['id'] as String?;
        if (gid == null) continue;
        try {
          final routesRes =
              await api.get('/family/groups/$gid/members/$myId/safe-routes');
          final routes = (routesRes['routes'] as List?) ?? const [];
          for (final r in routes) {
            if (r is Map && r['is_active'] == true) {
              if (mounted) {
                setState(() => _activeRoute = Map<String, dynamic>.from(r));
              }
              return;
            }
          }
        } catch (_) {
          // Skip group on error, try next.
        }
      }
    } catch (_) {
      // Silent — banner is optional.
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  void _onPomocTap() {
    HapticFeedback.heavyImpact();
    _pomocTaps += 1;
    _pomocTimer?.cancel();
    _pomocTimer = Timer(const Duration(milliseconds: 1500), () {
      _pomocTaps = 0;
    });

    if (_pomocTaps >= 3) {
      _pomocTaps = 0;
      _pomocTimer?.cancel();
      _openSos();
    } else {
      final remaining = 3 - _pomocTaps;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1200),
          backgroundColor: SerenityColors.glowAlertCoral,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(SerenityShapes.radiusXl.toDouble()),
          ),
          content: Text(
            remaining == 1
                ? 'Naciśnij jeszcze 1 raz aby wezwać pomoc'
                : 'Naciśnij jeszcze $remaining razy',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  void _openSos() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SosKidsScreen()),
    );
  }

  void _openMap() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  }

  void _openFamily() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FamilyScreen()),
    );
  }

  Future<void> _sendImOk() async {
    HapticFeedback.mediumImpact();
    try {
      await context
          .read<ApiService>()
          .post('/users/me/checkin', {'status': 'safe'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: SerenityColors.secondary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(SerenityShapes.radiusXl.toDouble()),
          ),
          content: const Text(
            '✓ Mama i tata wiedzą, że jesteś bezpieczna',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
            borderRadius:
                BorderRadius.circular(SerenityShapes.radiusXl.toDouble()),
          ),
          content: const Text(
            'Nie udało się wysłać wiadomości. Spróbuj jeszcze raz.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
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
    final auth = context.watch<AuthProvider>();
    final firstName = _firstName(auth.user?.username);

    return Scaffold(
      backgroundColor: context.iosBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.iosBackground,
              const Color(0xFFE8F8F2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(auth.user?.avatarUrl),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatusCard(firstName),
                      if (_isSchoolHoursNow) ...[
                        const SizedBox(height: 20),
                        _buildSchoolHoursBanner(),
                      ],
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          'Co chcesz zrobić?',
                          style: SerenityText.bodyMain.copyWith(
                            color: context.iosSecondaryLabel,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _buildActionGrid(),
                      if (_activeRoute != null) ...[
                        const SizedBox(height: 24),
                        _buildSafeRouteBanner(),
                      ],
                    ],
                  ),
                ),
              ),
              _KidsBottomNav(
                onMap: _openMap,
                onFamily: _openFamily,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String? avatarUrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Avatar 56px with mint border
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.iosCardSurface,
              border: Border.all(
                color: SerenityColors.secondaryContainer,
                width: 3,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarPlaceholder(),
                  )
                : _avatarPlaceholder(),
          ),
          // Bell button 56px with mint dot
          Tooltip(
            message: 'Powiadomienia',
            child: InkWell(
              onTap: _openNotifications,
              borderRadius:
                  BorderRadius.circular(SerenityShapes.radiusMd.toDouble()),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: context.iosCardSurface,
                  borderRadius: BorderRadius.circular(
                      SerenityShapes.radiusMd.toDouble()),
                  boxShadow: [
                    BoxShadow(
                      color: SerenityColors.primaryContainer.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: SerenityColors.primaryContainer,
                      size: 30,
                    ),
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: SerenityColors.secondaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.iosCardSurface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: SerenityColors.secondaryContainer.withValues(alpha: 0.4),
      child: const Icon(
        Icons.face,
        color: SerenityColors.primaryContainer,
        size: 32,
      ),
    );
  }

  Widget _buildStatusCard(String firstName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.iosCardSurface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: SerenityColors.primaryContainer.withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cześć, $firstName!',
                  style: const TextStyle(
                    color: SerenityColors.primaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: SerenityColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'JESTEŚ BEZPIECZNA',
                    style: TextStyle(
                      color: SerenityColors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const SizedBox(
            width: 80,
            height: 80,
            child: GlowOrb(
              size: 80,
              color: SerenityColors.glowSafeMint,
              coreOpacity: 0.85,
              child: Icon(
                Icons.shield,
                color: SerenityColors.onSecondaryContainer,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _KidsActionTile(
          label: 'POMOC',
          subtitle: 'Naciśnij 3 razy',
          icon: Icons.local_hospital,
          background: SerenityColors.glowAlertCoral,
          foreground: Colors.white,
          subtitleColor: Colors.white.withValues(alpha: 0.85),
          shadowColor: SerenityColors.glowAlertCoral.withValues(alpha: 0.30),
          onTap: _onPomocTap,
        ),
        _KidsActionTile(
          label: 'MAPA',
          subtitle: 'Zobacz okolicę',
          icon: Icons.map_outlined,
          background: SerenityColors.primaryContainer,
          foreground: Colors.white,
          subtitleColor: Colors.white.withValues(alpha: 0.85),
          shadowColor: SerenityColors.primaryContainer.withValues(alpha: 0.20),
          onTap: _openMap,
        ),
        _KidsActionTile(
          label: 'RODZINA',
          subtitle: 'Mama i Tata',
          icon: Icons.family_restroom,
          background: SerenityColors.secondaryContainer,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SerenityColors.glowSafeMint,
              SerenityColors.glowCalmAqua,
            ],
          ),
          foreground: SerenityColors.primaryContainer,
          subtitleColor:
              SerenityColors.primaryContainer.withValues(alpha: 0.70),
          shadowColor: SerenityColors.glowSafeMint.withValues(alpha: 0.30),
          onTap: _openFamily,
        ),
        _KidsActionTile(
          label: 'JESTEM OK',
          subtitle: 'Wyślij wiadomość',
          icon: Icons.check_circle,
          background: context.iosCardSurface,
          foreground: SerenityColors.primaryContainer,
          subtitleColor: SerenityColors.onSurfaceVariant,
          iconColor: SerenityColors.onSecondaryContainer,
          border: Border.all(
            color: SerenityColors.secondaryContainer,
            width: 2,
          ),
          onTap: _sendImOk,
        ),
      ],
    );
  }

  Widget _buildSafeRouteBanner() {
    final name = (_activeRoute?['name'] as String?) ?? 'bezpiecznej trasy';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SerenityColors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.iosSeparator.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.iosCardSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_walk,
              color: SerenityColors.primaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'W drodze do "$name"',
                  style: const TextStyle(
                    color: SerenityColors.primaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Mama i tata widzą, gdzie jesteś',
                  style: SerenityText.labelCaps.copyWith(
                    color: context.iosSecondaryLabel,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _firstName(String? username) {
    if (username == null || username.trim().isEmpty) return 'Przyjacielu';
    final parts = username.trim().split(RegExp(r'\s+'));
    return parts.first;
  }

  // F20: Tryb szkolny - sprawdza czy obecnie godziny lekcji (pn-pt 8-15) lokalnie
  bool get _isSchoolHoursNow {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mon, 7=Sun
    if (weekday > 5) return false;
    final hour = now.hour;
    return hour >= 8 && hour < 15;
  }

  Widget _buildSchoolHoursBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: SerenityColors.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🎒', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CISZA SZKOLNA',
                  style: SerenityText.labelCaps.copyWith(
                    color: SerenityColors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Telefon nie dzwoni w czasie lekcji',
                  style: SerenityText.bodyMain.copyWith(
                    color: SerenityColors.onSecondaryContainer,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KidsActionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color subtitleColor;
  final Color? iconColor;
  final Color? shadowColor;
  final Gradient? gradient;
  final BoxBorder? border;
  final VoidCallback onTap;

  const _KidsActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.subtitleColor,
    this.iconColor,
    this.shadowColor,
    this.gradient,
    this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: gradient == null ? background : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: border,
          boxShadow: shadowColor != null
              ? [
                  BoxShadow(
                    color: shadowColor!,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: foreground.withValues(alpha: 0.1),
          highlightColor: foreground.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: iconColor ?? foreground,
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KidsBottomNav extends StatelessWidget {
  final VoidCallback onMap;
  final VoidCallback onFamily;

  const _KidsBottomNav({
    required this.onMap,
    required this.onFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: context.iosCardSurface,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _KidsNavItem(
              icon: Icons.home_filled,
              label: 'Start',
              active: true,
              onTap: () {},
            ),
            _KidsNavItem(
              icon: Icons.location_on_outlined,
              label: 'Mapa',
              active: false,
              onTap: onMap,
            ),
            _KidsNavItem(
              icon: Icons.group_outlined,
              label: 'Rodzina',
              active: false,
              onTap: onFamily,
            ),
          ],
        ),
      ),
    );
  }
}

class _KidsNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _KidsNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? SerenityColors.primaryContainer
        : SerenityColors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            if (active)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SerenityColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

