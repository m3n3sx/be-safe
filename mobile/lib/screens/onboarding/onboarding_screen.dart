/// be:Safe v2 — Onboarding Screen (Serenity Guard)
///
/// 5-page intro flow. Each page features a glow orb with an icon, headline,
/// and supporting copy. Final CTA transitions user to login.
///
/// Design source: design/stitch_v2/screens/onboarding_*
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/glow_orb.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _pages = const [
    _OnboardPage(
      icon: Icons.shield_outlined,
      title: 'Witaj w be:Safe',
      desc: 'Twoja spokojna strefa bezpieczeństwa. Zobacz co dzieje się w okolicy i chroń bliskich.',
      orbColor: SerenityColors.glowSafeMint,
    ),
    _OnboardPage(
      icon: Icons.map_outlined,
      title: 'Mapa w czasie rzeczywistym',
      desc: 'Zobacz zagrożenia zgłoszone przez społeczność. Wszystko w jednym, wyciszonym widoku.',
      orbColor: SerenityColors.glowCalmAqua,
    ),
    _OnboardPage(
      icon: Icons.notifications_none,
      title: 'Inteligentne alerty',
      desc: 'Powiadamiamy tylko o tym co ważne, w promieniu który sam ustawisz.',
      orbColor: SerenityColors.glowSafeMint,
    ),
    _OnboardPage(
      icon: Icons.family_restroom_outlined,
      title: 'Rodzina pod opieką',
      desc: 'Utwórz grupę rodzinną. Wiedz gdzie są bliscy i czy są bezpieczni.',
      orbColor: SerenityColors.glowCalmAqua,
    ),
    _OnboardPage(
      icon: Icons.sos,
      title: 'Jeden gest, cała pomoc',
      desc: 'SOS powiadamia rodzinę, społeczność i dzwoni po pomoc. Dostępny zawsze.',
      orbColor: SerenityColors.glowAlertCoral,
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: SerenityColors.surfaceBright,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                  right: SerenitySpacing.md,
                ),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Pomiń',
                    style: SerenityText.labelButton,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SerenitySpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GlowOrb(
                          size: 260,
                          color: p.orbColor,
                          coreOpacity: 0.5,
                          pulse: _page == i,
                          child: Icon(
                            p.icon,
                            size: 72,
                            color: SerenityColors.primary,
                          ),
                        ),
                        const SizedBox(height: SerenitySpacing.xxxl),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: SerenityText.displayMd.copyWith(
                            fontSize: 32,
                            height: 40 / 32,
                          ),
                        ),
                        const SizedBox(height: SerenitySpacing.md),
                        Text(
                          p.desc,
                          textAlign: TextAlign.center,
                          style: SerenityText.bodyMain,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? SerenityColors.primary
                        : SerenityColors.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: SerenitySpacing.xl),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: SerenityColors.primaryContainer,
                  borderRadius: SerenityShapes.pill(),
                  child: InkWell(
                    borderRadius: SerenityShapes.pill(),
                    onTap: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _ctrl.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          isLast ? 'Rozpocznij' : 'Dalej',
                          style: SerenityText.labelButton.copyWith(
                            fontSize: 16,
                            color: SerenityColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final String title;
  final String desc;
  final Color orbColor;
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.desc,
    required this.orbColor,
  });
}
