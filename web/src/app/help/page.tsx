import { PageHeader } from '@/components/layout/PageHeader';
import { HubSection } from '@/components/layout/HubSection';
import { EmergencyCall } from '@/components/safety/EmergencyCall';

export default function Page() {
  return (
    <div className="page-container">
      <PageHeader title="Pomoc" description="Wybierz to, czego teraz potrzebujesz." />
      <div className="max-w-xl">
        <EmergencyCall />
      </div>
      <HubSection
        title="Potrzebuję pomocy teraz"
        entries={[
          ['/sos', 'Alarm SOS', 'Wyślij alarm z wybranego miejsca.', 'shield'],
          ['/emergency', 'Numery pomocy', 'Służby ratunkowe i pogotowia techniczne.', 'phone'],
          ['/aed', 'Znajdź defibrylator', 'AED w okolicy i trasa dojścia.', 'bolt'],
          [
            '/sos/mental',
            'Wsparcie w kryzysie',
            'Porozmawiaj z osobą, która Cię wysłucha.',
            'heart',
          ],
        ]}
      />
      <HubSection
        title="Bezpieczniej na co dzień"
        entries={[
          ['/escort', 'Bezpieczny powrót', 'Udostępnij bliskiej osobie przebieg drogi.', 'walk'],
          ['/fakecall', 'Fałszywy telefon', 'Zaplanuj symulację połączenia.', 'phone'],
          ['/guide', 'Poradnik bezpieczeństwa', 'Pierwsza pomoc i codzienne sytuacje.', 'book'],
          ['/cyber', 'Bezpieczeństwo w sieci', 'Oszustwa, dane i zgłaszanie incydentów.', 'shield'],
          ['/parental-controls', 'Dziecko w sieci', 'Narzędzia i porady dla opiekunów.', 'people'],
        ]}
      />
      <HubSection
        title="Informacje i kontakt"
        entries={[
          ['/landing', 'O aplikacji', 'Poznaj be:Safe i wersję na Androida.', 'book'],
          [
            'mailto:support@besafe.org.pl',
            'Kontakt z be:Safe',
            'Napisz w sprawie konta lub działania aplikacji.',
            'people',
          ],
        ]}
      />
    </div>
  );
}
