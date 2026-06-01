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
import '../../theme/ios_surfaces.dart';
import '../../widgets/collapsible_dock.dart' show dockAccentColor;
import '../../widgets/glow_orb.dart'; // ignore: unused_import (kept for hero fallback)
import '../../widgets/safety_hero_xl.dart';
import '../../widgets/stagger_list.dart';
import '../../widgets/serenity_card.dart';
import '../../widgets/aqi_widget.dart';
import '../alerts/my_alerts_screen.dart';
import '../family/family_screen.dart';
import '../family/child_profile_screen.dart';
import '../family/member_profile_screen.dart';
import '../map/map_screen.dart';
import '../settings/settings_screen.dart';

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

  /// v100: 3 progi (zielony / żółty / czerwony) zgodnie z Figmą.
  /// User m2445: "zielony bezpiecznie, żółty średnio bezpiecznie, czerwony niebezpiecznie".
  Color get _orbColor {
    if (_safetyLevel >= 7) return const Color(0xFF44FE00); // zielony bezpiecznie
    if (_safetyLevel >= 4) return const Color(0xFFEB6A00); // żółty/pomarańcz średnio
    return const Color(0xFFCE2200); // czerwony niebezpiecznie
  }

  @override
  Widget build(BuildContext context) {
    // v106: sync dock active-pill color z poziomem zagrozenia (zielony/pomarancz/czerwony).
    final orbColor = _orbColor;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (dockAccentColor.value != orbColor) {
        dockAccentColor.value = orbColor;
      }
    });
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.username.split(' ').first ?? '';

    return Scaffold(
      backgroundColor: context.iosBackground,
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
              SliverToBoxAdapter(
                child: StaggerSliverItem(
                  delay: const Duration(milliseconds: 0),
                  child: _buildTopBar(userName),
                ),
              ),
              SliverToBoxAdapter(
                child: StaggerSliverItem(
                  delay: const Duration(milliseconds: 60),
                  child: _buildHero(),
                ),
              ),
              if (_children.isNotEmpty)
                SliverToBoxAdapter(
                  child: StaggerSliverItem(
                    delay: const Duration(milliseconds: 140),
                    child: _buildChildrenCard(),
                  ),
                ),
              SliverToBoxAdapter(
                child: StaggerSliverItem(
                  delay: const Duration(milliseconds: 200),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: AqiWidget(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: StaggerSliverItem(
                  delay: const Duration(milliseconds: 260),
                  child: _buildActivitySection(),
                ),
              ),
              // Mały odstęp pod ostatnim widgetem.
              // MediaQuery.padding.bottom już zawiera reserved space dla docka (~100pt z GlobalDockOverlay).
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
      // bottomNavigationBar usunięty — globalny dock przez MaterialApp.builder.
      // FAB "Zgłoś" przeniesiony do globalnego docka jako center button (v94+).
    );
  }

  // ── TopAppBar (v100: bell left, "Cześć Imię" center, more-vert right) ──
  // User m2445: "na górze wywal logo i nazwe apki i zamiast tego ma być:
  // Cześć Piotr (imie użytkownika), dzwoneczek na lewo a menu na prawo."

  Widget _buildTopBar(String userName) {
    final greeting = userName.isEmpty ? 'Cześć' : 'Cześć $userName';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
      child: Row(
        children: [
          // Bell (left) → /news
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 24),
            color: context.iosLabel,
            onPressed: () => Navigator.pushNamed(context, '/news'),
            tooltip: 'Powiadomienia',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          // Greeting (center, expanded)
          Expanded(
            child: Text(
              greeting,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 20,
                height: 1.17,
                color: context.iosLabel,
              ),
            ),
          ),
          // More menu (right) → /settings
          IconButton(
            icon: const Icon(Icons.more_vert, size: 24),
            color: context.iosLabel,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            tooltip: 'Ustawienia',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  // ── Hero (glow orb) ─────────────────────────────────────────────────────

  Widget _buildHero() {
    return SafetyHeroXL(
      level: _safetyLevel,
      headline: _safetyMessage,
      subtitle: _safetySubtitle,
      ringColor: _orbColor,
      alertsNearby: _alertsNearby,
      onMapTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MapScreen()),
      ),
    );
  }

  // ── Activity cards ──────────────────────────────────────────────────────

  Widget _buildActivitySection() {
    return Padding(
      padding: const EdgeInsets.only(top: SerenitySpacing.xxl),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'DZISIEJSZA AKTYWNOŚĆ',
                style: SerenityText.iosSectionHeader,
              ),
            ),
          ),
          const SizedBox(height: SerenitySpacing.sm),
          SizedBox(
            height: 160,
            child: _loading
                ? const _CardsSkeleton()
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        decoration: BoxDecoration(
          color: context.iosCardSurface,
          borderRadius: BorderRadius.circular(SerenityShapes.iosInline),
          boxShadow: context.iosShadow,
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
      borderRadius: BorderRadius.circular(SerenityShapes.iosInline),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: SerenitySpacing.md),
      itemBuilder: (_, __) => SerenityCard(
        width: 180,
        borderRadius: BorderRadius.circular(SerenityShapes.iosInline),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

// v100: _MenuTile removed — top bar uses /settings directly (user m2445).
