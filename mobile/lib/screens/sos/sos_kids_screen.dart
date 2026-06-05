/// be:Safe — SOS Kids Screen
///
/// Tryb dziecka (7-12 lat). Jeden ogromny biały okrąg z napisem 'NACIŚNIJ'
/// + 3 koncentryczne pulsujące pierścienie. Press-and-hold 3 sekundy
/// (dłużej niż NORMAL żeby uniknąć przypadkowego odpalenia) z lightImpact
/// co 500ms i heavyImpact + vibrate na koniec.
///
/// Pełen ekran coral (#FF7A7A), zero menu, jedna akcja, link 'Anuluj' na dole.
/// Po wysłaniu: SnackBar zielony 'Mama i tata wiedzą' + powrót do HomeKids.
///
/// Design source: design/new/.../sos_tryb_dziecka/code.html
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

class SosKidsScreen extends StatefulWidget {
  const SosKidsScreen({super.key});

  @override
  State<SosKidsScreen> createState() => _SosKidsScreenState();
}

class _SosKidsScreenState extends State<SosKidsScreen>
    with TickerProviderStateMixin {
  static const _coral = Color(0xFFFF7A7A);
  static const _holdDuration = Duration(milliseconds: 3000);

  late final AnimationController _holdCtrl;
  late final AnimationController _pulseCtrl;
  Timer? _hapticTimer;
  bool _holding = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _holdCtrl = AnimationController(vsync: this, duration: _holdDuration);
    _holdCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _fireSOS();
    });
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _holdCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onHoldStart() {
    if (_sending) return;
    HapticFeedback.mediumImpact();
    setState(() => _holding = true);
    _holdCtrl.forward();
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

      // Powiadom rodzinę + społeczność (kids mode = obie warstwy)
      await api.post('/alerts', {
        'category': 'aggression',
        'title': '🆘 SOS — Dziecko potrzebuje pomocy!',
        'description': 'Alarm SOS od dziecka — powiadomiono rodzinę i społeczność',
        'lat': loc.latitude,
        'lng': loc.longitude,
        'radius_m': 500,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: SerenityColors.secondary,
          content: const Text(
            '✓ Mama i tata już wiedzą!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
          ),
        ),
      );

      // Krótkie opóźnienie żeby user zobaczył SnackBar
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: SerenityColors.error,
          content: Text(
            'Nie udało się wysłać. Spróbuj jeszcze raz.',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _cancel() {
    HapticFeedback.selectionClick();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _coral,
      body: Stack(
        children: [
          // Background glow orbs (dekoracja)
          Positioned(
            top: -80,
            left: -80,
            child: _BlurOrb(size: 256, color: Colors.white.withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: _BlurOrb(size: 320, color: Colors.white.withValues(alpha: 0.10)),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tall = constraints.maxHeight >= 720;
                final closeBtn = Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _cancel,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.close,
                              color: _coral,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                final headerTexts = const <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'POTRZEBUJESZ\nPOMOCY?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Mama i Tata dostaną wiadomość',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ),
                ];

                final orbBlock = SizedBox(
                  width: 320,
                  height: 320,
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, _) {
                      final t = _pulseCtrl.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          _ring(diameter: 320 + t * 32, opacity: (1 - t) * 0.15),
                          _ring(diameter: 280 + t * 24, opacity: (1 - t) * 0.25),
                          _ring(diameter: 240 + t * 16, opacity: (1 - t) * 0.35),
                          _buildHoldButton(),
                        ],
                      );
                    },
                  ),
                );

                final instructionText = AnimatedOpacity(
                  opacity: _holding ? 1.0 : 0.85,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _holding
                        ? 'Trzymaj jeszcze...'
                        : 'Trzymaj wciśnięty 3 sekundy',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );

                final cancelBtn = Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: TextButton(
                    onPressed: _sending ? null : _cancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'Anuluj',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white60,
                        decorationThickness: 1.5,
                      ),
                    ),
                  ),
                );

                if (tall) {
                  return Column(
                    children: [
                      closeBtn,
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...headerTexts,
                            const SizedBox(height: 40),
                            orbBlock,
                            const SizedBox(height: 32),
                            instructionText,
                          ],
                        ),
                      ),
                      cancelBtn,
                    ],
                  );
                }

                // Krótszy ekran: scrollowalny, orb pełnowymiarowy
                return Column(
                  children: [
                    closeBtn,
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ...headerTexts,
                            const SizedBox(height: 24),
                            orbBlock,
                            const SizedBox(height: 20),
                            instructionText,
                          ],
                        ),
                      ),
                    ),
                    cancelBtn,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring({required double diameter, required double opacity}) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildHoldButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _onHoldStart(),
      onTapUp: (_) => _onHoldEnd(),
      onTapCancel: _onHoldEnd,
      child: AnimatedScale(
        scale: _holding ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: _coral, width: 10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress overlay przy trzymaniu (zaciemnia coral wokół)
              if (_holding || _sending)
                Positioned.fill(
                  child: ClipOval(
                    child: AnimatedBuilder(
                      animation: _holdCtrl,
                      builder: (context, _) => CircularProgressIndicator(
                        value: _holdCtrl.value > 0 ? _holdCtrl.value : null,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _coral.withValues(alpha: 0.25),
                        ),
                        strokeWidth: 12,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NACIŚNIJ',
                    style: TextStyle(
                      color: context.iosLabel,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.emergency_share,
                    color: _coral,
                    size: 64,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _BlurOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 80, spreadRadius: 20),
        ],
      ),
    );
  }
}
