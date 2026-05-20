import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import 'draw_safe_route_screen.dart';

/// Lista bezpiecznych tras danego dziecka w grupie rodzinnej.
/// Tylko rodzice mogą dodawać/usuwać/edytować - klient pokazuje akcje warunkowo.
class SafeRoutesScreen extends StatefulWidget {
  final String groupId;
  final String userId;
  final String userName;
  final bool isParent;

  const SafeRoutesScreen({
    super.key,
    required this.groupId,
    required this.userId,
    required this.userName,
    this.isParent = true,
  });

  @override
  State<SafeRoutesScreen> createState() => _SafeRoutesScreenState();
}

class _SafeRoutesScreenState extends State<SafeRoutesScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool _loading = true;
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
      final res = await api.get(
        '/family/groups/${widget.groupId}/members/${widget.userId}/safe-routes',
      );
      final list = List<Map<String, dynamic>>.from(res['routes'] ?? []);
      if (!mounted) return;
      setState(() {
        _routes = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Nie udało się załadować tras.';
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DrawSafeRouteScreen(
          groupId: widget.groupId,
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
    if (added == true) _load();
  }

  Future<void> _toggle(Map<String, dynamic> r) async {
    final newValue = !(r['is_active'] == true);
    try {
      final api = context.read<ApiService>();
      await api.patch(
        '/family/groups/${widget.groupId}/members/${widget.userId}/safe-routes/${r['id']}',
        {'is_active': newValue},
      );
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się zmienić stanu trasy.')),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> r) async {
    final name = r['name'] ?? 'tę trasę';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć trasę?'),
        content: Text(
          'Trasa «$name» zostanie usunięta. Nie otrzymasz '
          'powiadomień gdy ${widget.userName} z niej zboczy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: SerenityColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    try {
      final api = context.read<ApiService>();
      await api.delete(
        '/family/groups/${widget.groupId}/members/${widget.userId}/safe-routes/${r['id']}',
      );
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się usunąć trasy.')),
      );
    }
  }

  void _preview(Map<String, dynamic> r) {
    final points = _extractPoints(r);
    if (points.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoutePreviewSheet(
        name: r['name'] ?? 'Trasa',
        thresholdM: (r['threshold_m'] as num?)?.toInt() ?? 100,
        points: points,
        groupId: widget.groupId,
        userId: widget.userId,
        routeId: r['id'] as String?,
      ),
    );
  }

  List<LatLng> _extractPoints(Map<String, dynamic> r) {
    final raw = r['points'];
    if (raw is! List) return const [];
    final out = <LatLng>[];
    for (final p in raw) {
      if (p is List && p.length >= 2 && p[0] is num && p[1] is num) {
        out.add(LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SerenityColors.surfaceBright,
      appBar: AppBar(
        backgroundColor: SerenityColors.surfaceBright,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Wróć',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bezpieczne trasy',
          style: TextStyle(
            color: SerenityColors.primaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież listę',
            onPressed: _load,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Text(
                widget.userName.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: SerenityColors.primaryContainer.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Zdefiniuj trasę którą dziecko pokonuje codziennie (np. do szkoły). '
                'Otrzymasz powiadomienie gdy z niej zboczy.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: SerenityColors.primaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: widget.isParent
          ? FloatingActionButton.extended(
              onPressed: _add,
              backgroundColor: SerenityColors.primaryContainer,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.route_outlined),
              label: const Text('Dodaj trasę'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Spróbuj ponownie')),
          ],
        ),
      );
    }
    if (_routes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.route_outlined,
                size: 64,
                color: SerenityColors.primaryContainer.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Brak zapisanych tras',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SerenityColors.primaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isParent
                    ? 'Dodaj pierwszą trasę aby otrzymywać powiadomienia gdy '
                        '${widget.userName} z niej zboczy.'
                    : 'Rodzic nie dodał jeszcze tras.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: SerenityColors.primaryContainer.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _routes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildTile(_routes[i]),
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> r) {
    final isActive = r['is_active'] == true;
    final threshold = (r['threshold_m'] as num?)?.toInt() ?? 100;
    final points = _extractPoints(r);
    return Container(
      decoration: BoxDecoration(
        color: SerenityColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? SerenityColors.secondaryContainer.withValues(alpha: 0.4)
              : SerenityColors.primaryContainer.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: SerenityColors.primaryContainer.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _preview(r),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isActive
                          ? SerenityColors.secondaryContainer
                          : SerenityColors.primaryContainer)
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.route_outlined,
                  size: 22,
                  color: isActive
                      ? const Color(0xFF1B873A)
                      : SerenityColors.primaryContainer.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['name'] ?? 'Trasa',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: SerenityColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${points.length} punktów · korytarz ${threshold} m'
                      '${isActive ? '' : ' · wyłączona'}',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            SerenityColors.primaryContainer.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isParent) ...[
                Switch(
                  value: isActive,
                  onChanged: (_) => _toggle(r),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 22),
                  tooltip: 'Usuń trasę',
                  color: SerenityColors.error,
                  onPressed: () => _delete(r),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePreviewSheet extends StatefulWidget {
  final String name;
  final int thresholdM;
  final List<LatLng> points;
  final String? groupId;
  final String? userId;
  final String? routeId;

  const _RoutePreviewSheet({
    required this.name,
    required this.thresholdM,
    required this.points,
    this.groupId,
    this.userId,
    this.routeId,
  });

  @override
  State<_RoutePreviewSheet> createState() => _RoutePreviewSheetState();
}

class _RoutePreviewSheetState extends State<_RoutePreviewSheet> {
  GoogleMapController? _ctrl;
  int? _alertsNearCount;
  bool _loadingAlerts = false;

  @override
  void initState() {
    super.initState();
    _loadAlertsNear();
  }

  Future<void> _loadAlertsNear() async {
    if (widget.groupId == null || widget.userId == null || widget.routeId == null) return;
    if (_loadingAlerts) return;
    setState(() => _loadingAlerts = true);
    try {
      final api = context.read<ApiService>();
      final res = await api.get(
        '/family/groups/${widget.groupId}/members/${widget.userId}/safe-routes/${widget.routeId}/alerts-near?buffer_m=200',
      );
      final alerts = (res['alerts'] as List?) ?? const [];
      if (mounted) setState(() => _alertsNearCount = alerts.length);
    } catch (_) {
      if (mounted) setState(() => _alertsNearCount = null);
    } finally {
      if (mounted) setState(() => _loadingAlerts = false);
    }
  }

  void _fit() {
    if (_ctrl == null || widget.points.isEmpty) return;
    if (widget.points.length == 1) {
      _ctrl!.animateCamera(
        CameraUpdate.newLatLngZoom(widget.points.first, 15),
      );
      return;
    }
    var south = widget.points.first.latitude;
    var north = south;
    var west = widget.points.first.longitude;
    var east = west;
    for (final p in widget.points) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }
    _ctrl!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(south, west),
        northeast: LatLng(north, east),
      ),
      60,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          padding: EdgeInsets.only(bottom: bottom),
          decoration: BoxDecoration(
            color: SerenityColors.surfaceBright,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SerenityColors.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: SerenityColors.primaryContainer,
                            ),
                          ),
                          Text(
                            '${widget.points.length} punktów · korytarz ${widget.thresholdM} m',
                            style: TextStyle(
                              fontSize: 12,
                              color: SerenityColors.primaryContainer
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Zamknij',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (_alertsNearCount != null && _alertsNearCount! > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: SerenityColors.glowAlertCoral.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: SerenityColors.glowAlertCoral.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: SerenityColors.glowAlertCoral, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Uwaga: ${_alertsNearCount} aktywnych alertów blisko trasy',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: SerenityColors.primaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24)),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.points.isNotEmpty
                          ? widget.points.first
                          : const LatLng(52.325, 17.565),
                      zoom: 14,
                    ),
                    onMapCreated: (c) {
                      _ctrl = c;
                      _fit();
                    },
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('preview'),
                        points: widget.points,
                        color: SerenityColors.primaryContainer,
                        width: 5,
                      ),
                    },
                    markers: widget.points.isNotEmpty
                        ? {
                            Marker(
                              markerId: const MarkerId('start'),
                              position: widget.points.first,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueGreen),
                              infoWindow:
                                  const InfoWindow(title: 'Początek trasy'),
                            ),
                            Marker(
                              markerId: const MarkerId('end'),
                              position: widget.points.last,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueRed),
                              infoWindow:
                                  const InfoWindow(title: 'Koniec trasy'),
                            ),
                          }
                        : <Marker>{},
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false,
                    scrollGesturesEnabled: true,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
