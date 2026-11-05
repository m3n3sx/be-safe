import 'package:flutter/material.dart';
import '../../theme/map_style.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

/// Ekran wyświetlany rodzicowi po tapnięciu powiadomienia SOS od dziecka (type=family_sos).
/// Pokazuje lokalizację dziecka na mapie + dwa wielkie przyciski: Zadzwoń + Wyślij sygnał.
class FamilySosScreen extends StatefulWidget {
  static final Set<String> dismissedThisProcess = {};
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

  bool _contextReady = false;
  String? _contextError;
  double? _resolvedLat;
  double? _resolvedLng;
  String? _senderName;
  String? _sentAt;
  String? _notificationId;
  String _alertStatus = 'active';

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    if (widget.alertId.isEmpty) {
      setState(() {
        _contextError = 'Brak identyfikatora alarmu.';
        _contextReady = true;
      });
      return;
    }
    final res = await _api.get('/alerts/${widget.alertId}/sos-context');
    if (!mounted) return;
    if (res['error'] != null || res['lat'] is! num || res['lng'] is! num) {
      setState(() {
        _contextError = res['error']?.toString() ?? 'Nie można pokazać miejsca alarmu.';
        _contextReady = true;
      });
      return;
    }
    setState(() {
      _contextReady = true;
      _resolvedLat = (res['lat'] as num).toDouble();
      _resolvedLng = (res['lng'] as num).toDouble();
      _senderName = res['sender_username']?.toString() ?? widget.childUsername;
      _sentAt = res['sent_at']?.toString();
      _childPhone = res['phone']?.toString();
      _notificationId = res['notification_id']?.toString();
      _alertStatus = res['status']?.toString() ?? 'active';
    });
  }

  Future<void> _ack() async {
    if (_notificationId != null && _notificationId!.isNotEmpty) {
      await _api.post('/notifications/$_notificationId/ack', {});
    }
    if (mounted) Navigator.maybePop(context);
  }

  void _dismiss() {
    FamilySosScreen.dismissedThisProcess.add(widget.alertId);
    Navigator.maybePop(context);
  }

  Future<void> _call() async {
    if (_childPhone == null || _childPhone!.isEmpty) return;
    HapticFeedback.mediumImpact();
    final number = _childPhone!;
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
      final res = await _api.post('/family/groups/${widget.groupId}/ping', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? res['error']?.toString() ?? 'Nie udało się odczytać wyniku sygnału.')),
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
      backgroundColor: context.iosBackground,
      appBar: AppBar(
        title: const Text('be:Safe · SOS'),
        backgroundColor: const Color(0xFF7A1212),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Wróć',
          icon: const Icon(Icons.arrow_back),
          onPressed: _dismiss,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: !_contextReady
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _resolvedLat == null || _resolvedLng == null
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_contextError ?? 'Nie można pokazać miejsca alarmu.', textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 18)),
                      ))
                    : GoogleMap(
              style: Theme.of(context).brightness == Brightness.dark ? kDarkMapStyle : null,
              initialCameraPosition: CameraPosition(
                target: LatLng(_resolvedLat!, _resolvedLng!),
                zoom: 16,
              ),
              onMapCreated: (_) {},
              markers: {
                Marker(
                  markerId: const MarkerId('child_sos'),
                  position: LatLng(_resolvedLat!, _resolvedLng!),
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
                  center: LatLng(_resolvedLat!, _resolvedLng!),
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
                          _alertStatus == 'active' ? 'Alarm w aplikacji be:Safe' : 'Alarm wygasł',
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
                    _senderName ?? widget.childUsername,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _sentAt ?? 'Miejsce wysłania alarmu',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 64,
                          child: FilledButton.icon(
                            onPressed: _childPhone == null ? null : _call,
                            icon: const Icon(Icons.call, size: 28),
                            label: Text(
                              _childPhone != null ? 'Zadzwoń' : 'Brak numeru',
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
                    child: FilledButton(
                      onPressed: _ack,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7A1212), foregroundColor: Colors.white),
                      child: const Text('Widzę ten alarm'),
                    ),
                  ),
                  TextButton(onPressed: _dismiss, child: const Text('Zamknij')),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _open112,
                      icon: const Icon(Icons.emergency, color: SerenityColors.glowAlertCoral),
                      label: const Text(
                        'Zadzwoń pod 112 samodzielnie',
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
