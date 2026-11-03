'use client';
import type { ReactNode } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAdminAccess } from '@/hooks/useAdminAccess';
import { routes } from '@/lib/navigation';
import { Skeleton } from './Skeleton';
import { EmptyState } from './EmptyState';
export default function AdminShell({ children }: { children: ReactNode }) {
  const access = useAdminAccess(); const path = usePathname();
  if (access.loading) return <Skeleton />;
  if (!access.isAdmin) return <EmptyState title="Brak dostępu do administracji" description="Ta sekcja wymaga uprawnień."><Link href="/profile" className="btn btn-secondary">Wróć do profilu</Link></EmptyState>;
  return <div className="page-container"><Link href="/" className="btn btn-quiet mb-4">← Wróć do aplikacji</Link><nav aria-label="Administracja" className="flex flex-wrap gap-2 mb-6">{routes.filter(route => route.permission !== undefined && (!route.permission || access.can(route.permission))).map(route => <Link key={route.href} href={route.href} className={`btn ${path === route.href ? 'btn-primary' : 'btn-secondary'}`} aria-current={path === route.href ? 'page' : undefined}>{route.label}</Link>)}</nav>{children}</div>;
}
