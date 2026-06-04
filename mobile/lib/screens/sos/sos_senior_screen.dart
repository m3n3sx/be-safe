/// be:Safe — SOS Senior Screen
///
/// Tryb seniora (60+). Maksymalnie prosty UX: 2 ogromne przyciski (96px height)
/// + brak gestów hold/swipe. Każda akcja działa od razu po jednym tapie.
/// Czcionka 22-32px, wysokie kontrasty, haptic + sound feedback.
///
/// 3 akcje:
/// - ZADZWOŃ POD 112 (coral) → launchUrl('tel:112')
/// - POWIADOM RODZINĘ (navy) → POST /alerts SOS + powrót
/// - WRACAM (outline) → pop
///
/// Design source: design/new/.../sos_tryb_seniora/code.html
library;

import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

class SosSeniorScreen extends StatefulWidget {
  const SosSeniorScreen({super.key});

  @override
  State<SosSeniorScreen> createState() => _SosSeniorScreenState();
}

class _SosSeniorScreenState extends State<SosSeniorScreen> {
  static const _coral = Color(0xFFFF7A7A);
  bool _sendingFamily = false;
  bool _calling112 = false;

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

  Future<void> _call112() async {
    if (_calling112) return;
    setState(() => _calling112 = true);
    await HapticFeedback.heavyImpact();
    try {
      final uri = Uri.parse('tel:112');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        _showError('Nie można nawiązać połączenia. Wybierz 112 ręcznie.');
      }
    } finally {
      if (mounted) setState(() => _calling112 = false);
    }
  }

  Future<void> _notifyFamily() async {
    if (_sendingFamily) return;
    setState(() => _sendingFamily = true);
    await HapticFeedback.heavyImpact();
    await HapticFeedback.vibrate();

    try {
      final pos = await _getPosition();
      final loc = pos != null
          ? LatLng(pos.latitude, pos.longitude)
          : const LatLng(52.2297, 21.0122);

      if (!mounted) return;
      final api = context.read<ApiService>();

      await api.post('/alerts', {
        'category': 'aggression',
        'title': '🆘 SOS — Potrzebuję pomocy!',
        'description': 'Alarm SOS — powiadomiono rodzinę',
        'lat': loc.latitude,
        'lng': loc.longitude,
        'radius_m': 500,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: SerenityColors.secondary,
          content: const Text(
            '✓ Twoja rodzina została powiadomiona',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      _showError('Nie udało się wysłać sygnału. Spróbuj jeszcze raz.');
    } finally {
      if (mounted) setState(() => _sendingFamily = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: SerenityColors.error,
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _goBack() {
    HapticFeedback.selectionClick();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SerenityColors.background,
      body: Stack(
        children: [
          // Ambient background blobs (delikatne)
          Positioned(
            top: -100,
            left: -100,
            child: _BlurBlob(
              size: 380,
              color: SerenityColors.secondaryContainer.withValues(alpha: 0.30),
            ),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: _BlurBlob(
              size: 256,
              color: _coral.withValues(alpha: 0.18),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // TopBar: Zamknij + POMOC
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: SizedBox(
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Tooltip(
                            message: 'Zamknij',
                            child: Material(
                              color: SerenityColors.primaryContainer,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _goBack,
                                child: const SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'POMOC',
                          style: TextStyle(
                            color: SerenityColors.primaryContainer,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // Hero SOS shield
                        _buildHeroShield(),
                        const SizedBox(height: 32),

                        // Heading
                        Text(
                          'POTRZEBUJESZ\nPOMOCY?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: SerenityColors.primaryContainer,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Naciśnij jeden z dużych przycisków.\nTwoja rodzina otrzyma sygnał\nz Twoją lokalizacją.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.iosSecondaryLabel,
                            fontSize: 18,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ZADZWOŃ POD 112 (coral)
                        _SeniorSosButton(
                          label: 'ZADZWOŃ POD 112',
                          icon: Icons.call,
                          iconBg: Colors.white.withValues(alpha: 0.20),
                          iconColor: Colors.white,
                          backgroundColor: _coral,
                          foregroundColor: Colors.white,
                          loading: _calling112,
                          shadowColor: _coral.withValues(alpha: 0.30),
                          onTap: _call112,
                        ),
                        const SizedBox(height: 16),

                        // POWIADOM RODZINĘ (navy)
                        _SeniorSosButton(
                          label: 'POWIADOM RODZINĘ',
                          subtitle: 'Anna, Tomek otrzymają wiadomość',
                          icon: Icons.family_restroom,
                          iconBg: SerenityColors.secondaryContainer,
                          iconColor: SerenityColors.primaryContainer,
                          backgroundColor: SerenityColors.primaryContainer,
                          foregroundColor: Colors.white,
                          loading: _sendingFamily,
                          shadowColor: SerenityColors.primaryContainer
                              .withValues(alpha: 0.25),
                          onTap: _notifyFamily,
                        ),
                        const SizedBox(height: 32),

                        // WRACAM (outline)
                        SizedBox(
                          height: 64,
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _goBack,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: SerenityColors.primaryContainer,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'WRACAM',
                              style: TextStyle(
                                color: SerenityColors.primaryContainer,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroShield() {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow halo
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _coral.withValues(alpha: 0.18),
                  _coral.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
          // White circle z coral border
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: _coral, width: 5),
              boxShadow: [
                BoxShadow(
                  color: _coral.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'SOS',
                style: TextStyle(
                  color: _coral,
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeniorSosButton extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color shadowColor;
  final bool loading;
  final VoidCallback onTap;

  const _SeniorSosButton({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.shadowColor,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 96,
          width: double.infinity,
          child: Material(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            elevation: 0,
            child: Ink(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: loading ? null : onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Icon tarcza
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconBg,
                        ),
                        child: loading
                            ? Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      iconColor,
                                    ),
                                  ),
                                ),
                              )
                            : Icon(icon, size: 36, color: iconColor),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: foregroundColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: TextStyle(
              color: context.iosSecondaryLabel,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _BlurBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _BlurBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 100, spreadRadius: 30),
        ],
      ),
    );
  }
}
