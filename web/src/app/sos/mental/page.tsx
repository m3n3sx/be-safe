'use client';

import React from 'react';
import { useRouter } from 'next/navigation';

interface HelpLine {
  number: string;
  display: string;
  title: string;
  subtitle: string;
  bg: string;
  fg: string;
}

const lines: HelpLine[] = [
  {
    number: '116123',
    display: '116 123',
    title: 'Telefon Zaufania dla dorosłych',
    subtitle: 'Kryzys, depresja, samotność — 24/7',
    bg: 'bg-[#1A2027]',
    fg: 'text-white',
  },
  {
    number: '116111',
    display: '116 111',
    title: 'Telefon Zaufania dla Dzieci i Młodzieży',
    subtitle: 'Dla osób do 18 r. ż. — 24/7',
    bg: 'bg-[#9EEBEC]',
    fg: 'text-[#1A2027]',
  },
  {
    number: '800702222',
    display: '800 70 22 22',
    title: 'Centrum Wsparcia dla Osób w Stanie Kryzysu',
    subtitle: 'Linia dla dorosłych — pon-pt 9-21',
    bg: 'bg-[#9DF4CB]',
    fg: 'text-[#1A2027]',
  },
  {
    number: '112',
    display: '112',
    title: 'Numer alarmowy',
    subtitle: 'Bezpośrednie zagrożenie życia',
    bg: 'bg-[#FF7A7A]',
    fg: 'text-white',
  },
];

export default function MentalHealthSosPage() {
  const router = useRouter();
  return (
    <div className="min-h-screen bg-white dark:bg-neutral-900 px-6 py-6 max-w-2xl mx-auto">
      <div className="flex items-center gap-3 mb-6">
        <button
          onClick={() => router.back()}
          className="w-10 h-10 rounded-full flex items-center justify-center hover:bg-neutral-100 dark:hover:bg-neutral-800"
          aria-label="Zamknij"
        >
          <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
        <h1 className="text-xl font-light text-neutral-900 dark:text-white">Wsparcie psychologiczne</h1>
      </div>

      <div className="bg-[#9EEBEC]/20 dark:bg-[#9EEBEC]/10 rounded-2xl p-5 mb-6">
        <h2 className="font-semibold text-neutral-900 dark:text-white mb-2">Nie jesteś sam/a</h2>
        <p className="text-sm text-neutral-700 dark:text-neutral-300 leading-relaxed">
          Te numery są bezpłatne i anonimowe. Specjaliści wysłuchają i pomogą znaleźć rozwiązanie.
        </p>
      </div>

      <div className="space-y-3">
        {lines.map(l => (
          <a
            key={l.number}
            href={`tel:${l.number}`}
            className={`block ${l.bg} ${l.fg} rounded-2xl p-5 hover:opacity-95 active:scale-[0.98] transition-all`}
          >
            <div className="flex items-center gap-4">
              <div className="text-2xl font-light">📞</div>
              <div className="flex-1 min-w-0">
                <div className="text-2xl font-light tracking-wide">{l.display}</div>
                <div className="text-sm font-medium opacity-95 mt-1">{l.title}</div>
                <div className="text-xs opacity-80 mt-0.5">{l.subtitle}</div>
              </div>
              <svg className="w-5 h-5 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </a>
        ))}
      </div>

      <a
        href="https://www.psycholodzy.pl"
        target="_blank"
        rel="noreferrer"
        className="mt-6 flex items-center gap-4 p-4 rounded-2xl bg-white dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-700 hover:bg-neutral-50 dark:hover:bg-neutral-750"
      >
        <div className="w-12 h-12 rounded-full bg-[#9EEBEC]/40 dark:bg-[#9EEBEC]/20 flex items-center justify-center text-xl">🧠</div>
        <div className="flex-1">
          <div className="font-semibold text-neutral-900 dark:text-white">Znajdź psychologa</div>
          <div className="text-xs text-neutral-500">psycholodzy.pl — baza specjalistów</div>
        </div>
        <svg className="w-5 h-5 text-neutral-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
        </svg>
      </a>
    </div>
  );
}
