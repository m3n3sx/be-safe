import Link from 'next/link';
import { PageHeader } from '@/components/layout/PageHeader';
import { HubSection } from '@/components/layout/HubSection';
import { ALERT_CATEGORIES } from '@/types';

export default function LandingPage() {
  return (
    <div className="page-container space-y-8">
      <PageHeader
        title="be:Safe — bliżej okolicy i bliskich"
        description="Społecznościowe zgłoszenia, kontakt z bliskimi i pomoc w jednym miejscu."
      />
      <section className="panel space-y-5">
        <h2 className="text-2xl font-bold">Sprawdź, co dzieje się w pobliżu</h2>
        <p className="max-w-2xl text-ink-2">
          Przeglądaj mapę lub listę, zgłaszaj ważne zdarzenia i uzupełniaj informacje innych osób. W
          nagłej sytuacji SOS w górnym pasku prowadzi do telefonu 112 i alarmu be:Safe.
        </p>
        <div className="flex flex-wrap gap-3">
          <Link className="btn btn-primary" href="/">
            Otwórz aplikację
          </Link>
          <Link className="btn btn-secondary" href="/register">
            Utwórz konto
          </Link>
          <a className="btn btn-secondary" href="https://alert.u235.pl/api/v1/download">
            Pobierz na Androida (APK)
          </a>
          <Link className="btn btn-quiet" href="/login">
            Zaloguj się
          </Link>
        </div>
        <p className="text-sm text-ink-2">
          Dane okolicy wymagają zalogowania. Numery pomocy i poradnik są dostępne bez konta.
        </p>
      </section>
      <div id="features">
        <HubSection
          title="Na co dzień"
          entries={[
            [
              '/',
              'Mapa i lista okolicy',
              'Wyszukaj miejsce, ustaw promień i filtruj zgłoszenia.',
              'pin',
            ],
            [
              '/report',
              'Zgłoszenie w trzech krokach',
              'Wybierz zdarzenie, miejsce i szczegóły; zdjęcie jest opcjonalne.',
              'check',
            ],
            [
              '/notifications',
              'Powiadomienia',
              'Sprawdź komunikaty i przejdź do konkretnego zadania.',
              'chat',
            ],
            [
              '/help',
              'Pomoc i poradnik',
              'Numery, AED, wsparcie w kryzysie i codzienne porady.',
              'heart',
            ],
          ]}
        />
        <p className="text-ink-2">
          Zgłoszenia można potwierdzać, oznaczać jako nieaktualne oraz komentować. Nowe informacje
          pojawiają się w aktywnej aplikacji; nie gwarantujemy natychmiastowego dostarczenia
          powiadomień.
        </p>
      </div>
      <div id="family">
        <HubSection
          title="Bliscy w jednym miejscu"
          entries={[
            ['/family', 'Grupy bliskich', 'Dołącz kodem, rozmawiaj i wysyłaj meldunki.', 'people'],
            [
              '/escort',
              'Bezpieczny powrót',
              'Podziel się przebiegiem drogi w otwartej karcie.',
              'walk',
            ],
            ['/pets', 'Zwierzęta', 'Zapisz profil i zgłoś zaginięcie lub odnalezienie.', 'heart'],
            [
              '/parental-controls',
              'Dziecko w sieci',
              'Poznaj zewnętrzne narzędzia dla opiekunów.',
              'shield',
            ],
          ]}
        />
        <p className="text-ink-2">
          W grupie dostępne są ostatnie udostępnione pozycje, historia, bezpieczne strefy i trasy.
          Widoczność zależy od uprawnień. Przeglądarka nie zapewnia śledzenia po zamknięciu karty.
        </p>
      </div>
      <section id="categories" className="panel">
        <h2 className="text-xl font-bold mb-4">{ALERT_CATEGORIES.length} kategorii zgłoszeń</h2>
        <ul className="grid sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {ALERT_CATEGORIES.map((category) => (
            <li key={category.key} className="text-ink-2">
              {category.label}
            </li>
          ))}
        </ul>
      </section>
      <section id="stats" className="panel space-y-3">
        <h2 className="text-xl font-bold">Liczby dla Twojej okolicy</h2>
        <p>
          Sprawdź faktyczną liczbę zgłoszeń i zmiany w czasie po wybraniu obszaru. Brak zgłoszeń nie
          oznacza braku zagrożeń.
        </p>
        <Link href="/stats" className="btn btn-secondary">
          Statystyki okolicy
        </Link>
      </section>
      <section className="panel space-y-3">
        <h2 className="text-xl font-bold">Jak zacząć?</h2>
        <ol className="list-decimal pl-6 space-y-2">
          <li>Utwórz konto lub zaloguj się.</li>
          <li>Wybierz okolicę po adresie albo lokalizacji.</li>
          <li>Sprawdź zgłoszenia i zaproś bliskich.</li>
        </ol>
        <Link href="/onboarding" className="btn btn-secondary">
          Przejdź przez pierwsze kroki
        </Link>
      </section>
      <nav aria-label="Dokumenty i kontakt" className="flex flex-wrap gap-3">
        <Link href="/privacy" className="btn btn-quiet">
          Prywatność
        </Link>
        <Link href="/terms" className="btn btn-quiet">
          Regulamin
        </Link>
        <a href="mailto:support@besafe.org.pl" className="btn btn-quiet">
          Kontakt
        </a>
      </nav>
    </div>
  );
}
