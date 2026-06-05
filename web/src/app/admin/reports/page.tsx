'use client';

import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import AdminShell from '@/components/ui/AdminShell';
import { useAuth } from '@/contexts/AuthContext';
import api from '@/lib/api';
import { getCategoryInfo } from '@/types';
import type { AlertCategory } from '@/types';

interface Report {
  id: string;
  alert_id: string;
  reporter_id: string;
  reporter_username: string;
  reason: string;
  details: string | null;
  status: string;
  created_at: string;
  alert_title: string;
  alert_category: AlertCategory;
  alert_description: string | null;
}

export default function AdminReportsPage() {
  const { user } = useAuth();
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    const res = await api.get<{ reports: Report[]; error?: string }>(`/admin/reports?status=pending`);
    setLoading(false);
    if (!res.error) setReports(res.reports || []);
  }, []);

  useEffect(() => {
    if (user?.is_admin) load();
  }, [user, load]);

  const resolve = async (id: string, action: 'delete_alert' | 'dismiss') => {
    const msg = action === 'delete_alert' ? 'Usunąć alert i zamknąć zgłoszenie?' : 'Odrzucić zgłoszenie (alert pozostaje)?';
    if (!confirm(msg)) return;
    setBusy(id);
    const res = await api.post<{ ok?: boolean; error?: string }>(`/admin/reports/${id}/resolve`, { action });
    setBusy(null);
    if (!res.error) {
      setReports(prev => prev.filter(r => r.id !== id));
    } else {
      alert(res.error);
    }
  };

  if (!user?.is_admin) return <AdminShell><div className="p-8 text-center text-neutral-500">Brak dostępu</div></AdminShell>;

  return (
    <AdminShell>
      <div className="max-w-4xl mx-auto px-4 py-6 space-y-4">
        <div className="flex items-center gap-3">
          <Link href="/admin" className="text-sm text-neutral-500 hover:underline">← Panel</Link>
          <h1 className="text-2xl font-medium">Zgłoszenia ({reports.length})</h1>
        </div>

        {loading && <p className="text-sm text-neutral-500">Ładowanie…</p>}

        <div className="grid gap-3">
          {reports.map(r => {
            const cat = getCategoryInfo(r.alert_category);
            return (
              <div key={r.id} className="rounded-2xl bg-white dark:bg-neutral-900 border border-red-200 dark:border-red-900 p-4 space-y-3">
                <div className="flex items-start gap-3">
                  <div className="text-2xl">{cat.emoji}</div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium">{r.alert_title}</p>
                    {r.alert_description && <p className="text-sm text-neutral-600 dark:text-neutral-400 line-clamp-2 mt-0.5">{r.alert_description}</p>}
                  </div>
                </div>

                <div className="rounded-xl bg-red-50 dark:bg-red-950/40 p-3">
                  <p className="text-xs text-red-700 dark:text-red-300 font-medium">
                    Powód: <span className="font-semibold">{r.reason}</span>
                  </p>
                  {r.details && <p className="text-sm text-red-900 dark:text-red-200 mt-1">{r.details}</p>}
                  <p className="text-[11px] text-red-600 dark:text-red-400 mt-2">
                    od <span className="font-medium">{r.reporter_username}</span> · {new Date(r.created_at).toLocaleString('pl-PL')}
                  </p>
                </div>

                <div className="flex gap-2">
                  <button
                    onClick={() => resolve(r.id, 'delete_alert')}
                    disabled={busy === r.id}
                    className="flex-1 px-4 py-2 text-sm rounded-xl font-medium bg-red-100 text-red-700 hover:bg-red-200 dark:bg-red-950 dark:text-red-300 disabled:opacity-40"
                  >
                    🗑️ Usuń alert
                  </button>
                  <button
                    onClick={() => resolve(r.id, 'dismiss')}
                    disabled={busy === r.id}
                    className="flex-1 px-4 py-2 text-sm rounded-xl font-medium bg-neutral-100 text-neutral-700 hover:bg-neutral-200 dark:bg-neutral-800 dark:text-neutral-300 disabled:opacity-40"
                  >
                    ✓ Odrzuć zgłoszenie
                  </button>
                  <Link href={`/alerts/${r.alert_id}`} className="px-4 py-2 text-sm rounded-xl font-medium bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 hover:bg-neutral-50">
                    Zobacz
                  </Link>
                </div>
              </div>
            );
          })}
          {!loading && reports.length === 0 && (
            <div className="text-center py-12">
              <div className="text-5xl mb-3">🛡️</div>
              <p className="text-neutral-500">Brak oczekujących zgłoszeń</p>
            </div>
          )}
        </div>
      </div>
    </AdminShell>
  );
}
