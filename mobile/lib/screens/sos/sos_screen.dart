/// be:Safe v2 — SOS Screen
///
/// Press-and-hold (2s) large SOS orb to trigger an emergency broadcast.
/// Three toggleable actions: notify community / family / call 112.
///
/// Design source: design/stitch_v2/screens/sos_be_safe/
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/sos_audio_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/nav_routes.dart';
import '../../widgets/serenity_card.dart';
import '../fake_call/fake_call_setup_screen.dart';
import '../escort/escort_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  bool _notifyCommunity = true;
  bool _notifyFamily = true;
  bool _call112 = true; // SOS12: default true for emergencies
  bool _sending = false;
  bool _holding = false;
  int _familyCount = 0;

  late final AnimationController _holdCtrl;
  Timer? _hapticTimer;

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
    _hapticTimer?.cancel();
    _holdCtrl.dispose();
    super.dispose();
  }

  void _onHoldStart() {
    HapticFeedback.mediumImpact();
    setState(() => _holding = true);
    _holdCtrl.forward();
    // SOS12: pulsująca informacja zwrotna co 500ms żeby user wiedział, że hold działa
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_holding) HapticFeedback.lightImpact();
    });
  }

  void _onHoldEnd() {
    _hapticTimer?.cancel();
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

    // F02: Start audio recording (jeśli user wyraził zgodę RODO + włączona)
    final audio = SosAudioService();
    if (audio.enabled && audio.hasConsent) {
      // Fire-and-forget — nie blokuje SOS flow
      audio.startRecording().catchError((_) => false);
    }

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
      if (!mounted) return;
      // SOS jest tabem (Nav2 unifikacja) — pop może zostawić pusty stack.
      // Wracamy do mapy przez navigateToTab.
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      } else {
        navigateToTab(context,
            targetIndex: NavTabs.map, currentIndex: NavTabs.sos);
      }
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
      backgroundColor: context.iosBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Na dużych ekranach (>700 dostępnej wysokości) zachowujemy
            // klasyczny layout z Expanded+Center wokół orb.
            // Na mniejszych — całość jest przewijalna żeby SOS button był
            // zawsze widoczny, mimo globalnego docka na dole.
            final tall = constraints.maxHeight >= 700;
            if (tall) {
              return Column(
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  Expanded(child: Center(child: _buildOrb())),
                  _buildFakeCallShortcut(),
                  _buildEscortShortcut(),
                  _buildOptions(),
                  _buildCancel(),
                ],
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Center(child: _buildOrb()),
                  const SizedBox(height: 24),
                  _buildFakeCallShortcut(),
                  _buildEscortShortcut(),
                  _buildOptions(),
                  _buildCancel(),
                ],
              ),
            );
          },
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
                      if (!_sending) ...[
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.5, end: 1.0),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeInOut,
                          builder: (_, value, child) {
                            return Opacity(opacity: value, child: child);
                          },
                          onEnd: () {
                            if (mounted) setState(() {});
                          },
                          child: Text(
                            'PRZYTRZYMAJ 2 SEKUNDY',
                            style: SerenityText.labelCaps.copyWith(
                              color: SerenityColors.glowAlertCoral,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildFakeCallShortcut() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          SerenitySpacing.xl, SerenitySpacing.xs, SerenitySpacing.xl, 0),
      child: Material(
        color: context.iosCardSurface,
        borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
        child: InkWell(
          onTap: _sending
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FakeCallSetupScreen(),
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(SerenitySpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: SerenityColors.secondaryContainer
                        .withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_in_talk,
                    color: SerenityColors.onSecondaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: SerenitySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fałszywy telefon',
                        style: SerenityText.labelButton.copyWith(
                          fontSize: 15,
                          color: context.iosLabel,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Atrapa połączenia — wyjście z niezręcznej sytuacji',
                        style:
                            SerenityText.bodyMain.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: context.iosSecondaryLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEscortShortcut() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          SerenitySpacing.xl, SerenitySpacing.xs, SerenitySpacing.xl, 0),
      child: Material(
        color: context.iosCardSurface,
        borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
        child: InkWell(
          onTap: _sending
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EscortScreen()),
                  );
                },
          borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(SerenitySpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: SerenityColors.glowCalmAqua.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: context.iosLabel,
                    size: 22,
                  ),
                ),
                const SizedBox(width: SerenitySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eskorta — Follow Me',
                        style: SerenityText.labelButton.copyWith(
                          fontSize: 15,
                          color: context.iosLabel,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rodzina widzi Twoją trasę i alarmuje gdy nie dotrzesz',
                        style: SerenityText.bodyMain.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: context.iosSecondaryLabel),
              ],
            ),
          ),
        ),
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
            inactiveThumbColor: context.iosCardSurface,
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
        onPressed: _sending
            ? null
            : () {
                if (Navigator.of(context).canPop()) {
                  Navigator.pop(context);
                } else {
                  navigateToTab(context,
                      targetIndex: NavTabs.map, currentIndex: NavTabs.sos);
                }
              },
        child: Text(
          'Anuluj',
          style: SerenityText.labelButton.copyWith(fontSize: 16),
        ),
      ),
    );
  }
}
