'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import AppLayout from '@/components/ui/AppLayout';
import api from '@/lib/api';
import type { Alert } from '@/types';

const CAT_LABEL: Record<string, string> = {
  aggression: 'Agresja',
  theft: 'Kradzież',
  accident: 'Wypadek',
  fire: 'Pożar',
  flood: 'Powódź',
  ice: 'Lód',
  construction: 'Roboty',
  animal: 'Zwierzę',
  dark_area: 'Ciemny zakątek',
  drugs: 'Narkotyki',
  police: 'Policja',
  weather: 'Pogoda',
  other: 'Inne',
  stranger_danger: 'Obcy',
  traffic_danger: 'Drogowe',
  playground_hazard: 'Plac zabaw',
  water_hazard: 'Woda',
  school_zone: 'Strefa szkolna',
};

export default function MyAlertsPage() {
  const router = useRouter();
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    const res = await api.get<{ alerts: Alert[] }>('/alerts/mine');
    if (!res.error && res.alerts) setAlerts(res.alerts);
    setLoading(false);
  };
  useEffect(() => { load(); }, []);

  const remove = async (id: string) => {
    if (!confirm('Usunąć zgłoszenie?')) return;
    await api.delete(`/alerts/${id}`);
    load();
  };

  return (
    <AppLayout>
      <div className="max-w-3xl mx-auto px-4 py-6">
        <div className="flex items-center gap-3 mb-6">
          <button onClick={() => router.push('/')} className="text-2xl">←</button>
          <h1 className="text-2xl font-bold">📋 Moje zgłoszenia</h1>
        </div>

        {loading && <p className="text-neutral-500">Ładowanie…</p>}
        {!loading && alerts.length === 0 && (
          <div className="text-center py-12 text-neutral-500">
            <p className="text-5xl mb-2">📋</p>
            <p>Nie zgłosiłeś jeszcze nic.</p>
          </div>
        )}

        <div className="space-y-3">
          {alerts.map(a => (
            <div key={a.id} className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-4">
              <div className="flex justify-between items-start">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-xs px-2 py-0.5 rounded-full bg-[#9DF4CB]/30 text-[#1A2027] font-medium">{CAT_LABEL[a.category] || a.category}</span>
                    <span className={`text-xs px-2 py-0.5 rounded-full ${a.status === 'active' ? 'bg-emerald-100 text-emerald-700' : 'bg-neutral-200 text-neutral-700'}`}>
                      {a.status === 'active' ? 'Aktywne' : a.status}
                    </span>
                    <span className="text-xs text-neutral-500">Trust {(((a.trust_score ?? 0)) * 100).toFixed(0)}%</span>
                  </div>
                  <h3 className="font-semibold mt-1 truncate">{a.title}</h3>
                  {a.description && <p className="text-sm text-neutral-600 dark:text-neutral-400 mt-1 line-clamp-2">{a.description}</p>}
                  <p className="text-xs text-neutral-500 mt-2">
                    {new Date(a.created_at).toLocaleString('pl-PL', { dateStyle: 'short', timeStyle: 'short' })}
                    {' · '}👍 {a.confirms} 👎 {a.denies}
                  </p>
                </div>
                <button onClick={() => remove(a.id)} className="text-red-500 text-sm ml-2 shrink-0">Usuń</button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </AppLayout>
  );
}
