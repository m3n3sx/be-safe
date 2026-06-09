import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

/// Pełnoekranowy ekran tworzenia bezpiecznej strefy (geofence).
///
/// Zastępuje stary kompresowany `AlertDialog` (350px, hardkodowany 200m promień).
/// - Mapa zajmuje ~60% ekranu
/// - Slider 50-500m do regulacji promienia z wizualnym kołem na mapie
/// - Pole nazwy strefy (np. "Dom", "Szkoła")
/// - Confirmation gdy próba wyjścia z niezapisanymi zmianami
class AddGeofenceScreen extends StatefulWidget {
  final String groupId;
  final LatLng initialCenter;

  const AddGeofenceScreen({
    super.key,
    required this.groupId,
    required this.initialCenter,
  });

  @override
  State<AddGeofenceScreen> createState() => _AddGeofenceScreenState();
}

class _AddGeofenceScreenState extends State<AddGeofenceScreen> {
  final _nameCtrl = TextEditingController();
  late LatLng _picked = widget.initialCenter;
  double _radius = 200;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges =>
      _nameCtrl.text.trim().isNotEmpty ||
      _picked != widget.initialCenter ||
      _radius != 200;

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges || _submitting) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Porzucić strefę?'),
        content: const Text('Wpisane dane zostaną utracone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Wróć do edycji'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Porzuć',
              style: TextStyle(color: SerenityColors.error),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaj nazwę strefy (np. Dom, Szkoła)')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await context.read<ApiService>().post(
        '/family/groups/${widget.groupId}/geofences',
        {
          'name': name,
          'lat': _picked.latitude,
          'lng': _picked.longitude,
          'radius_m': _radius.round(),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: !_hasUnsavedChanges || _submitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: context.iosBackground,
        appBar: AppBar(
          backgroundColor: context.iosBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: context.iosLabel),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Zamknij',
            onPressed: () async {
              final ok = await _confirmDiscard();
              if (ok && mounted) Navigator.pop(context);
            },
          ),
          title: Text(
            'Nowa bezpieczna strefa',
            style: SerenityText.headlineHeroMobile.copyWith(fontSize: 20),
          ),
        ),
        body: Column(
          children: [
            // Mapa — stała, niższa wysokość (jak preview na karcie)
            SizedBox(
              height: 260,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.initialCenter,
                      zoom: 15,
                    ),
                    onTap: (p) => setState(() => _picked = p),
                    markers: {
                      Marker(
                        markerId: const MarkerId('picked'),
                        position: _picked,
                        draggable: true,
                        onDragEnd: (p) => setState(() => _picked = p),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                      ),
                    },
                    circles: {
                      Circle(
                        circleId: const CircleId('zone'),
                        center: _picked,
                        radius: _radius,
                        fillColor: SerenityColors.secondaryContainer
                            .withValues(alpha: 0.25),
                        strokeColor: SerenityColors.secondaryContainer,
                        strokeWidth: 2,
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    style: isDark ? _darkStyle : null,
                  ),
                  // Pomocnicza nakładka instrukcji
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.iosCardSurface
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: SerenityElevation.card(),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 18,
                              color: context.iosLabel,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tapnij na mapę aby ustawić środek strefy. Pinezkę można przeciągnąć.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.iosSecondaryLabel,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sekcja formularza — reszta wysokości, przewijalna
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NAZWA STREFY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: context.iosSecondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      onChanged: (_) => setState(() {}),
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'np. Dom, Szkoła, Babcia',
                        filled: true,
                        fillColor: context.iosCardSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.iosSeparator,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.iosSeparator,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.iosLabel,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PROMIEŃ STREFY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: context.iosSecondaryLabel,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: SerenityColors.secondaryContainer
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_radius.round()} m',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.iosLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: SerenityColors.primary,
                        inactiveTrackColor: context.iosSeparator,
                        thumbColor: SerenityColors.primary,
                        overlayColor: SerenityColors.primary.withValues(
                          alpha: 0.12,
                        ),
                      ),
                      child: Slider(
                        value: _radius,
                        min: 50,
                        max: 500,
                        divisions: 45,
                        label: '${_radius.round()} m',
                        onChanged: (v) => setState(() => _radius = v),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '50 m',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.iosSecondaryLabel,
                          ),
                        ),
                        Text(
                          '500 m',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.iosSecondaryLabel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: SerenityColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Zapisz strefę',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    if (_nameCtrl.text.trim().isEmpty) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Wpisz nazwę aby zapisać strefę',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.iosSecondaryLabel,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String _darkStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#232a32"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#9ea1a8"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a2027"}]}
]
''';
