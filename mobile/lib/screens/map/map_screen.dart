import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart' as gcm;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../models/alert.dart';
import '../../providers/alert_provider.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/i18n.dart';
import '../alerts/create_alert_screen.dart';
import '../alerts/alert_detail_screen.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/pill_nav_bar.dart';
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
  final Map<AlertCategory, BitmapDescriptor> _iconCache = {};
  List<Map<String, dynamic>> _children = [];
  final Map<String, BitmapDescriptor> _childIconCache = {};

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
    _loadFamilyChildren();
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
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(cluster.location, 15));
        },
      );
    }
    // Single item → render as alert pin with category color.
    final a = cluster.items.first.alert;
    return Marker(
      markerId: MarkerId(a.id),
      position: a.location,
      icon: _iconCache[a.category] ?? await MapMarkers.alertPin(a.category),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(context, MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: a)));
      },
    );
  }

  Future<void> _precacheIcons() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    for (final cat in AlertCategory.values) {
      _iconCache[cat] = await MapMarkers.alertPin(cat);
    }
    if (mounted) setState(() {});
  }

  Future<void> _initLocation() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() => _currentPos = LatLng(pos.latitude, pos.longitude));
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPos, 15));
      context.read<ApiService>().post('/users/me/location', {'lat': pos.latitude, 'lng': pos.longitude}).catchError((_) {});
    }
    if (mounted) context.read<AlertProvider>().loadNearby(_currentPos, radiusM: 10000);
  }

  Future<void> _loadFamilyChildren() async {
    try {
      final api = context.read<ApiService>();
      final res = await api.get('/family/groups');
      final kids = <Map<String, dynamic>>[];
      for (final g in (res['groups'] as List? ?? [])) {
        final m = await api.get('/family/groups/${g['id']}/members');
        for (final member in (m['members'] as List? ?? [])) {
          if (member['role'] == 'child' && member['lat'] != null) kids.add(member);
        }
      }
      for (final k in kids) {
        final name = k['username'] ?? '?';
        if (!_childIconCache.containsKey(name)) {
          _childIconCache[name] = await MapMarkers.childPin(name);
        }
      }
      if (mounted) setState(() => _children = kids);
    } catch (_) {}
  }

  void _dismissOverlays() {
    if (_showAlertList || _showFilters) setState(() { _showAlertList = false; _showFilters = false; });
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
              ..._children.map((c) => Marker(markerId: MarkerId('child_${c['user_id']}'), position: LatLng(c['lat'], c['lng']),
                icon: _childIconCache[c['username']] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(c['lat'], c['lng']), 17));
                })),
            },
            circles: {
              ...alerts.map((a) => Circle(circleId: CircleId(a.id), center: a.location, radius: a.radiusM.toDouble(),
                fillColor: Colors.red.withValues(alpha: 0.12), strokeColor: Colors.redAccent.withValues(alpha: 0.5), strokeWidth: 1)),
              ..._children.map((c) => Circle(circleId: CircleId('child_${c['user_id']}'), center: LatLng(c['lat'], c['lng']),
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
                color: SerenityColors.surfaceContainerLowest,
                borderRadius: SerenityShapes.pill(),
                boxShadow: SerenityElevation.card(),
              ),
              child: TextField(
                style: SerenityText.bodyMain.copyWith(color: SerenityColors.primary),
                decoration: InputDecoration(
                  hintText: 'Szukaj adresu lub miejsca',
                  hintStyle: SerenityText.bodyMain.copyWith(color: SerenityColors.onSurfaceVariant),
                  prefixIcon: const Icon(Icons.search, color: SerenityColors.primary, size: 22),
                  suffixIcon: Semantics(
                    label: 'Wycentruj mapę na moją lokalizację',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.my_location, color: SerenityColors.primary, size: 22),
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
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black.withValues(alpha: 0.15))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(16),
              child: ListView.separated(shrinkWrap: true, padding: EdgeInsets.zero, itemCount: alerts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final a = alerts[i];
                  return ListTile(dense: true,
                    leading: Icon(a.category.iconData, color: a.category.color, size: 28),
                    title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${a.category.label} • ${a.distanceM?.round() ?? '?'}m', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showAlertList = false);
                      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(a.location, 17));
                    },
                  );
                },
              ),
            ),
          ),
        ),

        // "Zgłoś" pill button (Serenity style: primaryContainer navy + white text)
        Positioned(bottom: 104, right: 16,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            // Location button (pill)
            Container(
              decoration: BoxDecoration(
                color: SerenityColors.primaryContainer,
                borderRadius: SerenityShapes.pill(),
                boxShadow: SerenityElevation.floating(),
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location, color: SerenityColors.onPrimary),
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

        // Bottom info bar — "X aktywnych alertów w twojej okolicy"
        if (alerts.isNotEmpty) Positioned(bottom: 8, left: 16, right: 16,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showAlertList = !_showAlertList);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SerenityColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: SerenityElevation.card(),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: SerenityColors.tertiaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_active, color: SerenityColors.onTertiaryContainer, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  '${alerts.length} aktywn${alerts.length == 1 ? 'y alert' : (alerts.length < 5 ? 'e alerty' : 'ych alertów')} w twojej okolicy',
                  style: SerenityText.labelButton.copyWith(fontSize: 15, color: SerenityColors.primary),
                )),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: SerenityColors.tertiaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('${alerts.length}',
                    style: SerenityText.labelCaps.copyWith(color: SerenityColors.onTertiaryContainer, fontSize: 12))),
                ),
              ]),
            ),
          ),
        ),

        // Floating family avatars
        if (_children.isNotEmpty) Positioned(right: 12, top: MediaQuery.of(context).padding.top + 80,
          child: Column(mainAxisSize: MainAxisSize.min, children: _children.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(c['lat'], c['lng']), 16));
              },
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 46, height: 46,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                    border: Border.all(color: Colors.green, width: 2.5),
                    boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black.withValues(alpha: 0.15))]),
                  child: const Center(child: Icon(Icons.child_care, color: Colors.green, size: 24))),
                const SizedBox(height: 2),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black.withValues(alpha: 0.1))]),
                  child: Text(c['username'] ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
              ]),
            ),
          )).toList()),
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
      bottomNavigationBar: isTablet ? null : _buildBottomNav(cs, alerts),
    );
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

  Widget _buildBottomNav(ColorScheme cs, List<AlertModel> alerts) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 8,
      ),
      child: PillNavBar(
        currentIndex: 0, // Map is active
        items: const [
          PillNavItem(
            icon: Icons.map_outlined,
            activeIcon: Icons.map,
            label: 'Mapa',
          ),
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
          PillNavItem(
            icon: Icons.sos_outlined,
            activeIcon: Icons.sos,
            label: 'SOS',
          ),
        ],
        onTap: (i) {
          HapticFeedback.selectionClick();
          switch (i) {
            case 0:
              _dismissOverlays();
              break;
            case 1:
              Navigator.pop(context);
              break;
            case 2:
              Navigator.pushNamed(context, '/family');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
            case 4:
              Navigator.pushNamed(context, '/sos');
              break;
          }
        },
      ),
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
      backgroundColor: SerenityColors.surfaceContainerLowest,
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
                      color: SerenityColors.outlineVariant,
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

  static const String _lightMapStyle = '''[
    {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
    {"featureType":"poi","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#e5f5e0"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#f5d142"}]},
    {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#e8c430"}]},
    {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
    {"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#f0f0f0"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#7b7b7b"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9e8f5"}]},
    {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},
    {"featureType":"transit","stylers":[{"visibility":"off"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"},{"weight":3}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#616161"}]}
  ]''';

  static const String _darkMapStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#212121"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
    {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
    {"featureType":"poi.business","stylers":[{"visibility":"off"}]}
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
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final a = alerts[i];
                    return ListTile(
                      leading: Icon(a.category.iconData, color: a.category.color, size: 32),
                      title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${a.category.label} • ${a.distanceM?.round() ?? '?'}m',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      onTap: () => onAlertTap(a),
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
          : SerenityColors.surfaceContainerLowest,
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
                    : SerenityColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                hasFilters ? 'Filtry · $activeCount' : 'Filtruj kategorie',
                style: SerenityText.labelButton.copyWith(
                  color: hasFilters
                      ? SerenityColors.onPrimary
                      : SerenityColors.primary,
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
                  color: SerenityColors.onSurfaceVariant,
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
          : SerenityColors.surfaceContainerLowest,
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
                    color: SerenityColors.primary.withValues(alpha: 0.4),
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
                    color: SerenityColors.primary,
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
                        : SerenityColors.outlineVariant,
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
