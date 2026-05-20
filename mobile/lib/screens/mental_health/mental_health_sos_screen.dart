// F26: Mental Health SOS - linie zaufania dla osób w kryzysie
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/design_tokens.dart';

class MentalHealthSosScreen extends StatelessWidget {
  const MentalHealthSosScreen({super.key});

  Future<void> _call(BuildContext context, String number, String label) async {
    HapticFeedback.mediumImpact();
    final uri = Uri.parse('tel:${number.replaceAll(' ', '')}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie można otworzyć dialera. Numer: $number')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd. Zadzwoń ręcznie: $number')),
        );
      }
    }
  }

  Future<void> _openWeb(BuildContext context, String url) async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się otworzyć: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SerenityColors.surface,
      appBar: AppBar(
        backgroundColor: SerenityColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 28),
          color: SerenityColors.primary,
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Zamknij',
        ),
        title: Text(
          'Wsparcie psychologiczne',
          style: SerenityText.headlineHeroMobile.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SerenityColors.secondaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite, color: SerenityColors.onSecondaryContainer, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nie jesteś sam/sama',
                            style: SerenityText.headlineHeroMobile.copyWith(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Te numery są bezpłatne i anonimowe. Specjaliści wysłuchają i pomogą znaleźć rozwiązanie.',
                      style: SerenityText.bodyMain.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _CallTile(
                number: '116 123',
                title: 'Telefon Zaufania dla dorosłych',
                subtitle: 'Kryzys, depresja, samotność — 24/7',
                color: SerenityColors.primaryContainer,
                foreground: Colors.white,
                onTap: () => _call(context, '116123', 'Telefon Zaufania'),
              ),
              const SizedBox(height: 12),
              _CallTile(
                number: '116 111',
                title: 'Telefon Zaufania dla Dzieci i Młodzieży',
                subtitle: 'Dla osób do 18 r. ż. — 24/7',
                color: SerenityColors.secondaryContainer,
                foreground: SerenityColors.onSecondaryContainer,
                onTap: () => _call(context, '116111', 'Telefon Zaufania dzieci'),
              ),
              const SizedBox(height: 12),
              _CallTile(
                number: '800 70 22 22',
                title: 'Centrum Wsparcia dla Osób w Stanie Kryzysu',
                subtitle: 'Linia dla dorosłych — pon-pt 9-21',
                color: SerenityColors.glowCalmAqua,
                foreground: SerenityColors.primaryContainer,
                onTap: () => _call(context, '800702222', 'Centrum Wsparcia'),
              ),
              const SizedBox(height: 12),
              _CallTile(
                number: '112',
                title: 'Numer alarmowy',
                subtitle: 'Bezpośrednie zagrożenie życia',
                color: SerenityColors.glowAlertCoral,
                foreground: Colors.white,
                onTap: () => _call(context, '112', '112'),
              ),
              const SizedBox(height: 24),
              Material(
                color: SerenityColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openWeb(context, 'https://www.psycholodzy.pl'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: SerenityColors.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.psychology_outlined,
                              color: SerenityColors.onSecondaryContainer),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Znajdź psychologa', style: SerenityText.bodyMain.copyWith(
                                fontWeight: FontWeight.w600, color: SerenityColors.primary)),
                              const SizedBox(height: 2),
                              Text('psycholodzy.pl — baza specjalistów',
                                  style: SerenityText.labelCaps),
                            ],
                          ),
                        ),
                        Icon(Icons.open_in_new, color: SerenityColors.onSurfaceVariant, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pamiętaj: prośba o pomoc to oznaka siły, nie słabości.',
                textAlign: TextAlign.center,
                style: SerenityText.labelCaps.copyWith(letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Color color;
  final Color foreground;
  final VoidCallback onTap;
  const _CallTile({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.call, color: foreground, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(number, style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: foreground, letterSpacing: 0.5,
                    )),
                    const SizedBox(height: 2),
                    Text(title, style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: foreground, height: 1.2,
                    )),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(
                      fontSize: 12, color: foreground.withValues(alpha: 0.85),
                    )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: foreground.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
