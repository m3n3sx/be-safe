import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Regulamin — be:Safe',
  description: 'Regulamin korzystania z aplikacji be:Safe.',
};

const LAST_UPDATED = '2026-05-09';

export default function TermsPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16 text-neutral-800 dark:text-neutral-200 leading-relaxed [&_h2]:mt-10 [&_h2]:mb-3 [&_h2]:text-xl [&_h2]:font-semibold [&_p]:my-3 [&_ol]:my-3 [&_ol]:pl-6 [&_ol]:list-decimal [&_ul]:my-3 [&_ul]:pl-6 [&_ul]:list-disc [&_li]:my-1 [&_a]:text-blue-600 dark:[&_a]:text-blue-400 [&_a]:underline [&_code]:bg-neutral-100 dark:[&_code]:bg-neutral-800 [&_code]:rounded [&_code]:px-1 [&_hr]:my-8 [&_hr]:border-neutral-300 dark:[&_hr]:border-neutral-700">
      <h1 className="text-3xl font-bold">Regulamin</h1>
      <p className="text-sm text-neutral-500">Data ostatniej aktualizacji: {LAST_UPDATED}</p>

      <h2>§1. Postanowienia ogólne</h2>
      <ol>
        <li>Aplikacja <strong>be:Safe</strong> (dalej „Aplikacja") jest społecznościową aplikacją mobilną umożliwiającą zgłaszanie zagrożeń bezpieczeństwa oraz śledzenie lokalizacji członków rodziny.</li>
        <li>Operatorem Aplikacji jest właściciel strony <a href="https://alert.u235.pl">alert.u235.pl</a> (dalej „Operator").</li>
        <li>Korzystanie z Aplikacji oznacza akceptację niniejszego Regulaminu.</li>
      </ol>

      <h2>§2. Wymagania techniczne</h2>
      <ol>
        <li>Do korzystania z Aplikacji wymagane jest urządzenie z systemem Android 7.0+ lub iOS 14+.</li>
        <li>Do pełnej funkcjonalności wymagane jest połączenie internetowe i dostęp do GPS.</li>
      </ol>

      <h2>§3. Rejestracja i konto</h2>
      <ol>
        <li>Korzystanie z Aplikacji wymaga założenia konta.</li>
        <li>Użytkownik zobowiązuje się podać prawdziwe dane.</li>
        <li>Osoby poniżej 13 roku życia mogą korzystać z Aplikacji wyłącznie za zgodą rodzica/opiekuna w ramach grupy rodzinnej.</li>
        <li>Użytkownik ponosi odpowiedzialność za zachowanie poufności danych logowania.</li>
      </ol>

      <h2>§4. Zgłaszanie zagrożeń</h2>
      <ol>
        <li>Użytkownik może zgłaszać zagrożenia bezpieczeństwa poprzez utworzenie alertu.</li>
        <li>Zgłoszenia muszą być prawdziwe i dotyczyć realnych zagrożeń.</li>
        <li>Zabronione jest:
          <ul>
            <li>zgłaszanie fałszywych alarmów,</li>
            <li>zamieszczanie treści obraźliwych, dyskryminujących lub niezgodnych z prawem,</li>
            <li>zamieszczanie danych osobowych osób trzecich,</li>
            <li>wykorzystywanie Aplikacji do celów sprzecznych z jej przeznaczeniem.</li>
          </ul>
        </li>
        <li>Naruszenie powyższych zasad skutkuje usunięciem zgłoszenia i/lub zawieszeniem konta.</li>
      </ol>

      <h2>§5. Alerty SOS</h2>
      <ol>
        <li>Funkcja SOS służy <strong>wyłącznie</strong> do sytuacji bezpośredniego zagrożenia życia lub zdrowia.</li>
        <li>Aplikacja <strong>NIE ZASTĘPUJE</strong> numerów alarmowych (112, 997, 998, 999, 986).</li>
        <li>W nagłych przypadkach <strong>zawsze</strong> należy w pierwszej kolejności zadzwonić pod numer alarmowy.</li>
      </ol>

      <h2>§6. Grupy rodzinne i śledzenie lokalizacji</h2>
      <ol>
        <li>Śledzenie lokalizacji dziecka wymaga jego zgody oraz zainstalowania Aplikacji na jego urządzeniu.</li>
        <li>Rodzic zobowiązuje się informować dziecko o śledzeniu lokalizacji.</li>
        <li>Dziecko może w każdej chwili wyłączyć udostępnianie lokalizacji w ustawieniach Aplikacji.</li>
      </ol>

      <h2>§7. Ograniczenie odpowiedzialności</h2>
      <ol>
        <li>Operator <strong>nie ponosi odpowiedzialności</strong> za:
          <ul>
            <li>prawdziwość zgłoszeń publikowanych przez użytkowników,</li>
            <li>działania podjęte na podstawie informacji z Aplikacji,</li>
            <li>awarie techniczne, utratę połączenia, niedokładność GPS,</li>
            <li>szkody wynikłe z użycia lub niemożności użycia Aplikacji.</li>
          </ul>
        </li>
        <li>Aplikacja jest udostępniana w trybie „as is" bez gwarancji jej działania.</li>
      </ol>

      <h2>§8. Zmiany regulaminu</h2>
      <ol>
        <li>Operator zastrzega sobie prawo do zmiany Regulaminu.</li>
        <li>O zmianach użytkownicy zostaną poinformowani w Aplikacji.</li>
      </ol>

      <h2>§9. Postanowienia końcowe</h2>
      <ol>
        <li>W sprawach nieuregulowanych zastosowanie mają przepisy prawa polskiego.</li>
        <li>Spory rozstrzyga sąd właściwy dla siedziby Operatora.</li>
      </ol>

      <hr />
      <p className="text-sm text-neutral-500">
        Powiązane: <a href="/privacy">Polityka prywatności</a> · <a href="/">Strona główna</a>
      </p>
    </div>
  );
}
