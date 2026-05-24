'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import AppLayout from '@/components/ui/AppLayout';

const PERMISSIONS = [
  { key: 'geolocation', label: 'Lokalizacja', icon: '📍', desc: 'Pokaż okolicę i blisko-położone zagrożenia' },
  { key: 'notifications', label: 'Powiadomienia', icon: '🔔', desc: 'Otrzymuj alerty w pobliżu i sygnały rodziny' },
  { key: 'camera', label: 'Kamera', icon: '📷', desc: 'Dodawanie zdjęć do zgłoszeń' },
  { key: 'microphone', label: 'Mikrofon', icon: '🎤', desc: 'Audio SOS (RODO consent)' },
];

export default function PermissionsPage() {
  const router = useRouter();
  const [status, setStatus] = useState<Record<string, string>>({});

  const check = useCallback(async () => {
    const out: Record<string, string> = {};
    for (const p of PERMISSIONS) {
      try {
        const r = await navigator.permissions?.query({ name: p.key as PermissionName });
        out[p.key] = r?.state || 'unknown';
      } catch {
        out[p.key] = 'unsupported';
      }
    }
    setStatus(out);
  }, []);

  useEffect(() => { check(); }, [check]);

  const request = async (key: string) => {
    if (key === 'geolocation') {
      navigator.geolocation?.getCurrentPosition(() => check(), () => check(), { timeout: 5000 });
    } else if (key === 'notifications') {
      await Notification.requestPermission();
      check();
    } else if (key === 'camera') {
      try {
        const s = await navigator.mediaDevices?.getUserMedia({ video: true });
        s?.getTracks().forEach(t => t.stop());
      } catch {}
      check();
    } else if (key === 'microphone') {
      try {
        const s = await navigator.mediaDevices?.getUserMedia({ audio: true });
        s?.getTracks().forEach(t => t.stop());
      } catch {}
      check();
    }
  };

  const badge = (s: string) => {
    if (s === 'granted') return { txt: 'Włączone', cls: 'bg-emerald-100 text-emerald-700' };
    if (s === 'denied') return { txt: 'Zablokowane', cls: 'bg-red-100 text-red-700' };
    if (s === 'prompt') return { txt: 'Nie ustawione', cls: 'bg-amber-100 text-amber-700' };
    return { txt: 'Niedostępne', cls: 'bg-neutral-200 text-neutral-700' };
  };

  return (
    <AppLayout>
      <div className="max-w-2xl mx-auto px-4 py-6">
        <div className="flex items-center gap-3 mb-6">
          <button onClick={() => router.push('/settings')} className="text-2xl">←</button>
          <h1 className="text-2xl font-bold">🔐 Uprawnienia</h1>
        </div>
        <p className="text-sm text-neutral-500 mb-6">Włącz potrzebne uprawnienia przeglądarki. Zablokowane uprawnienia odblokowuj w ustawieniach przeglądarki.</p>

        <div className="space-y-3">
          {PERMISSIONS.map(p => {
            const b = badge(status[p.key] || 'unknown');
            return (
              <div key={p.key} className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-4 flex items-center gap-3">
                <div className="w-12 h-12 rounded-xl bg-[#9DF4CB]/20 flex items-center justify-center text-2xl">{p.icon}</div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <p className="font-semibold">{p.label}</p>
                    <span className={`text-xs px-2 py-0.5 rounded-full ${b.cls}`}>{b.txt}</span>
                  </div>
                  <p className="text-xs text-neutral-500">{p.desc}</p>
                </div>
                <button
                  onClick={() => request(p.key)}
                  disabled={status[p.key] === 'denied'}
                  className="px-3 py-1.5 rounded-lg bg-[#1A2027] text-white text-sm disabled:opacity-40"
                >
                  {status[p.key] === 'granted' ? '✓' : 'Włącz'}
                </button>
              </div>
            );
          })}
        </div>
      </div>
    </AppLayout>
  );
}
