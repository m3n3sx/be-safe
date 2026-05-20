/// be:Safe v2 — Home Screen (Status Okolicy)
///
/// First screen after login. Presents a calm overview of neighborhood safety
/// using the signature Glow Orb + three activity cards.
///
/// Design source: design/stitch_v2/screens/ekran_glowny_status_okolicy/
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:provider/provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/glow_orb.dart';
import '../../widgets/serenity_card.dart';
import '../../widgets/aqi_widget.dart';
import '../alerts/create_alert_screen.dart';
import '../alerts/my_alerts_screen.dart';
import '../family/family_screen.dart';
import '../family/child_profile_screen.dart';
import '../family/member_profile_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../emergency/emergency_numbers_screen.dart';
import '../fake_call/fake_call_setup_screen.dart';

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
  List<Map<String, dynamic>> _children = []; // {user_id, username, lat, lng, last_location_at, group_id, group_name, avatar_url}

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
    final myId = context.read<AuthProvider>().user?.id;

    // Równolegle: lokalizacja+alerty ORAZ rodzina — żeby nie blokować się sekwencyjnie.
    await Future.wait<void>([
      _loadAlertsNearby(alertProv).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          _alertsNearby = alertProv.allAlerts.length;
        },
      ),
      _loadFamily(api, myId).timeout(
        const Duration(seconds: 8),
        onTimeout: () {},
      ),
    ]);

    // 3. Community confirmations — sum of confirms on nearby alerts as proxy
    _communityConfirmations = alertProv.allAlerts
        .fold(0, (sum, a) => sum + a.confirms);

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadAlertsNearby(AlertProvider alertProv) async {
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
  }

  Future<void> _loadFamily(ApiService api, String? myId) async {
    try {
      final groups = await api.get('/family/groups');
      final groupsList = ((groups as dynamic)['groups'] as List?) ?? [];
      if (groupsList.isEmpty) {
        _familyTotal = 0;
        _familyOnline = 0;
        _children = [];
        return;
      }

      // Równolegle: pobieramy wszystkich members dla wszystkich grup naraz.
      final memberFetches = await Future.wait<Map<String, dynamic>>(
        groupsList.map<Future<Map<String, dynamic>>>((g) async {
          final groupId = g['id'];
          final groupName = (g['name'] ?? 'Rodzina').toString();
          final yourRole = (g['your_role'] ?? '').toString();
          try {
            final results = await Future.wait<dynamic>([
              api.get('/family/groups/$groupId/members'),
              api.get('/family/groups/$groupId/checkins/today').catchError(
                (_) => <String, dynamic>{'members': []},
              ),
            ]);
            final m = results[0];
            final c = results[1];
            final members = ((m as dynamic)['members'] as List?) ?? [];
            final checkins = ((c as dynamic)['members'] as List?) ?? [];
            // Mapowanie user_id -> checked_in_today (bool? - true/false/null)
            final ciMap = <String, dynamic>{};
            for (final r in checkins) {
              final uid = r['user_id']?.toString();
              if (uid != null) {
                ciMap[uid] = {
                  'checked_in_today': r['checked_in_today'],
                  'last_checkin_at': r['last_checkin_at'],
                  'app_mode': r['app_mode'],
                };
              }
            }
            return {
              'group_id': groupId,
              'group_name': groupName,
              'your_role': yourRole,
              'members': members,
              'checkins': ciMap,
            };
          } catch (_) {
            return {
              'group_id': groupId,
              'group_name': groupName,
              'your_role': yourRole,
              'members': const <dynamic>[],
              'checkins': const <String, dynamic>{},
            };
          }
        }),
      );

      final family = <Map<String, dynamic>>[];
      final seen = <String>{};
      var totalMembers = 0;
      var onlineMembers = 0;
      final now = DateTime.now();
      for (final entry in memberFetches) {
        final groupId = entry['group_id'];
        final groupName = entry['group_name'];
        final yourRole = entry['your_role'];
        final members = entry['members'] as List;
        final ciMap = (entry['checkins'] as Map?)?.cast<String, dynamic>() ?? {};
        totalMembers += members.length;
        for (final mem in members) {
          final last = mem['last_location_at'] ?? mem['last_seen_at'] ?? mem['updated_at'];
          if (last != null) {
            try {
              final dt = DateTime.parse(last.toString());
              if (now.difference(dt).inMinutes < 15) onlineMembers++;
            } catch (_) {}
          }
          final memberId = mem['user_id']?.toString();
          if (memberId == null || memberId == myId || seen.contains(memberId)) continue;
          if (mem['lat'] == null || mem['lng'] == null) continue;
          seen.add(memberId);
          final ci = (ciMap[memberId] as Map?)?.cast<String, dynamic>() ?? const {};
          family.add({
            'user_id': mem['user_id'],
            'username': (mem['username'] ?? '').toString(),
            'avatar_url': mem['avatar_url'],
            'role': mem['role'],
            'your_role': yourRole,
            'app_mode': mem['app_mode'] ?? ci['app_mode'],
            'lat': (mem['lat'] as num).toDouble(),
            'lng': (mem['lng'] as num).toDouble(),
            'last_location_at': mem['last_location_at'],
            'last_seen_at': mem['last_seen_at'],
            'battery_level': mem['last_battery_level'] ?? mem['battery_level'],
            'phone': mem['phone'],
            'group_id': groupId,
            'group_name': groupName,
            'checked_in_today': ci['checked_in_today'],
            'last_checkin_at': ci['last_checkin_at'],
          });
        }
      }
      _familyTotal = totalMembers;
      _familyOnline = onlineMembers;
      _children = family;
    } catch (_) {}
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
              if (_children.isNotEmpty)
                SliverToBoxAdapter(child: _buildChildrenCard()),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: AqiWidget(),
                ),
              ),
              SliverToBoxAdapter(child: _buildActivitySection()),
              const SliverToBoxAdapter(child: SizedBox(height: 180)),
            ],
          ),
        ),
      ),
      // bottomNavigationBar usunięty — globalny dock przez MaterialApp.builder
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
          Tooltip(
            message: 'Mój profil',
            child: GestureDetector(
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
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.shield, color: SerenityColors.primary, size: 28),
              SizedBox(width: SerenitySpacing.xs),
              Text('be:Safe', style: SerenityText.headlineHeroMobile),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 28),
                color: SerenityColors.primary,
                onPressed: () => Navigator.pushNamed(context, '/my-alerts'),
                tooltip: 'Powiadomienia',
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, size: 28),
                color: SerenityColors.primary,
                onPressed: _openMenu,
                tooltip: 'Więcej',
              ),
            ],
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
              icon: Icons.phone_in_talk,
              label: 'Fałszywy telefon',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FakeCallSetupScreen()),
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

  // ─────────────────────────────────────────────────────────────
  //  Karta "Moje dzieci" — top of HomeScreen
  // ─────────────────────────────────────────────────────────────

  String _formatAge(dynamic raw) {
    if (raw == null) return 'Brak kontaktu';
    try {
      final dt = DateTime.parse(raw.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'przed chwilą';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min temu';
      if (diff.inHours < 24) return '${diff.inHours} h temu';
      return '${diff.inDays} dni temu';
    } catch (_) {
      return '—';
    }
  }

  /// Świeżość lokalizacji: zielony < 5min, żółty 5-30min, czerwony > 30min lub null.
  Color _freshnessColor(dynamic raw) {
    if (raw == null) return SerenityColors.glowAlertCoral;
    try {
      final dt = DateTime.parse(raw.toString());
      final mins = DateTime.now().difference(dt).inMinutes;
      if (mins < 5) return const Color(0xFF1B873A); // green
      if (mins < 30) return const Color(0xFFFFA000); // amber
      return SerenityColors.glowAlertCoral;
    } catch (_) {
      return SerenityColors.glowAlertCoral;
    }
  }

  /// Status online dziecka: <2min = online (zielony), <15min = recent (amber), >15min lub null = offline.
  ({Color color, String label, IconData icon}) _onlineStatus(dynamic raw) {
    if (raw == null) {
      return (color: const Color(0xFF999999), label: 'Offline', icon: Icons.wifi_off);
    }
    try {
      final dt = DateTime.parse(raw.toString());
      final mins = DateTime.now().difference(dt).inMinutes;
      if (mins < 2) return (color: const Color(0xFF1B873A), label: 'Online', icon: Icons.wifi);
      if (mins < 15) return (color: const Color(0xFFFFA000), label: 'Niedawno', icon: Icons.access_time);
      return (color: const Color(0xFF999999), label: 'Offline', icon: Icons.wifi_off);
    } catch (_) {
      return (color: const Color(0xFF999999), label: 'Offline', icon: Icons.wifi_off);
    }
  }

  Widget _buildChildrenCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        decoration: BoxDecoration(
          color: SerenityColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: SerenityColors.primaryContainer.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups_2_outlined, color: SerenityColors.primaryContainer, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'MOJA RODZINA',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                ),
                const Spacer(),
                Text(
                  '${_children.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: SerenityColors.primaryContainer.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ..._children.map(_buildChildTile),
          ],
        ),
      ),
    );
  }

  Widget _buildChildTile(Map<String, dynamic> c) {
    final username = c['username']?.toString() ?? 'Członek rodziny';
    final last = c['last_location_at'];
    final color = _freshnessColor(last);
    final battery = c['battery_level'];
    final online = _onlineStatus(c['last_seen_at']);
    final role = c['role']?.toString();
    final isChild = role == 'child';
    final myRole = c['your_role']?.toString();
    final appMode = c['app_mode']?.toString();
    final isSenior = appMode == 'senior';
    final checkedToday = c['checked_in_today'] == true;
    return InkWell(
      onTap: () {
        final groupId = c['group_id']?.toString();
        final userId = c['user_id']?.toString();
        if (groupId == null || userId == null) return;
        HapticFeedback.selectionClick();
        final lat = (c['lat'] as num?)?.toDouble();
        final lng = (c['lng'] as num?)?.toDouble();
        // Pełny profil dziecka (z trasami/historią) — tylko dla rodzica.
        // Inni członkowie dostają zwykły MemberProfileScreen.
        if (isChild && myRole == 'parent') {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChildProfileScreen(
              groupId: groupId,
              userId: userId,
              userName: username,
              initialLat: lat,
              initialLng: lng,
            ),
          ));
        } else {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => MemberProfileScreen(
              groupId: groupId,
              userId: userId,
              userName: username,
              role: role,
              initialLat: lat,
              initialLng: lng,
            ),
          ));
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SerenityColors.secondaryContainer.withValues(alpha: 0.25),
                    border: Border.all(color: color, width: 2.5),
                  ),
                  child: Icon(isChild ? Icons.face : Icons.person, color: SerenityColors.primaryContainer, size: 22),
                ),
                // Online dot - bottom-right of avatar
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: online.color,
                      border: Border.all(color: SerenityColors.surfaceContainerLowest, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          username,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: online.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(online.icon, size: 11, color: online.color),
                            const SizedBox(width: 4),
                            Text(
                              online.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: online.color,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatAge(last),
                        style: TextStyle(
                          fontSize: 12,
                          color: SerenityColors.primaryContainer.withValues(alpha: 0.6),
                        ),
                      ),
                      if (battery is num) ...[
                        const SizedBox(width: 10),
                        Icon(
                          battery < 20 ? Icons.battery_alert : Icons.battery_full,
                          size: 13,
                          color: battery < 20
                              ? SerenityColors.glowAlertCoral
                              : SerenityColors.primaryContainer.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${battery.toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: battery < 20
                                ? SerenityColors.glowAlertCoral
                                : SerenityColors.primaryContainer.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                      if (isSenior) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: checkedToday
                                ? SerenityColors.secondaryContainer
                                : SerenityColors.glowAlertCoral.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                checkedToday ? Icons.check_circle : Icons.schedule,
                                size: 11,
                                color: checkedToday
                                    ? SerenityColors.onSecondaryContainer
                                    : SerenityColors.glowAlertCoral,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                checkedToday ? 'Zameldowany' : 'Brak meldunku',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: checkedToday
                                      ? SerenityColors.onSecondaryContainer
                                      : SerenityColors.glowAlertCoral,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFAAAAAA)),
          ],
        ),
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
