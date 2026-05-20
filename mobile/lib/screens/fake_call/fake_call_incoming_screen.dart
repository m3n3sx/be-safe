/// be:Safe — F01 Fake Call incoming + active call
///
/// Pełnoekranowa atrapa przychodzącego połączenia (czarne tło, awatar, 2 przyciski).
/// Po Accept przechodzi w "rozmowę" z licznikiem czasu i głośnikiem/kamerą buttonami.
/// Wykorzystuje HapticFeedback w interwałach + SystemChrome immersive jako proxy dzwonka.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FakeCallIncomingScreen extends StatefulWidget {
  final String callerName;
  final String callerNumber;

  const FakeCallIncomingScreen({
    super.key,
    required this.callerName,
    required this.callerNumber,
  });

  @override
  State<FakeCallIncomingScreen> createState() => _FakeCallIncomingScreenState();
}

class _FakeCallIncomingScreenState extends State<FakeCallIncomingScreen>
    with SingleTickerProviderStateMixin {
  bool _accepted = false;
  int _callSeconds = 0;
  Timer? _ringTimer;
  Timer? _callTimer;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    // Immersive sticky + wibracja co 1s symulująca dzwonek
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startRinging();
  }

  void _startRinging() {
    HapticFeedback.heavyImpact();
    _ringTimer?.cancel();
    _ringTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
    });
    // Auto-decline po 45 sekundach jeśli nie reaguje
    Timer(const Duration(seconds: 45), () {
      if (mounted && !_accepted) _hangup();
    });
  }

  void _accept() {
    HapticFeedback.mediumImpact();
    _ringTimer?.cancel();
    _pulseCtrl.stop();
    setState(() => _accepted = true);
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _callSeconds++);
    });
  }

  void _hangup() {
    HapticFeedback.mediumImpact();
    _ringTimer?.cancel();
    _callTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _ringTimer?.cancel();
    _callTimer?.cancel();
    _pulseCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _formatDuration(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _hangup();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A2027),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                _accepted ? 'Rozmowa trwa' : 'Połączenie przychodzące',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.callerName,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.callerNumber,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              if (_accepted) ...[
                const SizedBox(height: 8),
                Text(
                  _formatDuration(_callSeconds),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              const Spacer(),
              // Animowany awatar
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, child) {
                  final scale =
                      _accepted ? 1.0 : (1.0 + 0.06 * _pulseCtrl.value);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF9DF4CB),
                        boxShadow: _accepted
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF9DF4CB)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                              ],
                      ),
                      child: Center(
                        child: Text(
                          widget.callerName.isNotEmpty
                              ? widget.callerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF1A2027),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              if (_accepted)
                _buildActiveControls()
              else
                _buildIncomingControls(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CallButton(
            color: const Color(0xFFFF7A7A),
            icon: Icons.call_end,
            label: 'Odrzuć',
            onTap: _hangup,
          ),
          _CallButton(
            color: const Color(0xFF1B873A),
            icon: Icons.call,
            label: 'Odbierz',
            onTap: _accept,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _IconLabel(icon: Icons.mic_off_outlined, label: 'Wycisz'),
              _IconLabel(icon: Icons.dialpad, label: 'Klawiatura'),
              _IconLabel(icon: Icons.volume_up_outlined, label: 'Głośnik'),
            ],
          ),
          const SizedBox(height: 32),
          _CallButton(
            color: const Color(0xFFFF7A7A),
            icon: Icons.call_end,
            label: 'Rozłącz',
            onTap: _hangup,
            wide: true,
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool wide;

  const _CallButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: wide ? 88 : 72,
            height: wide ? 88 : 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: wide ? 36 : 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IconLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
