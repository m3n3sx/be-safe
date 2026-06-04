// F27: Poradnik bezpieczeństwa - 12 sekcji rozwijanych
import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/design_tokens.dart';

class SafetyGuideScreen extends StatelessWidget {
  const SafetyGuideScreen({super.key});

  static const _sections = <_GuideSection>[
    _GuideSection(
      icon: Icons.local_phone,
      title: 'Numery alarmowe',
      summary: 'Kiedy 112 / 999 / 998 / 997',
      content:
          '• 112 — uniwersalny numer alarmowy (działa nawet bez karty SIM)\n'
          '• 999 — Pogotowie Ratunkowe (życie/zdrowie)\n'
          '• 998 — Straż Pożarna (pożar, gaz, wypadek, ratownictwo)\n'
          '• 997 — Policja (przestępstwo, zagrożenie)\n'
          '• 991 — Pogotowie Energetyczne\n'
          '• 992 — Pogotowie Gazowe\n'
          '• 994 — Pogotowie Wodne\n\n'
          'Mów spokojnie: gdzie jesteś, co się stało, ilu jest poszkodowanych. Nie rozłączaj się pierwszy.',
    ),
    _GuideSection(
      icon: Icons.favorite,
      title: 'Pierwsza pomoc (RKO)',
      summary: '30:2 + AED — uratujesz życie',
      content:
          '1. SPRAWDŹ przytomność — potrząśnij, zapytaj „Słyszysz mnie?"\n'
          '2. WEZWIJ 112 / 999\n'
          '3. UDROŻNIJ drogi oddechowe — odchyl głowę\n'
          '4. SPRAWDŹ oddech 10 sekund\n'
          '5. Jeśli BRAK oddechu — zacznij RKO:\n'
          '   • 30 uciśnięć klatki piersiowej (głębokość 5-6 cm, tempo 100-120/min)\n'
          '   • 2 oddechy ratownicze\n'
          '   • Powtarzaj do przyjazdu pomocy\n\n'
          'Użyj AED jeśli dostępne — urządzenie samo prowadzi głosem. Znajdź najbliższy AED na ekranie Mapa.',
    ),
    _GuideSection(
      icon: Icons.home,
      title: 'Bezpieczeństwo w domu',
      summary: 'Gaz, prąd, kuchnia, łazienka',
      content:
          '• Czujki dymu i czadu — sprawdzaj baterie co 6 miesięcy\n'
          '• Wyłączniki różnicowoprądowe (RCD) w łazience\n'
          '• Gaz: nie zostawiaj garnka bez nadzoru. Czujesz gaz? Otwórz okna, nie włączaj światła, zakręć główny zawór, wyjdź, zadzwoń 992.\n'
          '• Środki czystości w zamkniętej szafce, z dala od żywności\n'
          '• Mata antypoślizgowa w wannie/prysznicu (szczególnie dla seniorów)',
    ),
    _GuideSection(
      icon: Icons.thunderstorm,
      title: 'Burza i blackout',
      summary: 'Co robić podczas burzy / awarii prądu',
      content:
          'Podczas burzy:\n'
          '• Schowaj się w solidnym budynku lub samochodzie\n'
          '• Unikaj otwartych przestrzeni, samotnych drzew, masztów, wody\n'
          '• Wyłącz elektronikę z sieci (przepięcia)\n\n'
          'Awaria prądu:\n'
          '• Latarka, świece, zapałki — trzymaj w łatwym miejscu\n'
          '• Powerbank dla telefonu\n'
          '• Lodówka utrzyma temperaturę ~4h zamknięta\n'
          '• Sprawdź lokalną informację Tauron/Enea/PGE',
    ),
    _GuideSection(
      icon: Icons.window,
      title: 'Drzwi, okna, klucze',
      summary: 'Włamania, zgubione klucze',
      content:
          '• Zamykaj drzwi na klucz, nawet wychodząc na chwilę\n'
          '• Nie chowaj klucza pod wycieraczką ani w doniczce\n'
          '• Okna na parterze i piwnicy — zamykaj na zasuwy\n'
          '• Krata w drzwiach od balkonu (parter)\n'
          '• Domofon: nie wpuszczaj nikogo obcego, nawet jeśli „idzie do sąsiada"\n'
          '• Zgubione klucze? Wymień zamki ZARAZ jeśli klucze miały adres',
    ),
    _GuideSection(
      icon: Icons.warning_amber,
      title: 'Oszustwa „na wnuczka"',
      summary: 'Telefoniczne, SMS, BLIK — uważaj!',
      content:
          'NIGDY nie:\n'
          '• Przekazuj pieniędzy obcej osobie, „policjantowi", „prokuratorowi"\n'
          '• Podawaj kodów BLIK ani SMS-em ani przez telefon\n'
          '• Klikaj linków w SMS-ach o „dopłacie", „przesyłce"\n'
          '• Loguj się do banku przez link z maila/SMS-a\n\n'
          'Gdy ktoś dzwoni „z banku" — ROZŁĄCZ SIĘ i zadzwoń na numer z karty.\n'
          'Wnuczek w opałach? Zadzwoń bezpośrednio do niego/jego rodziców.',
    ),
    _GuideSection(
      icon: Icons.directions_car,
      title: 'Bezpieczna jazda',
      summary: 'Alkohol, leki, zmęczenie',
      content:
          '• Po alkoholu — nigdy za kierownicę. 0,2‰ to już wykroczenie.\n'
          '• Leki mogą wpływać na reakcję — sprawdź ulotkę („Wpływ na zdolność prowadzenia")\n'
          '• Zmęczenie = pijany kierowca. Przerwa co 2h jazdy.\n'
          '• Pasy bezpieczeństwa również z tyłu\n'
          '• Foteliki dla dzieci do 150 cm wzrostu\n'
          '• Trzymaj odległość 2 sekundy od poprzedzającego pojazdu',
    ),
    _GuideSection(
      icon: Icons.medication,
      title: 'Lekarstwa',
      summary: 'Dawkowanie, interakcje, termin',
      content:
          '• Sprawdzaj termin ważności — przeterminowane do apteki (utylizacja)\n'
          '• Lista swoich leków przy sobie (w portfelu) — pomoc dla ratowników\n'
          '• Nie łącz alkoholu z lekami\n'
          '• Niektóre leki + grejpfrut = niebezpieczne\n'
          '• Pamiętaj o godzinach (alarmy w telefonie pomocne)\n'
          '• Konsultuj nowe leki z farmaceutą — sprawdzi interakcje',
    ),
    _GuideSection(
      icon: Icons.hiking,
      title: 'Wycieczki i sport',
      summary: 'Co zabrać, jak się przygotować',
      content:
          'W góry / las / nad wodę:\n'
          '• Powiedz komuś gdzie idziesz i o której wracasz\n'
          '• Naładowany telefon + powerbank\n'
          '• Aplikacja Ratunek (GOPR/TOPR/WOPR) — jednoznaczna lokalizacja\n'
          '• Apteczka, woda, czołówka, kurtka przeciwdeszczowa\n'
          '• Sprawdź prognozę pogody\n'
          '• Nie kąp się po alkoholu, w nieznanych miejscach, w nocy',
    ),
    _GuideSection(
      icon: Icons.security,
      title: 'Cyberbezpieczeństwo',
      summary: 'Hasła, 2FA, phishing',
      content:
          '• Hasło: minimum 12 znaków, NIE używaj tego samego w wielu miejscach\n'
          '• Włącz weryfikację dwuetapową (2FA / SMS / aplikacja Authenticator)\n'
          '• Manager haseł: Bitwarden, 1Password, Apple/Google\n'
          '• Nigdy nie podawaj hasła ani PIN-u przez telefon/SMS/email\n'
          '• Aktualizuj system i aplikacje\n'
          '• Połączenia WiFi w kawiarniach — zachowaj ostrożność, używaj VPN\n'
          '• mObywatel — bezpieczna alternatywa dla dokumentów',
    ),
    _GuideSection(
      icon: Icons.child_friendly,
      title: 'Bezpieczeństwo dzieci',
      summary: 'Co powtarzać dziecku codziennie',
      content:
          '• „Nie rozmawiaj z obcymi" — szczególnie gdy proponują coś (cukierka, podwózkę, „mama prosiła")\n'
          '• Numery telefonu rodziców — nauczcie się na pamięć\n'
          '• Bezpieczne miejsca po drodze do szkoły (sklep, przyjaciele)\n'
          '• Hasło rodzinne — które tylko rodzice znają i mogą podać\n'
          '• Kiedy zgubi się — zostań na miejscu, znajdź panią z dzieckiem lub w mundurze\n'
          '• be:Safe: sygnał „JESTEM OK" + bezpieczna trasa do szkoły',
    ),
    _GuideSection(
      icon: Icons.support_agent,
      title: 'Kontakt z be:Safe',
      summary: 'Pomoc techniczna, sugestie',
      content:
          'Masz pytanie lub sugestię? Coś nie działa?\n\n'
          '✉️  support@besafe.org.pl\n'
          '🌐  https://besafe.org.pl\n\n'
          'Aplikacja jest tworzona po to, by Wasza rodzina była bezpieczna. Każda wiadomość liczy się — czytamy wszystko.',
    ),
  ];

  Future<void> _openSupport(BuildContext context) async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse('mailto:support@besafe.org.pl?subject=Kontakt%20be%3ASafe');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('support@besafe.org.pl')),
        );
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
          icon: const Icon(Icons.arrow_back, size: 28),
          color: context.iosLabel,
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Wróć',
        ),
        title: Text(
          'Poradnik bezpieczeństwa',
          style: SerenityText.headlineHeroMobile.copyWith(fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: _sections.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
                child: Text(
                  '12 wskazówek na każdą sytuację. Stuknij w kafelek, by rozwinąć.',
                  style: SerenityText.bodyMain.copyWith(height: 1.4),
                ),
              );
            }
            final s = _sections[i - 1];
            return _GuideCard(section: s, onContactTap: () => _openSupport(context));
          },
        ),
      ),
    );
  }
}

class _GuideSection {
  final IconData icon;
  final String title;
  final String summary;
  final String content;
  const _GuideSection({
    required this.icon,
    required this.title,
    required this.summary,
    required this.content,
  });
}

class _GuideCard extends StatelessWidget {
  final _GuideSection section;
  final VoidCallback onContactTap;
  const _GuideCard({required this.section, required this.onContactTap});

  @override
  Widget build(BuildContext context) {
    final isContact = section.title == 'Kontakt z be:Safe';
    return Material(
      color: context.iosCardSurface,
      borderRadius: BorderRadius.circular(20),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: SerenityColors.secondaryContainer.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: Icon(section.icon, color: SerenityColors.onSecondaryContainer, size: 22),
          ),
          title: Text(section.title, style: SerenityText.bodyMain.copyWith(
            fontWeight: FontWeight.w600, color: context.iosLabel, height: 1.2,
          )),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(section.summary,
                style: SerenityText.labelCaps.copyWith(letterSpacing: 0.2)),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          children: [
            Text(section.content, style: SerenityText.bodyMain.copyWith(height: 1.6)),
            if (isContact) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onContactTap,
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('Napisz do nas'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SerenityColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
