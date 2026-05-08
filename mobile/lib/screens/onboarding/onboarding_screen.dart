import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _pages = const [
    _OnboardData(
      icon: Icons.map_outlined,
      title: 'Mapa zagrożeń w czasie rzeczywistym',
      desc: 'Zobacz co się dzieje w Twojej okolicy. Użytkownicy zgłaszają niebezpieczeństwa, Ty widzisz je na mapie.',
      color: Color(0xFFE53935),
    ),
    _OnboardData(
      icon: Icons.notifications_active_outlined,
      title: 'Alerty proximity',
      desc: 'Dostajesz powiadomienie gdy zbliżasz się do strefy zagrożenia. Promień możesz dostosować w ustawieniach.',
      color: Color(0xFFFB8C00),
    ),
    _OnboardData(
      icon: Icons.family_restroom_outlined,
      title: 'Rodzina pod kontrolą',
      desc: 'Utwórz grupę rodzinną i bądź spokojny o bliskich. Widzisz ich lokalizację, dostajesz alerty gdy opuszczą bezpieczną strefę.',
      color: Color(0xFF43A047),
    ),
    _OnboardData(
      icon: Icons.warning_amber_rounded,
      title: 'Zgłaszaj zagrożenia',
      desc: 'Pomagaj innym — zgłaszaj wypadki, kradzieże, agresję, niebezpieczne zwierzęta. Razem tworzymy bezpieczną społeczność.',
      color: Color(0xFF1976D2),
    ),
    _OnboardData(
      icon: Icons.sos,
      title: 'Przycisk SOS',
      desc: 'W nagłej sytuacji jedno kliknięcie wysyła alert do wszystkich w okolicy. W razie zagrożenia życia ZAWSZE dzwoń pod 112.',
      color: Color(0xFFD32F2F),
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
      body: SafeArea(
        child: Column(children: [
          // Skip button
          Align(
            alignment: Alignment.topRight,
            child: TextButton(onPressed: _finish, child: const Text('Pomiń')),
          ),

          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _pages.length,
              itemBuilder: (_, i) {
                final p = _pages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 160, height: 160,
                      decoration: BoxDecoration(color: p.color.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(p.icon, size: 80, color: p.color)),
                    const SizedBox(height: 40),
                    Text(p.title, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text(p.desc, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.4)),
                  ]),
                );
              },
            ),
          ),

          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _page == i ? 24 : 8, height: 8,
              decoration: BoxDecoration(
                color: _page == i ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          const SizedBox(height: 24),

          // Next / Start button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (isLast) _finish();
                  else _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(isLast ? 'Rozpocznij' : 'Dalej', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _OnboardData {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  const _OnboardData({required this.icon, required this.title, required this.desc, required this.color});
}
