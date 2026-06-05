'use client';

import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import AdminShell from '@/components/ui/AdminShell';
import { useAuth } from '@/contexts/AuthContext';
import api from '@/lib/api';
import { getCategoryInfo } from '@/types';
import type { Alert } from '@/types';

interface AdminAlert extends Alert {
  reports_count?: number;
  author_username?: string;
}

export default function AdminAlertsPage() {
  const { user } = useAuth();
  const [alerts, setAlerts] = useState<AdminAlert[]>([]);
  const [status, setStatus] = useState<string>('active');
  const [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    const res = await api.get<{ alerts: AdminAlert[]; error?: string }>(`/admin/alerts?status=${status}&limit=200`);
    setLoading(false);
    if (!res.error) setAlerts(res.alerts || []);
  }, [status]);

  useEffect(() => {
    if (user?.is_admin) load();
  }, [user, load]);

  const removeAlert = async (id: string) => {
    if (!confirm('Usunąć alert na stałe?')) return;
    setBusy(id);
    const res = await api.delete<{ ok?: boolean; error?: string }>(`/admin/alerts/${id}`);
    setBusy(null);
    if (!res.error) {
      setAlerts(prev => prev.filter(a => a.id !== id));
    }
  };

  if (!user?.is_admin) return <AdminShell><div className="p-8 text-center text-neutral-500">Brak dostępu</div></AdminShell>;

  return (
    <AdminShell>
      <div className="max-w-6xl mx-auto px-4 py-6 space-y-4">
        <div className="flex items-center gap-3">
          <Link href="/admin" className="text-sm text-neutral-500 hover:underline">← Panel</Link>
          <h1 className="text-2xl font-medium">Alerty ({alerts.length})</h1>
        </div>

        <div className="flex gap-2 flex-wrap">
          {[
            { val: 'active', label: 'Aktywne' },
            { val: 'expired', label: 'Wygasłe' },
            { val: 'removed', label: 'Usunięte' },
            { val: 'hidden', label: 'Ukryte' },
            { val: '', label: 'Wszystkie' },
          ].map(s => (
            <button
              key={s.val}
              onClick={() => setStatus(s.val)}
              className={`px-4 py-2 rounded-full text-sm font-medium ${status === s.val ? 'bg-[#1A2027] dark:bg-[#9DF4CB] text-white dark:text-[#1A2027]' : 'bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800'}`}
            >
              {s.label}
            </button>
          ))}
        </div>

        {loading && <p className="text-sm text-neutral-500">Ładowanie…</p>}

        <div className="grid gap-2">
          {alerts.map(a => {
            const cat = getCategoryInfo(a.category);
            return (
              <div key={a.id} className="rounded-2xl bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 p-4">
                <div className="flex items-start gap-3">
                  <div className="text-2xl">{cat.emoji}</div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <p className="font-medium truncate">{a.title}</p>
                      <span className="px-2 py-0.5 text-[10px] rounded-full bg-neutral-100 dark:bg-neutral-800 font-medium">{cat.label}</span>
                      <span className={`px-2 py-0.5 text-[10px] rounded-full font-medium ${a.status === 'active' ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300' : 'bg-neutral-100 text-neutral-600 dark:bg-neutral-800 dark:text-neutral-400'}`}>
                        {a.status}
                      </span>
                      {(a.reports_count ?? 0) > 0 && (
                        <span className="px-2 py-0.5 text-[10px] rounded-full bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-300 font-medium">
                          ⚠️ {a.reports_count} zgłoszeń
                        </span>
                      )}
                    </div>
                    {a.description && <p className="text-sm text-neutral-600 dark:text-neutral-400 mt-1 line-clamp-2">{a.description}</p>}
                    <p className="text-xs text-neutral-500 mt-1.5">
                      {a.author_username && <>od <span className="font-medium">{a.author_username}</span> · </>}
                      ✓ {a.confirms} / ✗ {a.denies} · trust {((a.trust_score ?? 0) * 100).toFixed(0)}%
                    </p>
                  </div>
                  <button
                    onClick={() => removeAlert(a.id)}
                    disabled={busy === a.id}
                    className="px-3 py-1.5 text-xs rounded-lg font-medium bg-red-100 text-red-700 hover:bg-red-200 dark:bg-red-950 dark:text-red-300 disabled:opacity-40 flex-shrink-0"
                  >
                    Usuń
                  </button>
                </div>
              </div>
            );
          })}
          {!loading && alerts.length === 0 && (
            <p className="text-center text-sm text-neutral-500 py-8">Brak alertów</p>
          )}
        </div>
      </div>
    </AdminShell>
  );
}
