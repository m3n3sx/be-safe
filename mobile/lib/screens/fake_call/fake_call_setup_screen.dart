/// be:Safe — F01 Fake Call setup
///
/// Ekran do skonfigurowania i uruchomienia fałszywego połączenia.
/// Użytkownik wybiera kto "dzwoni", opóźnienie i odpala atrapę.
/// Pozwala wyjść z niezręcznej sytuacji udając, że odbiera ważny telefon.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import 'fake_call_incoming_screen.dart';

class FakeCallSetupScreen extends StatefulWidget {
  const FakeCallSetupScreen({super.key});

  @override
  State<FakeCallSetupScreen> createState() => _FakeCallSetupScreenState();
}

class _FakeCallSetupScreenState extends State<FakeCallSetupScreen> {
  String _callerName = 'Mama';
  String _callerNumber = '+48 600 100 200';
  int _delaySec = 5;
  Timer? _countdownTimer;
  int _countdown = 0;

  static const _presetCallers = [
    {'name': 'Mama', 'number': '+48 600 100 200'},
    {'name': 'Tata', 'number': '+48 600 100 201'},
    {'name': 'Szef', 'number': '+48 22 500 50 50'},
    {'name': 'Lekarz', 'number': '+48 22 700 80 80'},
    {'name': 'Babcia', 'number': '+48 65 444 22 11'},
  ];

  static const _delayOptions = [
    {'sec': 0, 'label': 'Natychmiast'},
    {'sec': 5, 'label': '5 sek.'},
    {'sec': 15, 'label': '15 sek.'},
    {'sec': 30, 'label': '30 sek.'},
    {'sec': 60, 'label': '1 min'},
  ];

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _start() {
    HapticFeedback.mediumImpact();
    if (_delaySec == 0) {
      _open();
      return;
    }
    setState(() => _countdown = _delaySec);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _open();
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 0);
    HapticFeedback.lightImpact();
  }

  void _open() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => FakeCallIncomingScreen(
          callerName: _callerName,
          callerNumber: _callerNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final running = _countdown > 0;
    return Scaffold(
      backgroundColor: SerenityColors.surfaceBright,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Wróć',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Fałszywy telefon',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: SerenityColors.secondaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: SerenityColors.onSecondaryContainer, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Wybierz kto "zadzwoni" i kiedy. Idealne aby wyjść z niezręcznej rozmowy lub uniknąć niebezpiecznej sytuacji.',
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: SerenityColors.onSecondaryContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Kto dzwoni?',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: SerenityColors.onSurfaceVariant)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetCallers.map((c) {
                final sel = c['name'] == _callerName;
                return ChoiceChip(
                  label: Text(c['name']!),
                  selected: sel,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _callerName = c['name']!;
                      _callerNumber = c['number']!;
                    });
                  },
                  selectedColor: SerenityColors.secondaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: sel
                        ? SerenityColors.onSecondaryContainer
                        : SerenityColors.primary,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _callerName,
              decoration: const InputDecoration(
                labelText: 'Lub wpisz własne imię',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) =>
                  setState(() => _callerName = v.trim().isEmpty ? 'Mama' : v),
            ),
            const SizedBox(height: 24),
            const Text('Kiedy zadzwonić?',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: SerenityColors.onSurfaceVariant)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _delayOptions.map((d) {
                final sel = d['sec'] == _delaySec;
                return ChoiceChip(
                  label: Text(d['label']! as String),
                  selected: sel,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _delaySec = d['sec']! as int);
                  },
                  selectedColor: SerenityColors.secondaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: sel
                        ? SerenityColors.onSecondaryContainer
                        : SerenityColors.primary,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            if (!running)
              SizedBox(
                height: 64,
                child: FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.phone_in_talk, size: 28),
                  label: Text(_delaySec == 0
                      ? 'ZADZWOŃ TERAZ'
                      : 'ZAPLANUJ ZA $_delaySec s'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SerenityColors.primaryContainer,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SerenityColors.glowAlertCoral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
                  border: Border.all(
                      color: SerenityColors.glowAlertCoral, width: 1.5),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.timer,
                        color: SerenityColors.glowAlertCoral, size: 36),
                    const SizedBox(height: 8),
                    Text('Telefon zadzwoni za $_countdown s',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('"$_callerName" — $_callerNumber',
                        style: const TextStyle(
                            fontSize: 14,
                            color: SerenityColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _cancelCountdown,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('ANULUJ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SerenityColors.error,
                    side: const BorderSide(
                        color: SerenityColors.error, width: 2),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Po odebraniu połączenia zobaczysz ekran z odtwarzanym dźwiękiem rozmowy. Możesz "rozmawiać" lub po prostu wyjść z sytuacji.',
              style: TextStyle(
                  fontSize: 13,
                  color: SerenityColors.onSurfaceVariant,
                  height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
