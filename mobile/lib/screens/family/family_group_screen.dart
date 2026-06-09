import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import 'location_history_screen.dart';
import 'add_geofence_screen.dart';
import 'safe_routes_screen.dart';
import 'family_chat_screen.dart';
import 'family_planner_screen.dart';
import '../pets/pets_screen.dart';

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
    final center = _members
            .where((m) => m['lat'] != null)
            .map((m) => LatLng(m['lat'], m['lng']))
            .firstOrNull ??
        const LatLng(52.325, 17.565);
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddGeofenceScreen(
          groupId: widget.groupId,
          initialCenter: center,
        ),
      ),
    );
    if (added == true) _load();
  }

  Future<void> _uploadChildAvatar(String userId) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (picked == null) return;
    // Upload as avatar for child user
    await context.read<ApiService>().multipart('/users/$userId/avatar', {}, filePath: picked.path, fileField: 'avatar');
    _load();
  }

  // F20: Toggle school hours silent mode (cichy pn-pt 8-15)
  Future<void> _toggleSchoolMode(Map<String, dynamic> m) async {
    final current = m['school_hours_silent'] == true;
    final name = m['username'] ?? 'dziecka';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(current ? 'Wyłączyć tryb szkolny?' : 'Włączyć tryb szkolny?'),
        content: Text(current
            ? 'Powiadomienia dla $name znów będą głośne we wszystkie godziny.'
            : 'W godzinach 8:00–15:00 w dni szkolne (pn-pt) powiadomienia dla $name będą wyciszone (priorytet niski, brak dźwięku). Alerty SOS i zagrożenia nadal dotrą.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: current ? SerenityColors.error : SerenityColors.onSecondaryContainer,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(current ? 'Wyłącz' : 'Włącz'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    await context.read<ApiService>().patch(
      '/family/groups/${widget.groupId}/members/${m['user_id']}',
      {'school_hours_silent': !current},
    );
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
      backgroundColor: context.iosBackground,
      appBar: AppBar(
        backgroundColor: context.iosBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.iosLabel),
        title: Text(widget.groupName, style: SerenityText.headlineHeroMobile), actions: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: 'Czat rodzinny',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => FamilyChatScreen(groupId: widget.groupId, groupName: widget.groupName),
          )),
        ),
        IconButton(
          icon: const Icon(Icons.event_note_outlined),
          tooltip: 'Planner rodzinny',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => FamilyPlannerScreen(groupId: widget.groupId, groupName: widget.groupName),
          )),
        ),
        IconButton(
          icon: const Icon(Icons.pets),
          tooltip: 'Zwierzaki',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PetsScreen(groupId: widget.groupId, groupName: widget.groupName),
          )),
        ),
        IconButton(icon: const Icon(Icons.add_location_alt), onPressed: _addGeofence, tooltip: 'Dodaj bezpieczną strefę'),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Odśwież listę'),
      ]),
      body: Column(children: [
        SizedBox(
          height: 240,
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
                subtitle: Text(
                  m['role'] == 'parent'
                      ? 'Rodzic'
                      : (m['school_hours_silent'] == true
                          ? 'Dziecko · 🎒 Tryb szkolny'
                          : 'Dziecko'),
                ),
              trailing: m['role'] == 'child' ? Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: Icon(
                    Icons.school_outlined,
                    size: 22,
                    color: m['school_hours_silent'] == true
                        ? SerenityColors.onSecondaryContainer
                        : null,
                  ),
                  tooltip: m['school_hours_silent'] == true
                      ? 'Tryb szkolny: WŁĄCZONY (cichy pn-pt 8-15)'
                      : 'Tryb szkolny: wyłączony',
                  onPressed: () => _toggleSchoolMode(m),
                ),
                IconButton(
                  icon: const Icon(Icons.route_outlined, size: 22),
                  tooltip: 'Bezpieczne trasy',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SafeRoutesScreen(
                      groupId: widget.groupId,
                      userId: m['user_id'],
                      userName: m['username'] ?? 'Dziecko',
                    ),
                  )),
                ),
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
                    // Confirm before disabling tracking (safety-critical for child)
                    if (!v) {
                      final name = m['username'] ?? 'tego dziecka';
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Wyłączyć śledzenie?'),
                          content: Text(
                            'Stracisz wgląd w lokalizację $name. Nie otrzymasz '
                            'powiadomień gdy opuści strefę bezpieczeństwa.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Anuluj'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: SerenityColors.error,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Wyłącz'),
                            ),
                          ],
                        ),
                      );
                      if (ok != true) return;
                    }
                    if (!mounted) return;
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
                  tooltip: 'Usuń strefę',
                  onPressed: () async {
                    final name = g['name'] ?? 'tę strefę';
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Usunąć strefę?'),
                        content: Text(
                          'Strefa «$name» zostanie usunięta. Nie otrzymasz '
                          'powiadomień gdy ktoś z rodziny wejdzie lub opuści ten obszar.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Anuluj'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: SerenityColors.error,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Usuń'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    if (!mounted) return;
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
