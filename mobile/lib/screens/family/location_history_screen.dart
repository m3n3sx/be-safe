import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

class LocationHistoryScreen extends StatefulWidget {
  final String groupId;
  final String userId;
  final String userName;
  const LocationHistoryScreen({super.key, required this.groupId, required this.userId, required this.userName});
  @override State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  List<Map<String, dynamic>> _points = [];
  GoogleMapController? _mapController;
  bool _loading = true;
  DateTime _date = DateTime.now();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final from = DateTime(_date.year, _date.month, _date.day);
    final to = from.add(const Duration(days: 1));
    try {
      final res = await context.read<ApiService>().get(
        '/family/groups/${widget.groupId}/members/${widget.userId}/location/history',
        {'from': from.toIso8601String(), 'to': to.toIso8601String(), 'limit': '500'},
      );
      if (mounted) setState(() {
        _points = List<Map<String, dynamic>>.from(res['history'] ?? []);
        _loading = false;
      });
      _fitBounds();
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _fitBounds() {
    if (_points.isEmpty || _mapController == null) return;
    double minLat = _points[0]['lat'], maxLat = minLat;
    double minLng = _points[0]['lng'], maxLng = minLng;
    for (final p in _points) {
      if (p['lat'] < minLat) minLat = p['lat'];
      if (p['lat'] > maxLat) maxLat = p['lat'];
      if (p['lng'] < minLng) minLng = p['lng'];
      if (p['lng'] > maxLng) maxLng = p['lng'];
    }
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 50,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: context.iosBackground,
      appBar: AppBar(
        backgroundColor: context.iosBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.iosLabel),
        title: Text(
          'Trasa: ${widget.userName}',
          style: SerenityText.headlineHeroMobile,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            color: context.iosLabel,
            tooltip: 'Wybierz datę',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (picked != null) { setState(() => _date = picked); _load(); }
            },
          ),
        ],
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: cs.primaryContainer,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('Punkty', '${_points.length}'),
            _stat('Data', '${_date.day}/${_date.month}/${_date.year}'),
          ]),
        ),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _points.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.location_off, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Brak danych dla tej daty'),
                ]))
              : Stack(children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_points.first['lat'], _points.first['lng']),
                      zoom: 14,
                    ),
                    onMapCreated: (c) { _mapController = c; _fitBounds(); },
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        points: _points.map((p) => LatLng(p['lat'], p['lng'])).toList(),
                        color: cs.primary,
                        width: 4,
                      ),
                    },
                    markers: {
                      if (_points.isNotEmpty) Marker(
                        markerId: const MarkerId('start'),
                        position: LatLng(_points.last['lat'], _points.last['lng']),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        infoWindow: const InfoWindow(title: 'Start'),
                      ),
                      if (_points.length > 1) Marker(
                        markerId: const MarkerId('end'),
                        position: LatLng(_points.first['lat'], _points.first['lng']),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        infoWindow: const InfoWindow(title: 'Koniec'),
                      ),
                    },
                    myLocationEnabled: false, zoomControlsEnabled: false, mapToolbarEnabled: false,
                    style: isDark ? _darkStyle : null,
                  ),
                ]),
        ),
      ]),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(fontSize: 11)),
  ]);

  static const _darkStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#212121"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}
  ]''';
}
