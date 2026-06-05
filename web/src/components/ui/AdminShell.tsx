'use client';

// PowerAdmin shell — sidebar (grupy gated RBAC) + topbar + breadcrumbs.
// Desktop-first, tokeny Serenity, theme-aware. Mobile: sidebar jako drawer.
import React, { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useTheme } from '@/contexts/ThemeContext';
import { useAdminAccess } from '@/hooks/useAdminAccess';
import { RoleBadge } from '@/components/ui/Badge';

interface NavItem { href: string; label: string; icon: string; perm?: string }
interface NavGroup { title: string; items: NavItem[] }

const NAV: NavGroup[] = [
  { title: 'Przegląd', items: [
    { href: '/admin', label: 'Dashboard', icon: '📊' },
    { href: '/admin/system', label: 'System', icon: '🖥️', perm: 'system.read' },
  ]},
  { title: 'Moderacja', items: [
    { href: '/admin/users', label: 'Użytkownicy', icon: '👥', perm: 'users.read' },
    { href: '/admin/alerts', label: 'Alerty', icon: '🚨', perm: 'alerts.read' },
    { href: '/admin/reports', label: 'Zgłoszenia', icon: '🛡️', perm: 'reports.read' },
    { href: '/admin/groups', label: 'Grupy', icon: '👨‍👩‍👧', perm: 'groups.read' },
  ]},
  { title: 'Kontrola', items: [
    { href: '/admin/control', label: 'Konfiguracja', icon: '⚙️', perm: 'config.read' },
    { href: '/admin/audit', label: 'Audit log', icon: '📋', perm: 'audit.read' },
  ]},
];

export default function AdminShell({ children }: { children: React.ReactNode }) {
  const { user, loading: authLoading } = useAuth();
  const access = useAdminAccess();
  const { resolvedTheme, setTheme } = useTheme();
  const pathname = usePathname();
  const [open, setOpen] = useState(false);

  if (authLoading || access.loading) {
    return (
      <div className="h-full flex items-center justify-center bg-background">
        <div className="w-12 h-12 rounded-2xl bg-coral flex items-center justify-center text-white font-bold animate-pulse">b:S</div>
      </div>
    );
  }

  if (!user || !access.isAdmin) {
    return (
      <div className="h-full flex items-center justify-center bg-background px-6">
        <div className="text-center">
          <div className="text-6xl mb-4">🔒</div>
          <h1 className="text-2xl font-medium text-ink mb-2">Brak dostępu</h1>
          <p className="text-ink-2">Panel administracyjny — wymaga uprawnień.</p>
          <Link href="/" className="inline-block mt-6 px-5 py-2.5 rounded-full bg-navy text-white text-sm">Wróć do aplikacji</Link>
        </div>
      </div>
    );
  }

  const crumbs = pathname.split('/').filter(Boolean);

  const sidebar = (
    <nav className="flex flex-col gap-6 p-4">
      <div className="flex items-center gap-2 px-2">
        <div className="w-9 h-9 rounded-xl bg-coral flex items-center justify-center text-white font-bold text-sm">b:S</div>
        <div>
          <div className="text-ink font-semibold text-sm leading-tight">be:Safe</div>
          <div className="text-ink-2 text-[11px] leading-tight">PowerAdmin</div>
        </div>
      </div>
      {NAV.map((g) => {
        const items = g.items.filter((i) => !i.perm || access.can(i.perm));
        if (!items.length) return null;
        return (
          <div key={g.title}>
            <div className="px-2 mb-1 text-[11px] uppercase tracking-wider text-ink-2 font-semibold">{g.title}</div>
            <div className="flex flex-col gap-0.5">
              {items.map((i) => {
                const active = pathname === i.href;
                return (
                  <Link key={i.href} href={i.href} onClick={() => setOpen(false)}
                    className={`flex items-center gap-3 px-3 py-2 rounded-xl text-sm transition ${active ? 'bg-mint/25 text-ink font-medium' : 'text-ink-2 hover:bg-surface-2'}`}>
                    <span className="text-base">{i.icon}</span>{i.label}
                  </Link>
                );
              })}
            </div>
          </div>
        );
      })}
    </nav>
  );

  return (
    <div className="h-full flex bg-background text-ink">
      {/* Sidebar desktop */}
      <aside className="hidden lg:block w-60 shrink-0 border-r border-border bg-surface overflow-y-auto">{sidebar}</aside>
      {/* Sidebar mobile drawer */}
      {open && (
        <div className="lg:hidden fixed inset-0 z-40 flex">
          <div className="w-60 bg-surface border-r border-border overflow-y-auto">{sidebar}</div>
          <div className="flex-1 bg-black/40" onClick={() => setOpen(false)} />
        </div>
      )}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Topbar */}
        <header className="h-14 shrink-0 border-b border-border bg-surface flex items-center gap-3 px-4 sticky top-0 z-30">
          <button className="lg:hidden text-ink-2" onClick={() => setOpen(true)} aria-label="Menu">☰</button>
          <nav className="flex items-center gap-1.5 text-sm text-ink-2 min-w-0">
            {crumbs.map((c, i) => (
              <span key={i} className="flex items-center gap-1.5">
                {i > 0 && <span className="opacity-40">/</span>}
                <span className={i === crumbs.length - 1 ? 'text-ink font-medium' : ''}>{c}</span>
              </span>
            ))}
          </nav>
          <div className="ml-auto flex items-center gap-3">
            <button onClick={() => setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')}
              className="text-ink-2 hover:text-ink w-9 h-9 rounded-lg hover:bg-surface-2 flex items-center justify-center" aria-label="Motyw">
              {resolvedTheme === 'dark' ? '☀️' : '🌙'}
            </button>
            <div className="flex items-center gap-2">
              {access.roles[0] && <RoleBadge role={access.roles[0].key} />}
              <span className="text-sm text-ink hidden sm:inline">{user.username}</span>
            </div>
          </div>
        </header>
        <main className="flex-1 overflow-y-auto p-4 lg:p-6">{children}</main>
      </div>
    </div>
  );
}
