'use client';

import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import AppLayout from '@/components/ui/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import api from '@/lib/api';

interface Stats {
  users: { n: number; banned: number; admins: number; new_week: number };
  alerts: { n: number; active: number; new_24h: number };
  groups: { n: number };
  pets: { n: number; lost: number };
  reports_pending: number;
}

export default function AdminPage() {
  const { user, loading } = useAuth();
  const [stats, setStats] = useState<Stats | null>(null);
  const [backup, setBackup] = useState<{ age_hours?: number; is_stale?: boolean; file?: string; size_human?: string } | null>(null);
  const [err, setErr] = useState<string | null>(null);

  const loadStats = useCallback(async () => {
    const res = await api.get<Stats & { error?: string }>('/admin/stats');
    if (res.error) { setErr(res.error); return; }
    setStats(res as Stats);
  }, []);

  const loadBackup = useCallback(async () => {
    const res = await api.get<{ age_hours?: number; is_stale?: boolean; file?: string; size_human?: string; error?: string }>('/admin/backup-status');
    if (!res.error) setBackup(res);
  }, []);

  useEffect(() => {
    if (!user?.is_admin) return;
    loadStats();
    loadBackup();
  }, [user, loadStats, loadBackup]);

  if (loading) return <AppLayout><div /></AppLayout>;

  if (!user?.is_admin) {
    return (
      <AppLayout>
        <div className="max-w-3xl mx-auto px-4 py-12 text-center">
          <div className="text-6xl mb-4">🔒</div>
          <h1 className="text-2xl font-medium mb-2">Brak dostępu</h1>
          <p className="text-neutral-500">Ten panel jest dostępny tylko dla administratorów.</p>
        </div>
      </AppLayout>
    );
  }

  return (
    <AppLayout>
      <div className="max-w-6xl mx-auto px-4 py-6 space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-medium tracking-tight">Panel admina</h1>
            <p className="text-sm text-neutral-500 mt-1">Moderacja i kontrola be:Safe</p>
          </div>
          <span className="px-3 py-1.5 text-xs rounded-full bg-[#9DF4CB]/20 text-[#1A2027] dark:text-[#9DF4CB] font-medium">
            {user.username}
          </span>
        </div>

        {err && (
          <div className="rounded-2xl p-4 bg-red-50 dark:bg-red-950 border border-red-200 dark:border-red-900 text-red-900 dark:text-red-200">
            {err}
          </div>
        )}

        {/* Stats grid */}
        {stats && (
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <StatCard label="Użytkownicy" value={stats.users.n} sub={`+${stats.users.new_week} ten tydzień`} color="#9DF4CB" />
            <StatCard label="Alerty aktywne" value={stats.alerts.active} sub={`+${stats.alerts.new_24h} ostatnie 24h`} color="#9EEBEC" />
            <StatCard label="Grupy rodzinne" value={stats.groups.n} sub={`${stats.pets.n} zwierzaków`} color="#FFE0B2" />
            <StatCard label="Do moderacji" value={stats.reports_pending} sub={`${stats.users.banned} zbanowanych`} color="#FF7A7A" highlight={stats.reports_pending > 0} />
          </div>
        )}

        {/* Backup */}
        {backup && (
          <div className={`rounded-2xl p-4 border ${backup.is_stale ? 'bg-amber-50 dark:bg-amber-950 border-amber-200 dark:border-amber-900' : 'bg-emerald-50 dark:bg-emerald-950 border-emerald-200 dark:border-emerald-900'}`}>
            <div className="flex items-start gap-3">
              <div className="text-2xl">{backup.is_stale ? '⚠️' : '✅'}</div>
              <div className="flex-1">
                <p className="font-medium">
                  Backup DB: {backup.is_stale ? `${backup.age_hours?.toFixed(1)}h temu (przeterminowany!)` : `${backup.age_hours?.toFixed(1)}h temu`}
                </p>
                <p className="text-xs text-neutral-600 dark:text-neutral-400 mt-1">
                  {backup.file} · {backup.size_human}
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Sekcje moderacji */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-3">
          <AdminTile href="/admin/users" emoji="👥" title="Użytkownicy" desc="Lista, ban, role" />
          <AdminTile href="/admin/alerts" emoji="🚨" title="Alerty" desc="Edycja, usuwanie" />
          <AdminTile href="/admin/reports" emoji="🛡️" title="Zgłoszenia" desc={`${stats?.reports_pending ?? 0} oczekujące`} highlight={(stats?.reports_pending ?? 0) > 0} />
          <AdminTile href="/admin/groups" emoji="👨‍👩‍👧" title="Grupy rodzinne" desc="Lista, usuwanie" />
          <AdminTile href="/admin/audit" emoji="📋" title="Audit log" desc="Historia akcji adminów" />
          <AdminTile href="/admin/stats" emoji="📊" title="Statystyki" desc="Pełna analityka" />
        </div>
      </div>
    </AppLayout>
  );
}

function StatCard({ label, value, sub, color, highlight }: { label: string; value: number; sub?: string; color: string; highlight?: boolean }) {
  return (
    <div className={`rounded-2xl p-4 bg-white dark:bg-neutral-900 border ${highlight ? 'border-red-300 dark:border-red-700' : 'border-neutral-200 dark:border-neutral-800'} relative overflow-hidden`}>
      <div className="absolute -top-6 -right-6 w-20 h-20 rounded-full opacity-30" style={{ background: `radial-gradient(circle, ${color} 0%, transparent 70%)` }} />
      <p className="text-xs text-neutral-500 dark:text-neutral-400 relative">{label}</p>
      <p className="text-3xl font-medium mt-1 relative">{value}</p>
      {sub && <p className="text-xs text-neutral-500 dark:text-neutral-400 mt-1 relative">{sub}</p>}
    </div>
  );
}

function AdminTile({ href, emoji, title, desc, highlight }: { href: string; emoji: string; title: string; desc: string; highlight?: boolean }) {
  return (
    <Link href={href} className={`rounded-2xl p-4 bg-white dark:bg-neutral-900 border hover:shadow-md transition ${highlight ? 'border-red-300 dark:border-red-700' : 'border-neutral-200 dark:border-neutral-800'}`}>
      <div className="flex items-start gap-3">
        <div className="text-3xl">{emoji}</div>
        <div className="flex-1">
          <p className="font-medium">{title}</p>
          <p className="text-xs text-neutral-500 dark:text-neutral-400 mt-0.5">{desc}</p>
        </div>
      </div>
    </Link>
  );
}
