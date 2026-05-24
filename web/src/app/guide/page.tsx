'use client';

import React, { useState } from 'react';

interface Section {
  icon: string;
  title: string;
  summary: string;
  content: string;
}

const sections: Section[] = [
  { icon: '📞', title: 'Numery alarmowe', summary: 'Kiedy 112 / 999 / 998 / 997', content: '• 112 — uniwersalny numer alarmowy (działa nawet bez karty SIM)\n• 999 — Pogotowie Ratunkowe (życie/zdrowie)\n• 998 — Straż Pożarna (pożar, gaz, wypadek, ratownictwo)\n• 997 — Policja (przestępstwo, zagrożenie)\n• 991 — Pogotowie Energetyczne\n• 992 — Pogotowie Gazowe\n• 994 — Pogotowie Wodne\n\nMów spokojnie: gdzie jesteś, co się stało, ilu jest poszkodowanych. Nie rozłączaj się pierwszy.' },
  { icon: '❤️', title: 'Pierwsza pomoc (RKO)', summary: '30:2 + AED — uratujesz życie', content: '1. SPRAWDŹ przytomność — potrząśnij, zapytaj „Słyszysz mnie?"\n2. WEZWIJ 112 / 999\n3. UDROŻNIJ drogi oddechowe — odchyl głowę\n4. SPRAWDŹ oddech 10 sekund\n5. Jeśli BRAK oddechu — zacznij RKO:\n   • 30 uciśnięć klatki piersiowej (głębokość 5-6 cm, tempo 100-120/min)\n   • 2 oddechy ratownicze\n   • Powtarzaj do przyjazdu pomocy\n\nUżyj AED jeśli dostępne — urządzenie samo prowadzi głosem. Znajdź najbliższy AED na ekranie Mapa.' },
  { icon: '🏠', title: 'Bezpieczeństwo w domu', summary: 'Gaz, prąd, kuchnia, łazienka', content: '• Czujki dymu i czadu — sprawdzaj baterie co 6 miesięcy\n• Wyłączniki różnicowoprądowe (RCD) w łazience\n• Gaz: nie zostawiaj garnka bez nadzoru. Czujesz gaz? Otwórz okna, nie włączaj światła, zakręć główny zawór, wyjdź, zadzwoń 992.\n• Środki czystości w zamkniętej szafce, z dala od żywności\n• Mata antypoślizgowa w wannie/prysznicu (szczególnie dla seniorów)' },
  { icon: '⛈️', title: 'Burza i blackout', summary: 'Co robić podczas burzy / awarii prądu', content: 'Podczas burzy:\n• Schowaj się w solidnym budynku lub samochodzie\n• Unikaj otwartych przestrzeni, samotnych drzew, masztów, wody\n• Wyłącz elektronikę z sieci (przepięcia)\n\nAwaria prądu:\n• Latarka, świece, zapałki — trzymaj w łatwym miejscu\n• Powerbank dla telefonu\n• Lodówka utrzyma temperaturę ~4h zamknięta\n• Sprawdź lokalną informację Tauron/Enea/PGE' },
  { icon: '🚪', title: 'Drzwi, okna, klucze', summary: 'Włamania, zgubione klucze', content: '• Zamykaj drzwi na klucz, nawet wychodząc na chwilę\n• Nie chowaj klucza pod wycieraczką ani w doniczce\n• Okna na parterze i piwnicy — zamykaj na zasuwy\n• Krata w drzwiach od balkonu (parter)\n• Domofon: nie wpuszczaj nikogo obcego, nawet jeśli „idzie do sąsiada"\n• Zgubione klucze? Wymień zamki ZARAZ jeśli klucze miały adres' },
  { icon: '⚠️', title: 'Oszustwa „na wnuczka"', summary: 'Telefoniczne, SMS, BLIK — uważaj!', content: 'NIGDY nie:\n• Przekazuj pieniędzy obcej osobie, „policjantowi", „prokuratorowi"\n• Podawaj kodów BLIK ani SMS-em ani przez telefon\n• Klikaj linków w SMS-ach o „dopłacie", „przesyłce"\n• Loguj się do banku przez link z maila/SMS-a\n\nGdy ktoś dzwoni „z banku" — ROZŁĄCZ SIĘ i zadzwoń na numer z karty.\nWnuczek w opałach? Zadzwoń bezpośrednio do niego/jego rodziców.' },
  { icon: '🚗', title: 'Bezpieczna jazda', summary: 'Alkohol, leki, zmęczenie', content: '• Po alkoholu — nigdy za kierownicę. 0,2‰ to już wykroczenie.\n• Leki mogą wpływać na reakcję — sprawdź ulotkę („Wpływ na zdolność prowadzenia")\n• Zmęczenie = pijany kierowca. Przerwa co 2h jazdy.\n• Pasy bezpieczeństwa również z tyłu\n• Foteliki dla dzieci do 150 cm wzrostu\n• Trzymaj odległość 2 sekundy od poprzedzającego pojazdu' },
  { icon: '💊', title: 'Lekarstwa', summary: 'Dawkowanie, interakcje, termin', content: '• Sprawdzaj termin ważności — przeterminowane do apteki (utylizacja)\n• Lista swoich leków przy sobie (w portfelu) — pomoc dla ratowników\n• Nie łącz alkoholu z lekami\n• Niektóre leki + grejpfrut = niebezpieczne\n• Pamiętaj o godzinach (alarmy w telefonie pomocne)\n• Konsultuj nowe leki z farmaceutą — sprawdzi interakcje' },
  { icon: '🥾', title: 'Wycieczki i sport', summary: 'Co zabrać, jak się przygotować', content: 'W góry / las / nad wodę:\n• Powiedz komuś gdzie idziesz i o której wracasz\n• Naładowany telefon + powerbank\n• Aplikacja Ratunek (GOPR/TOPR/WOPR) — jednoznaczna lokalizacja\n• Apteczka, woda, czołówka, kurtka przeciwdeszczowa\n• Sprawdź prognozę pogody\n• Nie kąp się po alkoholu, w nieznanych miejscach, w nocy' },
  { icon: '🔒', title: 'Cyberbezpieczeństwo', summary: 'Hasła, 2FA, phishing', content: '• Hasło: minimum 12 znaków, NIE używaj tego samego w wielu miejscach\n• Włącz weryfikację dwuetapową (2FA / SMS / aplikacja Authenticator)\n• Manager haseł: Bitwarden, 1Password, Apple/Google\n• Nigdy nie podawaj hasła ani PIN-u przez telefon/SMS/email\n• Aktualizuj system i aplikacje\n• Połączenia WiFi w kawiarniach — zachowaj ostrożność, używaj VPN\n• mObywatel — bezpieczna alternatywa dla dokumentów' },
  { icon: '🧒', title: 'Bezpieczeństwo dzieci', summary: 'Co powtarzać dziecku codziennie', content: '• „Nie rozmawiaj z obcymi" — szczególnie gdy proponują coś (cukierka, podwózkę, „mama prosiła")\n• Numery telefonu rodziców — nauczcie się na pamięć\n• Bezpieczne miejsca po drodze do szkoły (sklep, przyjaciele)\n• Hasło rodzinne — które tylko rodzice znają i mogą podać\n• Kiedy zgubi się — zostań na miejscu, znajdź panią z dzieckiem lub w mundurze\n• be:Safe: sygnał „JESTEM OK" + bezpieczna trasa do szkoły' },
  { icon: '✉️', title: 'Kontakt z be:Safe', summary: 'Pomoc techniczna, sugestie', content: 'Masz pytanie lub sugestię? Coś nie działa?\n\n✉️  support@besafe.org.pl\n🌐  https://besafe.org.pl\n\nAplikacja jest tworzona po to, by Wasza rodzina była bezpieczna. Każda wiadomość liczy się — czytamy wszystko.' },
];

export default function SafetyGuidePage() {
  const [open, setOpen] = useState<number | null>(null);
  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-neutral-950 px-4 py-6 max-w-3xl mx-auto">
      <h1 className="text-2xl font-light text-neutral-900 dark:text-white mb-2">📘 Poradnik bezpieczeństwa</h1>
      <p className="text-sm text-neutral-500 mb-6">12 sekcji — naciśnij, aby rozwinąć</p>

      <div className="bg-white dark:bg-neutral-900 rounded-2xl divide-y divide-neutral-100 dark:divide-neutral-800 overflow-hidden">
        {sections.map((s, i) => (
          <div key={i}>
            <button
              onClick={() => setOpen(open === i ? null : i)}
              className="w-full p-4 flex items-center gap-4 hover:bg-neutral-50 dark:hover:bg-neutral-800 text-left"
            >
              <div className="w-10 h-10 rounded-2xl bg-[#9EEBEC]/30 flex items-center justify-center text-xl flex-shrink-0">
                {s.icon}
              </div>
              <div className="flex-1 min-w-0">
                <h3 className="font-semibold text-neutral-900 dark:text-white">{s.title}</h3>
                <p className="text-xs text-neutral-500 mt-0.5">{s.summary}</p>
              </div>
              <svg
                className={`w-5 h-5 text-neutral-400 transition-transform ${open === i ? 'rotate-180' : ''}`}
                fill="none" stroke="currentColor" viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </button>
            {open === i && (
              <div className="px-4 pb-5 pl-[4.25rem]">
                <pre className="text-sm text-neutral-700 dark:text-neutral-300 leading-relaxed whitespace-pre-wrap font-sans">
                  {s.content}
                </pre>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
