/// be:Safe — Member Profile Screen
///
/// Karta profilu zwykłego członka rodziny (parenta lub innego dorosłego)
/// dla pozostałych członków grupy. W odróżnieniu od ChildProfileScreen:
/// - brak Historii lokalizacji i Bezpiecznych tras (wymagają parent-only
///   uprawnień i dotyczą tylko podopiecznych dzieci)
/// - są: Zadzwoń (gdy phone), Wyślij sygnał (ping do grupy)
/// - pokazuje: avatar, online status, baterię, wiek lokalizacji, małą mapę
library;

import 'package:flutter/material.dart';
import '../../theme/map_style.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import 'family_screen.dart' show pickRole, roleLabel, roleIcon;

class MemberProfileScreen extends StatefulWidget {
  final String groupId;
  final String userId;
  final String userName;
  final String? role; // 'parent' | 'child' | null
  final double? initialLat;
  final double? initialLng;

  const MemberProfileScreen({
    super.key,
    required this.groupId,
    required this.userId,
    required this.userName,
    this.role,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  Map<String, dynamic>? _member;
  String? _groupName;
  String? _ownerId;
  bool _loading = true;
  bool _pinging = false;
  bool _changingRole = false;
  bool _removing = false;
  String? _error;

  /// F23: matryca widoczności gdy _isSelf (jak inni mnie widzą) lub
  /// gdy ja jestem parent/guardian i target=child (jak inni widzą dziecko).
  List<Map<String, dynamic>>? _privacyMatrix;
  // Pole `viewerId:field` aktualnie zapisywane (do disabled state).
  final Set<String> _savingVis = {};

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
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Nie udało się załadować profilu.';
          _loading = false;
        });
      }
    }
  }

  String? get _phone => _member?['phone']?.toString();
  String get _role => widget.role ?? _member?['role']?.toString() ?? 'parent';
  bool get _isChild => _role == 'child';

  /// F35: czy zalogowany user jest ownerem tej grupy (może edytować role).
  bool get _isOwner {
    final me = context.read<AuthProvider>().user?.id;
    return _ownerId != null && me != null && _ownerId == me;
  }

  /// F35: czy targetowany użytkownik to ja (nie pozwalamy zmieniać własnej roli stąd).
  bool get _isSelf {
    final me = context.read<AuthProvider>().user?.id;
    return me != null && me == widget.userId;
  }

  /// F23: ja mogę zarządzać matrycą prywatności dziecka.
  bool get _canManageChildPrivacy {
    if (_isSelf) return false;
    final myRole = _member == null
        ? null
        : (context.read<AuthProvider>().user == null
            ? null
            : _myRoleInGroup());
    if (myRole != 'parent' && myRole != 'guardian') return false;
    return _role == 'child';
  }

  String? _myRoleInGroup() {
    // Backend GET /family/groups zwraca your_role per grupę.
    // Niestety nie trzymamy jej tu lokalnie — pobieramy z _ownerId+widget.role
    // jako proxy nie zadziała. Zamiast tego użyjemy AuthProvider gdy są
    // grupy w cache; jeśli nie, fallback na 'parent' tylko jeśli _isOwner.
    // Praktycznie: w grupie owner zawsze ma role=parent.
    return _isOwner ? 'parent' : null;
  }

  Future<void> _loadPrivacyMatrix(String targetUserId) async {
    try {
      final api = context.read<ApiService>();
      final res = await api.get(
        '/family/groups/${widget.groupId}/visibility-matrix/$targetUserId',
      );
      final list = (res['matrix'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _privacyMatrix = list.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się pobrać prywatności: $e')),
      );
    }
  }

  Future<void> _toggleVisibility({
    required String viewerId,
    required String targetId,
    required String field,
    required bool current,
    required void Function(void Function()) setSheetState,
  }) async {
    final key = '$viewerId:$field';
    if (_savingVis.contains(key)) return;
    setSheetState(() => _savingVis.add(key));
    try {
      await context.read<ApiService>().put(
        '/family/groups/${widget.groupId}/visibility/$targetId',
        {'viewer_id': viewerId, 'field': field, 'granted': !current},
      );
      // Optimistic local update
      if (_privacyMatrix != null) {
        for (final row in _privacyMatrix!) {
          if (row['viewer_id'] == viewerId) {
            final vis = Map<String, dynamic>.from(
                (row['visibility'] as Map?) ?? {});
            vis[field] = !current;
            row['visibility'] = vis;
            break;
          }
        }
      }
      setSheetState(() {});
      HapticFeedback.selectionClick();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się zapisać: $e')),
        );
      }
    } finally {
      setSheetState(() => _savingVis.remove(key));
    }
  }

  Future<void> _removeMember() async {
    if (_removing) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć z grupy?'),
        content: Text(
            '${widget.userName} straci dostęp do grupy oraz wszystkie zapisane dane widoczności w tej grupie.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: SerenityColors.glowAlertCoral),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _removing = true);
    try {
      await context.read<ApiService>().delete(
        '/family/groups/${widget.groupId}/members/${widget.userId}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.userName} usunięty z grupy.')),
      );
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się usunąć: $e')),
        );
        setState(() => _removing = false);
      }
    }
  }

  Future<void> _showPrivacySheet({
    required String targetUserId,
    required String title,
  }) async {
    // Załaduj macierz przed pokazaniem (refresh) jeśli nie ma.
    if (_privacyMatrix == null) {
      await _loadPrivacyMatrix(targetUserId);
    } else {
      // Refresh w tle.
      // ignore: unawaited_futures
      _loadPrivacyMatrix(targetUserId);
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.iosCardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final matrix = _privacyMatrix ?? const [];
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.4,
            builder: (_, controller) {
              return Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.iosSeparator,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.iosLabel,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Wyłącz przełącznik aby ukryć dane przed danym członkiem.',
                      style: TextStyle(
                          fontSize: 12,
                          color: context.iosSecondaryLabel),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: matrix.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Brak innych członków w grupie.',
                                style: TextStyle(
                                    color: context.iosSecondaryLabel),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: controller,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: matrix.length,
                            itemBuilder: (_, i) {
                              final row = matrix[i];
                              return _PrivacyRowCard(
                                row: row,
                                targetId: targetUserId,
                                savingVis: _savingVis,
                                onToggle: (viewerId, field, current) =>
                                    _toggleVisibility(
                                  viewerId: viewerId,
                                  targetId: targetUserId,
                                  field: field,
                                  current: current,
                                  setSheetState: setSheetState,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        });
      },
    );
    // Po zamknięciu wyczyść matrix żeby świeży load przy następnym otwarciu.
    if (mounted) {
      setState(() => _privacyMatrix = null);
    }
  }

  Future<void> _changeRole() async {
    if (_changingRole) return;
    final current = _member?['role']?.toString() ?? _role;
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
          content: Text('Sygnał wysłany — wszyscy w grupie dostaną powiadomienie.'),
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

  @override
  Widget build(BuildContext context) {
    final online = _onlineStatus();

    return Scaffold(
      backgroundColor: context.iosBackground,
      appBar: AppBar(
        backgroundColor: context.iosBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.iosLabel),
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
                      _buildLocationCard(),
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
              const Icon(Icons.error_outline,
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
    // F35: lokalna alias żeby nie kolidować z top-level helperem `roleLabel`.
    final roleText = roleLabel(_member?['role']?.toString() ?? _role);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.iosCardSurface,
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
                    child: Icon(_isChild ? Icons.face : Icons.person,
                        color: context.iosLabel, size: 40),
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
                          color: context.iosCardSurface,
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
                    Row(
                      children: [
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
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: SerenityColors.primaryContainer
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(roleText,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.iosLabel)),
                        ),
                      ],
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
                  color: context.iosSeparator
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
                  color: context.iosSeparator
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
                  color: context.iosSecondaryLabel,
                  letterSpacing: 0.4)),
        ],
      );

  Widget _buildLocationCard() {
    final lat = _lat;
    final lng = _lng;
    if (lat == null || lng == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.iosCardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: context.iosSeparator.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off,
                size: 32, color: context.iosSecondaryLabel),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Brak danych o lokalizacji. ${widget.userName} może mieć wyłączone udostępnianie lokalizacji.',
                style: SerenityText.bodyMain.copyWith(
                    fontSize: 13, color: context.iosSecondaryLabel),
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
              style: Theme.of(context).brightness == Brightness.dark ? kDarkMapStyle : null,
              initialCameraPosition:
                  CameraPosition(target: LatLng(lat, lng), zoom: 15),
              markers: {
                Marker(
                  markerId: const MarkerId('member'),
                  position: LatLng(lat, lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      _isChild
                          ? BitmapDescriptor.hueGreen
                          : BitmapDescriptor.hueAzure),
                  infoWindow: InfoWindow(title: widget.userName),
                ),
              },
              circles: {
                Circle(
                  circleId: const CircleId('member'),
                  center: LatLng(lat, lng),
                  radius: 150,
                  fillColor:
                      SerenityColors.glowSafeMint.withValues(alpha: 0.18),
                  strokeColor:
                      SerenityColors.glowSafeMint.withValues(alpha: 0.6),
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
                  color: context.iosCardSurface
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
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    final hasPhone = _phone != null && _phone!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: context.iosCardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: SerenityElevation.card(),
      ),
      child: Column(
        children: [
          _actionTile(
            icon: Icons.call,
            iconColor: const Color(0xFF1B873A),
            title: hasPhone ? 'Zadzwoń' : 'Brak numeru telefonu',
            subtitle: hasPhone
                ? _phone!
                : '${widget.userName} nie podał numeru w ustawieniach',
            onTap: hasPhone ? _call : null,
          ),
          _divider(),
          _actionTile(
            icon: Icons.notifications_active,
            iconColor: SerenityColors.glowAlertCoral,
            title: _pinging ? 'Wysyłanie...' : 'Wyślij sygnał',
            subtitle:
                'Powiadomienie "daj znak życia" do wszystkich w grupie',
            onTap: _pinging ? null : _sendPing,
            trailing: _pinging
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          if (_isOwner && !_isSelf) ...[
            _divider(),
            _actionTile(
              icon: roleIcon(_member?['role']?.toString() ?? _role),
              iconColor: SerenityColors.primary,
              title: _changingRole ? 'Zmienianie...' : 'Zmień rolę',
              subtitle:
                  'Obecna rola: ${roleLabel(_member?['role']?.toString() ?? _role)}',
              onTap: _changingRole ? null : _changeRole,
              trailing: _changingRole
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.swap_horiz,
                      color: context.iosSecondaryLabel),
            ),
          ],
          if (_isSelf) ...[
            _divider(),
            _actionTile(
              icon: Icons.visibility_outlined,
              iconColor: SerenityColors.secondary,
              title: 'Twoja prywatność',
              subtitle: 'Wybierz co inni członkowie mogą o Tobie widzieć',
              onTap: () => _showPrivacySheet(
                targetUserId: widget.userId,
                title: 'Jak inni widzą Ciebie',
              ),
            ),
          ],
          if (_canManageChildPrivacy) ...[
            _divider(),
            _actionTile(
              icon: Icons.shield_outlined,
              iconColor: SerenityColors.secondary,
              title: 'Prywatność ${widget.userName}',
              subtitle:
                  'Kontrolujesz co członkowie grupy widzą o tym dziecku',
              onTap: () => _showPrivacySheet(
                targetUserId: widget.userId,
                title: 'Widoczność ${widget.userName}',
              ),
            ),
          ],
          if (_isOwner && !_isSelf) ...[
            _divider(),
            _actionTile(
              icon: Icons.person_remove_outlined,
              iconColor: SerenityColors.glowAlertCoral,
              title: _removing ? 'Usuwanie...' : 'Usuń z grupy',
              subtitle: 'Trwale usuwa ${widget.userName} z tej grupy',
              onTap: _removing ? null : _removeMember,
              trailing: _removing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 1,
        color: context.iosSeparator.withValues(alpha: 0.3),
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
                            color: context.iosSecondaryLabel)),
                  ],
                ),
              ),
              trailing ??
                  Icon(Icons.chevron_right,
                      color: context.iosSecondaryLabel
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
                size: 14, color: context.iosSecondaryLabel),
            const SizedBox(width: 6),
            Text('Grupa: $_groupName',
                style: TextStyle(
                    fontSize: 11, color: context.iosSecondaryLabel)),
          ],
        ),
      );
}

/// F23 Field labels (PL) — używane w bottom sheet matrycy.
const Map<String, ({String label, IconData icon})> _kVisibilityFieldsMobile = {
  'location': (label: 'Lokalizacja', icon: Icons.place_outlined),
  'history': (label: 'Historia tras', icon: Icons.history_outlined),
  'battery': (label: 'Bateria', icon: Icons.battery_5_bar_outlined),
  'online': (label: 'Status online', icon: Icons.wifi_outlined),
  'phone': (label: 'Numer telefonu', icon: Icons.phone_outlined),
  'alerts': (label: 'Zgłoszenia', icon: Icons.warning_amber_outlined),
  'checkin': (label: 'Check-in', icon: Icons.check_circle_outline),
};

class _PrivacyRowCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final String targetId;
  final Set<String> savingVis;
  final void Function(String viewerId, String field, bool current) onToggle;

  const _PrivacyRowCard({
    required this.row,
    required this.targetId,
    required this.savingVis,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final viewerId = row['viewer_id']?.toString() ?? '';
    final viewerName = row['viewer_username']?.toString() ?? '—';
    final avatar = row['avatar_url']?.toString();
    final role = row['role']?.toString();
    final vis = (row['visibility'] as Map?) ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.iosCardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.iosSeparator.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: context.iosSeparator
                    .withValues(alpha: 0.4),
                backgroundImage: (avatar != null && avatar.isNotEmpty)
                    ? NetworkImage(avatar)
                    : null,
                child: (avatar == null || avatar.isEmpty)
                    ? Text(
                        viewerName.isNotEmpty
                            ? viewerName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: context.iosLabel),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(viewerName,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.iosLabel)),
                    if (role != null)
                      Text(role,
                          style: TextStyle(
                              fontSize: 11,
                              color: context.iosSecondaryLabel)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._kVisibilityFieldsMobile.entries.map((e) {
            final field = e.key;
            final granted = (vis[field] as bool?) ?? true;
            final key = '$viewerId:$field';
            final saving = savingVis.contains(key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(e.value.icon,
                      size: 18,
                      color: granted
                          ? SerenityColors.primary
                          : SerenityColors.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: granted
                            ? SerenityColors.primary
                            : SerenityColors.onSurfaceVariant,
                        decoration: granted
                            ? TextDecoration.none
                            : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                  saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch.adaptive(
                          value: granted,
                          activeColor: SerenityColors.secondary,
                          onChanged: (_) =>
                              onToggle(viewerId, field, granted),
                        ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
