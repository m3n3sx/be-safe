'use client';

import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import AdminShell from '@/components/ui/AdminShell';
import { useAuth } from '@/contexts/AuthContext';
import api from '@/lib/api';

interface AuditEntry {
  id: string;
  admin_id: string;
  admin_username: string;
  action: string;
  target_type: string;
  target_id: string;
  payload: Record<string, unknown> | null;
  created_at: string;
}

const ACTION_LABELS: Record<string, string> = {
  'user.ban': '🚫 Ban',
  'user.unban': '✅ Odbanowanie',
  'user.set_admin': '⭐ Admin',
  'user.update': '✏️ Edycja',
  'alert.delete': '🗑️ Usunięcie alertu',
  'alert.update': '✏️ Edycja alertu',
  'report.resolve': '🛡️ Rozstrzygnięcie zgłoszenia',
  'group.delete': '🗑️ Usunięcie grupy',
};

export default function AdminAuditPage() {
  const { user } = useAuth();
  const [log, setLog] = useState<AuditEntry[]>([]);
  const [loading, setLoading] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    const res = await api.get<{ log: AuditEntry[]; error?: string }>(`/admin/audit-log?limit=200`);
    setLoading(false);
    if (!res.error) setLog(res.log || []);
  }, []);

  useEffect(() => {
    if (user?.is_admin) load();
  }, [user, load]);

  if (!user?.is_admin) return <AdminShell><div className="p-8 text-center text-neutral-500">Brak dostępu</div></AdminShell>;

  return (
    <AdminShell>
      <div className="max-w-5xl mx-auto px-4 py-6 space-y-4">
        <div className="flex items-center gap-3">
          <Link href="/admin" className="text-sm text-neutral-500 hover:underline">← Panel</Link>
          <h1 className="text-2xl font-medium">Audit log ({log.length})</h1>
        </div>

        {loading && <p className="text-sm text-neutral-500">Ładowanie…</p>}

        <div className="rounded-2xl bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 overflow-hidden">
          <div className="divide-y divide-neutral-200 dark:divide-neutral-800">
            {log.map(e => (
              <div key={e.id} className="p-3.5 hover:bg-neutral-50 dark:hover:bg-neutral-800/40">
                <div className="flex items-start gap-3">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-medium text-sm">{ACTION_LABELS[e.action] || e.action}</span>
                      <span className="px-2 py-0.5 text-[10px] rounded-full bg-neutral-100 dark:bg-neutral-800 font-medium">{e.target_type}</span>
                    </div>
                    <p className="text-xs text-neutral-500 mt-1">
                      przez <span className="font-medium text-neutral-700 dark:text-neutral-300">{e.admin_username}</span> · target {e.target_id.slice(0, 8)}…
                    </p>
                    {e.payload && Object.keys(e.payload).length > 0 && (
                      <pre className="mt-2 text-[11px] bg-neutral-50 dark:bg-neutral-950 rounded-lg p-2 overflow-x-auto text-neutral-600 dark:text-neutral-400">
                        {JSON.stringify(e.payload, null, 2)}
                      </pre>
                    )}
                  </div>
                  <p className="text-[11px] text-neutral-500 flex-shrink-0 whitespace-nowrap">
                    {new Date(e.created_at).toLocaleString('pl-PL', { dateStyle: 'short', timeStyle: 'short' })}
                  </p>
                </div>
              </div>
            ))}
            {!loading && log.length === 0 && (
              <p className="p-8 text-center text-sm text-neutral-500">Brak wpisów</p>
            )}
          </div>
        </div>
      </div>
    </AdminShell>
  );
}
