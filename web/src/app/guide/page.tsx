'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { PageHeader } from '@/components/layout/PageHeader';
import { TextField } from '@/components/ui/TextField';
import { EmptyState } from '@/components/ui/EmptyState';

interface Section {
  icon: string;
  title: string;
  summary: string;
  content: string;
}

const sections: Section[] = [
  {
    icon: '📞',
    title: 'Numery alarmowe',
    summary: 'Kiedy 112 / 999 / 998 / 997',
    content:
      '• 112 — uniwersalny numer alarmowy (działa nawet bez karty SIM)\n• 999 — Pogotowie Ratunkowe (życie/zdrowie)\n• 998 — Straż Pożarna (pożar, gaz, wypadek, ratownictwo)\n• 997 — Policja (przestępstwo, zagrożenie)\n• 991 — Pogotowie Energetyczne\n• 992 — Pogotowie Gazowe\n• 994 — Pogotowie Wodne\n\nMów spokojnie: gdzie jesteś, co się stało, ilu jest poszkodowanych. Nie rozłączaj się pierwszy.',
  },
  {
    icon: '❤️',
    title: 'Pierwsza pomoc (RKO)',
    summary: 'Osoba dorosła: uciskanie klatki piersiowej i AED',
    content:
      '1. Upewnij się, że miejsce jest bezpieczne. Sprawdź reakcję: delikatnie potrząśnij ramionami i zapytaj, czy osoba Cię słyszy.\n2. Jeśli nie reaguje, wołaj o pomoc. Zadzwoń 112 lub 999, włącz głośnik i wykonuj polecenia dyspozytora. Poproś kogoś o AED.\n3. Udrożnij drogi oddechowe przez odchylenie głowy i uniesienie żuchwy. Sprawdzaj oddech nie dłużej niż 10 sekund. Pojedyncze westchnienia lub oddech nieregularny nie są prawidłowym oddechem.\n4. Jeśli osoba nie oddycha prawidłowo, uciskaj środek klatki piersiowej: 100–120 razy na minutę, na głębokość 5–6 cm. Pozwalaj klatce wracać do pierwotnej pozycji.\n5. Jeśli umiesz i możesz wykonywać oddechy ratownicze, stosuj 30 uciśnięć i 2 oddechy. W przeciwnym razie nieprzerwanie uciskaj klatkę.\n6. Włącz AED i postępuj zgodnie z poleceniami. Nie dotykaj osoby podczas analizy rytmu i wyładowania.\n\nKontynuuj do przejęcia działań przez ratowników, powrotu prawidłowego oddechu lub utraty możliwości dalszego działania. W przypadku dziecka wykonuj instrukcje dyspozytora.',
  },
  {
    icon: '🏠',
    title: 'Bezpieczeństwo w domu',
    summary: 'Gaz, prąd, kuchnia, łazienka',
    content:
      '• Czujki dymu i czadu — sprawdzaj baterie co 6 miesięcy\n• Wyłączniki różnicowoprądowe (RCD) w łazience\n• Gaz: nie zostawiaj garnka bez nadzoru. Czujesz gaz? Otwórz okna, nie włączaj światła, zakręć główny zawór, wyjdź, zadzwoń 992.\n• Środki czystości w zamkniętej szafce, z dala od żywności\n• Mata antypoślizgowa w wannie/prysznicu (szczególnie dla seniorów)',
  },
  {
    icon: '⛈️',
    title: 'Burza i blackout',
    summary: 'Co robić podczas burzy / awarii prądu',
    content:
      'Podczas burzy:\n• Schowaj się w solidnym budynku lub samochodzie\n• Unikaj otwartych przestrzeni, samotnych drzew, masztów, wody\n• Wyłącz elektronikę z sieci (przepięcia)\n\nAwaria prądu:\n• Latarka, świece, zapałki — trzymaj w łatwym miejscu\n• Powerbank dla telefonu\n• Lodówka utrzyma temperaturę ~4h zamknięta\n• Sprawdź lokalną informację Tauron/Enea/PGE',
  },
  {
    icon: '🚪',
    title: 'Drzwi, okna, klucze',
    summary: 'Włamania, zgubione klucze',
    content:
      '• Zamykaj drzwi na klucz, nawet wychodząc na chwilę\n• Nie chowaj klucza pod wycieraczką ani w doniczce\n• Okna na parterze i piwnicy — zamykaj na zasuwy\n• Krata w drzwiach od balkonu (parter)\n• Domofon: nie wpuszczaj nikogo obcego, nawet jeśli „idzie do sąsiada"\n• Zgubione klucze? Wymień zamki ZARAZ jeśli klucze miały adres',
  },
  {
    icon: '⚠️',
    title: 'Oszustwa „na wnuczka"',
    summary: 'Telefoniczne, SMS, BLIK — uważaj!',
    content:
      'NIGDY nie:\n• Przekazuj pieniędzy obcej osobie, „policjantowi", „prokuratorowi"\n• Podawaj kodów BLIK ani SMS-em ani przez telefon\n• Klikaj linków w SMS-ach o „dopłacie", „przesyłce"\n• Loguj się do banku przez link z maila/SMS-a\n\nGdy ktoś dzwoni „z banku" — ROZŁĄCZ SIĘ i zadzwoń na numer z karty.\nWnuczek w opałach? Zadzwoń bezpośrednio do niego/jego rodziców.',
  },
  {
    icon: '🚗',
    title: 'Bezpieczna jazda',
    summary: 'Alkohol, leki, zmęczenie',
    content:
      '• Po alkoholu — nigdy za kierownicę. 0,2‰ to już wykroczenie.\n• Leki mogą wpływać na reakcję — sprawdź ulotkę („Wpływ na zdolność prowadzenia")\n• Zmęczenie = pijany kierowca. Przerwa co 2h jazdy.\n• Pasy bezpieczeństwa również z tyłu\n• Foteliki dla dzieci do 150 cm wzrostu\n• Trzymaj odległość 2 sekundy od poprzedzającego pojazdu',
  },
  {
    icon: '💊',
    title: 'Lekarstwa',
    summary: 'Dawkowanie, interakcje, termin',
    content:
      '• Sprawdzaj termin ważności — przeterminowane do apteki (utylizacja)\n• Lista swoich leków przy sobie (w portfelu) — pomoc dla ratowników\n• Nie łącz alkoholu z lekami\n• Niektóre leki + grejpfrut = niebezpieczne\n• Pamiętaj o godzinach (alarmy w telefonie pomocne)\n• Konsultuj nowe leki z farmaceutą — sprawdzi interakcje',
  },
  {
    icon: '🥾',
    title: 'Wycieczki i sport',
    summary: 'Co zabrać, jak się przygotować',
    content:
      'W góry / las / nad wodę:\n• Powiedz komuś gdzie idziesz i o której wracasz\n• Naładowany telefon + powerbank\n• Aplikacja Ratunek (GOPR/TOPR/WOPR) — jednoznaczna lokalizacja\n• Apteczka, woda, czołówka, kurtka przeciwdeszczowa\n• Sprawdź prognozę pogody\n• Nie kąp się po alkoholu, w nieznanych miejscach, w nocy',
  },
  {
    icon: '🔒',
    title: 'Cyberbezpieczeństwo',
    summary: 'Hasła, 2FA, phishing',
    content:
      '• Hasło: minimum 12 znaków, NIE używaj tego samego w wielu miejscach\n• Włącz weryfikację dwuetapową (2FA / SMS / aplikacja Authenticator)\n• Manager haseł: Bitwarden, 1Password, Apple/Google\n• Nigdy nie podawaj hasła ani PIN-u przez telefon/SMS/email\n• Aktualizuj system i aplikacje\n• Połączenia WiFi w kawiarniach — zachowaj ostrożność, używaj VPN\n• mObywatel — bezpieczna alternatywa dla dokumentów',
  },
  {
    icon: '🧒',
    title: 'Bezpieczeństwo dzieci',
    summary: 'Co powtarzać dziecku codziennie',
    content:
      '• „Nie rozmawiaj z obcymi" — szczególnie gdy proponują coś (cukierka, podwózkę, „mama prosiła")\n• Numery telefonu rodziców — nauczcie się na pamięć\n• Bezpieczne miejsca po drodze do szkoły (sklep, przyjaciele)\n• Hasło rodzinne — które tylko rodzice znają i mogą podać\n• Kiedy zgubi się — zostań na miejscu, znajdź panią z dzieckiem lub w mundurze\n• be:Safe: sygnał „JESTEM OK" + bezpieczna trasa do szkoły',
  },
  {
    icon: '✉️',
    title: 'Kontakt z be:Safe',
    summary: 'Pomoc techniczna, sugestie',
    content:
      'Masz pytanie lub sugestię? Coś nie działa?\n\n✉️  support@besafe.org.pl\n🌐  https://besafe.org.pl\n\nAplikacja jest tworzona po to, by Wasza rodzina była bezpieczna. Każda wiadomość liczy się — czytamy wszystko.',
  },
];

export default function SafetyGuidePage() {
  const [query, setQuery] = useState('');
  const filtered = sections.filter((s) =>
    `${s.title} ${s.content}`.toLocaleLowerCase('pl').includes(query.toLocaleLowerCase('pl')),
  );
  return (
    <div className="form-container space-y-4">
      <PageHeader title="Poradnik bezpieczeństwa" description="Praktyczne wskazówki na co dzień." />
      <nav className="flex flex-wrap gap-2" aria-label="Szybka pomoc">
        <Link className="btn btn-secondary" href="/emergency">
          Numery pomocy
        </Link>
        <Link className="btn btn-secondary" href="/aed">
          Znajdź AED
        </Link>
      </nav>
      <TextField
        label="Szukaj w poradniku"
        type="search"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
      />
      {!filtered.length && (
        <EmptyState
          title="Brak pasujących tematów"
          description="Spróbuj innego słowa, np. gaz lub hasło."
        />
      )}
      {filtered.map((s) => (
        <details key={s.title} className="panel">
          <summary className="min-h-12 cursor-pointer">
            <strong>{s.title}</strong>
            <span className="block text-sm text-ink-2 mt-1">{s.summary}</span>
          </summary>
          <div className="whitespace-pre-wrap mt-4 leading-relaxed">{s.content}</div>
          {s.title.includes('Kontakt') && (
            <a className="btn btn-quiet" href="mailto:support@besafe.org.pl">
              Napisz do be:Safe
            </a>
          )}
        </details>
      ))}
    </div>
  );
}
