import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/accessibility_provider.dart';
import '../../theme/design_tokens.dart';
import '../../theme/ios_surfaces.dart';

/// Ekran ułatwień dostępu (WCAG) — skala tekstu, wysoki kontrast,
/// pogrubienie, ograniczenie animacji, respektowanie ustawień systemowych.
class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  static const _scales = <(String, double)>[
    ('Normalna', 1.0),
    ('Duża', 1.15),
    ('Większa', 1.3),
    ('Maksymalna', 1.5),
  ];

  @override
  Widget build(BuildContext context) {
    final a11y = context.watch<AccessibilityProvider>();
    return Scaffold(
      backgroundColor: context.iosBackground,
      appBar: AppBar(
        backgroundColor: context.iosBackground,
        surfaceTintColor: Colors.transparent,
        title: Text('Ułatwienia dostępu',
            style: SerenityText.headlineHeroMobile.copyWith(fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _section(context, 'ROZMIAR TEKSTU'),
          _card(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _scales.map((s) {
                    final selected = (a11y.textScale - s.$2).abs() < 0.01;
                    return ChoiceChip(
                      label: Text(s.$1),
                      selected: selected,
                      onSelected: (_) => a11y.textScale = s.$2,
                      selectedColor: SerenityColors.secondaryContainer,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? SerenityColors.onSecondaryContainer
                            : context.iosLabel,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                // Podgląd na żywo (skaluje się przez MediaQuery aplikacji).
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.iosCardSurfaceHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Podgląd',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.iosSecondaryLabel)),
                      const SizedBox(height: 6),
                      Text('Bezpieczeństwo Twojej rodziny',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: context.iosLabel)),
                      const SizedBox(height: 4),
                      Text(
                        'Tak będą wyglądać teksty w całej aplikacji.',
                        style:
                            TextStyle(fontSize: 14, color: context.iosSecondaryLabel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _section(context, 'CZYTELNOŚĆ'),
          _card(
            context,
            child: Column(
              children: [
                _switch(
                  context,
                  icon: Icons.contrast,
                  title: 'Wysoki kontrast',
                  subtitle: 'Czystsze czarno-białe teksty i mocniejsze ramki',
                  value: a11y.highContrast,
                  onChanged: (v) => a11y.highContrast = v,
                ),
                _divider(context),
                _switch(
                  context,
                  icon: Icons.format_bold,
                  title: 'Pogrubione teksty',
                  subtitle: 'Grubsza czcionka dla lepszej czytelności',
                  value: a11y.boldText,
                  onChanged: (v) => a11y.boldText = v,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _section(context, 'RUCH'),
          _card(
            context,
            child: _switch(
              context,
              icon: Icons.motion_photos_off,
              title: 'Ogranicz animacje',
              subtitle:
                  'Wyłącza pulsowanie, poświaty i efekty ruchu (epilepsja, choroba lokomocyjna)',
              value: a11y.reduceMotion,
              onChanged: (v) => a11y.reduceMotion = v,
            ),
          ),
          const SizedBox(height: 20),
          _section(context, 'SYSTEM'),
          _card(
            context,
            child: _switch(
              context,
              icon: Icons.settings_suggest_outlined,
              title: 'Respektuj ustawienia systemu',
              subtitle:
                  'Uwzględnij rozmiar czcionki, pogrubienie i animacje ustawione w Androidzie',
              value: a11y.respectSystem,
              onChanged: (v) => a11y.respectSystem = v,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Wskazówka: be:Safe działa też z czytnikiem ekranu (TalkBack). '
              'SOS i alarmy nie wymagają mowy — wszystko obsłużysz dotykiem.',
              style: TextStyle(fontSize: 13, color: context.iosSecondaryLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Text(title,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: context.iosSecondaryLabel)),
      );

  Widget _card(BuildContext context, {required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.iosCardSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      );

  Widget _divider(BuildContext context) => Divider(
      height: 20, color: context.iosSeparator.withValues(alpha: 0.4));

  Widget _switch(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.iosCardSurfaceHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: context.iosLabel),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.iosLabel)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style:
                      TextStyle(fontSize: 12, color: context.iosSecondaryLabel)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
