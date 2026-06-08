// F03: Eskorta / Follow Me — wybór watchera, monitorowanie ETA, "DOTARŁEM"
import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/map_style.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

class EscortScreen extends StatefulWidget {
  const EscortScreen({super.key});
  @override
  State<EscortScreen> createState() => _EscortScreenState();
}

class _EscortScreenState extends State<EscortScreen> {
  Map<String, dynamic>? _active;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final res = await api.get('/escort/active');
      final sessions = (res['sessions'] as List?) ?? const [];
      setState(() {
        _active = sessions.isNotEmpty ? Map<String, dynamic>.from(sessions.first) : null;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().user?.id;
    return Scaffold(
      backgroundColor: context.iosBackground,
      appBar: AppBar(
        title: const Text('Eskorta — Follow Me'),
        backgroundColor: context.iosBackground,
        foregroundColor: SerenityColors.primary,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Wróć',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _active == null
              ? const _EscortStartView()
              : _active!['requester_id'] == myId
                  ? _EscortRequesterView(session: _active!, onReload: _load)
                  : _EscortWatcherView(session: _active!, onReload: _load),
    );
  }
}

// =================== START VIEW ===================
class _EscortStartView extends StatefulWidget {
  const _EscortStartView();
  @override
  State<_EscortStartView> createState() => _EscortStartViewState();
}

class _EscortStartViewState extends State<_EscortStartView> {
  List<Map<String, dynamic>> _watchers = [];
  String? _selectedWatcherId;
  final _destNameCtrl = TextEditingController();
  double? _destLat;
  double? _destLng;
  int _etaMinutes = 30;
  bool _starting = false;
  bool _loadingWatchers = true;

  @override
  void initState() {
    super.initState();
    _loadWatchers();
  }

  @override
  void dispose() {
    _destNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWatchers() async {
    try {
      final api = context.read<ApiService>();
      final myId = context.read<AuthProvider>().user?.id;
      final gres = await api.get('/family/groups');
      final groups = (gres['groups'] as List?) ?? const [];
      final list = <Map<String, dynamic>>[];
      final seen = <String>{};
      for (final g in groups) {
        final gid = g['id'] as String?;
        if (gid == null) continue;
        try {
          final mres = await api.get('/family/groups/$gid/members');
          for (final m in ((mres['members'] as List?) ?? const [])) {
            final uid = m['user_id'] as String?;
            if (uid == null || uid == myId || seen.contains(uid)) continue;
            // Tylko dorośli (parent) jako watcherzy
            if (m['role'] != 'parent') continue;
            seen.add(uid);
            list.add({
              'user_id': uid,
              'username': m['username'] ?? 'Członek',
              'avatar_url': m['avatar_url'],
              'group_id': gid,
            });
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _watchers = list;
        _loadingWatchers = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingWatchers = false);
    }
  }

  Future<void> _pickCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _destLat = pos.latitude;
        _destLng = pos.longitude;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ustawiono cel: moja aktualna lokalizacja'),
        ));
      }
    } catch (_) {
      // fallback: Warszawa rynek
      setState(() {
        _destLat = 52.2297;
        _destLng = 21.0122;
      });
    }
  }

  Future<void> _start() async {
    if (_selectedWatcherId == null || _destLat == null || _destLng == null || _starting) return;
    setState(() => _starting = true);
    try {
      final api = context.read<ApiService>();
      final w = _watchers.firstWhere((x) => x['user_id'] == _selectedWatcherId);
      final res = await api.post('/escort/start', {
        'watcher_id': _selectedWatcherId,
        'destination_lat': _destLat,
        'destination_lng': _destLng,
        'destination_name': _destNameCtrl.text.trim(),
        'eta_seconds': _etaMinutes * 60,
        'group_id': w['group_id'],
      });
      if (res['error'] != null) throw Exception(res['error']);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      // Reload parent to show requester view
      final parent = context.findAncestorStateOfType<_EscortScreenState>();
      parent?._load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: SerenityColors.error,
          content: Text('Nie udało się rozpocząć eskorty: $e'),
        ));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canStart = _selectedWatcherId != null &&
        _destLat != null &&
        _destLng != null &&
        !_starting;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SerenitySpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(SerenitySpacing.lg),
            decoration: BoxDecoration(
              color: SerenityColors.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 28, color: SerenityColors.onSecondaryContainer),
                const SizedBox(width: SerenitySpacing.md),
                Expanded(
                  child: Text(
                    'Ktoś z rodziny będzie widzieć Twoją trasę w czasie rzeczywistym. '
                    'Jeśli nie potwierdzisz dotarcia, otrzyma alarm.',
                    style: SerenityText.bodyMain.copyWith(fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SerenitySpacing.xl),
          Text('KTO MA OBSERWOWAĆ',
              style: SerenityText.labelCaps.copyWith(letterSpacing: 1.2)),
          const SizedBox(height: SerenitySpacing.sm),
          if (_loadingWatchers)
            const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())
          else if (_watchers.isEmpty)
            Container(
              padding: const EdgeInsets.all(SerenitySpacing.lg),
              decoration: BoxDecoration(
                color: context.iosCardSurface,
                borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
              ),
              child: Text(
                'Brak dorosłych w rodzinie. Dodaj kogoś do grupy w zakładce Rodzina.',
                style: SerenityText.bodyMain,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _watchers.map((w) {
                final id = w['user_id'] as String;
                final selected = id == _selectedWatcherId;
                return ChoiceChip(
                  label: Text(w['username']),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedWatcherId = id),
                  selectedColor: SerenityColors.secondaryContainer,
                );
              }).toList(),
            ),
          const SizedBox(height: SerenitySpacing.xl),
          Text('CEL', style: SerenityText.labelCaps.copyWith(letterSpacing: 1.2)),
          const SizedBox(height: SerenitySpacing.sm),
          TextField(
            controller: _destNameCtrl,
            decoration: const InputDecoration(
              hintText: 'np. Dom mamy, Szkoła…',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: SerenitySpacing.sm),
          OutlinedButton.icon(
            onPressed: _pickCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: Text(_destLat == null
                ? 'Ustaw współrzędne celu (moja lokalizacja)'
                : 'Cel: ${_destLat!.toStringAsFixed(4)}, ${_destLng!.toStringAsFixed(4)}'),
          ),
          const SizedBox(height: SerenitySpacing.xl),
          Text('ETA: $_etaMinutes min',
              style: SerenityText.labelCaps.copyWith(letterSpacing: 1.2)),
          Slider(
            value: _etaMinutes.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            label: '$_etaMinutes min',
            onChanged: (v) => setState(() => _etaMinutes = v.toInt()),
          ),
          const SizedBox(height: SerenitySpacing.xl),
          FilledButton.icon(
            onPressed: canStart ? _start : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: SerenityColors.primaryContainer,
            ),
            icon: _starting
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.play_arrow),
            label: const Text('Rozpocznij eskortę',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// =================== REQUESTER VIEW ===================
class _EscortRequesterView extends StatefulWidget {
  final Map<String, dynamic> session;
  final VoidCallback onReload;
  const _EscortRequesterView({required this.session, required this.onReload});
  @override
  State<_EscortRequesterView> createState() => _EscortRequesterViewState();
}

class _EscortRequesterViewState extends State<_EscortRequesterView> {
  Timer? _ticker;
  Timer? _locationTimer;
  int _remainingSec = 0;

  @override
  void initState() {
    super.initState();
    _recomputeRemaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(_recomputeRemaining));
    _locationTimer = Timer.periodic(const Duration(seconds: 20), (_) => _pushLocation());
    _pushLocation();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  void _recomputeRemaining() {
    try {
      final started = DateTime.parse(widget.session['started_at']).toLocal();
      final eta = (widget.session['eta_seconds'] as num).toInt();
      final end = started.add(Duration(seconds: eta));
      _remainingSec = end.difference(DateTime.now()).inSeconds;
    } catch (_) {
      _remainingSec = 0;
    }
  }

  Future<void> _pushLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final api = context.read<ApiService>();
      await api.patch('/escort/${widget.session['id']}/location', {
        'lat': pos.latitude,
        'lng': pos.longitude,
      });
    } catch (_) {}
  }

  Future<void> _complete() async {
    HapticFeedback.heavyImpact();
    try {
      final api = context.read<ApiService>();
      await api.patch('/escort/${widget.session['id']}/complete', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: SerenityColors.secondaryContainer,
        content: const Text('✓ Powiadomiono, że dotarłeś bezpiecznie',
            style: TextStyle(color: SerenityColors.onSecondaryContainer)),
      ));
      widget.onReload();
    } catch (_) {}
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anulować eskortę?'),
        content: const Text('Obserwator otrzyma informację, że eskorta została anulowana.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nie')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: SerenityColors.error),
            child: const Text('Anuluj eskortę'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final api = context.read<ApiService>();
      await api.delete('/escort/${widget.session['id']}');
      widget.onReload();
    } catch (_) {}
  }

  String get _mmss {
    final s = _remainingSec.abs();
    final m = s ~/ 60;
    final ss = s % 60;
    return '${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final destLat = (widget.session['destination_lat'] as num?)?.toDouble() ?? 52.0;
    final destLng = (widget.session['destination_lng'] as num?)?.toDouble() ?? 21.0;
    final destName = (widget.session['destination_name'] as String?) ?? '';
    final overdue = _remainingSec < 0;
    return Column(
      children: [
        Expanded(
          child: GoogleMap(
              style: Theme.of(context).brightness == Brightness.dark ? kDarkMapStyle : null,
            initialCameraPosition: CameraPosition(target: LatLng(destLat, destLng), zoom: 14),
            markers: {
              Marker(
                markerId: const MarkerId('dest'),
                position: LatLng(destLat, destLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                infoWindow: InfoWindow(title: destName.isEmpty ? 'Cel' : destName),
              ),
            },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(SerenitySpacing.xl),
          color: context.iosCardSurface,
          child: Column(
            children: [
              Text(
                overdue ? 'PRZEKROCZONO ETA' : 'Pozostały czas',
                style: SerenityText.labelCaps.copyWith(
                    color: overdue ? SerenityColors.glowAlertCoral : context.iosSecondaryLabel,
                    letterSpacing: 1.4),
              ),
              const SizedBox(height: 4),
              Text(
                _mmss,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: overdue ? SerenityColors.glowAlertCoral : context.iosLabel,
                ),
              ),
              if (destName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Cel: $destName', style: SerenityText.bodyMain),
                ),
              const SizedBox(height: SerenitySpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _complete,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: SerenityColors.secondaryContainer,
                        foregroundColor: SerenityColors.onSecondaryContainer,
                      ),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('DOTARŁEM',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(width: SerenitySpacing.md),
                  OutlinedButton.icon(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      foregroundColor: SerenityColors.error,
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Anuluj'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =================== WATCHER VIEW ===================
class _EscortWatcherView extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onReload;
  const _EscortWatcherView({required this.session, required this.onReload});

  Future<void> _call(BuildContext context) async {
    final phone = session['requester_phone'] as String?;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final destLat = (session['destination_lat'] as num?)?.toDouble() ?? 52.0;
    final destLng = (session['destination_lng'] as num?)?.toDouble() ?? 21.0;
    final lastLat = (session['last_location_lat'] as num?)?.toDouble();
    final lastLng = (session['last_location_lng'] as num?)?.toDouble();
    final reqName = session['requester_username'] ?? 'Osoba';
    final destName = session['destination_name'] ?? '';
    final phone = session['requester_phone'] as String?;
    return Column(
      children: [
        Expanded(
          child: GoogleMap(
              style: Theme.of(context).brightness == Brightness.dark ? kDarkMapStyle : null,
            initialCameraPosition: CameraPosition(
              target: LatLng(lastLat ?? destLat, lastLng ?? destLng),
              zoom: 14,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('dest'),
                position: LatLng(destLat, destLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                infoWindow: InfoWindow(title: destName.isEmpty ? 'Cel' : destName),
              ),
              if (lastLat != null && lastLng != null)
                Marker(
                  markerId: const MarkerId('requester'),
                  position: LatLng(lastLat, lastLng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  infoWindow: InfoWindow(title: reqName),
                ),
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(SerenitySpacing.xl),
          color: context.iosCardSurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Obserwujesz: $reqName',
                style: SerenityText.headlineHeroMobile.copyWith(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              if (destName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Cel: $destName', style: SerenityText.bodyMain),
                ),
              const SizedBox(height: SerenitySpacing.lg),
              Row(
                children: [
                  if (phone != null && phone.isNotEmpty)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _call(context),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                        icon: const Icon(Icons.call),
                        label: const Text('Zadzwoń'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
