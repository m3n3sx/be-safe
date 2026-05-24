'use client';

import React, { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import AppLayout from '@/components/ui/AppLayout';

const PRESETS = [
  { label: 'Szef', name: 'Szef', delay: 5, ringtone: 'classic' },
  { label: 'Mama', name: 'Mama', delay: 10, ringtone: 'classic' },
  { label: 'Lekarz', name: 'Dr Kowalski', delay: 15, ringtone: 'classic' },
  { label: 'Partner', name: 'Anna', delay: 20, ringtone: 'classic' },
];

export default function FakeCallPage() {
  const router = useRouter();
  const [scheduled, setScheduled] = useState<{ name: string; ringIn: number } | null>(null);
  const [callActive, setCallActive] = useState<{ name: string; startedAt: number } | null>(null);
  const [tickKey, setTickKey] = useState(0);
  const timerRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (!scheduled) return;
    const id = setInterval(() => setTickKey(k => k + 1), 1000);
    return () => clearInterval(id);
  }, [scheduled]);

  useEffect(() => {
    if (!scheduled) return;
    const elapsed = Math.floor((Date.now() - (scheduled.ringIn * 1000 + Date.now() - scheduled.ringIn * 1000)) / 1000);
    if (elapsed >= 0 && scheduled.ringIn > 0) {
      const t = setTimeout(() => {
        setScheduled(null);
        setCallActive({ name: scheduled.name, startedAt: Date.now() });
        try { navigator.vibrate?.([500, 300, 500, 300, 500]); } catch {}
      }, scheduled.ringIn * 1000);
      return () => clearTimeout(t);
    }
  }, [scheduled]);

  useEffect(() => {
    if (!callActive) return;
    const id = setInterval(() => setTickKey(k => k + 1), 1000);
    return () => clearInterval(id);
  }, [callActive]);

  const schedule = (preset: typeof PRESETS[0]) => {
    setScheduled({ name: preset.name, ringIn: preset.delay });
  };

  const accept = () => {
    if (!callActive) return;
    // pretend we picked up - go to "in call" UI
  };
  const hangup = () => {
    setCallActive(null);
    setScheduled(null);
    if (timerRef.current) clearTimeout(timerRef.current);
    try { navigator.vibrate?.(0); } catch {}
  };

  // Faking ringing screen
  if (callActive) {
    const dur = Math.floor((Date.now() - callActive.startedAt) / 1000);
    const mm = String(Math.floor(dur / 60)).padStart(2, '0');
    const ss = String(dur % 60).padStart(2, '0');
    return (
      <div className="fixed inset-0 bg-[#1A2027] text-white flex flex-col items-center justify-between py-12 z-50">
        <div className="text-center" key={tickKey}>
          <p className="text-sm opacity-60 mb-2">Połączenie przychodzące</p>
          <div className="w-32 h-32 rounded-full bg-[#9DF4CB]/20 flex items-center justify-center mx-auto mb-4">
            <span className="text-5xl">{callActive.name[0]}</span>
          </div>
          <h2 className="text-3xl font-bold mb-1">{callActive.name}</h2>
          <p className="text-sm opacity-60">{mm}:{ss}</p>
        </div>
        <div className="flex gap-12">
          <button onClick={hangup} className="w-20 h-20 rounded-full bg-red-500 flex items-center justify-center text-3xl shadow-2xl">
            📞
          </button>
          <button onClick={accept} className="w-20 h-20 rounded-full bg-[#9DF4CB] flex items-center justify-center text-3xl shadow-2xl">
            ✅
          </button>
        </div>
      </div>
    );
  }

  return (
    <AppLayout>
      <div className="max-w-2xl mx-auto px-4 py-6">
        <div className="flex items-center gap-3 mb-6">
          <button onClick={() => router.push('/')} className="text-2xl">←</button>
          <h1 className="text-2xl font-bold">📞 Fake Call</h1>
        </div>
        <p className="text-sm text-neutral-500 mb-6">Symulowane połączenie przychodzące. Idealne na wyjście z niezręcznej sytuacji.</p>

        {scheduled ? (
          <div className="bg-[#9DF4CB]/20 border border-[#9DF4CB] rounded-2xl p-6 text-center">
            <p className="text-sm opacity-70 mb-2">Połączenie za</p>
            <p className="text-5xl font-bold mb-4">{scheduled.ringIn}s</p>
            <p className="text-sm mb-4">od: {scheduled.name}</p>
            <button onClick={() => setScheduled(null)} className="px-4 py-2 rounded-lg bg-neutral-200 dark:bg-neutral-800">Anuluj</button>
          </div>
        ) : (
          <div className="grid grid-cols-2 gap-3">
            {PRESETS.map(p => (
              <button
                key={p.label}
                onClick={() => schedule(p)}
                className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-5 hover:bg-[#9DF4CB]/10 transition-colors text-left"
              >
                <p className="text-3xl mb-2">📱</p>
                <p className="font-semibold">{p.label}</p>
                <p className="text-xs text-neutral-500">Za {p.delay}s · {p.name}</p>
              </button>
            ))}
          </div>
        )}

        <div className="mt-8 text-xs text-neutral-500 space-y-1">
          <p>💡 Brzęczyk wibracji włączy się gdy &laquo;telefon zadzwoni&raquo;.</p>
          <p>💡 Możesz tylko odrzucić — udajemy bezpieczeństwo, nie prawdziwą rozmowę.</p>
        </div>
      </div>
    </AppLayout>
  );
}
