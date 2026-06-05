'use client';

import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import AdminShell from '@/components/ui/AdminShell';
import { useAuth } from '@/contexts/AuthContext';
import api from '@/lib/api';
import type { User } from '@/types';

interface AdminUser extends User {
  is_admin: boolean;
  is_banned: boolean;
  banned_at: string | null;
  ban_reason: string | null;
  is_verified: boolean;
  verified_role: string | null;
  created_at: string;
}

export default function AdminUsersPage() {
  const { user } = useAuth();
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [q, setQ] = useState('');
  const [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState<string | null>(null);

  const load = useCallback(async (search: string) => {
    setLoading(true);
    const res = await api.get<{ users: AdminUser[]; error?: string }>(`/admin/users${search ? `?q=${encodeURIComponent(search)}&limit=100` : '?limit=100'}`);
    setLoading(false);
    if (!res.error) setUsers(res.users || []);
  }, []);

  useEffect(() => {
    if (user?.is_admin) load('');
  }, [user, load]);

  const patch = async (id: string, body: Record<string, unknown>) => {
    setBusy(id);
    const res = await api.patch<{ user: AdminUser; error?: string }>(`/admin/users/${id}`, body);
    setBusy(null);
    if (!res.error && res.user) {
      setUsers(prev => prev.map(u => u.id === id ? { ...u, ...res.user } : u));
    } else if (res.error) {
      alert(res.error);
    }
  };

  const toggleBan = (u: AdminUser) => {
    if (u.is_banned) {
      patch(u.id, { is_banned: false });
    } else {
      const reason = prompt(`Powód bana dla ${u.username}:`, 'Naruszenie regulaminu');
      if (!reason) return;
      patch(u.id, { is_banned: true, ban_reason: reason });
    }
  };

  const toggleAdmin = (u: AdminUser) => {
    if (!confirm(u.is_admin ? `Odebrać admina od ${u.username}?` : `Nadać admina dla ${u.username}?`)) return;
    patch(u.id, { is_admin: !u.is_admin });
  };

  if (!user?.is_admin) return <AdminShell><div className="p-8 text-center text-neutral-500">Brak dostępu</div></AdminShell>;

  return (
    <AdminShell>
      <div className="max-w-6xl mx-auto px-4 py-6 space-y-4">
        <div className="flex items-center gap-3">
          <Link href="/admin" className="text-sm text-neutral-500 hover:underline">← Panel</Link>
          <h1 className="text-2xl font-medium">Użytkownicy ({users.length})</h1>
        </div>

        <div className="flex gap-2">
          <input
            value={q}
            onChange={e => setQ(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && load(q)}
            placeholder="Szukaj po username lub email…"
            className="flex-1 px-4 py-2.5 rounded-xl bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 outline-none focus:border-[#1A2027] dark:focus:border-[#9DF4CB]"
          />
          <button onClick={() => load(q)} className="px-5 py-2.5 rounded-xl bg-[#1A2027] dark:bg-[#9DF4CB] text-white dark:text-[#1A2027] font-medium">Szukaj</button>
        </div>

        {loading && <p className="text-sm text-neutral-500">Ładowanie…</p>}

        <div className="rounded-2xl bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 overflow-hidden">
          <div className="divide-y divide-neutral-200 dark:divide-neutral-800">
            {users.map(u => (
              <div key={u.id} className="p-4 flex items-center gap-3">
                {u.avatar_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={u.avatar_url} alt="" className="w-10 h-10 rounded-full object-cover" />
                ) : (
                  <div className="w-10 h-10 rounded-full bg-neutral-200 dark:bg-neutral-800 flex items-center justify-center text-sm font-medium">
                    {u.username.slice(0, 1).toUpperCase()}
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <p className="font-medium truncate">{u.username}</p>
                    {u.is_admin && <span className="px-2 py-0.5 text-[10px] rounded-full bg-[#9DF4CB]/30 text-[#1A2027] dark:text-[#9DF4CB] font-medium">ADMIN</span>}
                    {u.is_banned && <span className="px-2 py-0.5 text-[10px] rounded-full bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-300 font-medium">BANNED</span>}
                    {u.is_verified && <span className="px-2 py-0.5 text-[10px] rounded-full bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300 font-medium">✓ {u.verified_role || 'verified'}</span>}
                    {u.is_child && <span className="px-2 py-0.5 text-[10px] rounded-full bg-amber-100 text-amber-700 dark:bg-amber-950 dark:text-amber-300 font-medium">CHILD</span>}
                  </div>
                  <p className="text-xs text-neutral-500 truncate">{u.email}</p>
                  {u.ban_reason && <p className="text-xs text-red-600 mt-0.5">📌 {u.ban_reason}</p>}
                </div>
                <div className="flex gap-2 flex-shrink-0">
                  <button
                    onClick={() => toggleBan(u)}
                    disabled={busy === u.id || u.id === user.id}
                    className={`px-3 py-1.5 text-xs rounded-lg font-medium disabled:opacity-40 ${u.is_banned ? 'bg-emerald-100 text-emerald-700 hover:bg-emerald-200 dark:bg-emerald-950 dark:text-emerald-300' : 'bg-red-100 text-red-700 hover:bg-red-200 dark:bg-red-950 dark:text-red-300'}`}
                  >
                    {u.is_banned ? 'Odbanuj' : 'Banuj'}
                  </button>
                  <button
                    onClick={() => toggleAdmin(u)}
                    disabled={busy === u.id || u.id === user.id}
                    className="px-3 py-1.5 text-xs rounded-lg font-medium bg-neutral-100 text-neutral-700 hover:bg-neutral-200 dark:bg-neutral-800 dark:text-neutral-300 disabled:opacity-40"
                  >
                    {u.is_admin ? '↓ Admin' : '↑ Admin'}
                  </button>
                </div>
              </div>
            ))}
            {!loading && users.length === 0 && (
              <p className="p-8 text-center text-sm text-neutral-500">Brak wyników</p>
            )}
          </div>
        </div>
      </div>
    </AdminShell>
  );
}
