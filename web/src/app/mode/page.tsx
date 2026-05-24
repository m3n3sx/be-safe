'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import api from '@/lib/api';
import AppLayout from '@/components/ui/AppLayout';

type Mode = 'kids' | 'senior' | 'normal';

interface ModeOption {
  value: Mode;
  emoji: string;
  title: string;
  desc: string;
  glow: string;
}

const OPTIONS: ModeOption[] = [
  {
    value: 'kids',
    emoji: '🧒',
    title: 'Dla dziecka',
    desc: 'Duże ikony, prosty SOS, wesołe kolory. Dla osób 7-12 lat.',
    glow: '#9EEBEC',
  },
  {
    value: 'senior',
    emoji: '👵',
    title: 'Dla seniora',
    desc: 'Bardzo duże napisy, codzienny check-in, łatwy SOS bez przytrzymania.',
    glow: '#FFD89D',
  },
  {
    value: 'normal',
    emoji: '👤',
    title: 'Standardowy',
    desc: 'Pełen zestaw funkcji be:Safe. Domyślny tryb dla osób 13-59 lat.',
    glow: '#9DF4CB',
  },
];

export default function ModePickerPage() {
  const router = useRouter();
  const { user, refreshUser } = useAuth();
  const [saving, setSaving] = useState<Mode | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!user) {
      router.replace('/');
    }
  }, [user, router]);

  const pick = async (m: Mode) => {
    setSaving(m);
    setError('');
    try {
      await api.patch('/users/me', { app_mode: m });
      await refreshUser();
      router.replace('/');
    } catch (e) {
      setError((e as Error)?.message ?? 'Błąd zapisu');
    } finally {
      setSaving(null);
    }
  };

  return (
    <AppLayout>
      <div className="mx-auto max-w-2xl">
        <h1 className="mb-2 text-3xl font-light text-neutral-900 dark:text-white">
          Wybierz tryb aplikacji
        </h1>
        <p className="mb-8 text-sm text-neutral-600 dark:text-neutral-400">
          Każdy tryb dopasowuje interfejs i powiadomienia do innego użytkownika. Zmienisz go w dowolnym momencie w Ustawieniach.
        </p>

        {error && (
          <div className="mb-4 rounded-2xl bg-red-50 dark:bg-red-950/30 p-3 text-sm text-red-600">
            {error}
          </div>
        )}

        <div className="grid gap-4">
          {OPTIONS.map((o) => (
            <button
              key={o.value}
              onClick={() => pick(o.value)}
              disabled={saving !== null}
              className="group relative flex items-center gap-4 overflow-hidden rounded-3xl bg-white dark:bg-[#1A2027] p-6 text-left shadow-sm transition hover:shadow-md disabled:opacity-50"
            >
              <div
                className="absolute right-0 top-0 h-32 w-32 rounded-full opacity-50 blur-2xl"
                style={{ background: o.glow }}
              />
              <div className="relative text-5xl">{o.emoji}</div>
              <div className="relative flex-1">
                <div className="mb-1 flex items-center gap-2">
                  <h2 className="text-lg font-medium text-neutral-900 dark:text-white">
                    {o.title}
                  </h2>
                  {user?.app_mode === o.value && (
                    <span className="rounded-full bg-emerald-100 dark:bg-emerald-900/30 px-2 py-0.5 text-xs text-emerald-700 dark:text-emerald-300">
                      aktywny
                    </span>
                  )}
                </div>
                <p className="text-sm text-neutral-600 dark:text-neutral-400">
                  {o.desc}
                </p>
              </div>
              {saving === o.value && (
                <div className="relative h-5 w-5 animate-spin rounded-full border-2 border-neutral-900 border-t-transparent dark:border-white" />
              )}
            </button>
          ))}
        </div>
      </div>
    </AppLayout>
  );
}
