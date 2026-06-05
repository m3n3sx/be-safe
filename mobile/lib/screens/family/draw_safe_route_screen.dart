import 'dart:async';

import 'package:flutter/material.dart';
import '../../theme/map_style.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

/// Ekran rysowania bezpiecznej trasy palcem na mapie.
///
/// Tryb mapy: standardowy (przesuwanie, zoom). Tryb rysowania:
/// blokuje gesty mapy i zbiera ścieżkę punktów w czasie rzeczywistym.
class DrawSafeRouteScreen extends StatefulWidget {
  final String groupId;
  final String userId;
  final String userName;

  const DrawSafeRouteScreen({
    super.key,
    required this.groupId,
    required this.userId,
    required this.userName,
  });

  @override
  State<DrawSafeRouteScreen> createState() => _DrawSafeRouteScreenState();
}

class _DrawSafeRouteScreenState extends State<DrawSafeRouteScreen> {
  GoogleMapController? _ctrl;
  final List<LatLng> _points = [];
  final List<List<LatLng>> _history = [];
  bool _drawing = false;
  bool _submitting = false;
  DateTime _lastSample = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _sampleInterval = Duration(milliseconds: 60);

  bool get _hasUnsaved => _points.isNotEmpty;

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsaved || _submitting) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Porzucić trasę?'),
        content: const Text('Narysowana trasa zostanie utracona.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Wróć do rysowania'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: SerenityColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Porzuć'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _toggleDrawing() {
    HapticFeedback.selectionClick();
    setState(() => _drawing = !_drawing);
  }

  void _clear() {
    if (_points.isEmpty) return;
    setState(() {
      _history.add(List.of(_points));
      _points.clear();
    });
  }

  void _undo() {
    if (_history.isEmpty && _points.isEmpty) return;
    setState(() {
      if (_history.isNotEmpty) {
        // Restore previous batch (undo a 'clear')
        _points
          ..clear()
          ..addAll(_history.removeLast());
      } else {
        // Remove last segment of strokes (chunk of ~10 points)
        final removeCount =
            _points.length > 10 ? 10 : _points.length;
        _points.removeRange(_points.length - removeCount, _points.length);
      }
    });
  }

  Future<void> _onPanUpdate(DragUpdateDetails d) async {
    if (!_drawing || _ctrl == null) return;
    final now = DateTime.now();
    if (now.difference(_lastSample) < _sampleInterval) return;
    _lastSample = now;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    try {
      final coord = ScreenCoordinate(
        x: (d.localPosition.dx * dpr).round(),
        y: (d.localPosition.dy * dpr).round(),
      );
      final latLng = await _ctrl!.getLatLng(coord);
      if (!mounted) return;
      setState(() => _points.add(latLng));
    } catch (_) {
      /* ignore */
    }
  }

  Future<void> _save() async {
    if (_points.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trasa potrzebuje min. 2 punktów (narysuj palcem).'),
        ),
      );
      return;
    }
    final result = await showModalBottomSheet<_SaveOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SaveOptionsSheet(),
    );
    if (result == null) return;
    if (!mounted) return;
    setState(() => _submitting = true);
    try {
      final api = context.read<ApiService>();
      final payload = {
        'name': result.name,
        'threshold_m': result.thresholdM,
        'points': _points.map((p) => [p.latitude, p.longitude]).toList(),
      };
      final res = await api.post(
        '/family/groups/${widget.groupId}/members/${widget.userId}/safe-routes',
        payload,
      );
      if (res['error'] != null) {
        throw Exception(res['error']);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zapisać trasy: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsaved || _submitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (ok && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: context.iosBackground,
        appBar: AppBar(
          backgroundColor: context.iosBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Zamknij',
            onPressed: () async {
              final ok = await _confirmDiscard();
              if (ok && mounted) Navigator.pop(context);
            },
          ),
          title: Text(
            'Nowa trasa: ${widget.userName}',
            style: TextStyle(
              color: context.iosLabel,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _submitting ? null : _save,
              child: Text(
                'Zapisz',
                style: TextStyle(
                  color: _points.length >= 2
                      ? SerenityColors.primaryContainer
                      : SerenityColors.primaryContainer.withValues(alpha: 0.3),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _buildMap()),
            _buildToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        GoogleMap(
              style: Theme.of(context).brightness == Brightness.dark ? kDarkMapStyle : null,
          initialCameraPosition: const CameraPosition(
            target: LatLng(52.325, 17.565),
            zoom: 14,
          ),
          onMapCreated: (c) => _ctrl = c,
          polylines: _points.length >= 2
              ? {
                  Polyline(
                    polylineId: const PolylineId('drawing'),
                    points: _points,
                    color: SerenityColors.primaryContainer,
                    width: 5,
                  ),
                }
              : const <Polyline>{},
          markers: _points.isNotEmpty
              ? {
                  Marker(
                    markerId: const MarkerId('start'),
                    position: _points.first,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen),
                  ),
                  if (_points.length > 1)
                    Marker(
                      markerId: const MarkerId('end'),
                      position: _points.last,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed),
                    ),
                }
              : const <Marker>{},
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          scrollGesturesEnabled: !_drawing,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomGesturesEnabled: !_drawing,
        ),
        if (_drawing)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: _onPanUpdate,
              onPanStart: (_) => HapticFeedback.lightImpact(),
            ),
          ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.iosCardSurface
                    .withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _drawing
                      ? SerenityColors.glowAlertCoral
                      : SerenityColors.primaryContainer.withValues(alpha: 0.1),
                  width: _drawing ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _drawing ? Icons.touch_app : Icons.info_outline,
                    size: 18,
                    color: _drawing
                        ? SerenityColors.glowAlertCoral
                        : SerenityColors.primaryContainer
                            .withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _drawing
                          ? 'Rysuj palcem trasę – tryb mapy wyłączony.'
                          : 'Najpierw ustaw widok mapy, potem włącz tryb rysowania.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: context.iosLabel,
                      ),
                    ),
                  ),
                  if (_points.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: SerenityColors.secondaryContainer
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_points.length} pkt',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.iosLabel,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: context.iosCardSurface,
        boxShadow: [
          BoxShadow(
            color: SerenityColors.primaryContainer.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _drawing
                    ? SerenityColors.glowAlertCoral
                    : SerenityColors.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _submitting ? null : _toggleDrawing,
              icon: Icon(_drawing ? Icons.stop_circle : Icons.gesture),
              label: Text(_drawing ? 'Zakończ rysowanie' : 'Rysuj palcem'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed:
                _submitting || (_points.isEmpty && _history.isEmpty) ? null : _undo,
            icon: const Icon(Icons.undo),
            tooltip: 'Cofnij',
          ),
          IconButton.outlined(
            onPressed: _submitting || _points.isEmpty ? null : _clear,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Wyczyść',
          ),
        ],
      ),
    );
  }
}

class _SaveOptions {
  final String name;
  final int thresholdM;
  const _SaveOptions(this.name, this.thresholdM);
}

class _SaveOptionsSheet extends StatefulWidget {
  const _SaveOptionsSheet();

  @override
  State<_SaveOptionsSheet> createState() => _SaveOptionsSheetState();
}

class _SaveOptionsSheetState extends State<_SaveOptionsSheet> {
  final _name = TextEditingController();
  double _threshold = 100;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.iosBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: SerenityColors.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Zapisz trasę',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.iosLabel,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nadaj nazwę i ustaw szerokość korytarza – w jakiej odległości od trasy '
              'dziecko może iść, zanim wyślemy alert.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: SerenityColors.primaryContainer.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'NAZWA TRASY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: SerenityColors.primaryContainer.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'np. Do szkoły, Na trening',
                filled: true,
                fillColor: context.iosCardSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLength: 120,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'KORYTARZ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color:
                        SerenityColors.primaryContainer.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: SerenityColors.secondaryContainer
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_threshold.round()} m',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.iosLabel,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: _threshold,
              min: 30,
              max: 500,
              divisions: 47,
              activeColor: SerenityColors.primaryContainer,
              onChanged: (v) => setState(() => _threshold = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '30 m',
                  style: TextStyle(
                    fontSize: 11,
                    color: SerenityColors.primaryContainer.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  '500 m',
                  style: TextStyle(
                    fontSize: 11,
                    color: SerenityColors.primaryContainer.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: SerenityColors.primaryContainer,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _name.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(
                          context,
                          _SaveOptions(
                              _name.text.trim(), _threshold.round()),
                        ),
                child: const Text(
                  'Zapisz trasę',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (_name.text.trim().isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'Wpisz nazwę aby zapisać trasę',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.iosLabel
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
