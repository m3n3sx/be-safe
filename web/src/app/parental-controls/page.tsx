'use client';

import React from 'react';
import AppLayout from '@/components/ui/AppLayout';

interface PcTool {
  name: string;
  desc: string;
  url: string;
  emoji: string;
  gradient: string;
}

const TOOLS: PcTool[] = [
  {
    name: 'Google Family Link',
    desc: 'Limity czasu, blokada aplikacji, lokalizacja, kontrola zakupów (Android + iOS).',
    url: 'https://families.google.com/familylink/',
    emoji: '👨‍👩‍👧‍👦',
    gradient: 'from-emerald-500/15 to-emerald-500/5',
  },
  {
    name: 'Apple Screen Time / Czas przed ekranem',
    desc: 'Wbudowane w iOS/macOS. Limity, raporty użycia, treści dla dzieci.',
    url: 'https://support.apple.com/pl-pl/HT208982',
    emoji: '📱',
    gradient: 'from-neutral-500/15 to-neutral-500/5',
  },
  {
    name: 'Qustodio',
    desc: 'Płatny menedżer kontroli rodzicielskiej — filtr WWW, social, śledzenie wiadomości.',
    url: 'https://www.qustodio.com/pl/',
    emoji: '🛡️',
    gradient: 'from-rose-500/15 to-rose-500/5',
  },
  {
    name: 'Bark',
    desc: 'AI monitorujące wiadomości i social media dziecka pod kątem zagrożeń (US/EN).',
    url: 'https://www.bark.us/',
    emoji: '🧠',
    gradient: 'from-amber-500/15 to-amber-500/5',
  },
  {
    name: 'NASK — Dyzurnet.pl',
    desc: 'Polskie centrum zgłaszania nielegalnych treści dotyczących dzieci.',
    url: 'https://dyzurnet.pl/',
    emoji: '🚨',
    gradient: 'from-blue-500/15 to-blue-500/5',
  },
  {
    name: 'Fundacja Dajemy Dzieciom Siłę',
    desc: 'Porady dla rodziców, materiały edukacyjne, telefon zaufania 116 111.',
    url: 'https://fdds.pl/',
    emoji: '💚',
    gradient: 'from-teal-500/15 to-teal-500/5',
  },
];

export default function ParentalControlsPage() {
  return (
    <AppLayout>
      <div className="max-w-3xl mx-auto px-4 py-6 space-y-4">
        <h1 className="text-2xl font-bold text-neutral-900 dark:text-white">Kontrola rodzicielska</h1>

        <div
          className="rounded-3xl p-5 text-[#1A2027]"
          style={{
            background: 'linear-gradient(135deg, #9DF4CB 0%, #9EEBEC 100%)',
          }}
        >
          <div className="text-2xl mb-2">🛡️</div>
          <div className="font-bold text-lg mb-1">be:Safe nie zastępuje pełnego parental control</div>
          <div className="text-sm">
            My zajmujemy się bezpieczeństwem w okolicy i komunikacją rodzinną. Do limitów czasu, kontroli treści i filtrów WWW polecamy sprawdzone narzędzia ↓
          </div>
        </div>

        <div className="grid gap-3">
          {TOOLS.map(tool => (
            <a
              key={tool.url}
              href={tool.url}
              target="_blank"
              rel="noopener noreferrer"
              className={`block rounded-2xl bg-gradient-to-br ${tool.gradient} border border-neutral-200 dark:border-neutral-800 p-4 hover:border-neutral-400 dark:hover:border-neutral-600 transition-colors`}
            >
              <div className="flex items-start gap-3">
                <div className="text-3xl">{tool.emoji}</div>
                <div className="flex-1">
                  <div className="font-semibold text-neutral-900 dark:text-white">{tool.name}</div>
                  <div className="text-sm text-neutral-600 dark:text-neutral-400 mt-1">{tool.desc}</div>
                  <div className="text-xs text-neutral-500 mt-2">Otwórz w nowej karcie →</div>
                </div>
              </div>
            </a>
          ))}
        </div>

        <p className="text-xs text-center text-neutral-500 pt-4">
          F32 — be:Safe nie wymaga uprawnień administratora ani dostępu do treści twojego dziecka.
        </p>
      </div>
    </AppLayout>
  );
}
