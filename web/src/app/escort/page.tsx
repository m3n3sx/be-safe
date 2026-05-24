'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import AppLayout from '@/components/ui/AppLayout';
import api from '@/lib/api';
import type { FamilyGroup, FamilyMember } from '@/types';

interface EscortSession {
  id: string;
  started_at: string;
  eta_seconds: number;
  status: string;
  destination_name?: string | null;
}

export default function EscortPage() {
  const router = useRouter();
  const [groups, setGroups] = useState<FamilyGroup[]>([]);
  const [members, setMembers] = useState<FamilyMember[]>([]);
  const [selectedGroup, setSelectedGroup] = useState<string>('');
  const [watcherId, setWatcherId] = useState<string>('');
  const [destName, setDestName] = useState('');
  const [etaMin, setEtaMin] = useState(15);
  const [active, setActive] = useState<EscortSession[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    (async () => {
      const g = await api.get<{ groups: FamilyGroup[] }>('/family/groups');
      if (!g.error && g.groups) setGroups(g.groups);
      const a = await api.get<{ sessions: EscortSession[] }>('/escort/active');
      if (!a.error && a.sessions) setActive(a.sessions);
    })();
  }, []);

  useEffect(() => {
    if (!selectedGroup) { setMembers([]); return; }
    (async () => {
      const m = await api.get<{ members: FamilyMember[] }>(`/family/groups/${selectedGroup}/members`);
      if (!m.error && m.members) setMembers(m.members);
    })();
  }, [selectedGroup]);

  const start = async () => {
    setError(null);
    if (!watcherId) { setError('Wybierz opiekuna'); return; }
    setLoading(true);
    const pos = await new Promise<GeolocationPosition | null>((r) => {
      if (!navigator.geolocation) return r(null);
      navigator.geolocation.getCurrentPosition(p => r(p), () => r(null), { timeout: 5000 });
    });
    const dest_lat = pos?.coords.latitude ?? 52.23;
    const dest_lng = pos?.coords.longitude ?? 21.01;
    const res = await api.post('/escort/start', {
      watcher_id: watcherId,
      destination_lat: dest_lat,
      destination_lng: dest_lng,
      destination_name: destName || 'Punkt docelowy',
      eta_seconds: etaMin * 60,
      group_id: selectedGroup,
    });
    setLoading(false);
    if (res.error) { setError(res.error); return; }
    setDestName(''); setWatcherId('');
    const a = await api.get<{ sessions: EscortSession[] }>('/escort/active');
    if (!a.error && a.sessions) setActive(a.sessions);
  };

  const cancel = async (id: string) => {
    if (!confirm('Anulować eskortę?')) return;
    await api.delete(`/escort/${id}`);
    const a = await api.get<{ sessions: EscortSession[] }>('/escort/active');
    if (!a.error && a.sessions) setActive(a.sessions);
  };

  return (
    <AppLayout>
      <div className="max-w-2xl mx-auto px-4 py-6">
        <div className="flex items-center gap-3 mb-6">
          <button onClick={() => router.push('/')} className="text-2xl">←</button>
          <h1 className="text-2xl font-bold">🛡 Eskorta &laquo;Follow Me&raquo;</h1>
        </div>
        <p className="text-sm text-neutral-500 mb-6">Wybrana osoba widzi Twoją trasę. Jeśli nie dotrzesz w ETA + 30s, dostaje powiadomienie panic.</p>

        {active.length > 0 && (
          <div className="bg-[#FFE4B5]/40 border border-orange-300 rounded-2xl p-4 mb-6">
            <h2 className="font-semibold mb-3">⏱ Aktywne sesje</h2>
            {active.map(s => (
              <div key={s.id} className="flex justify-between items-center py-2">
                <div>
                  <p className="text-sm font-medium">{s.destination_name || 'Eskorta'}</p>
                  <p className="text-xs text-neutral-500">ETA {Math.round(s.eta_seconds / 60)} min · {new Date(s.started_at).toLocaleTimeString('pl-PL')}</p>
                </div>
                <button onClick={() => cancel(s.id)} className="text-red-500 text-sm font-medium">Zakończ</button>
              </div>
            ))}
          </div>
        )}

        <div className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-5 space-y-4">
          <h2 className="font-semibold">Nowa eskorta</h2>

          <div>
            <label className="block text-sm mb-1">Grupa rodzinna</label>
            <select value={selectedGroup} onChange={e => setSelectedGroup(e.target.value)} className="w-full px-3 py-2 rounded-lg bg-neutral-100 dark:bg-neutral-800">
              <option value="">-- wybierz --</option>
              {groups.map(g => <option key={g.id} value={g.id}>{g.name}</option>)}
            </select>
          </div>

          <div>
            <label className="block text-sm mb-1">Opiekun</label>
            <select value={watcherId} onChange={e => setWatcherId(e.target.value)} className="w-full px-3 py-2 rounded-lg bg-neutral-100 dark:bg-neutral-800" disabled={!selectedGroup}>
              <option value="">-- wybierz członka --</option>
              {members.map(m => <option key={m.user_id} value={m.user_id}>{m.username} ({m.role})</option>)}
            </select>
          </div>

          <div>
            <label className="block text-sm mb-1">Cel</label>
            <input value={destName} onChange={e => setDestName(e.target.value)} placeholder="np. Dom, Szkoła" className="w-full px-3 py-2 rounded-lg bg-neutral-100 dark:bg-neutral-800" />
          </div>

          <div>
            <label className="block text-sm mb-1">ETA: {etaMin} min</label>
            <input type="range" min="5" max="120" step="5" value={etaMin} onChange={e => setEtaMin(parseInt(e.target.value))} className="w-full" />
          </div>

          {error && <p className="text-red-500 text-sm">{error}</p>}

          <button onClick={start} disabled={loading || !watcherId} className="w-full py-3 rounded-2xl bg-[#1A2027] text-white font-semibold disabled:opacity-40">
            {loading ? 'Startuję…' : '🛡 Rozpocznij eskortę'}
          </button>
        </div>
      </div>
    </AppLayout>
  );
}
