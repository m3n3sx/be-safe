import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/design_tokens.dart';

/// F32: Lekka warstwa parental controls — linkuje do dedykowanych narzędzi.
/// be:Safe nie próbuje zastępować Family Link / Qustodio, tylko kieruje na
/// sprawdzone narzędzia. Sami zajmujemy się safety + komunikacją rodzinną.
class ParentalControlsScreen extends StatelessWidget {
  const ParentalControlsScreen({super.key});

  static const _tools = <_PcTool>[
    _PcTool(
      name: 'Google Family Link',
      desc: 'Limity czasu, blokada aplikacji, lokalizacja, kontrola zakupów (Android + iOS).',
      url: 'https://families.google.com/familylink/',
      icon: Icons.family_restroom,
      iconColor: Color(0xFF1A2027),
    ),
    _PcTool(
      name: 'Apple Screen Time / Czas przed ekranem',
      desc: 'Wbudowane w iOS/macOS. Limity, raporty użycia, treści dla dzieci.',
      url: 'https://support.apple.com/pl-pl/HT208982',
      icon: Icons.phone_iphone,
      iconColor: Color(0xFF44474B),
    ),
    _PcTool(
      name: 'Qustodio',
      desc: 'Płatny menedżer kontroli rodzicielskiej — filtr WWW, social, śledzenie wiadomości.',
      url: 'https://www.qustodio.com/pl/',
      icon: Icons.shield_outlined,
      iconColor: Color(0xFFFF7A7A),
    ),
    _PcTool(
      name: 'Bark',
      desc: 'AI monitorujące wiadomości i social media dziecka pod kątem zagrożeń (US/EN).',
      url: 'https://www.bark.us/',
      icon: Icons.psychology_alt_outlined,
      iconColor: Color(0xFF9DF4CB),
    ),
    _PcTool(
      name: 'NASK — Bezpieczna szkoła / dyzurnet.pl',
      desc: 'Polskie centrum zgłaszania nielegalnych treści dotyczących dzieci.',
      url: 'https://dyzurnet.pl/',
      icon: Icons.report_problem_outlined,
      iconColor: Color(0xFF03080E),
    ),
    _PcTool(
      name: 'Fundacja Dajemy Dzieciom Siłę',
      desc: 'Porady dla rodziców, materiały edukacyjne, telefon zaufania 116 111.',
      url: 'https://fdds.pl/',
      icon: Icons.volunteer_activism_outlined,
      iconColor: Color(0xFF9EEBEC),
    ),
  ];

  Future<void> _open(BuildContext ctx, String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Nie udało się otworzyć $url')));
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
        leading: IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Wróć', onPressed: () => Navigator.pop(context)),
        title: const Text('Kontrola rodzicielska', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF9DF4CB), Color(0xFF9EEBEC)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 36, color: Color(0xFF1A2027)),
                SizedBox(height: 12),
                Text('be:Safe nie zastępuje pełnego parental control',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A2027))),
                SizedBox(height: 6),
                Text(
                  'My zajmujemy się bezpieczeństwem w okolicy i komunikacją rodzinną. '
                  'Do limitów czasu, kontroli treści i filtrów WWW polecamy sprawdzone narzędzia ↓',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1A2027), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('POLECANE NARZĘDZIA',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFF44474B))),
          ),
          const SizedBox(height: 8),
          ..._tools.map((t) => _ToolTile(tool: t, onTap: () => _open(context, t.url))),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A7A).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pamiętaj', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF03080E))),
                SizedBox(height: 6),
                Text(
                  '• Rozmawiaj z dzieckiem zamiast wyłącznie blokować.\n'
                  '• Ustal wspólnie zasady korzystania z telefonu.\n'
                  '• Sam(a) bądź przykładem zdrowego korzystania z urządzeń.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF44474B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PcTool {
  final String name, desc, url;
  final IconData icon;
  final Color iconColor;
  const _PcTool({required this.name, required this.desc, required this.url, required this.icon, required this.iconColor});
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool, required this.onTap});
  final _PcTool tool;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: tool.iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(tool.icon, color: tool.iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tool.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF03080E))),
                      const SizedBox(height: 4),
                      Text(tool.desc, style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF44474B))),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new, size: 18, color: Color(0xFF44474B)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
