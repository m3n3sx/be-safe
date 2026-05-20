/// be:Safe v2 — Emergency Numbers Screen (Serenity Guard)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/serenity_card.dart';
import '../mental_health/mental_health_sos_screen.dart';

class EmergencyNumbersScreen extends StatelessWidget {
  const EmergencyNumbersScreen({super.key});

  static const _numbers = [
    _Emergency('112', 'Europejski numer alarmowy', Icons.emergency,
        'Uniwersalny — policja, straż, pogotowie'),
    _Emergency('997', 'Policja', Icons.local_police,
        'Kradzieże, wypadki, zagrożenia'),
    _Emergency('998', 'Straż Pożarna', Icons.local_fire_department,
        'Pożary, wypadki, ratownictwo'),
    _Emergency('999', 'Pogotowie ratunkowe', Icons.medical_services,
        'Sytuacje zagrażające życiu'),
    _Emergency('986', 'Straż Miejska', Icons.security, 'Porządek publiczny'),
    _Emergency('987', 'Centrum Zarządzania Kryzysowego', Icons.crisis_alert,
        'Kryzysy, katastrofy'),
    _Emergency('601100100', 'GOPR / TOPR — Góry', Icons.terrain,
        'Ratownictwo górskie'),
    _Emergency('601100300', 'WOPR — Woda', Icons.water,
        'Ratownictwo wodne'),
    _Emergency('116111', 'Telefon zaufania dla dzieci', Icons.child_care,
        'Pomoc psychologiczna (bezpłatny)'),
    _Emergency('116123', 'Kryzysowy telefon zaufania', Icons.support_agent,
        'Pomoc w kryzysie emocjonalnym'),
  ];

  Future<void> _call(String number) async {
    HapticFeedback.mediumImpact();
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SerenityColors.surfaceBright,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SerenitySpacing.md,
                vertical: SerenitySpacing.md,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    color: SerenityColors.primary,
                    tooltip: 'Wróć',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Numery alarmowe',
                    style: SerenityText.headlineHeroMobile,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  SerenitySpacing.xl,
                  SerenitySpacing.sm,
                  SerenitySpacing.xl,
                  SerenitySpacing.xxxl,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(SerenitySpacing.md),
                    decoration: BoxDecoration(
                      color: SerenityColors.tertiaryFixed,
                      borderRadius: BorderRadius.circular(
                        SerenityShapes.radiusXl,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: SerenityColors.onTertiaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'W sytuacji bezpośredniego zagrożenia życia ZAWSZE dzwoń pod 112. Aplikacja nie zastępuje służb ratunkowych.',
                            style: SerenityText.bodyMain.copyWith(
                              fontSize: 13,
                              color: SerenityColors.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SerenitySpacing.md),
                  // F26: Mental Health SOS tile
                  Builder(builder: (context) => SerenityCard(
                    padding: const EdgeInsets.all(SerenitySpacing.md),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const MentalHealthSosScreen(),
                      ));
                    },
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SerenityColors.secondaryContainer,
                        ),
                        child: Icon(Icons.favorite, color: SerenityColors.onSecondaryContainer, size: 22),
                      ),
                      const SizedBox(width: SerenitySpacing.md),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Wsparcie psychologiczne',
                              style: SerenityText.labelButton.copyWith(fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('Telefony zaufania 116 123, 116 111 i więcej',
                              style: SerenityText.labelCaps),
                        ],
                      )),
                      Icon(Icons.chevron_right, color: SerenityColors.onSurfaceVariant),
                    ]),
                  )),
                  const SizedBox(height: SerenitySpacing.md),
                  ..._numbers.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: SerenitySpacing.xs,
                      ),
                      child: SerenityCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SerenitySpacing.md,
                          vertical: SerenitySpacing.sm + 2,
                        ),
                        onTap: () => _call(n.number),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: SerenityColors.surfaceContainer,
                              ),
                              child: Icon(
                                n.icon,
                                color: SerenityColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: SerenitySpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: SerenityText.labelButton.copyWith(
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    n.desc,
                                    style: SerenityText.bodyMain.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: SerenityColors.primaryContainer,
                                borderRadius: SerenityShapes.pill(),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: SerenityColors.onPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    n.number,
                                    style: SerenityText.labelButton.copyWith(
                                      fontSize: 13,
                                      color: SerenityColors.onPrimary,
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }
}

class _Emergency {
  final String number;
  final String title;
  final IconData icon;
  final String desc;
  const _Emergency(this.number, this.title, this.icon, this.desc);
}
