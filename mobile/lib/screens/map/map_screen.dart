import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart' as gcm;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/alert.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/i18n.dart';
import '../../services/pinned_family_service.dart';
import '../alerts/create_alert_screen.dart';
import '../alerts/alert_detail_screen.dart';
import '../family/child_profile_screen.dart';
import '../family/member_profile_screen.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/map_markers.dart';

/// Wrapper for AlertModel to satisfy ClusterItem contract.
class _ClusterableAlert with gcm.ClusterItem {
  final AlertModel alert;
  _ClusterableAlert(this.alert);

  @override
  LatLng get location => alert.location;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final _locationService = LocationService();
  LatLng _currentPos = const LatLng(52.325, 17.565);
  bool _showFilters = false;
  bool _showAlertList = false;
  List<Map<String, dynamic>> _familyMembers = [];
  // F23-pin: lista user_id przypiętych przez usera (max 3) — pokazywani
  // zawsze na pasku karuzeli. Persystencja w SharedPreferences.
  List<String> _pinnedIds = [];
  final Map<String, BitmapDescriptor> _memberIconCache = {};

  /// Online = lokalizacja świeższa niż 15 min.
  bool _memberOnline(Map<String, dynamic> m) {
    final raw = m['last_location_at'];
    if (raw == null) return false;
    try {
      return DateTime.now()
              .difference(DateTime.parse(raw.toString()).toLocal())
              .inMinutes <
          15;
    } catch (_) {
      return false;
    }
  }

  // F11: AED Locator
  bool _aedsVisible = false;
  List<Map<String, dynamic>> _aeds = [];
  BitmapDescriptor? _aedIcon;
  bool _loadingAeds = false;

  // Clustering state
  gcm.ClusterManager<_ClusterableAlert>? _clusterManager;
  Set<Marker> _clusterMarkers = {};
  String _lastAlertsFingerprint = '';

  @override
  void initState() {
    super.initState();
    // Dark status bar icons for light theme
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _clusterManager = gcm.ClusterManager<_ClusterableAlert>(
      const [],
      _updateClusterMarkers,
      markerBuilder: _buildClusterMarker,
      stopClusteringZoom: 16.0,
    );
    _initLocation();
    _precacheIcons();
    _loadFamilyMembers();
    _loadPinned();
  }

  Future<void> _loadPinned() async {
    final list = await PinnedFamilyService.load();
    if (!mounted) return;
    setState(() => _pinnedIds = list);
  }

  void _updateClusterMarkers(Set<Marker> markers) {
    if (mounted) setState(() => _clusterMarkers = markers);
  }

  Future<Marker> _buildClusterMarker(gcm.Cluster<_ClusterableAlert> cluster) async {
    if (cluster.isMultiple) {
      return Marker(
        markerId: MarkerId(cluster.getId()),
        position: cluster.location,
        icon: await MapMarkers.clusterPin(cluster.count),
        onTap: () {
          HapticFeedback.selectionClick();
          _zoomToCluster(cluster);
        },
      );
    }
    // Single item → render as alert pin with category-aware icon + variant.
    final a = cluster.items.first.alert;
    final variant = _variantFor(a);
    return Marker(
      markerId: MarkerId(a.id),
      position: a.location,
      icon: await MapMarkers.alertPin(a.category, variant: variant),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(context, MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: a)));
      },
    );
  }

  Future<void> _precacheIcons() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    // Warm-up the marker cache so first map paint has icons ready.
    for (final cat in AlertCategory.values) {
      await MapMarkers.alertPin(cat);
    }
    _aedIcon = await MapMarkers.aedPin();
    if (mounted) setState(() {});
  }

  /// F11: Toggle AED layer on map.
  Future<void> _toggleAeds() async {
    HapticFeedback.selectionClick();
    setState(() => _aedsVisible = !_aedsVisible);
    if (_aedsVisible && _aeds.isEmpty) {
      await _loadAeds();
    }
  }

  Future<void> _loadAeds() async {
    if (_loadingAeds) return;
    _loadingAeds = true;
    try {
      final api = context.read<ApiService>();
      final center = _currentPos;
      final res = await api.get(
        '/aeds/nearby?lat=${center.latitude}&lng=${center.longitude}&radius=5000',
      );
      if (!mounted) return;
      final list = (res['aeds'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() {
        _aeds = list;
      });
      // ignore: unused_local_variable
      final _ = center; // keep for future refetch-on-move heuristic
    } catch (_) {
      // silent — banner pokazuje empty state
    } finally {
      _loadingAeds = false;
    }
  }

  void _showAedDetail(Map<String, dynamic> aed) {
    HapticFeedback.selectionClick();
    final lat = (aed['lat'] as num).toDouble();
    final lng = (aed['lng'] as num).toDouble();
    final description = aed['description'] as String?;
    final address = aed['address'] as String?;
    final operator = aed['operator'] as String?;
    final openingHours = aed['opening_hours'] as String?;
    final indoor = aed['indoor'] as bool?;
    final distance = aed['distance_m'] as int?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SafeArea(top: false, child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: context.iosSeparator, borderRadius: BorderRadius.circular(2)))),
            Row(children: [
              Container(width: 56, height: 56, decoration: BoxDecoration(
                color: const Color(0xFF9DF4CB), shape: BoxShape.circle),
                child: const Icon(Icons.favorite, color: Color(0xFF0F7252), size: 28)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Defibrylator AED',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                if (distance != null) Text(
                  distance < 1000 ? '${distance}m od Ciebie' : '${(distance / 1000).toStringAsFixed(1)}km',
                  style: TextStyle(fontSize: 13, color: context.iosSecondaryLabel)),
              ])),
            ]),
            const SizedBox(height: 16),
            if (description != null) Padding(padding: const EdgeInsets.only(bottom: 6),
              child: Text(description, style: const TextStyle(fontSize: 15, height: 1.4))),
            if (address != null) _aedDetailRow(Icons.location_on_outlined, address),
            if (operator != null) _aedDetailRow(Icons.business_outlined, operator),
            if (openingHours != null) _aedDetailRow(Icons.schedule_outlined, openingHours),
            if (indoor != null) _aedDetailRow(
              indoor ? Icons.meeting_room_outlined : Icons.park_outlined,
              indoor ? 'Wewnątrz budynku' : 'Na zewnątrz'),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: FilledButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('google.navigation:q=$lat,$lng&mode=w');
                  try {
                    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                      final web = Uri.parse('https://maps.google.com/?daddr=$lat,$lng&directionsmode=walking');
                      await launchUrl(web, mode: LaunchMode.externalApplication);
                    }
                  } catch (_) {}
                },
                icon: const Icon(Icons.directions_walk), label: const Text('Nawiguj'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2027), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton.icon(
                onPressed: () async {
                  try { await launchUrl(Uri.parse('tel:112'), mode: LaunchMode.externalApplication); } catch (_) {}
                },
                icon: const Icon(Icons.call, color: Colors.white),
                label: const Text('Zadzwoń 112', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
            ]),
          ],
        )),
      ),
    );
  }

  Widget _aedDetailRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: context.iosSecondaryLabel),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4))),
    ]),
  );

  /// Decide which visual variant best represents this alert today.
  AlertPinVariant _variantFor(AlertModel a) {
    if (a.confirms >= 3 && a.confirms > a.denies) {
      return AlertPinVariant.confirmed;
    }
    return AlertPinVariant.defaultV;
  }

  /// Tap on a cluster → fit the camera to the bounding box of all items in it
  /// so the individual pins reveal themselves. Falls back to a step-zoom when
  /// every alert sits on the same coordinate.
  Future<void> _zoomToCluster(gcm.Cluster<_ClusterableAlert> cluster) async {
    final ctl = _mapController;
    if (ctl == null) return;

    final positions = cluster.items.map((c) => c.alert.location).toList();
    if (positions.isEmpty) return;

    if (positions.length == 1) {
      await ctl.animateCamera(CameraUpdate.newLatLngZoom(positions.first, 16));
      return;
    }

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;
    for (final p in positions) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // All alerts at virtually the same spot → just zoom in two steps.
    if ((maxLat - minLat).abs() < 1e-6 && (maxLng - minLng).abs() < 1e-6) {
      final z = await ctl.getZoomLevel();
      await ctl.animateCamera(
        CameraUpdate.newLatLngZoom(cluster.location, (z + 2).clamp(3.0, 19.0)),
      );
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await ctl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Future<void> _initLocation() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() => _currentPos = LatLng(pos.latitude, pos.longitude));
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPos, 15));
      context.read<ApiService>().put('/users/me/location', {'lat': pos.latitude, 'lng': pos.longitude}).catchError((_) => <String, dynamic>{});
    }
    if (mounted) context.read<AlertProvider>().loadNearby(_currentPos, radiusM: 10000);
  }

  Future<void> _loadFamilyMembers() async {
    try {
      final api = context.read<ApiService>();
      final myId = context.read<AuthProvider>().user?.id;
      final res = await api.get('/family/groups');
      debugPrint('[family] groups response: ${res['groups']?.length ?? 0} groups');
      final members = <Map<String, dynamic>>[];
      final seen = <String>{};
      for (final g in (res['groups'] as List? ?? [])) {
        final m = await api.get('/family/groups/${g['id']}/members');
        debugPrint('[family] group ${g['id']}: ${m['members']?.length ?? 0} members');
        for (final member in (m['members'] as List? ?? [])) {
          final userId = member['user_id']?.toString();
          // Skip self & duplicates (member może być w kilku grupach)
          if (userId == null || userId == myId || seen.contains(userId)) continue;
          if (member['lat'] == null || member['lng'] == null) continue;
          seen.add(userId);
          members.add({
            ...member,
            'group_id': g['id'],
            'group_name': g['name'],
            'your_role': g['your_role'], // moja rola w tej grupie (parent/child)
          });
        }
      }
      debugPrint('[family] total members with location: ${members.length}');
      for (final mem in members) {
        final uid = mem['user_id']?.toString();
        if (uid == null) continue;
        final url = mem['avatar_url']?.toString();
        final name = (mem['username'] ?? '?').toString();
        _memberIconCache[uid] = await MapMarkers.avatarPin(
          url, name,
          online: _memberOnline(mem),
        );
      }
      if (mounted) setState(() => _familyMembers = members);
    } catch (e) {
      debugPrint('[family] ERROR: $e');
    }
  }

  void _dismissOverlays() {
    if (_showAlertList || _showFilters) setState(() { _showAlertList = false; _showFilters = false; });
  }

  /// Counts how many other alerts sit within [neighborhoodM] metres of [a].
  /// Used to scale danger-zone circles: dense areas get bigger circles.
  int _neighborCount(AlertModel a, List<AlertModel> all, {double neighborhoodM = 800}) {
    int n = 0;
    for (final b in all) {
      if (identical(a, b) || a.id == b.id) continue;
      final dLat = (a.location.latitude - b.location.latitude) * 111320.0;
      final dLng = (a.location.longitude - b.location.longitude) *
          111320.0 * math.cos(a.location.latitude * math.pi / 180.0);
      final dist = math.sqrt(dLat * dLat + dLng * dLng);
      if (dist <= neighborhoodM) n++;
    }
    return n;
  }

  /// Builds a Circle for an alert with radius scaled by local density.
  /// - base radius from a.radiusM (alert's declared range)
  /// - +8% per neighbor in 800m radius, capped at +40%
  /// - minimum visual radius of 80m so tiny alerts stay readable
  Circle _zoneCircle(AlertModel a, List<AlertModel> all, bool isDark) {
    final neighbors = _neighborCount(a, all);
    final densityBonus = 1.0 + math.min(0.4, neighbors * 0.08);
    final scaled = math.max(80.0, a.radiusM.toDouble() * densityBonus);
    return Circle(
      circleId: CircleId(a.id),
      center: a.location,
      radius: scaled,
      fillColor: const Color(0xFFFF7A7A).withValues(alpha: isDark ? 0.06 : 0.10),
      strokeColor: const Color(0xFFFF7A7A).withValues(alpha: isDark ? 0.30 : 0.42),
      strokeWidth: 1,
    );
  }

  /// Push current alerts into the ClusterManager if the list has changed.
  void _syncClusterItems(List<AlertModel> alerts) {
    final fp = alerts.map((a) => a.id).join(',');
    if (fp == _lastAlertsFingerprint) return;
    _lastAlertsFingerprint = fp;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clusterManager?.setItems(alerts.map(_ClusterableAlert.new).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertProv = context.watch<AlertProvider>();
    final alerts = alertProv.alerts;
    _syncClusterItems(alerts);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final showSidePane = width >= 900;

    final mapStack = Stack(children: [
        Semantics(
          label: 'Mapa z alertami bezpieczeństwa',
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentPos, zoom: 15),
            onMapCreated: (c) {
              _mapController = c;
              _clusterManager?.setMapId(c.mapId);
            },
            onCameraMove: (pos) => _clusterManager?.onCameraMove(pos),
            onCameraIdle: () => _clusterManager?.updateMap(),
            onTap: (_) => _dismissOverlays(),
            myLocationEnabled: true, myLocationButtonEnabled: false,
            zoomControlsEnabled: false, mapToolbarEnabled: false,
            markers: {
              ..._clusterMarkers,
              if (_aedsVisible) ..._aeds.map((aed) => Marker(
                markerId: MarkerId('aed_${aed['id']}'),
                position: LatLng((aed['lat'] as num).toDouble(), (aed['lng'] as num).toDouble()),
                icon: _aedIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                onTap: () => _showAedDetail(aed),
                zIndexInt: 1,
              )),
              ..._familyMembers.map((c) {
                final role = c['role']?.toString();
                final isChild = role == 'child';
                final icon = _memberIconCache[c['user_id'].toString()] ??
                    BitmapDescriptor.defaultMarker;
                return Marker(
                  markerId: MarkerId('member_${c['user_id']}'),
                  position: LatLng(c['lat'], c['lng']),
                  icon: icon,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final groupId = c['group_id'] as String?;
                    final userId = c['user_id'] as String?;
                    final name = (c['username'] as String?) ?? '?';
                    final myRole = c['your_role'] as String?;
                    if (groupId == null || userId == null) return;
                    final lat = (c['lat'] as num?)?.toDouble();
                    final lng = (c['lng'] as num?)?.toDouble();
                    // Pełny profil dziecka (z trasami/historią) — tylko dla rodzica.
                    // Pozostali członkowie (inni rodzice, dzieci patrzące na rodzica
                    // lub na inne dziecko) dostają zwykły MemberProfileScreen.
                    if (isChild && myRole == 'parent') {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChildProfileScreen(
                          groupId: groupId,
                          userId: userId,
                          userName: name,
                          initialLat: lat,
                          initialLng: lng,
                        ),
                      ));
                    } else {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MemberProfileScreen(
                          groupId: groupId,
                          userId: userId,
                          userName: name,
                          role: role,
                          initialLat: lat,
                          initialLng: lng,
                        ),
                      ));
                    }
                  },
                );
              }),
            },
            circles: {
              ...alerts.map((a) => _zoneCircle(a, alerts, isDark)),
              ..._familyMembers.map((c) => Circle(circleId: CircleId('member_${c['user_id']}'), center: LatLng(c['lat'], c['lng']),
                radius: 150, fillColor: cs.primary.withValues(alpha: 0.08), strokeColor: cs.primary.withValues(alpha: 0.4), strokeWidth: 2)),
            },
            style: isDark ? _darkMapStyle : _lightMapStyle,
            padding: const EdgeInsets.only(bottom: 120),
          ),
        ),

        // Search bar — Serenity style (white pill + category filter chips below)
        Positioned(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              decoration: BoxDecoration(
                color: context.iosCardSurface,
                borderRadius: SerenityShapes.pill(),
                boxShadow: SerenityElevation.card(),
              ),
              child: TextField(
                style: SerenityText.bodyMain.copyWith(color: context.iosLabel),
                decoration: InputDecoration(
                  hintText: 'Szukaj adresu lub miejsca',
                  hintStyle: SerenityText.bodyMain.copyWith(color: context.iosSecondaryLabel),
                  prefixIcon: Icon(Icons.search, color: context.iosLabel, size: 22),
                  suffixIcon: Semantics(
                    label: 'Wycentruj mapę na moją lokalizację',
                    button: true,
                    child: IconButton(
                      icon: Icon(Icons.my_location, color: context.iosLabel, size: 22),
                      tooltip: 'Moja lokalizacja',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPos, 15));
                        alertProv.loadNearby(_currentPos, radiusM: 10000);
                      },
                    ),
                  ),
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (q) => _searchLocation(q),
              ),
            ),
            const SizedBox(height: 12),
            // Compact filter button (opens bottom sheet)
            Align(
              alignment: Alignment.centerLeft,
              child: _FilterPillButton(
                activeCount: alertProv.activeFilters.length,
                onTap: () => _openFiltersSheet(alertProv),
              ),
            ),
          ]),
        ),

        // Alert list (overlay on mobile; hidden on tablets where side pane takes over)
        if (_showAlertList && !showSidePane) Positioned(bottom: 130, left: 16, right: 16,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 380),
            decoration: BoxDecoration(color: context.iosCardSurface, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(blurRadius: 16, color: Colors.black.withValues(alpha: 0.15))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                  child: Row(children: [
                    Icon(Icons.notifications_active, size: 18, color: context.iosLabel),
                    const SizedBox(width: 8),
                    Text('Alerty w okolicy (${alerts.length})',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: 'Zamknij',
                      onPressed: () => setState(() => _showAlertList = false),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                  ]),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: context.iosSeparator.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (_, i) {
                      final a = alerts[i];
                      return _AlertListItem(
                        alert: a,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _showAlertList = false);
                          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(a.location, 17));
                        },
                        onDetails: () async {
                          HapticFeedback.selectionClick();
                          setState(() => _showAlertList = false);
                          await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AlertDetailScreen(alert: a),
                          ));
                        },
                      );
                    },
                  ),
                ),
              ]),
            ),
          ),
        ),

        // "Zgłoś" pill button (Serenity style: primaryContainer navy + white text)
        Positioned(bottom: 104, right: 16,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            // F11: AED toggle pill
            Container(
              decoration: BoxDecoration(
                color: _aedsVisible ? const Color(0xFF9DF4CB) : context.iosCardSurface,
                borderRadius: SerenityShapes.pill(),
                boxShadow: SerenityElevation.floating(),
              ),
              child: IconButton(
                icon: Icon(Icons.favorite,
                  color: _aedsVisible ? const Color(0xFF0F7252) : const Color(0xFFE53935)),
                tooltip: _aedsVisible ? 'Ukryj AED' : 'Pokaż defibrylatory (AED)',
                onPressed: _toggleAeds,
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              ),
            ),
            const SizedBox(width: 12),
            // Location button (pill)
            Container(
              decoration: BoxDecoration(
                color: SerenityColors.primaryContainer,
                borderRadius: SerenityShapes.pill(),
                boxShadow: SerenityElevation.floating(),
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location, color: SerenityColors.onPrimary),
                tooltip: 'Wycentruj mapę',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPos, 15));
                },
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              ),
            ),
            const SizedBox(width: 12),
            // Zgłoś pill
            Semantics(
              button: true,
              label: 'Zgłoś zagrożenie w twojej okolicy',
              child: Material(
                color: SerenityColors.primaryContainer,
                borderRadius: SerenityShapes.pill(),
                child: InkWell(
                  borderRadius: SerenityShapes.pill(),
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAlertScreen(position: _currentPos)));
                    if (mounted) alertProv.loadNearby(_currentPos, radiusM: 10000);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: SerenityShapes.pill(),
                      boxShadow: SerenityElevation.floating(),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, color: SerenityColors.glowAlertCoral, size: 20),
                      const SizedBox(width: 8),
                      Text('Zgłoś', style: SerenityText.labelButton.copyWith(color: SerenityColors.onPrimary)),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),

        // Bottom bell badge — kompaktowy dzwoneczek z liczbą zagrożeń
        if (alerts.isNotEmpty) Positioned(bottom: 16, left: 16,
          child: Tooltip(
            message: 'Lista alertów w okolicy',
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _showAlertList = !_showAlertList);
              },
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: context.iosCardSurface,
                  shape: BoxShape.circle,
                  boxShadow: SerenityElevation.card(),
                ),
                child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                  Icon(Icons.notifications_active, color: SerenityColors.onTertiaryContainer, size: 28),
                  Positioned(top: -2, right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                      decoration: BoxDecoration(
                        color: SerenityColors.glowAlertCoral,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: context.iosCardSurface, width: 2),
                      ),
                      child: Center(child: Text(
                        alerts.length > 99 ? '99+' : '${alerts.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.1),
                      )),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),

        // Empty state when 0 alerts (Empty18)
        if (alerts.isEmpty && !alertProv.loading) Positioned(
          left: 16, right: 16, bottom: 190,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.iosCardSurface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                boxShadow: SerenityElevation.card(),
              ),
              child: Row(children: [
                Icon(Icons.verified_user_outlined, color: SerenityColors.secondary, size: 32),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Brak zagrożeń w okolicy', style: SerenityText.bodyMain.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      'Tapnij «Zgłoś» w prawym dolnym rogu aby ostrzec sąsiadów.',
                      style: SerenityText.bodyMain.copyWith(fontSize: 13, color: context.iosSecondaryLabel),
                    ),
                  ],
                )),
              ]),
            ),
          ),
        ),

        // Floating family carousel (compact, collapsible)
        if (_familyMembers.isNotEmpty) Positioned(
          right: 12,
          top: MediaQuery.of(context).padding.top + 80,
          child: _buildFamilyCarousel(),
        ),

        if (alertProv.loading) Positioned(top: 120, left: 0, right: 0, child: Center(child: CircularProgressIndicator(color: cs.primary))),
      ]);

    return Scaffold(
      body: Row(children: [
        if (isTablet) _buildNavigationRail(cs, alerts),
        Expanded(child: mapStack),
        if (showSidePane) SizedBox(
          width: 320,
          child: _AlertSidePane(
            alerts: alerts,
            onAlertTap: (a) {
              HapticFeedback.selectionClick();
              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(a.location, 17));
            },
          ),
        ),
      ]),
      // bottomNavigationBar globalny przez MaterialApp.builder (zachowany tylko desktop NavigationRail)
    );
  }

  /// Floating compact carousel for family members.
  ///
  /// Domyślnie 1 awatar widoczny + chip "+N" gdy są inni. Jeśli user przypiął
  /// członków (max 3 via PinnedFamilyService), pokazujemy wszystkich pinned
  /// na pasku + chip "+N" dla pozostałych. Tap "+N" / chevron → bottom sheet.
  Widget _buildFamilyCarousel() {
    const avatarSize = 40.0;

    // 1) Wyciągnij pinned w kolejności jaką user ustawił.
    final pinned = <Map<String, dynamic>>[];
    final rest = <Map<String, dynamic>>[];
    final byId = {
      for (final m in _familyMembers)
        if (m['user_id'] is String) m['user_id'] as String: m,
    };
    for (final id in _pinnedIds) {
      final m = byId[id];
      if (m != null) pinned.add(m);
    }
    for (final m in _familyMembers) {
      if (!_pinnedIds.contains(m['user_id'])) rest.add(m);
    }

    // 2) Widoczne na pasku: pinned, jeśli brak — pierwszy z listy.
    final visible = pinned.isNotEmpty ? pinned : (rest.isNotEmpty ? [rest.first] : <Map<String, dynamic>>[]);
    final overflow = _familyMembers.length - visible.length;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: context.iosCardSurface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(blurRadius: 12, color: Colors.black.withValues(alpha: 0.15), offset: const Offset(0, 4)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ...visible.map((c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _buildAvatarChip(c, size: avatarSize),
          )),
          if (overflow > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showFamilySheet();
                },
                customBorder: const CircleBorder(),
                child: Container(
                  width: avatarSize, height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SerenityColors.primaryContainer,
                    border: Border.all(color: SerenityColors.secondary, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '+$overflow',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          if (_familyMembers.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showFamilySheet();
                },
                customBorder: const CircleBorder(),
                child: Container(
                  width: 28, height: 22,
                  decoration: BoxDecoration(
                    color: SerenityColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(child: Icon(Icons.expand_more, size: 16, color: context.iosSecondaryLabel)),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildAvatarChip(Map<String, dynamic> c, {required double size}) {
    final role = c['role']?.toString();
    final isChild = role == 'child';
    final username = (c['username'] as String?) ?? '?';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final avatarUrl = c['avatar_url'] as String?;

    return GestureDetector(
      onTap: () => _openMemberProfile(c),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showFamilySheet();
      },
      child: Tooltip(
        message: username,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: isChild ? SerenityColors.glowAlertCoral : SerenityColors.secondary,
              width: 2.5,
            ),
            boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black.withValues(alpha: 0.12))],
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _avatarFallback(initial, isChild),
                )
              : _avatarFallback(initial, isChild),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String initial, bool isChild) {
    return Container(
      color: SerenityColors.surfaceContainerHighest,
      child: Center(
        child: Text(initial, style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: isChild ? SerenityColors.glowAlertCoral : SerenityColors.primary,
        )),
      ),
    );
  }

  void _openMemberProfile(Map<String, dynamic> c) {
    HapticFeedback.selectionClick();
    final groupId = c['group_id'] as String?;
    final userId = c['user_id'] as String?;
    final name = (c['username'] as String?) ?? '?';
    final role = c['role']?.toString();
    final myRole = c['your_role'] as String?;
    final isChild = role == 'child';
    if (groupId == null || userId == null) return;
    final lat = (c['lat'] as num?)?.toDouble();
    final lng = (c['lng'] as num?)?.toDouble();
    if (isChild && (myRole == 'parent' || myRole == 'guardian')) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChildProfileScreen(
          groupId: groupId,
          userId: userId,
          userName: name,
          initialLat: lat,
          initialLng: lng,
        ),
      ));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MemberProfileScreen(
          groupId: groupId,
          userId: userId,
          userName: name,
          role: role,
          initialLat: lat,
          initialLng: lng,
        ),
      ));
    }
  }

  Future<void> _togglePin(String userId, void Function(VoidCallback) setSheetState) async {
    final wasPinned = _pinnedIds.contains(userId);
    final after = await PinnedFamilyService.toggle(userId);
    if (!mounted) return;
    final nowPinned = after.contains(userId);
    if (!wasPinned && !nowPinned) {
      // Nie przypięto bo limit 3.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Możesz przypiąć maksymalnie 3 osoby. Odepnij kogoś najpierw.'),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _pinnedIds = after);
    setSheetState(() {});
  }

  void _showFamilySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55, minChildSize: 0.35, maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => StatefulBuilder(builder: (ctx2, setSheetState) => Container(
          decoration: BoxDecoration(
            color: context.iosBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 44, height: 4, decoration: BoxDecoration(
              color: context.iosSeparator, borderRadius: BorderRadius.circular(2),
            )),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Icon(Icons.family_restroom, color: context.iosLabel),
                const SizedBox(width: 8),
                Expanded(child: Text('Rodzina na mapie (${_familyMembers.length})',
                  style: SerenityText.headlineHeroMobile.copyWith(fontSize: 18),
                )),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
            const Divider(height: 16),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _familyMembers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final c = _familyMembers[i];
                  final username = (c['username'] as String?) ?? '?';
                  final role = c['role']?.toString();
                  final isChild = role == 'child';
                  final hasLocation = c['lat'] != null && c['lng'] != null;
                  final lastSeenStr = c['last_location_at']?.toString();
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pop(ctx);
                      // Centruj mapę na członka
                      final lat = (c['lat'] as num?)?.toDouble();
                      final lng = (c['lng'] as num?)?.toDouble();
                      if (lat != null && lng != null) {
                        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16));
                      }
                    },
                    onLongPress: () {
                      Navigator.pop(ctx);
                      _openMemberProfile(c);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.iosCardSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        _buildAvatarChip(c, size: 44),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(username, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Row(children: [
                            Container(width: 7, height: 7, decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasLocation ? SerenityColors.secondary : context.iosSeparator,
                            )),
                            const SizedBox(width: 6),
                            Text(
                              hasLocation
                                ? (lastSeenStr != null ? 'Aktywny' : 'Lokalizacja')
                                : 'Brak lokalizacji',
                              style: TextStyle(fontSize: 12, color: context.iosSecondaryLabel),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isChild
                                  ? SerenityColors.glowAlertCoral.withValues(alpha: 0.15)
                                  : SerenityColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(_roleLabel(role), style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600,
                                color: isChild ? SerenityColors.glowAlertCoral : SerenityColors.primary,
                              )),
                            ),
                          ]),
                        ])),
                        Builder(builder: (_) {
                          final uid = c['user_id'] as String?;
                          final isPinned = uid != null && _pinnedIds.contains(uid);
                          return IconButton(
                            tooltip: isPinned ? 'Odepnij' : 'Przypnij do paska',
                            icon: Icon(
                              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              color: isPinned ? SerenityColors.glowAlertCoral : SerenityColors.onSurfaceVariant,
                              size: 22,
                            ),
                            onPressed: uid == null ? null : () => _togglePin(uid, setSheetState),
                          );
                        }),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openMemberProfile(c);
                          },
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        )),
      ),
    );
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'parent': return 'Rodzic';
      case 'child': return 'Dziecko';
      case 'senior': return 'Senior';
      case 'guardian': return 'Opiekun';
      case 'family_member': return 'Rodzina';
      case 'partner': return 'Partner';
      case 'friend': return 'Znajomy';
      default: return 'Inny';
    }
  }

  Widget _buildNavigationRail(ColorScheme cs, List<AlertModel> alerts) {
    return NavigationRail(
      backgroundColor: cs.primary,
      selectedIndex: 0,
      onDestinationSelected: (i) {
        if (i == 0) { _dismissOverlays(); return; }
        if (i == 1) { setState(() { _showAlertList = !_showAlertList; _showFilters = false; }); return; }
        if (i == 2) { _sendSOS(); return; }
        if (i == 3) Navigator.pushNamed(context, '/family');
        if (i == 4) Navigator.pushNamed(context, '/profile');
      },
      labelType: NavigationRailLabelType.all,
      unselectedLabelTextStyle: const TextStyle(color: Colors.white60, fontSize: 11),
      selectedLabelTextStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      unselectedIconTheme: const IconThemeData(color: Colors.white60),
      selectedIconTheme: const IconThemeData(color: Colors.white),
      destinations: [
        const NavigationRailDestination(icon: Icon(Icons.map), label: Text('Mapa')),
        NavigationRailDestination(
          icon: alerts.isEmpty ? const Icon(Icons.notifications_none) : Badge(
            label: Text('${alerts.length}', style: const TextStyle(color: Colors.white, fontSize: 9)),
            backgroundColor: Colors.red, child: const Icon(Icons.notifications_active)),
          label: const Text('Alerty'),
        ),
        NavigationRailDestination(
          icon: Semantics(
            button: true,
            label: 'Przycisk SOS — wysyła alarmowe powiadomienie',
            child: Container(width: 52, height: 52,
              decoration: BoxDecoration(color: Colors.red.shade700, shape: BoxShape.circle),
              child: const Center(child: Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)))),
          ),
          label: const Text(''),
        ),
        const NavigationRailDestination(icon: Icon(Icons.family_restroom), label: Text('Rodzina')),
        const NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profil')),
      ],
    );
  }

  Future<void> _sendSOS() async {
    await HapticFeedback.heavyImpact();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Row(children: [Icon(Icons.sos, color: Colors.red), SizedBox(width: 8), Text('SOS')]),
      content: Text(S.get('sos_confirm')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.get('cancel'))),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('WYŚLIJ SOS', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (ok != true || !mounted) return;
    await HapticFeedback.vibrate();
    await context.read<ApiService>().post('/alerts', {
      'category': 'aggression', 'title': '🆘 SOS — Potrzebuję pomocy!',
      'description': 'Automatyczny alert SOS wysłany z aplikacji be:Safe.',
      'lat': _currentPos.latitude, 'lng': _currentPos.longitude, 'duration_hours': 1,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS wysłany!'), backgroundColor: Colors.red));
      context.read<AlertProvider>().loadNearby(_currentPos, radiusM: 10000);
    }
  }


  void _openFiltersSheet(AlertProvider alertProv) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.iosCardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.85,
            minChildSize: 0.4,
            expand: false,
            builder: (_, controller) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SerenitySpacing.xl,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.iosSeparator,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Filtruj kategorie',
                        style: SerenityText.headlineHeroMobile
                            .copyWith(fontSize: 22),
                      ),
                      const Spacer(),
                      if (alertProv.activeFilters.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            alertProv.clearFilters();
                            setS(() {});
                          },
                          child: Text(
                            'Wyczyść',
                            style: SerenityText.labelButton.copyWith(
                              color: SerenityColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        for (final cat in AlertCategory.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _CategoryRow(
                              category: cat,
                              selected: alertProv.activeFilters.contains(cat),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                alertProv.toggleFilter(cat);
                                setS(() {});
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).padding.bottom + 12,
                      top: 8,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: SerenityColors.primaryContainer,
                        borderRadius: SerenityShapes.pill(),
                        child: InkWell(
                          borderRadius: SerenityShapes.pill(),
                          onTap: () => Navigator.pop(ctx),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'Pokaż ${alertProv.activeFilters.isEmpty ? "wszystkie" : "wybrane (${alertProv.activeFilters.length})"}',
                                style: SerenityText.labelButton.copyWith(
                                  fontSize: 15,
                                  color: SerenityColors.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(queryParameters: {'q': query, 'format': 'json', 'limit': '1'});
      final res = await http.get(uri, headers: {'User-Agent': 'beSafe/1.0'});
      final data = jsonDecode(res.body);
      if (data is List && data.isNotEmpty) {
        final pos = LatLng(double.parse(data[0]['lat']), double.parse(data[0]['lon']));
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
        if (mounted) context.read<AlertProvider>().loadNearby(pos, radiusM: 10000);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.get('not_found'))));
      }
    } catch (_) {}
  }

  // Monochrome map styles — Serenity Guard. Strip saturation so coral / mint /
  // navy markers pop. Light = warm-neutral greys vs #fcf8f9 surface;
  // dark = navy-tinted neutrals vs #1a2027 surface.
  static const String _lightMapStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#e6e6ea"},{"saturation":-100}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#5e5e66"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#fcf8f9"},{"weight":3}]},
    {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#dcdce0"},{"saturation":-100}]},
    {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#d6d6da"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#cfcfd4"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#f0f0f3"}]},
    {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#c5c6cb"}]},
    {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#fafafc"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c4c4cc"},{"saturation":-100}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#7a7a80"}]},
    {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#d1d1d5"},{"saturation":-100}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#cfd4d2"}]},
    {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
    {"featureType":"poi.medical","stylers":[{"visibility":"off"}]},
    {"featureType":"poi.attraction","stylers":[{"visibility":"off"}]},
    {"featureType":"transit","stylers":[{"visibility":"off"}]},
    {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#b6b6bc"}]},
    {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]}
  ]''';

  static const String _darkMapStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#232a32"},{"saturation":-100}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#9ea1a8"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#1a2027"},{"weight":3}]},
    {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#1f262d"},{"saturation":-100}]},
    {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#222931"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c343d"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1a2027"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3b454f"}]},
    {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1a2027"}]},
    {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#303841"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#11171c"},{"saturation":-100}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4a525a"}]},
    {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#1c232a"},{"saturation":-100}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#1d262b"}]},
    {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
    {"featureType":"poi.medical","stylers":[{"visibility":"off"}]},
    {"featureType":"poi.attraction","stylers":[{"visibility":"off"}]},
    {"featureType":"transit","stylers":[{"visibility":"off"}]},
    {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#3a424c"}]},
    {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]}
  ]''';
}

/// Persistent right-hand pane showing the alert list on tablets (width >= 900).
class _AlertSidePane extends StatelessWidget {
  final List<AlertModel> alerts;
  final void Function(AlertModel) onAlertTap;

  const _AlertSidePane({required this.alerts, required this.onAlertTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          color: cs.primaryContainer,
          child: Text(
            'Aktywne alerty (${alerts.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child: alerts.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.shield_outlined, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('Brak alertów w okolicy'),
                  ]),
                )
              : ListView.separated(
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: context.iosSeparator.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (_, i) {
                    final a = alerts[i];
                    return _AlertListItem(
                      alert: a,
                      onTap: () => onAlertTap(a),
                      onDetails: () => onAlertTap(a),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
/// Compact filter button shown above the map. Replaces full chip row.
/// Shows "Filtruj" or "Filtry: N" if active filters present.
class _FilterPillButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _FilterPillButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasFilters = activeCount > 0;
    return Material(
      color: hasFilters
          ? SerenityColors.primaryContainer
          : context.iosCardSurface,
      borderRadius: SerenityShapes.pill(),
      child: InkWell(
        borderRadius: SerenityShapes.pill(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: SerenityShapes.pill(),
            boxShadow: hasFilters ? null : SerenityElevation.card(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune,
                size: 18,
                color: hasFilters
                    ? SerenityColors.onPrimary
                    : context.iosLabel,
              ),
              const SizedBox(width: 8),
              Text(
                hasFilters ? 'Filtry · $activeCount' : 'Filtruj kategorie',
                style: SerenityText.labelButton.copyWith(
                  color: hasFilters
                      ? SerenityColors.onPrimary
                      : context.iosLabel,
                ),
              ),
              if (hasFilters) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: SerenityColors.glowSafeMint,
                ),
              ] else ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.expand_more,
                  size: 18,
                  color: context.iosSecondaryLabel,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Single category row in the filter bottom sheet (icon + label + checkbox).
class _CategoryRow extends StatelessWidget {
  final AlertCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? SerenityColors.primary.withValues(alpha: 0.06)
          : context.iosCardSurface,
      borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
      child: InkWell(
        borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SerenitySpacing.md,
            vertical: SerenitySpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
            border: selected
                ? Border.all(
                    color: context.iosLabel.withValues(alpha: 0.4),
                  )
                : null,
            boxShadow: selected ? null : SerenityElevation.card(),
          ),
          child: Row(
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: SerenitySpacing.md),
              Expanded(
                child: Text(
                  category.label,
                  style: SerenityText.labelButton.copyWith(
                    fontSize: 15,
                    color: context.iosLabel,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? SerenityColors.primaryContainer
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? SerenityColors.primaryContainer
                        : context.iosSeparator,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: SerenityColors.onPrimary,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wzbogacony rząd listy alertów na mapie: ikona kategorii, tytuł, opis (1-2 linie),
/// chip statusu (aktywny/wygasł), czas powstania, dystans od użytkownika, liczba
/// potwierdzeń i sprzeciwów, plus przycisk szczegółów.
class _AlertListItem extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;
  final VoidCallback onDetails;

  const _AlertListItem({
    required this.alert,
    required this.onTap,
    required this.onDetails,
  });

  String _formatAge(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'przed chwilą';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min temu';
    if (diff.inHours < 24) return '${diff.inHours} h temu';
    return '${diff.inDays} d temu';
  }

  String _formatDistance(double? m) {
    if (m == null) return '? m';
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  // F15: skrócona etykieta zweryfikowanej roli (police/firefighter/...)
  String _verifiedRoleLabel(String? role) {
    switch (role) {
      case 'police':
        return 'Policja';
      case 'firefighter':
        return 'Straż';
      case 'emt':
      case 'ambulance':
        return 'Ratownictwo';
      case 'city':
      case 'gov':
        return 'Urząd';
      case 'school':
        return 'Szkoła';
      default:
        return 'Zweryfikowany';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = alert.expiresAt.isAfter(DateTime.now());
    final confirmed = alert.confirms >= 3 && alert.confirms > alert.denies;
    final disputed = alert.denies >= 2;
    final descTrim = alert.description?.trim();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon w kółku
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? alert.category.color.withValues(alpha: 0.15)
                    : context.iosSeparator.withValues(alpha: 0.25),
              ),
              child: Icon(
                alert.category.iconData,
                color: isActive
                    ? alert.category.color
                    : SerenityColors.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Środek - title, desc, meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? SerenityColors.primary
                                : SerenityColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isActive)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.iosSeparator
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'wygasły',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: context.iosSecondaryLabel,
                            ),
                          ),
                        )
                      else if (confirmed)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SerenityColors.glowSafeMint
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified,
                                  size: 10, color: Color(0xFF1B873A)),
                              SizedBox(width: 3),
                              Text(
                                'potwierdz.',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1B873A),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (disputed)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SerenityColors.glowAlertCoral
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'sporne',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: SerenityColors.glowAlertCoral,
                            ),
                          ),
                        ),
                      // F15: chip 'Zweryfikowany' (instytucja)
                      if (alert.authorVerified)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: SerenityColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Tooltip(
                            message:
                                'Konto zweryfikowane (${_verifiedRoleLabel(alert.authorRole)})',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified,
                                    size: 10,
                                    color:
                                        SerenityColors.onSecondaryContainer),
                                const SizedBox(width: 3),
                                Text(
                                  _verifiedRoleLabel(alert.authorRole),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        SerenityColors.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // F31: chip zaufania autora
                      if (isActive && !alert.authorVerified && alert.authorReputation >= 120)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: SerenityColors.glowCalmAqua
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Tooltip(
                            message: 'Zaufany autor (wysoka reputacja)',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield,
                                    size: 10,
                                    color: context.iosLabel),
                                SizedBox(width: 3),
                                Text(
                                  'zaufany',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: context.iosLabel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (descTrim != null && descTrim.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      descTrim,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.iosSecondaryLabel,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Meta: czas, dystans, votes, kategoria
                  Wrap(
                    spacing: 10,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _metaChip(
                        icon: Icons.schedule,
                        text: _formatAge(alert.createdAt),
                      ),
                      _metaChip(
                        icon: Icons.near_me,
                        text: _formatDistance(alert.distanceM),
                      ),
                      if (alert.confirms > 0 || alert.denies > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.thumb_up,
                                size: 12, color: Color(0xFF1B873A)),
                            const SizedBox(width: 3),
                            Text('${alert.confirms}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1B873A),
                                )),
                            const SizedBox(width: 8),
                            Icon(Icons.thumb_down,
                                size: 12,
                                color: SerenityColors.glowAlertCoral),
                            const SizedBox(width: 3),
                            Text('${alert.denies}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: SerenityColors.glowAlertCoral,
                                )),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 22),
              color: context.iosSecondaryLabel,
              tooltip: 'Szczegóły alertu',
              onPressed: onDetails,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip({required IconData icon, required String text}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: SerenityColors.secondaryLabel),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: SerenityColors.secondaryLabel,
            ),
          ),
        ],
      );
}
