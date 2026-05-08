import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  LatLng _currentPos = const LatLng(52.325, 17.565);
  bool _showFilters = false;
  bool _showAlertList = false;
  final Map<AlertCategory, BitmapDescriptor> _iconCache = {};
  List<Map<String, dynamic>> _children = [];
  final Map<String, BitmapDescriptor> _childIconCache = {};

  @override
  void initState() {
    super.initState();
    // Dark status bar icons for light theme
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _initLocation();
    _precacheIcons();
    _loadFamilyChildren();
  }

  Future<void> _precacheIcons() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    for (final cat in AlertCategory.values) {
      _iconCache[cat] = await _createAlertPin();
    }
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _createAlertPin() async {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final w = (44.0 * dpr).roundToDouble();
    final h = (58.0 * dpr).roundToDouble();
    final r = w / 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final pin = Paint()..color = Colors.red.shade700..isAntiAlias = true;
    canvas.drawCircle(Offset(w / 2, r), r, pin);
    final tri = Path()..moveTo(w / 2 - r * 0.5, r + r * 0.6)..lineTo(w / 2, h)..lineTo(w / 2 + r * 0.5, r + r * 0.6)..close();
    canvas.drawPath(tri, pin);

    final tp = TextPainter(
      text: TextSpan(text: '!', style: TextStyle(fontSize: 26 * dpr, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
      textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset((w - tp.width) / 2, r - tp.height / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(w.toInt(), h.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: 44, height: 58);
  }

  Future<BitmapDescriptor> _createChildPin(String name) async {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final w = (44.0 * dpr).roundToDouble();
    final h = (58.0 * dpr).roundToDouble();
    final r = w / 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final pin = Paint()..color = Colors.green.shade700..isAntiAlias = true;
    canvas.drawCircle(Offset(w / 2, r), r, pin);
    final tri = Path()..moveTo(w / 2 - r * 0.5, r + r * 0.6)..lineTo(w / 2, h)..lineTo(w / 2 + r * 0.5, r + r * 0.6)..close();
    canvas.drawPath(tri, pin);

    // White circle for avatar area
    canvas.drawCircle(Offset(w / 2, r), r * 0.6, Paint()..color = Colors.white..isAntiAlias = true);
    // Child icon
    final icon = TextPainter(
      text: TextSpan(text: String.fromCharCode(Icons.child_care.codePoint),
        style: TextStyle(fontSize: 18 * dpr, fontFamily: Icons.child_care.fontFamily, color: Colors.green.shade700)),
      textDirection: TextDirection.ltr)..layout();
    icon.paint(canvas, Offset((w - icon.width) / 2, r - icon.height / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(w.toInt(), h.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: 44, height: 58);
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
          _childIconCache[name] = await _createChildPin(name);
        }
      }
      if (mounted) setState(() => _children = kids);
    } catch (_) {}
  }

  void _dismissOverlays() {
    if (_showAlertList || _showFilters) setState(() { _showAlertList = false; _showFilters = false; });
  }

  @override
  Widget build(BuildContext context) {
    final alertProv = context.watch<AlertProvider>();
    final alerts = alertProv.alerts;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _currentPos, zoom: 15),
          onMapCreated: (c) => _mapController = c,
          onTap: (_) => _dismissOverlays(),
          myLocationEnabled: true, myLocationButtonEnabled: false,
          zoomControlsEnabled: false, mapToolbarEnabled: false,
          markers: {
            ...alerts.map((a) => Marker(markerId: MarkerId(a.id), position: a.location,
              icon: _iconCache[a.category] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: a))))),
            ..._children.map((c) => Marker(markerId: MarkerId('child_${c['user_id']}'), position: LatLng(c['lat'], c['lng']),
              icon: _childIconCache[c['username']] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              onTap: () => _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(c['lat'], c['lng']), 17)))),
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

        // Search bar
        Positioned(top: MediaQuery.of(context).padding.top + 8, left: 12, right: 12,
          child: Column(children: [
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withValues(alpha: 0.12))]),
              child: TextField(
                decoration: InputDecoration(
                  hintText: S.get('search_location'), hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: cs.primary),
                  suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: Icon(Icons.tune, color: _showFilters ? cs.primary : Colors.grey.shade400),
                      onPressed: () => setState(() { _showFilters = !_showFilters; _showAlertList = false; })),
                    IconButton(icon: Icon(Icons.my_location, color: cs.primary),
                      onPressed: () { _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPos, 15)); alertProv.loadNearby(_currentPos, radiusM: 10000); }),
                  ]),
                  border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (q) => _searchLocation(q),
              ),
            ),
            if (_showFilters) Container(
              margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withValues(alpha: 0.12))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Filtruj', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (alertProv.activeFilters.isNotEmpty) TextButton(onPressed: alertProv.clearFilters, child: Text('Wyczyść', style: TextStyle(color: cs.primary))),
                ]),
                Wrap(spacing: 6, runSpacing: 4, children: AlertCategory.values.map((c) => FilterChip(
                  label: Text('${c.emoji} ${c.label}', style: const TextStyle(fontSize: 12)),
                  selected: alertProv.activeFilters.contains(c), selectedColor: cs.primary.withValues(alpha: 0.15), checkmarkColor: cs.primary,
                  onSelected: (_) => alertProv.toggleFilter(c), visualDensity: VisualDensity.compact,
                )).toList()),
              ]),
            ),
          ]),
        ),

        // Alert list
        if (_showAlertList) Positioned(bottom: 130, left: 16, right: 16,
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
                    onTap: () { setState(() => _showAlertList = false); _mapController?.animateCamera(CameraUpdate.newLatLngZoom(a.location, 17)); },
                  );
                },
              ),
            ),
          ),
        ),

        // "Zgłoś" button — RED
        Positioned(bottom: 8, left: 16, right: 16,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAlertScreen(position: _currentPos)));
              alertProv.loadNearby(_currentPos, radiusM: 10000);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), elevation: 4),
            icon: const Icon(Icons.warning_amber_rounded),
            label: Text(S.get('report'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),

        // Floating family avatars
        if (_children.isNotEmpty) Positioned(right: 12, top: MediaQuery.of(context).padding.top + 80,
          child: Column(mainAxisSize: MainAxisSize.min, children: _children.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(c['lat'], c['lng']), 16)),
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
      ]),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: cs.primary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        currentIndex: 0,
        onTap: (i) {
          if (i == 0) { _dismissOverlays(); return; }
          if (i == 1) { setState(() { _showAlertList = !_showAlertList; _showFilters = false; }); return; }
          if (i == 2) { _sendSOS(); return; }
          if (i == 3) Navigator.pushNamed(context, '/family');
          if (i == 4) Navigator.pushNamed(context, '/profile');
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(
            icon: alerts.isEmpty ? const Icon(Icons.notifications_none) : Badge(
              label: Text('${alerts.length}', style: const TextStyle(color: Colors.white, fontSize: 9)),
              backgroundColor: Colors.red, child: const Icon(Icons.notifications_active)),
            label: 'Alerty'),
          BottomNavigationBarItem(
            icon: Container(width: 56, height: 56,
              decoration: BoxDecoration(color: Colors.red.shade700, shape: BoxShape.circle),
              child: const Center(child: Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)))),
            label: ''),
          const BottomNavigationBarItem(icon: Icon(Icons.family_restroom), label: 'Rodzina'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Future<void> _sendSOS() async {
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
