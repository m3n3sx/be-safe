import Link from 'next/link';
import { PageHeader } from '@/components/layout/PageHeader';
import { Icon } from '@/components/ui/Icon';
import { EmergencyCall } from '@/components/safety/EmergencyCall';
const tiles = [
  ['/sos', 'Alarm SOS', 'Wyślij alarm z wybranego miejsca.', 'shield'],
  ['/emergency', 'Numery pomocy', 'Służby ratunkowe i pogotowia techniczne.', 'phone'],
  ['/aed', 'Znajdź defibrylator', 'AED w okolicy i trasa dojścia.', 'bolt'],
  ['/sos/mental', 'Wsparcie w kryzysie', 'Porozmawiaj z osobą, która Cię wysłucha.', 'heart'],
  ['/escort', 'Bezpieczny powrót', 'Udostępnij bliskiej osobie przebieg drogi.', 'walk'],
  ['/fakecall', 'Fałszywy telefon', 'Zaplanuj symulację połączenia.', 'phone'],
  ['/guide', 'Poradnik bezpieczeństwa', 'Pierwsza pomoc i codzienne sytuacje.', 'book'],
  ['/cyber', 'Bezpieczeństwo w sieci', 'Oszustwa, dane i zgłaszanie incydentów.', 'shield'],
  ['/parental-controls', 'Dziecko w sieci', 'Narzędzia i porady dla opiekunów.', 'people'],
] as const;
export default function Page() { return <div className="page-container"><PageHeader title="Pomoc" description="Wybierz to, czego teraz potrzebujesz." /><div className="max-w-xl mb-6"><EmergencyCall /></div><div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">{tiles.map(([href, title, description, icon]) => <Link key={href} href={href} className="panel min-h-40 hover:border-primary flex flex-col items-start gap-3"><span className="p-3 rounded-xl bg-surface-2 text-primary"><Icon name={icon} /></span><h2 className="text-xl font-bold">{title}</h2><p className="text-ink-2">{description}</p></Link>)}</div><nav className="flex flex-wrap gap-3 mt-6" aria-label="Informacje i kontakt"><a href="mailto:support@besafe.org.pl" className="btn btn-secondary">Kontakt z be:Safe</a><Link href="/landing" className="btn btn-quiet">O aplikacji</Link></nav></div>; }
