import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Polityka prywatności — be:Safe',
  description: 'Polityka prywatności aplikacji be:Safe — jak chronimy Twoje dane.',
};

const LAST_UPDATED = '2026-05-09';

export default function PrivacyPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16 text-neutral-800 dark:text-neutral-200 leading-relaxed [&_h2]:mt-10 [&_h2]:mb-3 [&_h2]:text-xl [&_h2]:font-semibold [&_p]:my-3 [&_ol]:my-3 [&_ol]:pl-6 [&_ol]:list-decimal [&_ul]:my-3 [&_ul]:pl-6 [&_ul]:list-disc [&_li]:my-1 [&_a]:text-blue-600 dark:[&_a]:text-blue-400 [&_a]:underline [&_code]:bg-neutral-100 dark:[&_code]:bg-neutral-800 [&_code]:rounded [&_code]:px-1 [&_hr]:my-8 [&_hr]:border-neutral-300 dark:[&_hr]:border-neutral-700">
      <h1 className="text-3xl font-bold">Polityka prywatności</h1>
      <p className="text-sm text-neutral-500">Data ostatniej aktualizacji: {LAST_UPDATED}</p>

      <h2>§1. Administrator danych</h2>
      <p>
        Administratorem danych osobowych użytkowników aplikacji <strong>be:Safe</strong> jest
        właściciel domeny <a href="https://alert.u235.pl">alert.u235.pl</a> (dalej „Administrator").
      </p>
      <p>Kontakt: <a href="mailto:privacy@alert.u235.pl">privacy@alert.u235.pl</a></p>

      <h2>§2. Dane zbierane przez aplikację</h2>
      <p>W ramach aplikacji przetwarzamy następujące dane:</p>
      <ol>
        <li><strong>Dane konta:</strong> email, nazwa użytkownika, zahashowane hasło (bcrypt), zdjęcie profilowe (opcjonalnie z Google).</li>
        <li><strong>Dane lokalizacyjne:</strong> aktualna pozycja GPS oraz historia lokalizacji (dla funkcji rodzinnych).</li>
        <li><strong>Zgłoszenia:</strong> treść zgłoszeń zagrożeń, zdjęcia (opcjonalne), lokalizacja zdarzenia.</li>
        <li><strong>Dane techniczne:</strong> typ urządzenia, system operacyjny, adres IP, identyfikator instalacji FCM.</li>
        <li><strong>Dane rodzinne:</strong> przynależność do grup rodzinnych, relacje rodzic-dziecko, historia check-inów.</li>
      </ol>

      <h2>§3. Cel przetwarzania danych</h2>
      <ol>
        <li>Świadczenie usług aplikacji (art. 6 ust. 1 lit. b RODO — wykonanie umowy).</li>
        <li>Wyświetlanie alertów w okolicy użytkownika.</li>
        <li>Umożliwienie śledzenia lokalizacji członków rodziny.</li>
        <li>Zapewnienie bezpieczeństwa aplikacji (wykrywanie nadużyć, moderacja).</li>
        <li>Kontakt z użytkownikiem w sprawie konta.</li>
        <li>Analityka i udoskonalanie aplikacji (art. 6 ust. 1 lit. f RODO — uzasadniony interes).</li>
      </ol>

      <h2>§4. Udostępnianie danych</h2>
      <p>Dane <strong>nie są</strong> udostępniane podmiotom trzecim w celach marketingowych.</p>
      <p>Dane mogą być udostępnione:</p>
      <ul>
        <li>organom ścigania na podstawie prawomocnego nakazu,</li>
        <li>dostawcom usług IT (hosting: OVH, baza: PostgreSQL na własnym serwerze),</li>
        <li>Google LLC w zakresie usług Maps SDK i Google Sign-In (zgodnie z ich politykami),</li>
        <li>Firebase (Google) dla push notifications,</li>
        <li>Sentry.io dla crash reporting (anonimowe dane techniczne).</li>
      </ul>

      <h2>§5. Okres przechowywania danych</h2>
      <ul>
        <li>Dane konta: do czasu usunięcia konta przez użytkownika.</li>
        <li>Historia lokalizacji: 30 dni (starsze są automatycznie usuwane).</li>
        <li>Zgłoszenia: do wygaśnięcia + 90 dni (dla celów statystycznych).</li>
        <li>Dane po usunięciu konta: kasowane w ciągu 30 dni.</li>
      </ul>

      <h2>§6. Prawa użytkownika (RODO)</h2>
      <p>Użytkownik ma prawo do:</p>
      <ol>
        <li>Dostępu do swoich danych (GET <code>/users/me</code>).</li>
        <li>Sprostowania danych (PATCH <code>/users/me</code> w aplikacji).</li>
        <li>Usunięcia konta i danych (w Ustawieniach).</li>
        <li>Przenoszenia danych (eksport JSON na żądanie: GET <code>/users/me/export</code>).</li>
        <li>Sprzeciwu wobec przetwarzania.</li>
        <li>Skargi do Prezesa UODO (<a href="https://www.uodo.gov.pl">www.uodo.gov.pl</a>).</li>
      </ol>

      <h2>§7. Bezpieczeństwo</h2>
      <ul>
        <li>Hasła są hashowane algorytmem <strong>bcrypt</strong>.</li>
        <li>Komunikacja odbywa się przez <strong>HTTPS</strong> (TLS 1.2+).</li>
        <li>Lokalizacja dziecka widoczna jest <strong>wyłącznie</strong> dla członków jego grupy rodzinnej.</li>
        <li>Dane przechowywane są w Polsce (VPS w OVH, Strasbourg/Warszawa).</li>
      </ul>

      <h2>§8. Cookies i identyfikatory</h2>
      <p>Aplikacja mobilna nie używa cookies. Używa:</p>
      <ul>
        <li>Identyfikatora instalacji FCM (do powiadomień push).</li>
        <li>Tokena JWT (do sesji, przechowywany lokalnie w SharedPreferences).</li>
      </ul>
      <p>Strona webowa używa cookies tylko do sesji logowania (JWT w cookie HttpOnly).</p>

      <h2>§9. Dzieci</h2>
      <ol>
        <li>Aplikacja nie zbiera świadomie danych dzieci poniżej 13 roku życia bez zgody rodzica.</li>
        <li>W ramach grup rodzinnych rodzic oświadcza, że posiada zgodę dziecka na śledzenie lokalizacji.</li>
        <li>Dziecko może w każdej chwili wyłączyć udostępnianie lokalizacji w ustawieniach aplikacji.</li>
      </ol>

      <h2>§10. Zmiany polityki</h2>
      <p>
        Polityka może ulec zmianie. O istotnych zmianach użytkownicy zostaną
        poinformowani w aplikacji i/lub emailem. Dalsze korzystanie z aplikacji
        po zmianie oznacza akceptację nowej wersji polityki.
      </p>

      <hr />
      <p className="text-sm text-neutral-500">
        Powiązane: <a href="/terms">Regulamin</a> · <a href="/">Strona główna</a>
      </p>
    </div>
  );
}
