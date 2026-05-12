/// be:Safe v2 — SOS Screen
///
/// Press-and-hold (2s) large SOS orb to trigger an emergency broadcast.
/// Three toggleable actions: notify community / family / call 112.
///
/// Design source: design/stitch_v2/screens/sos_be_safe/
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/serenity_card.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  bool _notifyCommunity = true;
  bool _notifyFamily = true;
  bool _call112 = false;
  bool _sending = false;
  bool _holding = false;
  int _familyCount = 0;

  late final AnimationController _holdCtrl;

  @override
  void initState() {
    super.initState();
    _holdCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _holdCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _fireSOS();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFamilyCount());
  }

  Future<void> _loadFamilyCount() async {
    try {
      final api = context.read<ApiService>();
      final groups = await api.get('/family/groups');
      final groupsList = ((groups as dynamic)['groups'] as List?) ?? [];
      if (groupsList.isEmpty) return;
      final groupId = groupsList.first['id'];
      final m = await api.get('/family/groups/$groupId/members');
      final members = ((m as dynamic)['members'] as List?) ?? [];
      if (mounted) setState(() => _familyCount = members.length);
    } catch (_) {}
  }

  @override
  void dispose() {
    _holdCtrl.dispose();
    super.dispose();
  }

  void _onHoldStart() {
    HapticFeedback.mediumImpact();
    setState(() => _holding = true);
    _holdCtrl.forward();
  }

  void _onHoldEnd() {
    if (_holdCtrl.status != AnimationStatus.completed) {
      _holdCtrl.reverse();
    }
    setState(() => _holding = false);
  }

  Future<void> _fireSOS() async {
    if (_sending) return;
    setState(() => _sending = true);
    await HapticFeedback.heavyImpact();
    await HapticFeedback.vibrate();

    try {
      final pos = await _getPosition();
      final loc = pos != null
          ? LatLng(pos.latitude, pos.longitude)
          : const LatLng(52.2297, 21.0122);

      if (!mounted) return;
      final api = context.read<ApiService>();

      if (_notifyCommunity || _notifyFamily) {
        await api.post('/alerts', {
          'category': 'aggression',
          'title': '🆘 SOS — Potrzebuję pomocy!',
          'description': _notifyFamily
              ? 'Alarm SOS — powiadomiono rodzinę i społeczność'
              : 'Alarm SOS — powiadomiono społeczność',
          'lat': loc.latitude,
          'lng': loc.longitude,
          'radius_m': _notifyCommunity ? 500 : 200,
        });
      }

      if (_call112 && mounted) {
        final uri = Uri.parse('tel:112');
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: SerenityColors.secondary,
          content: const Text('Alarm SOS wysłany. Pomoc w drodze.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: SerenityColors.error,
          content: Text('Błąd wysyłania SOS: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<Position?> _getPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SerenityColors.surfaceBright,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildHeader(),
            Expanded(child: Center(child: _buildOrb())),
            _buildOptions(),
            _buildCancel(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SerenitySpacing.xl),
      child: Column(
        children: [
          Text(
            'Potrzebujesz pomocy?',
            style: SerenityText.displayMd.copyWith(
              fontSize: 40,
              height: 48 / 40,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Twoja rodzina, zaufane kontakty i społeczność w okolicy zostaną powiadomieni.',
            style: SerenityText.bodyMain,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrb() {
    return GestureDetector(
      onLongPressStart: _sending ? null : (_) => _onHoldStart(),
      onLongPressEnd: _sending ? null : (_) => _onHoldEnd(),
      onLongPressCancel: _sending ? null : _onHoldEnd,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _holdCtrl,
        builder: (context, child) {
          final progress = _holdCtrl.value;
          final scale = _holding ? 1.0 + progress * 0.1 : 1.0;
          final coreOpacity = 0.6 + progress * 0.4;
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          SerenityColors.glowAlertCoral
                              .withValues(alpha: coreOpacity),
                          SerenityColors.glowAlertCoral
                              .withValues(alpha: 0),
                        ],
                        stops: const [0, 0.7],
                      ),
                    ),
                  ),
                  // Progress ring while holding
                  if (_holding)
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(
                          SerenityColors.glowAlertCoral,
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SOS',
                        style: SerenityText.displayLg.copyWith(
                          fontSize: 96,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _sending
                            ? 'Wysyłam alarm...'
                            : (_holding
                                ? 'Trzymaj...'
                                : 'Wciśnij i przytrzymaj'),
                        style: SerenityText.bodyMain,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.all(SerenitySpacing.xl),
      child: Column(
        children: [
          _buildOptionCard(
            title: 'Powiadom społeczność',
            subtitle: 'Użytkownicy be:Safe w promieniu 500m',
            value: _notifyCommunity,
            onChanged: (v) => setState(() => _notifyCommunity = v),
          ),
          const SizedBox(height: SerenitySpacing.md),
          _buildOptionCard(
            title: 'Powiadom rodzinę',
            subtitle: _familyCount == 0
                ? 'Dodaj bliskich w zakładce Rodzina'
                : '$_familyCount ${_familyCount == 1 ? 'osoba dostępna' : 'osób dostępnych'}',
            value: _notifyFamily && _familyCount > 0,
            onChanged: _familyCount == 0
                ? null
                : (v) => setState(() => _notifyFamily = v),
          ),
          const SizedBox(height: SerenitySpacing.md),
          _buildOptionCard(
            title: 'Zadzwoń na 112',
            subtitle: 'Po wysłaniu alarmu',
            value: _call112,
            onChanged: (v) => setState(() => _call112 = v),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SerenityCard(
      padding: const EdgeInsets.all(SerenitySpacing.md + 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SerenityText.labelButton.copyWith(
                    fontSize: 16,
                    color: onChanged == null
                        ? SerenityColors.onSurfaceVariant
                        : SerenityColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: SerenityText.bodyMain.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: SerenityColors.primary,
            activeTrackColor: SerenityColors.secondaryContainer,
            inactiveThumbColor: SerenityColors.surfaceContainerLowest,
            inactiveTrackColor: SerenityColors.surfaceContainerHigh,
          ),
        ],
      ),
    );
  }

  Widget _buildCancel() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 8,
      ),
      child: TextButton(
        onPressed: _sending ? null : () => Navigator.pop(context),
        child: Text(
          'Anuluj',
          style: SerenityText.labelButton.copyWith(fontSize: 16),
        ),
      ),
    );
  }
}
