/// be:Safe v2 — Home Screen (Status Okolicy)
///
/// First screen after login. Presents a calm overview of neighborhood safety
/// using the signature Glow Orb + three activity cards.
///
/// Design source: design/stitch_v2/screens/ekran_glowny_status_okolicy/
library;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:provider/provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/glow_orb.dart';
import '../../widgets/pill_nav_bar.dart';
import '../../widgets/serenity_card.dart';
import '../alerts/create_alert_screen.dart';
import '../alerts/my_alerts_screen.dart';
import '../family/family_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../emergency/emergency_numbers_screen.dart';
import '../sos/sos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  int _alertsNearby = 0;
  int _communityConfirmations = 0;
  int _familyOnline = 0;
  int _familyTotal = 0;
  int _navIndex = 1; // Home tab highlighted by default

  static const _navItems = [
    PillNavItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Mapa'),
    PillNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    PillNavItem(
      icon: Icons.family_restroom_outlined,
      activeIcon: Icons.family_restroom,
      label: 'Rodzina',
    ),
    PillNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
    ),
    PillNavItem(icon: Icons.sos_outlined, activeIcon: Icons.sos, label: 'SOS'),
    PillNavItem(
      icon: Icons.apps_outlined,
      activeIcon: Icons.apps,
      label: 'Więcej',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final api = context.read<ApiService>();
    final alertProv = context.read<AlertProvider>();

    // 1. Get location + alerts nearby (reuse AlertProvider which handles cache)
    try {
      final pos = await _getPosition();
      if (pos != null) {
        await alertProv.loadNearby(
          LatLng(pos.latitude, pos.longitude),
          radiusM: 5000,
        );
      }
      _alertsNearby = alertProv.allAlerts.length;
    } catch (_) {
      _alertsNearby = alertProv.allAlerts.length;
    }

    // 2. Family online count (best-effort, ignore errors)
    try {
      final groups = await api.get('/family/groups');
      final groupsList = ((groups as dynamic)['groups'] as List?) ?? [];
      if (groupsList.isNotEmpty) {
        final groupId = groupsList.first['id'];
        final m = await api.get('/family/groups/$groupId/members');
        final members = ((m as dynamic)['members'] as List?) ?? [];
        _familyTotal = members.length;
        final now = DateTime.now();
        _familyOnline = members.where((m) {
          final last = m['last_seen_at'] ?? m['updated_at'];
          if (last == null) return false;
          try {
            final dt = DateTime.parse(last.toString());
            return now.difference(dt).inMinutes < 15;
          } catch (_) {
            return false;
          }
        }).length;
      }
    } catch (_) {}

    // 3. Community confirmations — sum of confirms on nearby alerts as proxy
    _communityConfirmations = alertProv.allAlerts
        .fold(0, (sum, a) => sum + a.confirms);

    if (mounted) setState(() => _loading = false);
  }

  Future<Position?> _getPosition() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      return null;
    }
  }

  /// Safety level: 10 = no alerts, drops by 1 per alert within 5km (clamped 0-10).
  int get _safetyLevel => (10 - _alertsNearby).clamp(0, 10);

  String get _safetyMessage {
    if (_safetyLevel >= 9) return 'Wszystko w porządku';
    if (_safetyLevel >= 7) return 'Sytuacja spokojna';
    if (_safetyLevel >= 5) return 'Zachowaj ostrożność';
    if (_safetyLevel >= 3) return 'Podwyższona czujność';
    return 'Kilka aktywnych zagrożeń';
  }

  String get _safetySubtitle {
    if (_alertsNearby == 0) return 'Twoja okolica jest bezpieczna';
    if (_alertsNearby == 1) return 'Jeden aktywny alert w pobliżu';
    if (_alertsNearby < 5) return '$_alertsNearby alerty w pobliżu';
    return '$_alertsNearby alertów w pobliżu — sprawdź mapę';
  }

  Color get _orbColor {
    if (_safetyLevel >= 7) return SerenityColors.glowSafeMint;
    if (_safetyLevel >= 4) return SerenityColors.glowCalmAqua;
    return SerenityColors.glowAlertCoral;
  }

  void _onNavTap(int i) {
    if (i == 1 || i == _navIndex) return;
    setState(() => _navIndex = i);
    // Navigate via push; restore index on return
    Future<void> route;
    switch (i) {
      case 0:
        route = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
        break;
      case 2:
        route = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FamilyScreen()),
        );
        break;
      case 3:
        route = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
      case 4:
        route = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SosScreen()),
        );
        break;
      case 5:
        // "Więcej" — open the same menu sheet that was in the topBar
        _openMenu();
        setState(() => _navIndex = 1);
        return;
      default:
        return;
    }
    route.then((_) {
      if (mounted) setState(() => _navIndex = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.username.split(' ').first ?? '';

    return Scaffold(
      backgroundColor: SerenityColors.surfaceBright,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: SerenityColors.primary,
          backgroundColor: SerenityColors.surfaceContainerLowest,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildTopBar(userName)),
              SliverToBoxAdapter(child: _buildHero()),
              SliverToBoxAdapter(child: _buildActivitySection()),
              const SliverToBoxAdapter(child: SizedBox(height: 180)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 12,
          top: 8,
        ),
        child: PillNavBar(
          currentIndex: _navIndex,
          onTap: _onNavTap,
          items: _navItems,
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 88),
        child: FloatingActionButton.extended(
          heroTag: 'home_report',
          backgroundColor: SerenityColors.primaryContainer,
          foregroundColor: SerenityColors.onPrimary,
          elevation: 0,
          onPressed: () async {
            // Prefer fresh location; fall back to cached nearby alert position
            LatLng? pos;
            final p = await _getPosition();
            if (!context.mounted) return;
            if (p != null) {
              pos = LatLng(p.latitude, p.longitude);
            } else {
              final alerts = context.read<AlertProvider>().allAlerts;
              if (alerts.isNotEmpty) pos = alerts.first.location;
            }
            pos ??= const LatLng(52.2297, 21.0122); // Warsaw fallback
            if (!context.mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateAlertScreen(position: pos!),
              ),
            );
          },
          icon: const Icon(Icons.warning, size: 20),
          label: Text(
            'Zgłoś',
            style: SerenityText.labelButton.copyWith(
              color: SerenityColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // ── TopAppBar ───────────────────────────────────────────────────────────

  Widget _buildTopBar(String userName) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SerenitySpacing.xl,
        vertical: SerenitySpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Avatar -> profile
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SerenityColors.surfaceContainerLowest,
                boxShadow: SerenityElevation.card(),
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: SerenityText.labelButton.copyWith(
                    fontSize: 16,
                    color: SerenityColors.primary,
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.shield, color: SerenityColors.primary, size: 28),
              SizedBox(width: SerenitySpacing.xs),
              Text('be:Safe', style: SerenityText.headlineHeroMobile),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 28),
            color: SerenityColors.primary,
            onPressed: () => Navigator.pushNamed(context, '/my-alerts'),
            tooltip: 'Powiadomienia',
          ),
        ],
      ),
    );
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SerenityColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: SerenityColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _MenuTile(
              icon: Icons.leaderboard_outlined,
              label: 'Statystyki',
              onTap: () => _popAndPush(ctx, '/stats'),
            ),
            _MenuTile(
              icon: Icons.emoji_events_outlined,
              label: 'Ranking',
              onTap: () => _popAndPush(ctx, '/ranking'),
            ),
            _MenuTile(
              icon: Icons.workspace_premium_outlined,
              label: 'Odznaki',
              onTap: () => _popAndPush(ctx, '/badges'),
            ),
            _MenuTile(
              icon: Icons.article_outlined,
              label: 'Aktualności',
              onTap: () => _popAndPush(ctx, '/news'),
            ),
            _MenuTile(
              icon: Icons.phone_in_talk_outlined,
              label: 'Numery alarmowe',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EmergencyNumbersScreen()),
                );
              },
            ),
            _MenuTile(
              icon: Icons.card_giftcard_outlined,
              label: 'Polecaj znajomym',
              onTap: () => _popAndPush(ctx, '/referral'),
            ),
            _MenuTile(
              icon: Icons.settings_outlined,
              label: 'Ustawienia',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _popAndPush(BuildContext ctx, String route) {
    Navigator.pop(ctx);
    Navigator.pushNamed(context, route);
  }

  // ── Hero (glow orb) ─────────────────────────────────────────────────────

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SerenitySpacing.xl),
            child: Text(
              _safetyMessage,
              style: SerenityText.displayMd.copyWith(
                fontSize: 40,
                height: 48 / 40,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SerenitySpacing.xl),
            child: Text(
              _safetySubtitle,
              style: SerenityText.bodyMain,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: GlowOrb(
              size: 280,
              color: _orbColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'POZIOM BEZPIECZEŃSTWA',
                    style: SerenityText.labelCaps,
                  ),
                  const SizedBox(height: 8),
                  Text('$_safetyLevel/10', style: SerenityText.displayLg),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            ),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Zobacz mapę', style: SerenityText.labelButton),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: SerenityColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Activity cards ──────────────────────────────────────────────────────

  Widget _buildActivitySection() {
    return Padding(
      padding: const EdgeInsets.only(top: SerenitySpacing.xxxl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 1,
            color: SerenityColors.outlineVariant.withValues(alpha: 0.3),
            margin: const EdgeInsets.only(bottom: 32),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: SerenitySpacing.xl),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Dzisiejsza aktywność',
                style: SerenityText.labelButton.copyWith(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: SerenitySpacing.lg),
          SizedBox(
            height: 160,
            child: _loading
                ? const _CardsSkeleton()
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: SerenitySpacing.xl),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _ActivityCard(
                        icon: Icons.warning_amber,
                        iconColor: SerenityColors.onTertiaryContainer,
                        value: '$_alertsNearby',
                        label: 'alerty w pobliżu',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MapScreen()),
                        ),
                      ),
                      const SizedBox(width: SerenitySpacing.md),
                      _ActivityCard(
                        icon: Icons.thumb_up_outlined,
                        iconColor: SerenityColors.secondary,
                        value: '$_communityConfirmations',
                        label: 'potwierdzeń\nspołeczności',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MyAlertsScreen()),
                        ),
                      ),
                      const SizedBox(width: SerenitySpacing.md),
                      _ActivityCard(
                        icon: Icons.family_restroom,
                        iconColor: SerenityColors.primary,
                        value: _familyTotal == 0
                            ? '—'
                            : '$_familyOnline/$_familyTotal',
                        label: _familyTotal == 0
                            ? 'dodaj bliskich'
                            : 'bliscy online',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const FamilyScreen()),
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

// ──────────────────────────────────────────────────────────────────────────
//  Private sub-widgets
// ──────────────────────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SerenityCard(
      width: 180,
      onTap: onTap,
      padding: const EdgeInsets.all(SerenitySpacing.md + 4),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: SerenityText.headlineHero.copyWith(
                  fontSize: 32,
                  height: 40 / 32,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: SerenityText.bodyMain.copyWith(
                  fontSize: 13,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardsSkeleton extends StatelessWidget {
  const _CardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: SerenitySpacing.xl),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: SerenitySpacing.md),
      itemBuilder: (_, __) => SerenityCard(
        width: 180,
        borderRadius: BorderRadius.circular(20),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: SerenityColors.primary),
      title: Text(
        label,
        style: SerenityText.labelButton.copyWith(fontSize: 16),
      ),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: SerenitySpacing.xl),
    );
  }
}
