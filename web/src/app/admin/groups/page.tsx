'use client';

import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import AppLayout from '@/components/ui/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import api from '@/lib/api';

interface AdminGroup {
  id: string;
  name: string;
  owner_id: string;
  owner_username: string;
  invite_code: string;
  members_count: number;
  created_at: string;
}

export default function AdminGroupsPage() {
  const { user } = useAuth();
  const [groups, setGroups] = useState<AdminGroup[]>([]);
  const [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    const res = await api.get<{ groups: AdminGroup[]; error?: string }>(`/admin/groups`);
    setLoading(false);
    if (!res.error) setGroups(res.groups || []);
  }, []);

  useEffect(() => {
    if (user?.is_admin) load();
  }, [user, load]);

  const remove = async (id: string, name: string) => {
    if (!confirm(`Usunąć grupę "${name}" wraz ze wszystkimi członkami?`)) return;
    setBusy(id);
    const res = await api.delete<{ ok?: boolean; error?: string }>(`/admin/groups/${id}`);
    setBusy(null);
    if (!res.error) {
      setGroups(prev => prev.filter(g => g.id !== id));
    } else {
      alert(res.error);
    }
  };

  if (!user?.is_admin) return <AppLayout><div className="p-8 text-center text-neutral-500">Brak dostępu</div></AppLayout>;

  return (
    <AppLayout>
      <div className="max-w-4xl mx-auto px-4 py-6 space-y-4">
        <div className="flex items-center gap-3">
          <Link href="/admin" className="text-sm text-neutral-500 hover:underline">← Panel</Link>
          <h1 className="text-2xl font-medium">Grupy rodzinne ({groups.length})</h1>
        </div>

        {loading && <p className="text-sm text-neutral-500">Ładowanie…</p>}

        <div className="grid gap-2">
          {groups.map(g => (
            <div key={g.id} className="rounded-2xl bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 p-4 flex items-center gap-3">
              <div className="text-2xl">👨‍👩‍👧</div>
              <div className="flex-1 min-w-0">
                <p className="font-medium">{g.name}</p>
                <p className="text-xs text-neutral-500 mt-0.5">
                  owner: <span className="font-medium">{g.owner_username}</span> · {g.members_count} {g.members_count === 1 ? 'członek' : 'członków'} · kod: <span className="font-mono">{g.invite_code}</span>
                </p>
              </div>
              <button
                onClick={() => remove(g.id, g.name)}
                disabled={busy === g.id}
                className="px-3 py-1.5 text-xs rounded-lg font-medium bg-red-100 text-red-700 hover:bg-red-200 dark:bg-red-950 dark:text-red-300 disabled:opacity-40 flex-shrink-0"
              >
                Usuń
              </button>
            </div>
          ))}
          {!loading && groups.length === 0 && (
            <p className="text-center text-sm text-neutral-500 py-8">Brak grup</p>
          )}
        </div>
      </div>
    </AppLayout>
  );
}
