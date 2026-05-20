import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

/// Ekran wyświetlany rodzicowi po tapnięciu powiadomienia SOS od dziecka (type=family_sos).
/// Pokazuje lokalizację dziecka na mapie + dwa wielkie przyciski: Zadzwoń + Wyślij sygnał.
class FamilySosScreen extends StatefulWidget {
  final String childId;
  final String childUsername;
  final String groupId;
  final String alertId;
  final double lat;
  final double lng;

  const FamilySosScreen({
    super.key,
    required this.childId,
    required this.childUsername,
    required this.groupId,
    required this.alertId,
    required this.lat,
    required this.lng,
  });

  /// Wywołanie z mapy payloadów FCM. Wszystkie pola są stringami (FCM data limit).
  factory FamilySosScreen.fromPayload(Map<String, dynamic> data) {
    return FamilySosScreen(
      childId: (data['child_id'] ?? '').toString(),
      childUsername: (data['child_username'] ?? 'Dziecko').toString(),
      groupId: (data['group_id'] ?? '').toString(),
      alertId: (data['alert_id'] ?? '').toString(),
      lat: double.tryParse('${data['lat']}') ?? 52.0,
      lng: double.tryParse('${data['lng']}') ?? 19.0,
    );
  }

  @override
  State<FamilySosScreen> createState() => _FamilySosScreenState();
}

class _FamilySosScreenState extends State<FamilySosScreen> {
  final _api = ApiService();
  String? _childPhone;
  bool _signalling = false;

  @override
  void initState() {
    super.initState();
    _loadChildPhone();
  }

  Future<void> _loadChildPhone() async {
    try {
      final res = await _api.get('/family/groups/${widget.groupId}/members');
      if (res is Map && res['members'] is List) {
        for (final m in res['members']) {
          if (m is Map && m['user_id']?.toString() == widget.childId) {
            final phone = m['phone'];
            if (phone is String && phone.isNotEmpty) {
              setState(() => _childPhone = phone);
            }
            break;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _call() async {
    HapticFeedback.mediumImpact();
    final number = _childPhone ?? '112';
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się otworzyć dialera')),
      );
    }
  }

  Future<void> _sendSignal() async {
    HapticFeedback.lightImpact();
    setState(() => _signalling = true);
    try {
      await _api.post('/family/groups/${widget.groupId}/ping', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sygnał wysłany do całej rodziny')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się wysłać sygnału')),
        );
      }
    } finally {
      if (mounted) setState(() => _signalling = false);
    }
  }

  Future<void> _open112() async {
    HapticFeedback.heavyImpact();
    final uri = Uri.parse('tel:112');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: SerenityColors.surfaceBright,
      appBar: AppBar(
        title: Text('🆘 SOS od ${widget.childUsername}'),
        backgroundColor: SerenityColors.glowAlertCoral,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Wróć',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.lat, widget.lng),
                zoom: 16,
              ),
              onMapCreated: (_) {},
              markers: {
                Marker(
                  markerId: const MarkerId('child_sos'),
                  position: LatLng(widget.lat, widget.lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                  infoWindow: InfoWindow(
                    title: widget.childUsername,
                    snippet: 'Wezwanie pomocy',
                  ),
                ),
              },
              circles: {
                Circle(
                  circleId: const CircleId('sos_radius'),
                  center: LatLng(widget.lat, widget.lng),
                  radius: 250,
                  fillColor: SerenityColors.glowAlertCoral.withValues(alpha: 0.15),
                  strokeColor: SerenityColors.glowAlertCoral.withValues(alpha: 0.6),
                  strokeWidth: 2,
                ),
              },
              myLocationEnabled: true,
              compassEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: SerenityColors.glowAlertCoral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: SerenityColors.glowAlertCoral, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Dziecko wzywa pomocy',
                          style: TextStyle(
                            color: SerenityColors.glowAlertCoral,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.childUsername,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _childPhone != null ? 'Tel: $_childPhone' : 'Numer telefonu nieznany',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 64,
                          child: FilledButton.icon(
                            onPressed: _call,
                            icon: const Icon(Icons.call, size: 28),
                            label: Text(
                              _childPhone != null ? 'Zadzwoń' : 'Zadzwoń 112',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1B873A),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 64,
                          child: FilledButton.icon(
                            onPressed: _signalling ? null : _sendSignal,
                            icon: _signalling
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.notifications_active, size: 26),
                            label: const Text(
                              'Wyślij sygnał',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: SerenityColors.primaryContainer,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _open112,
                      icon: const Icon(Icons.emergency, color: SerenityColors.glowAlertCoral),
                      label: const Text(
                        'Wezwij 112',
                        style: TextStyle(color: SerenityColors.glowAlertCoral, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: SerenityColors.glowAlertCoral, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
