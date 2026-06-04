import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/design_tokens.dart';

/// F28: Cyber-bezpieczeństwo i ochrona danych osobowych.
///
/// Lista zaufanych narzędzi (mObywatel, bezpiecznedane.gov.pl, HIBP, CERT.pl)
/// + checklist higieny cyfrowej. Bez integracji z prawdziwym mObywatel API
/// (wymaga eDoręczeń/podpisu zaufanego — out of scope).
class CyberSafetyScreen extends StatelessWidget {
  const CyberSafetyScreen({super.key});

  static const _tools = [
    (
      'mObywatel — Bezpieczny PESEL',
      'Zastrzeż swój PESEL, aby nikt nie wziął na Ciebie kredytu.',
      'https://www.gov.pl/web/mobywatel/zastrzezenia',
      Icons.lock_outline,
      0xFF1A2027,
    ),
    (
      'Bezpiecznedane.gov.pl',
      'Sprawdź, czy Twoje dane wyciekły i co zrobić, gdy zostały wykradzione.',
      'https://bezpiecznedane.gov.pl',
      Icons.shield_outlined,
      0xFF9DF4CB,
    ),
    (
      'Have I Been Pwned',
      'Globalna baza wycieków danych — sprawdź swój e-mail.',
      'https://haveibeenpwned.com',
      Icons.alternate_email,
      0xFF9EEBEC,
    ),
    (
      'CERT.pl',
      'Zgłoś phishing, oszustwo SMS lub fałszywą stronę.',
      'https://incydent.cert.pl',
      Icons.report_problem_outlined,
      0xFFFF7A7A,
    ),
    (
      'Numer 8080 — phishing SMS',
      'Prześlij dalej podejrzaną wiadomość SMS na numer 8080 (CERT Orange).',
      'sms:8080',
      Icons.sms_outlined,
      0xFFFFD580,
    ),
  ];

  static const _tips = [
    'Używaj różnych haseł do każdego serwisu. Menedżer haseł (Bitwarden, 1Password) pomoże.',
    'Włącz weryfikację dwuetapową (2FA) wszędzie, gdzie się da — szczególnie w banku i poczcie.',
    'NIE klikaj linków z SMS-ów typu „doplata 1zł" / „kurier" / „zwrot podatku". To prawie zawsze phishing.',
    'Sprawdzaj adres strony przed wpisaniem hasła. Banki nigdy nie proszą o pełne hasło/PIN.',
    'Zastrzeż PESEL przez mObywatela jeśli zgubiłeś dowód lub padłeś ofiarą wycieku.',
    'Nie udostępniaj w mediach społecznościowych zdjęć dokumentów (dowód, prawo jazdy).',
  ];

  Future<void> _open(BuildContext ctx, String url) async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Nie udało się otworzyć linku.'),
        ));
      }
    } catch (_) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Brak aplikacji do otwarcia linku.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.iosBackground,
      appBar: AppBar(
        backgroundColor: context.iosBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Wróć',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Bezpieczeństwo danych',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Hero
          Container(
            padding: const EdgeInsets.all(SerenitySpacing.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SerenityColors.secondaryContainer,
                  SerenityColors.glowCalmAqua,
                ],
              ),
              borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, size: 40, color: SerenityColors.primaryContainer),
                SizedBox(width: SerenitySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chroń swoje dane online',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: SerenityColors.primaryContainer,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Polskie i międzynarodowe narzędzia w jednym miejscu.',
                        style: TextStyle(
                          fontSize: 13,
                          color: SerenityColors.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SerenitySpacing.xl),
          Text(
            'NARZĘDZIA',
            style: SerenityText.labelCaps.copyWith(
              color: context.iosSecondaryLabel,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: SerenitySpacing.sm),
          ..._tools.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ToolTile(
                  title: t.$1,
                  description: t.$2,
                  url: t.$3,
                  icon: t.$4,
                  bg: Color(t.$5),
                  onTap: () => _open(context, t.$3),
                ),
              )),
          const SizedBox(height: SerenitySpacing.lg),
          Text(
            'ZASADY HIGIENY CYFROWEJ',
            style: SerenityText.labelCaps.copyWith(
              color: context.iosSecondaryLabel,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: SerenitySpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: context.iosCardSurface,
              borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
            ),
            child: Column(
              children: _tips
                  .asMap()
                  .entries
                  .map((e) => _TipTile(index: e.key + 1, text: e.value))
                  .toList(),
            ),
          ),
          const SizedBox(height: SerenitySpacing.xl),
          Container(
            padding: const EdgeInsets.all(SerenitySpacing.lg),
            decoration: BoxDecoration(
              color: SerenityColors.glowAlertCoral.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
              border: Border.all(
                color: SerenityColors.glowAlertCoral.withValues(alpha: 0.4),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: SerenityColors.glowAlertCoral),
                    SizedBox(width: 8),
                    Text(
                      'Padłeś ofiarą wyłudzenia?',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Zgłoś sprawę na policję (112 lub 997)\n'
                  '• Zastrzeż PESEL w mObywatel\n'
                  '• Powiadom bank i zablokuj karty\n'
                  '• Zgłoś incydent w CERT.pl',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final String title;
  final String description;
  final String url;
  final IconData icon;
  final Color bg;
  final VoidCallback onTap;

  const _ToolTile({
    required this.title,
    required this.description,
    required this.url,
    required this.icon,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.iosCardSurface,
      borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(SerenitySpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bg.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: bg.computeLuminance() < 0.5 ? Colors.white : SerenityColors.primaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: SerenitySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(description,
                        style: TextStyle(
                            fontSize: 12,
                            color: context.iosSecondaryLabel,
                            height: 1.3)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new,
                  size: 18, color: context.iosSecondaryLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  final int index;
  final String text;
  const _TipTile({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: SerenityColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: SerenityColors.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
