/// be:Safe — Child Profile Screen
///
/// Pełna karta profilu dziecka dla rodzica: avatar, online status, bateria,
/// ostatnia lokalizacja na małej mapie + szybkie akcje:
/// - Zadzwoń (gdy `phone` jest ustawione)
/// - Wyślij sygnał (ping do całej grupy)
/// - Historia tras (LocationHistoryScreen)
/// - Bezpieczne trasy (SafeRoutesScreen)
/// - Pokaż na mapie (zoom do dziecka)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import 'family_screen.dart' show pickRole, roleLabel, roleIcon;
import 'location_history_screen.dart';
import 'safe_routes_screen.dart';

class ChildProfileScreen extends StatefulWidget {
  final String groupId;
  final String userId;
  final String userName;
  // Opcjonalna początkowa lokalizacja (z karty home/markera mapy),
  // żeby od razu coś pokazać przed _load().
  final double? initialLat;
  final double? initialLng;

  const ChildProfileScreen({
    super.key,
    required this.groupId,
    required this.userId,
    required this.userName,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  Map<String, dynamic>? _member;
  String? _groupName;
  String? _ownerId;
  bool _loading = true;
  bool _pinging = false;
  bool _changingRole = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final res = await api.get('/family/groups/${widget.groupId}/members');
      final list = (res['members'] as List?) ?? [];
      final found = list.cast<Map<String, dynamic>>().firstWhere(
        (m) => m['user_id'] == widget.userId,
        orElse: () => <String, dynamic>{},
      );
      final groups = await api.get('/family/groups');
      final group = ((groups['groups'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (g) => g['id'] == widget.groupId,
            orElse: () => <String, dynamic>{},
          );
      if (!mounted) return;
      setState(() {
        _member = found.isEmpty ? null : found;
        _groupName = group['name']?.toString();
        _ownerId = group['owner_id']?.toString();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Nie udało się załadować profilu.';
          _loading = false;
        });
      }
    }
  }

  String? get _phone => _member?['phone']?.toString();

  /// F35: czy zalogowany user jest ownerem tej grupy (może edytować role).
  bool get _isOwner {
    final me = context.read<AuthProvider>().user?.id;
    return _ownerId != null && me != null && _ownerId == me;
  }

  bool get _isSelf {
    final me = context.read<AuthProvider>().user?.id;
    return me != null && me == widget.userId;
  }

  Future<void> _changeRole() async {
    if (_changingRole) return;
    final current = _member?['role']?.toString() ?? 'child';
    final picked = await pickRole(
      context,
      title: 'Zmień rolę ${widget.userName}',
      current: current,
    );
    if (picked == null || picked == current) return;
    if (!mounted) return;
    setState(() => _changingRole = true);
    try {
      await context.read<ApiService>().patch(
        '/family/groups/${widget.groupId}/members/${widget.userId}',
        {'role': picked},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rola zmieniona na: ${roleLabel(picked)}'),
          backgroundColor: SerenityColors.secondary,
        ),
      );
      HapticFeedback.lightImpact();
      // Po zmianie roli z 'child' na inną — wracamy do listy, bo ten ekran
      // jest tylko dla dzieci.
      if (picked != 'child' && mounted) {
        Navigator.of(context).pop();
        return;
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zmienić roli: $e')),
      );
    } finally {
      if (mounted) setState(() => _changingRole = false);
    }
  }

  double? get _lat {
    final v = _member?['lat'];
    if (v is num) return v.toDouble();
    return widget.initialLat;
  }

  double? get _lng {
    final v = _member?['lng'];
    if (v is num) return v.toDouble();
    return widget.initialLng;
  }

  int? get _battery {
    final v = _member?['last_battery_level'] ?? _member?['battery_level'];
    if (v is num) return v.toInt();
    return null;
  }

  ({Color color, String label, IconData icon}) _onlineStatus() {
    final raw = _member?['last_seen_at']?.toString();
    if (raw == null) {
      return (
        color: const Color(0xFF999999),
        label: 'Offline',
        icon: Icons.wifi_off,
      );
    }
    try {
      final t = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(t);
      if (diff.inMinutes < 2) {
        return (
          color: const Color(0xFF1B873A),
          label: 'Online',
          icon: Icons.wifi,
        );
      }
      if (diff.inMinutes < 15) {
        return (
          color: const Color(0xFFFFA000),
          label: 'Niedawno',
          icon: Icons.access_time,
        );
      }
      return (
        color: const Color(0xFF999999),
        label: 'Offline',
        icon: Icons.wifi_off,
      );
    } catch (_) {
      return (
        color: const Color(0xFF999999),
        label: 'Offline',
        icon: Icons.wifi_off,
      );
    }
  }

  String _formatAge(String? raw) {
    if (raw == null) return 'Brak danych';
    try {
      final t = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(t);
      if (diff.inSeconds < 60) return 'przed chwilą';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min temu';
      if (diff.inHours < 24) return '${diff.inHours} h temu';
      return '${diff.inDays} dni temu';
    } catch (_) {
      return 'Brak danych';
    }
  }

  Color _batteryColor(int? lvl) {
    if (lvl == null) return SerenityColors.onSurfaceVariant;
    if (lvl < 10) return SerenityColors.glowAlertCoral;
    if (lvl < 20) return const Color(0xFFFFA000);
    return const Color(0xFF1B873A);
  }

  IconData _batteryIcon(int? lvl) {
    if (lvl == null) return Icons.battery_unknown;
    if (lvl < 10) return Icons.battery_alert;
    if (lvl < 30) return Icons.battery_2_bar;
    if (lvl < 60) return Icons.battery_4_bar;
    return Icons.battery_full;
  }

  Future<void> _call() async {
    final p = _phone;
    if (p == null || p.isEmpty) return;
    HapticFeedback.mediumImpact();
    final uri = Uri.parse('tel:$p');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie można otworzyć dialera')),
      );
    }
  }

  Future<void> _sendPing() async {
    if (_pinging) return;
    setState(() => _pinging = true);
    try {
      await context
          .read<ApiService>()
          .post('/family/groups/${widget.groupId}/ping', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sygnał wysłany — dziecko otrzyma powiadomienie.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się wysłać sygnału')),
      );
    } finally {
      if (mounted) setState(() => _pinging = false);
    }
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationHistoryScreen(
          groupId: widget.groupId,
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }

  void _openSafeRoutes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SafeRoutesScreen(
          groupId: widget.groupId,
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final online = _onlineStatus();

    return Scaffold(
      backgroundColor: SerenityColors.surfaceBright,
      appBar: AppBar(
        backgroundColor: SerenityColors.surfaceBright,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: SerenityColors.primary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Wróć',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.userName, style: SerenityText.headlineHeroMobile),
        actions: [
          IconButton(
            tooltip: 'Odśwież',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _buildHeroCard(online),
                      const SizedBox(height: 16),
                      _buildLocationCard(isDark),
                      const SizedBox(height: 16),
                      _buildActionsSection(),
                      const SizedBox(height: 12),
                      if (_groupName != null) _buildGroupInfo(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 56, color: SerenityColors.glowAlertCoral),
              const SizedBox(height: 12),
              Text(_error ?? 'Błąd', style: SerenityText.bodyMain),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Spróbuj ponownie'),
              ),
            ],
          ),
        ),
      );

  Widget _buildHeroCard(({Color color, String label, IconData icon}) online) {
    final lvl = _battery;
    final lastSeen = _formatAge(_member?['last_seen_at']?.toString());
    final lastLoc = _formatAge(_member?['last_location_at']?.toString());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SerenityColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: SerenityElevation.card(),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SerenityColors.secondaryContainer
                          .withValues(alpha: 0.3),
                      border: Border.all(color: online.color, width: 3),
                    ),
                    child: const Icon(Icons.face,
                        color: SerenityColors.primaryContainer, size: 40),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: online.color,
                        border: Border.all(
                          color: SerenityColors.surfaceContainerLowest,
                          width: 3,
                        ),
                      ),
                      child: Icon(online.icon, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.userName,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: online.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(online.icon, size: 13, color: online.color),
                          const SizedBox(width: 6),
                          Text(online.label,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: online.color)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  icon: _batteryIcon(lvl),
                  color: _batteryColor(lvl),
                  label: 'Bateria',
                  value: lvl == null ? '—' : '$lvl%',
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: SerenityColors.outlineVariant
                      .withValues(alpha: 0.5)),
              Expanded(
                child: _miniStat(
                  icon: Icons.access_time,
                  color: online.color,
                  label: 'Aktywność',
                  value: lastSeen,
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: SerenityColors.outlineVariant
                      .withValues(alpha: 0.5)),
              Expanded(
                child: _miniStat(
                  icon: Icons.location_on,
                  color: SerenityColors.primaryContainer,
                  label: 'Lokalizacja',
                  value: lastLoc,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) =>
      Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: SerenityColors.onSurfaceVariant,
                  letterSpacing: 0.4)),
        ],
      );

  Widget _buildLocationCard(bool isDark) {
    final lat = _lat;
    final lng = _lng;
    if (lat == null || lng == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SerenityColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: SerenityColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off,
                size: 32, color: SerenityColors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Brak danych o lokalizacji. Upewnij się, że dziecko ma włączoną aplikację i udostępnianie lokalizacji.',
                style: SerenityText.bodyMain.copyWith(
                    fontSize: 13, color: SerenityColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: LatLng(lat, lng), zoom: 15),
              markers: {
                Marker(
                  markerId: const MarkerId('child'),
                  position: LatLng(lat, lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen),
                  infoWindow: InfoWindow(title: widget.userName),
                ),
              },
              circles: {
                Circle(
                  circleId: const CircleId('child'),
                  center: LatLng(lat, lng),
                  radius: 150,
                  fillColor: SerenityColors.glowSafeMint.withValues(alpha: 0.18),
                  strokeColor: SerenityColors.glowSafeMint.withValues(alpha: 0.6),
                  strokeWidth: 2,
                ),
              },
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
              liteModeEnabled: false,
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: SerenityColors.surfaceContainerLowest
                      .withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history, size: 14),
                    const SizedBox(width: 4),
                    Text(_formatAge(_member?['last_location_at']?.toString()),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Material(
                color: SerenityColors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _openHistory,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.timeline,
                            size: 16, color: SerenityColors.onPrimary),
                        SizedBox(width: 6),
                        Text('Trasa dziś',
                            style: TextStyle(
                                fontSize: 12,
                                color: SerenityColors.onPrimary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    final hasPhone = _phone != null && _phone!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: SerenityColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: SerenityElevation.card(),
      ),
      child: Column(
        children: [
          _actionTile(
            icon: Icons.call,
            iconColor: const Color(0xFF1B873A),
            title: hasPhone ? 'Zadzwoń' : 'Brak numeru telefonu',
            subtitle: hasPhone ? _phone! : 'Dziecko nie podało numeru w ustawieniach',
            onTap: hasPhone ? _call : null,
          ),
          _divider(),
          _actionTile(
            icon: Icons.notifications_active,
            iconColor: SerenityColors.glowAlertCoral,
            title: _pinging ? 'Wysyłanie...' : 'Wyślij sygnał',
            subtitle: 'Powiadomienie "daj znak życia" do wszystkich w grupie',
            onTap: _pinging ? null : _sendPing,
            trailing: _pinging
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          _divider(),
          _actionTile(
            icon: Icons.timeline,
            iconColor: SerenityColors.primaryContainer,
            title: 'Historia lokalizacji',
            subtitle: 'Zobacz trasę z wybranego dnia',
            onTap: _openHistory,
          ),
          _divider(),
          _actionTile(
            icon: Icons.route_outlined,
            iconColor: SerenityColors.primaryContainer,
            title: 'Bezpieczne trasy',
            subtitle: 'Skonfiguruj trasy do szkoły, treningu, itd.',
            onTap: _openSafeRoutes,
          ),
          if (_isOwner && !_isSelf) ...[
            _divider(),
            _actionTile(
              icon: roleIcon(_member?['role']?.toString() ?? 'child'),
              iconColor: SerenityColors.primary,
              title: _changingRole ? 'Zmienianie...' : 'Zmień rolę',
              subtitle: 'Obecna rola: ${roleLabel(_member?['role']?.toString() ?? 'child')}',
              onTap: _changingRole ? null : _changeRole,
              trailing: _changingRole
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz, color: SerenityColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 1,
        color: SerenityColors.outlineVariant.withValues(alpha: 0.3),
      );

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: onTap == null
                                ? SerenityColors.onSurfaceVariant
                                : SerenityColors.primary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: SerenityColors.onSurfaceVariant)),
                  ],
                ),
              ),
              trailing ??
                  Icon(Icons.chevron_right,
                      color: SerenityColors.onSurfaceVariant
                          .withValues(alpha: 0.5)),
            ],
          ),
        ),
      );

  Widget _buildGroupInfo() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined,
                size: 14, color: SerenityColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text('Grupa: $_groupName',
                style: TextStyle(
                    fontSize: 11, color: SerenityColors.onSurfaceVariant)),
          ],
        ),
      );
}
