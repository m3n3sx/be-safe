'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import AppLayout from '@/components/ui/AppLayout';
import api from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';

export default function ReferralPage() {
  const router = useRouter();
  const { user } = useAuth();
  const [code, setCode] = useState<string>('');
  const [count, setCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    (async () => {
      const res = await api.get<{ referral_code?: string; referrals_count?: number }>('/users/me');
      if (!res.error) {
        setCode(res.referral_code || '');
        setCount(res.referrals_count || 0);
      }
      setLoading(false);
    })();
  }, []);

  const link = code ? `https://besafe.org.pl/?ref=${code}` : '';

  const copy = async () => {
    if (!link) return;
    try {
      await navigator.clipboard.writeText(link);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {}
  };

  const share = async () => {
    if (!link) return;
    if (navigator.share) {
      try { await navigator.share({ title: 'be:Safe', text: 'Dołącz do mnie na be:Safe', url: link }); } catch {}
    } else { copy(); }
  };

  return (
    <AppLayout>
      <div className="max-w-2xl mx-auto px-4 py-6">
        <div className="flex items-center gap-3 mb-6">
          <button onClick={() => router.push('/profile')} className="text-2xl">←</button>
          <h1 className="text-2xl font-bold">🎁 Zaproś znajomych</h1>
        </div>

        {loading ? <p className="text-neutral-500">Ładowanie…</p> : (
          <>
            <div className="bg-gradient-to-br from-[#9DF4CB] to-[#9EEBEC] rounded-3xl p-6 mb-6 text-[#1A2027]">
              <p className="text-sm font-medium opacity-80">Twój kod polecający</p>
              <p className="text-4xl font-bold tracking-widest font-mono my-3">{code || '----'}</p>
              <p className="text-sm">Polecone osoby: <span className="font-bold text-lg">{count}</span></p>
            </div>

            <div className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-4 mb-4">
              <p className="text-xs text-neutral-500 mb-2">Twój link</p>
              <code className="block break-all text-sm font-mono bg-neutral-100 dark:bg-neutral-800 p-3 rounded-lg">{link || '...'}</code>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <button onClick={copy} disabled={!link} className="py-3 rounded-2xl bg-[#1A2027] text-white font-medium disabled:opacity-40">
                {copied ? '✓ Skopiowano' : '📋 Kopiuj link'}
              </button>
              <button onClick={share} disabled={!link} className="py-3 rounded-2xl bg-[#FF7A7A] text-white font-medium disabled:opacity-40">
                📤 Udostępnij
              </button>
            </div>

            <p className="text-xs text-neutral-500 text-center mt-6">
              Za każde polecenie zdobywasz odznakę i +50 pkt reputacji
              {user?.username && ` · ${user.username}`}
            </p>
          </>
        )}
      </div>
    </AppLayout>
  );
}
