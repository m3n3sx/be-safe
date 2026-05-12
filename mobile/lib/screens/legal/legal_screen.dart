import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class LegalScreen extends StatelessWidget {
  final String type; // 'terms' or 'privacy'
  const LegalScreen({super.key, required this.type});

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
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    type == 'terms' ? 'Regulamin' : 'Polityka prywatności',
                    style: SerenityText.headlineHeroMobile,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  SerenitySpacing.xl,
                  SerenitySpacing.sm,
                  SerenitySpacing.xl,
                  SerenitySpacing.xxxl,
                ),
                child: Text(
                  type == 'terms' ? _terms : _privacy,
                  style: SerenityText.bodyMain.copyWith(
                    fontSize: 14,
                    color: SerenityColors.primary,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const String _terms = '''
REGULAMIN APLIKACJI be:Safe

§1. Postanowienia ogólne
1. Aplikacja be:Safe (dalej „Aplikacja") jest społecznościową aplikacją mobilną umożliwiającą zgłaszanie zagrożeń bezpieczeństwa oraz śledzenie lokalizacji członków rodziny.
2. Operatorem Aplikacji jest właściciel strony besafe.org.pl (dalej „Operator").
3. Korzystanie z Aplikacji oznacza akceptację niniejszego Regulaminu.

§2. Wymagania techniczne
1. Do korzystania z Aplikacji wymagane jest urządzenie z systemem Android 7.0+ lub iOS 13+.
2. Do pełnej funkcjonalności wymagane jest połączenie internetowe i dostęp do GPS.

§3. Rejestracja i konto
1. Korzystanie z Aplikacji wymaga założenia konta.
2. Użytkownik zobowiązuje się podać prawdziwe dane.
3. Osoby poniżej 13 roku życia mogą korzystać z Aplikacji wyłącznie za zgodą rodzica/opiekuna w ramach grupy rodzinnej.
4. Użytkownik ponosi odpowiedzialność za zachowanie poufności danych logowania.

§4. Zgłaszanie zagrożeń
1. Użytkownik może zgłaszać zagrożenia bezpieczeństwa poprzez utworzenie alertu.
2. Zgłoszenia muszą być prawdziwe i dotyczyć realnych zagrożeń.
3. Zabronione jest:
   a) zgłaszanie fałszywych alarmów,
   b) zamieszczanie treści obraźliwych, dyskryminujących lub niezgodnych z prawem,
   c) zamieszczanie danych osobowych osób trzecich,
   d) wykorzystywanie Aplikacji do celów sprzecznych z jej przeznaczeniem.
4. Naruszenie powyższych zasad skutkuje usunięciem zgłoszenia i/lub zawieszeniem konta.

§5. Alerty SOS
1. Funkcja SOS służy wyłącznie do sytuacji bezpośredniego zagrożenia życia lub zdrowia.
2. Aplikacja NIE ZASTĘPUJE numerów alarmowych (112, 997, 998, 999, 986).
3. W nagłych przypadkach ZAWSZE należy w pierwszej kolejności zadzwonić pod numer alarmowy.

§6. Grupy rodzinne i śledzenie lokalizacji
1. Śledzenie lokalizacji dziecka wymaga jego zgody oraz zainstalowania Aplikacji na jego urządzeniu.
2. Rodzic zobowiązuje się informować dziecko o śledzeniu lokalizacji.
3. Dziecko może w każdej chwili wyłączyć udostępnianie lokalizacji w ustawieniach Aplikacji.

§7. Ograniczenie odpowiedzialności
1. Operator nie ponosi odpowiedzialności za:
   a) prawdziwość zgłoszeń publikowanych przez użytkowników,
   b) działania podjęte na podstawie informacji z Aplikacji,
   c) awarie techniczne, utratę połączenia, niedokładność GPS,
   d) szkody wynikłe z użycia lub niemożności użycia Aplikacji.
2. Aplikacja jest udostępniana w trybie „jak jest" bez gwarancji jej działania.

§8. Zmiany Regulaminu
1. Operator zastrzega sobie prawo do zmiany Regulaminu.
2. O zmianach użytkownicy zostaną poinformowani w Aplikacji.

§9. Postanowienia końcowe
1. W sprawach nieuregulowanych zastosowanie mają przepisy prawa polskiego.
2. Spory rozstrzyga sąd właściwy dla siedziby Operatora.

Data ostatniej aktualizacji: 2026-05-07
''';

  static const String _privacy = '''
POLITYKA PRYWATNOŚCI APLIKACJI be:Safe

§1. Administrator danych
Administratorem danych osobowych użytkowników Aplikacji be:Safe jest właściciel strony besafe.org.pl (dalej „Administrator").

Kontakt: privacy@besafe.org.pl

§2. Dane zbierane przez Aplikację
W ramach Aplikacji przetwarzamy następujące dane:
1. Dane konta: email, nazwa użytkownika, zahashowane hasło, zdjęcie profilowe (opcjonalnie z Google).
2. Dane lokalizacyjne: aktualna pozycja GPS oraz historia lokalizacji (dla funkcji rodzinnych).
3. Zgłoszenia: treść zgłoszeń, zdjęcia, lokalizacja zdarzenia.
4. Dane techniczne: typ urządzenia, system operacyjny, adres IP, identyfikator instalacji.
5. Dane rodzinne: przynależność do grup rodzinnych, relacje rodzic-dziecko.

§3. Cel przetwarzania danych
Dane są przetwarzane w celu:
1. Świadczenia usług Aplikacji (art. 6 ust. 1 lit. b RODO — wykonanie umowy).
2. Wyświetlania alertów w okolicy użytkownika.
3. Umożliwienia śledzenia lokalizacji członków rodziny.
4. Zapewnienia bezpieczeństwa Aplikacji (wykrywanie nadużyć).
5. Kontaktu z użytkownikiem w sprawie konta.
6. Analityki i udoskonalania Aplikacji (art. 6 ust. 1 lit. f RODO — uzasadniony interes).

§4. Udostępnianie danych
1. Dane NIE SĄ udostępniane podmiotom trzecim w celach marketingowych.
2. Dane mogą być udostępnione:
   a) organom ścigania na podstawie prawomocnego nakazu,
   b) dostawcom usług IT (hosting: OVH, baza: PostgreSQL na własnym serwerze),
   c) Google LLC w zakresie usług Maps SDK i Google Sign-In (zgodnie z ich politykami).

§5. Okres przechowywania danych
1. Dane konta: do czasu usunięcia konta przez użytkownika.
2. Historia lokalizacji: 30 dni.
3. Zgłoszenia: do wygaśnięcia + 90 dni (dla celów statystycznych).
4. Dane po usunięciu konta: kasowane w ciągu 30 dni.

§6. Prawa użytkownika (RODO)
Użytkownik ma prawo do:
1. Dostępu do swoich danych (GET /users/me).
2. Sprostowania danych (PATCH /users/me).
3. Usunięcia konta i danych (w Ustawieniach).
4. Przenoszenia danych (eksport na żądanie).
5. Sprzeciwu wobec przetwarzania.
6. Skargi do Prezesa UODO (www.uodo.gov.pl).

§7. Bezpieczeństwo
1. Hasła są hashowane algorytmem bcrypt.
2. Komunikacja odbywa się przez HTTPS (TLS 1.2+).
3. Lokalizacja dziecka widoczna jest WYŁĄCZNIE dla członków jego grupy rodzinnej.
4. Dane przechowywane są w Polsce (VPS w OVH).

§8. Cookies i identyfikatory
Aplikacja mobilna nie używa cookies. Używa:
1. Identyfikatora instalacji Flutter (do powiadomień push).
2. Tokena JWT (do sesji, przechowywany lokalnie w SharedPreferences).

§9. Dzieci
1. Aplikacja nie zbiera świadomie danych dzieci poniżej 13 roku życia bez zgody rodzica.
2. W ramach grup rodzinnych rodzic oświadcza, że posiada zgodę dziecka na śledzenie lokalizacji.

§10. Zmiany Polityki
1. Polityka może ulec zmianie.
2. O istotnych zmianach użytkownicy zostaną poinformowani w Aplikacji i/lub emailem.

Data ostatniej aktualizacji: 2026-05-07
''';
}
