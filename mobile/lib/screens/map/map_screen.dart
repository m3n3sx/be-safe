import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final _locationService = LocationService();
  LatLng _currentPos = const LatLng(52.325, 17.565); // Września
  bool _showFilters = false;
  int _navIndex = 0;
  bool _showAlertList = false;
  final Map<AlertCategory, BitmapDescriptor> _iconCache = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
    _precacheIcons();
    _loadFamilyChildren();
  }

  Future<void> _precacheIcons() async {
    // Wait for context to be ready
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    for (final cat in AlertCategory.values) {
      _iconCache[cat] = await _createCategoryIcon(cat);
    }
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _createCategoryIcon(AlertCategory cat) async {
    return _createPinIcon(cat.emoji, Colors.red.shade700);
  }

  Future<BitmapDescriptor> _createPinIcon(String emoji, Color pinColor) async {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final w = (48.0 * dpr).roundToDouble();
    final h = (64.0 * dpr).roundToDouble();
    final r = w / 2; // radius of top circle
    final cy = r; // center Y of circle
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Pin: full circle on top + triangle pointer at bottom
    final path = Path()
      ..addArc(Rect.fromCircle(center: Offset(w / 2, cy), radius: r), 3.14 * 0.85, 3.14 * 1.3)
      ..lineTo(w / 2, h)
      ..lineTo(w / 2 - r * 0.55, cy + r * 0.78)
      ..close();
    canvas.drawPath(path, Paint()..color = pinColor..isAntiAlias = true);
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 1.5 * dpr..isAntiAlias = true);

    // White inner circle
    canvas.drawCircle(Offset(w / 2, cy), r * 0.62, Paint()..color = Colors.white..isAntiAlias = true);

    // Emoji
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: 18 * dpr)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((w - tp.width) / 2, cy - tp.height / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(w.toInt(), h.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: 48, height: 64);
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

  Set<Marker> _buildMarkers(List<AlertModel> alerts) {
    return alerts.map((a) => Marker(
      markerId: MarkerId(a.id),
      position: a.location,
      icon: _iconCache[a.category] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: a))),
    )).toSet();
  }

  Set<Circle> _buildCircles(List<AlertModel> alerts) {
    return alerts.map((a) => Circle(
      circleId: CircleId(a.id),
      center: a.location,
      radius: a.radiusM.toDouble(),
      fillColor: Colors.red.withValues(alpha: 0.12),
      strokeColor: Colors.redAccent.withValues(alpha: 0.5),
      strokeWidth: 1,
    )).toSet();
  }

  List<Map<String, dynamic>> _children = [];
  final Map<String, BitmapDescriptor> _childIconCache = {};

  Future<void> _loadFamilyChildren() async {
    try {
      final api = context.read<ApiService>();
      final res = await api.get('/family/groups');
      final groups = res['groups'] as List? ?? [];
      final kids = <Map<String, dynamic>>[];
      for (final g in groups) {
        final m = await api.get('/family/groups/${g['id']}/members');
        for (final member in (m['members'] as List? ?? [])) {
          if (member['role'] == 'child' && member['lat'] != null) kids.add(member);
        }
      }
      for (final k in kids) {
        final name = k['username'] ?? '?';
        if (!_childIconCache.containsKey(name)) {
          _childIconCache[name] = await _createChildIcon(name);
        }
      }
      if (mounted) setState(() => _children = kids);
    } catch (_) {}
  }

  Future<BitmapDescriptor> _createChildIcon(String name) async {
    return _createPinIcon('💚', Colors.green.shade700);
  }

  @override
  Widget build(BuildContext context) {
    final alertProv = context.watch<AlertProvider>();
    final alerts = alertProv.alerts;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final onSurface = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final userDotColor = isDark ? Colors.cyanAccent : Colors.blue;

    return Scaffold(
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _currentPos, zoom: 15),
          onMapCreated: (c) => _mapController = c,
          myLocationEnabled: true, myLocationButtonEnabled: false,
          zoomControlsEnabled: false, mapToolbarEnabled: false,
          markers: {
            ..._buildMarkers(alerts),
            ..._children.map((c) => Marker(
              markerId: MarkerId('child_${c['user_id']}'),
              position: LatLng(c['lat'], c['lng']),
              icon: _childIconCache[c['username']] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            )),
          },
          circles: {
            ..._buildCircles(alerts),
            ..._children.map((c) => Circle(
              circleId: CircleId('child_${c['user_id']}'),
              center: LatLng(c['lat'], c['lng']),
              radius: 150,
              fillColor: Colors.green.withValues(alpha: 0.10),
              strokeColor: Colors.green.withValues(alpha: 0.5),
              strokeWidth: 2,
            )),
          },
          style: isDark ? _darkMapStyle : _lightMapStyle,
          padding: const EdgeInsets.only(bottom: 60),
        ),

        // Search bar
        Positioned(top: MediaQuery.of(context).padding.top + 8, left: 12, right: 12,
          child: Column(children: [
            Row(children: [
              Expanded(child: Container(
                decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1))]),
                child: TextField(
                  style: TextStyle(color: onSurface),
                  decoration: InputDecoration(
                    hintText: S.get('search_location'), hintStyle: TextStyle(color: hintColor),
                    prefixIcon: Icon(Icons.search, color: hintColor),
                    suffixIcon: IconButton(icon: Icon(Icons.tune, color: _showFilters ? Colors.red : hintColor),
                      onPressed: () => setState(() => _showFilters = !_showFilters)),
                    border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: (q) => _searchLocation(q),
                ),
              )),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(color: surfaceColor, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1))]),
                child: IconButton(icon: Icon(Icons.my_location, color: userDotColor),
                  onPressed: () { _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPos, 15)); alertProv.loadNearby(_currentPos, radiusM: 10000); }),
              ),
            ]),
            if (_showFilters) Container(
              margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(S.get('filter_categories'), style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
                  if (alertProv.activeFilters.isNotEmpty) TextButton(onPressed: alertProv.clearFilters, child: Text(S.get('clear'))),
                ]),
                Wrap(spacing: 6, runSpacing: 4, children: AlertCategory.values.map((c) => FilterChip(
                  label: Text('${c.emoji} ${c.label}', style: const TextStyle(fontSize: 12)),
                  selected: alertProv.activeFilters.contains(c),
                  onSelected: (_) => alertProv.toggleFilter(c), visualDensity: VisualDensity.compact,
                )).toList()),
              ]),
            ),
          ]),
        ),

        // Alert list overlay
        if (_showAlertList) Positioned(bottom: 70, left: 16, right: 16,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(16),
              child: ListView.separated(
                shrinkWrap: true, padding: EdgeInsets.zero,
                itemCount: alerts.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                itemBuilder: (_, i) {
                  final a = alerts[i];
                  return ListTile(
                    dense: true,
                    leading: Icon(a.category.iconData, color: a.category.color, size: 28),
                    title: Text(a.title, style: TextStyle(fontWeight: FontWeight.w600, color: onSurface, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${a.category.label} • ${a.distanceM?.round() ?? '?'}m', style: TextStyle(color: hintColor, fontSize: 12)),
                    trailing: Icon(Icons.near_me, size: 16, color: hintColor),
                    onTap: () {
                      setState(() => _showAlertList = false);
                      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(a.location, 17));
                    },
                  );
                },
              ),
            ),
          ),
        ),

        // "Zgłoś" button — full width at bottom of map
        Positioned(bottom: 8, left: 16, right: 16,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAlertScreen(position: _currentPos)));
              alertProv.loadNearby(_currentPos, radiusM: 10000);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            icon: const Icon(Icons.warning_amber, color: Colors.white),
            label: Text(S.get('report'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),

        if (alertProv.loading) const Positioned(top: 120, left: 0, right: 0, child: Center(child: CircularProgressIndicator())),
      ]),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, currentIndex: _navIndex,
        onTap: (i) {
          if (i == 0) { setState(() => _navIndex = 0); return; }
          if (i == 1) { setState(() => _showAlertList = !_showAlertList); return; }
          // i == 2 is SOS (handled separately)
          if (i == 3) { setState(() => _navIndex = 0); Navigator.pushNamed(context, '/family').then((_) { if (mounted) setState(() => _navIndex = 0); }); return; }
          if (i == 4) { setState(() => _navIndex = 0); Navigator.pushNamed(context, '/profile').then((_) { if (mounted) setState(() => _navIndex = 0); }); return; }
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.map), label: S.get('map')),
          BottomNavigationBarItem(
            icon: alerts.isEmpty
              ? const Icon(Icons.notifications_none)
              : Badge(
                  label: Text('${alerts.length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.notifications_active, color: Colors.redAccent),
                ),
            label: 'Alerty',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () => _sendSOS(),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: Colors.red.shade900, shape: BoxShape.circle),
                child: const Center(child: Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.family_restroom), label: S.get('family')),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: S.get('profile')),
        ],
      ),
    );
  }

  Future<void> _sendSOS() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Row(children: [const Icon(Icons.sos, color: Colors.red), const SizedBox(width: 8), Text(S.get('sos'))]),
      content: Text(S.get('sos_confirm')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.get('cancel'))),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('WYŚLIJ SOS', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (ok != true || !mounted) return;
    await context.read<ApiService>().post('/alerts', {
      'category': 'aggression', 'title': '🆘 SOS — Potrzebuję pomocy!',
      'description': 'Automatyczny alert SOS wysłany z aplikacji be:Safe.',
      'lat': _currentPos.latitude, 'lng': _currentPos.longitude, 'duration_hours': 1,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.get('sos_sent')), backgroundColor: Colors.red));
      context.read<AlertProvider>().loadNearby(_currentPos, radiusM: 10000);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(queryParameters: {'q': query, 'format': 'json', 'limit': '1'});
      final res = await http.get(uri, headers: {'User-Agent': 'beSafe/1.0'});
      final data = jsonDecode(res.body);
      if (data is List && data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lng = double.parse(data[0]['lon']);
        final pos = LatLng(lat, lng);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
        if (mounted) context.read<AlertProvider>().loadNearby(pos, radiusM: 10000);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.get('not_found'))));
      }
    } catch (_) {}
  }

  static const String _lightMapStyle = '''[
    {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
    {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
    {"featureType":"poi","elementType":"labels.icon","stylers":[{"saturation":-100},{"lightness":50}]},
    {"featureType":"transit","elementType":"labels.icon","stylers":[{"saturation":-70}]}
  ]''';

  static const String _darkMapStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#212121"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
    {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
    {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
    {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#555555"}]},
    {"featureType":"poi","elementType":"labels.icon","stylers":[{"saturation":-100},{"lightness":-20}]}
  ]''';
}
