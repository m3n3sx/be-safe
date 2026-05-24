'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import AppLayout from '@/components/ui/AppLayout';
import api from '@/lib/api';

interface Badge {
  code: string;
  name: string;
  description: string;
  earned_at: string;
  icon?: string;
}

export default function BadgesPage() {
  const router = useRouter();
  const [badges, setBadges] = useState<Badge[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      const res = await api.get<{ badges: Badge[] }>('/users/me/badges');
      if (!res.error && res.badges) setBadges(res.badges);
      setLoading(false);
    })();
  }, []);

  return (
    <AppLayout>
      <div className="max-w-3xl mx-auto px-4 py-6">
        <div className="flex items-center gap-3 mb-6">
          <button onClick={() => router.push('/profile')} className="text-2xl">←</button>
          <h1 className="text-2xl font-bold">🏅 Odznaki</h1>
        </div>

        {loading && <p className="text-neutral-500">Ładowanie…</p>}
        {!loading && badges.length === 0 && (
          <div className="text-center py-12 text-neutral-500">
            <p className="text-6xl mb-3">🏅</p>
            <p>Brak odznak. Zgłaszaj alerty, pomagaj rodzinie i wracaj.</p>
          </div>
        )}

        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
          {badges.map(b => (
            <div key={b.code} className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-4 text-center">
              <p className="text-4xl mb-2">{b.icon || '🏅'}</p>
              <p className="font-semibold text-sm">{b.name}</p>
              <p className="text-xs text-neutral-500 mt-1">{b.description}</p>
              <p className="text-[10px] text-neutral-400 mt-2">{new Date(b.earned_at).toLocaleDateString('pl-PL')}</p>
            </div>
          ))}
        </div>
      </div>
    </AppLayout>
  );
}
