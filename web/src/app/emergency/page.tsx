'use client';

import React from 'react';

interface ENumber {
  number: string;
  display: string;
  title: string;
  subtitle: string;
  bg: string;
  fg: string;
  icon: string;
}

const numbers: ENumber[] = [
  { number: '112', display: '112', title: 'Numer alarmowy', subtitle: 'Jeden numer dla wszystkich służb (UE)', bg: 'bg-[#FF7A7A]', fg: 'text-white', icon: '🚨' },
  { number: '997', display: '997', title: 'Policja', subtitle: 'Przestępstwa, wypadki', bg: 'bg-[#1A2027]', fg: 'text-white', icon: '👮' },
  { number: '998', display: '998', title: 'Straż pożarna', subtitle: 'Pożary, ratownictwo', bg: 'bg-orange-500', fg: 'text-white', icon: '🚒' },
  { number: '999', display: '999', title: 'Pogotowie ratunkowe', subtitle: 'Zagrożenie życia i zdrowia', bg: 'bg-red-500', fg: 'text-white', icon: '🚑' },
  { number: '986', display: '986', title: 'Straż miejska', subtitle: 'Porządek publiczny', bg: 'bg-blue-600', fg: 'text-white', icon: '🛡️' },
  { number: '991', display: '991', title: 'Pogotowie energetyczne', subtitle: 'Awarie prądu', bg: 'bg-yellow-500', fg: 'text-[#1A2027]', icon: '⚡' },
  { number: '992', display: '992', title: 'Pogotowie gazowe', subtitle: 'Wycieki gazu', bg: 'bg-green-700', fg: 'text-white', icon: '🔥' },
  { number: '993', display: '993', title: 'Pogotowie ciepłownicze', subtitle: 'Awarie ogrzewania', bg: 'bg-amber-700', fg: 'text-white', icon: '🌡️' },
  { number: '994', display: '994', title: 'Pogotowie wodno-kanalizacyjne', subtitle: 'Awarie wody', bg: 'bg-cyan-600', fg: 'text-white', icon: '💧' },
  { number: '601100100', display: '601 100 100', title: 'WOPR', subtitle: 'Ratownictwo wodne', bg: 'bg-blue-500', fg: 'text-white', icon: '🌊' },
  { number: '601100300', display: '601 100 300', title: 'GOPR', subtitle: 'Ratownictwo górskie', bg: 'bg-emerald-700', fg: 'text-white', icon: '⛰️' },
];

export default function EmergencyNumbersPage() {
  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-neutral-950 px-4 py-6 max-w-2xl mx-auto">
      <h1 className="text-2xl font-light text-neutral-900 dark:text-white mb-2">📞 Numery alarmowe</h1>
      <p className="text-sm text-neutral-500 mb-6">Kliknij, aby zadzwonić</p>

      <div className="space-y-2">
        {numbers.map(n => (
          <a
            key={n.number}
            href={`tel:${n.number}`}
            className={`block ${n.bg} ${n.fg} rounded-2xl p-4 hover:opacity-95 active:scale-[0.98] transition-all`}
          >
            <div className="flex items-center gap-4">
              <div className="text-2xl">{n.icon}</div>
              <div className="flex-1 min-w-0">
                <div className="text-2xl font-light tracking-wide">{n.display}</div>
                <div className="text-sm font-medium opacity-95 mt-1">{n.title}</div>
                <div className="text-xs opacity-80 mt-0.5">{n.subtitle}</div>
              </div>
              <svg className="w-5 h-5 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </a>
        ))}
      </div>

      <div className="mt-8 bg-white dark:bg-neutral-900 rounded-2xl p-5 text-sm text-neutral-600 dark:text-neutral-300">
        <h3 className="font-semibold text-neutral-900 dark:text-white mb-2">💡 Pamiętaj</h3>
        <ul className="space-y-2 list-disc list-inside">
          <li>112 działa nawet bez karty SIM i poza zasięgiem własnej sieci.</li>
          <li>Podaj imię, lokalizację i opis zdarzenia.</li>
          <li>Nie rozłączaj się, dopóki dyspozytor sam nie zakończy rozmowy.</li>
          <li>Z aplikacji be:Safe SOS lokalizacja jest dzielona automatycznie z bliskimi.</li>
        </ul>
      </div>
    </div>
  );
}
