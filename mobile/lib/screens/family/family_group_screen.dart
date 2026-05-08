import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import 'location_history_screen.dart';

class FamilyGroupScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  const FamilyGroupScreen({super.key, required this.groupId, required this.groupName});
  @override State<FamilyGroupScreen> createState() => _FamilyGroupScreenState();
}

class _FamilyGroupScreenState extends State<FamilyGroupScreen> {
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _geofences = [];
  GoogleMapController? _mapController;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final api = context.read<ApiService>();
    final m = await api.get('/family/groups/${widget.groupId}/members');
    final g = await api.get('/family/groups/${widget.groupId}/geofences');
    setState(() {
      _members = List<Map<String, dynamic>>.from(m['members'] ?? []);
      _geofences = List<Map<String, dynamic>>.from(g['geofences'] ?? []);
    });
    _fitBounds();
  }

  void _fitBounds() {
    final points = _members.where((m) => m['lat'] != null && m['lng'] != null)
        .map((m) => LatLng(m['lat'], m['lng'])).toList();
    if (points.isEmpty || _mapController == null) return;
    if (points.length == 1) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
    } else {
      var south = points.first.latitude, north = south;
      var west = points.first.longitude, east = west;
      for (final p in points) {
        if (p.latitude < south) south = p.latitude;
        if (p.latitude > north) north = p.latitude;
        if (p.longitude < west) west = p.longitude;
        if (p.longitude > east) east = p.longitude;
      }
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east)), 60,
      ));
    }
  }

  Future<void> _addGeofence() async {
    final nameCtrl = TextEditingController();
    final center = _members.where((m) => m['lat'] != null).map((m) => LatLng(m['lat'], m['lng'])).firstOrNull ?? const LatLng(52.325, 17.565);
    LatLng picked = center;

    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setDlgState) => AlertDialog(
        title: const Text('Nowa bezpieczna strefa'),
        content: SizedBox(width: double.maxFinite, height: 350, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nazwa (np. Dom, Szkoła)')),
          const SizedBox(height: 8),
          const Text('Kliknij na mapę aby wybrać lokalizację:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 15),
            onTap: (p) => setDlgState(() => picked = p),
            markers: {Marker(markerId: const MarkerId('picked'), position: picked, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen))},
            circles: {Circle(circleId: const CircleId('zone'), center: picked, radius: 200,
              fillColor: Colors.green.withValues(alpha: 0.2), strokeColor: Colors.green, strokeWidth: 2)},
            myLocationEnabled: false, zoomControlsEnabled: false, mapToolbarEnabled: false,
            style: Theme.of(context).brightness == Brightness.dark ? _darkStyle : null,
          ))),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
          TextButton(onPressed: () => Navigator.pop(ctx, {'name': nameCtrl.text, 'lat': picked.latitude, 'lng': picked.longitude}), child: const Text('Dodaj')),
        ],
      ));
    });
    if (result == null || (result['name'] as String).isEmpty) return;

    await context.read<ApiService>().post('/family/groups/${widget.groupId}/geofences', {
      'name': result['name'], 'lat': result['lat'], 'lng': result['lng'], 'radius_m': 200,
    });
    _load();
  }

  Future<void> _uploadChildAvatar(String userId) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (picked == null) return;
    // Upload as avatar for child user
    await context.read<ApiService>().multipart('/users/$userId/avatar', {}, filePath: picked.path, fileField: 'avatar');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final withLocation = _members.where((m) => m['lat'] != null && m['lng'] != null).toList();
    final fallback = withLocation.isNotEmpty ? LatLng(withLocation.first['lat'], withLocation.first['lng']) : const LatLng(52.325, 17.565);

    final markers = <Marker>{};
    for (final m in withLocation) {
      markers.add(Marker(
        markerId: MarkerId(m['user_id'] ?? ''),
        position: LatLng(m['lat'], m['lng']),
        icon: BitmapDescriptor.defaultMarkerWithHue(m['tracking_enabled'] == true ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(title: m['username'] ?? '', snippet: m['role'] == 'parent' ? 'Rodzic' : 'Dziecko'),
      ));
    }

    final circles = <Circle>{};
    for (final m in withLocation.where((m) => m['role'] == 'child')) {
      circles.add(Circle(
        circleId: CircleId('child_${m['user_id']}'),
        center: LatLng(m['lat'], m['lng']),
        radius: 150,
        fillColor: Colors.green.withValues(alpha: 0.10),
        strokeColor: Colors.green.withValues(alpha: 0.5),
        strokeWidth: 2,
      ));
    }
    for (final g in _geofences.where((g) => g['lat'] != null && g['lng'] != null)) {
      circles.add(Circle(
        circleId: CircleId(g['id'] ?? ''),
        center: LatLng((g['lat'] as num).toDouble(), (g['lng'] as num).toDouble()),
        radius: (g['radius_m'] ?? 200).toDouble(),
        fillColor: Colors.blue.withValues(alpha: 0.10),
        strokeColor: Colors.blue.withValues(alpha: 0.5),
        strokeWidth: 2,
      ));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName), actions: [
        IconButton(icon: const Icon(Icons.add_location_alt), onPressed: _addGeofence, tooltip: 'Dodaj bezpieczną strefę'),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      body: Column(children: [
        Expanded(
          flex: 3,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: fallback, zoom: 14),
            onMapCreated: (c) { _mapController = c; _fitBounds(); },
            markers: markers, circles: circles,
            myLocationEnabled: true, myLocationButtonEnabled: false,
            zoomControlsEnabled: false, mapToolbarEnabled: false,
            style: isDark ? _darkStyle : null,
          ),
        ),
        Expanded(
          flex: 2,
          child: ListView(children: [
            const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Członkowie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ..._members.map((m) {
              final avatarUrl = m['avatar_url'] as String?;
              return ListTile(
                leading: GestureDetector(
                  onTap: m['role'] == 'child' ? () => _uploadChildAvatar(m['user_id']) : null,
                  child: CircleAvatar(
                    backgroundColor: m['role'] == 'parent' ? Colors.blue.shade100 : Colors.green.shade100,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null ? Icon(m['role'] == 'parent' ? Icons.person : Icons.child_care,
                      color: m['role'] == 'parent' ? Colors.blue : Colors.green) : null,
                  ),
                ),
                title: Text(m['username'] ?? 'Nieznany'),
                subtitle: Text(m['role'] == 'parent' ? 'Rodzic' : 'Dziecko'),
              trailing: m['role'] == 'child' ? Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.history, size: 22),
                  tooltip: 'Historia tras',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => LocationHistoryScreen(
                      groupId: widget.groupId,
                      userId: m['user_id'],
                      userName: m['username'] ?? 'Dziecko',
                    ),
                  )),
                ),
                Switch(
                  value: m['tracking_enabled'] ?? true,
                  onChanged: (v) async {
                    await context.read<ApiService>().patch(
                      '/family/groups/${widget.groupId}/members/${m['user_id']}',
                      {'tracking_enabled': v},
                    );
                    _load();
                  },
                ),
              ]) : null,
            );
            }),
            if (_geofences.isNotEmpty) ...[
              const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('Bezpieczne strefy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ..._geofences.map((g) => ListTile(
                leading: const Icon(Icons.fence, color: Colors.green),
                title: Text(g['name'] ?? ''),
                subtitle: Text('Promień: ${g['radius_m']}m'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    await context.read<ApiService>().delete('/family/groups/${widget.groupId}/geofences/${g['id']}');
                    _load();
                  },
                ),
              )),
            ],
          ]),
        ),
      ]),
    );
  }

  static const String _darkStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#212121"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
    {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
    {"featureType":"poi.business","stylers":[{"visibility":"off"}]}
  ]''';
}
