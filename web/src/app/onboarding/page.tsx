'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

interface OnboardPage {
  icon: string;
  title: string;
  desc: string;
  glow: string;
}

const PAGES: OnboardPage[] = [
  {
    icon: '🛡️',
    title: 'Witaj w be:Safe',
    desc: 'Twoja spokojna strefa bezpieczeństwa. Zobacz co dzieje się w okolicy i chroń bliskich.',
    glow: '#9DF4CB',
  },
  {
    icon: '🗺️',
    title: 'Mapa w czasie rzeczywistym',
    desc: 'Zobacz zagrożenia zgłoszone przez społeczność. Wszystko w jednym, wyciszonym widoku.',
    glow: '#9EEBEC',
  },
  {
    icon: '🔔',
    title: 'Inteligentne alerty',
    desc: 'Powiadamiamy tylko o tym co ważne, w promieniu który sam ustawisz.',
    glow: '#9DF4CB',
  },
  {
    icon: '👨‍👩‍👧',
    title: 'Rodzina pod opieką',
    desc: 'Utwórz grupę rodzinną. Wiedz gdzie są bliscy i czy są bezpieczni.',
    glow: '#9EEBEC',
  },
  {
    icon: '🆘',
    title: 'SOS w jednej chwili',
    desc: 'Przytrzymaj SOS na ekranie głównym, by w 3 sekundy zaalarmować rodzinę i społeczność.',
    glow: '#FF7A7A',
  },
];

export default function OnboardingPage() {
  const router = useRouter();
  const [page, setPage] = useState(0);

  useEffect(() => {
    if (typeof window !== 'undefined' && localStorage.getItem('besafe.onboarded') === '1') {
      router.replace('/');
    }
  }, [router]);

  const finish = () => {
    if (typeof window !== 'undefined') {
      localStorage.setItem('besafe.onboarded', '1');
    }
    router.replace('/');
  };

  const next = () => {
    if (page < PAGES.length - 1) setPage(page + 1);
    else finish();
  };

  const cur = PAGES[page];
  const isLast = page === PAGES.length - 1;

  return (
    <main className="fixed inset-0 flex flex-col bg-white dark:bg-[#0F1419]">
      <div className="flex justify-end p-4">
        <button
          onClick={finish}
          className="text-sm font-medium text-neutral-500 dark:text-neutral-400 hover:text-neutral-900 dark:hover:text-white"
        >
          Pomiń
        </button>
      </div>

      <div className="flex flex-1 flex-col items-center justify-center px-6 text-center">
        <div
          className="relative mb-12 flex h-64 w-64 items-center justify-center rounded-full"
          style={{
            background: `radial-gradient(circle at center, ${cur.glow}66 0%, ${cur.glow}00 70%)`,
          }}
        >
          <div className="text-7xl">{cur.icon}</div>
        </div>
        <h1 className="mb-4 text-3xl font-light text-neutral-900 dark:text-white">
          {cur.title}
        </h1>
        <p className="max-w-md text-base leading-relaxed text-neutral-600 dark:text-neutral-300">
          {cur.desc}
        </p>
      </div>

      <div className="flex justify-center gap-2 py-6">
        {PAGES.map((_, i) => (
          <div
            key={i}
            className={`h-2 rounded-full transition-all ${
              i === page
                ? 'w-8 bg-neutral-900 dark:bg-white'
                : 'w-2 bg-neutral-300 dark:bg-neutral-700'
            }`}
          />
        ))}
      </div>

      <div className="p-6 pb-10">
        <button
          onClick={next}
          className="w-full rounded-full bg-neutral-900 dark:bg-white py-4 text-base font-medium text-white dark:text-neutral-900 transition-opacity hover:opacity-90"
        >
          {isLast ? 'Rozpocznij' : 'Dalej'}
        </button>
      </div>
    </main>
  );
}
