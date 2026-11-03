'use client';
import Link from 'next/link';
import { routes, type Section } from '@/lib/navigation';
import { useAdminAccess } from '@/hooks/useAdminAccess';
export function RouteLinks({ section }: { section: Section }) {
  return (
    <div className="grid sm:grid-cols-2 gap-3">
      {routes
        .filter(
          (route) =>
            route.section === section &&
            !route.dynamic &&
            route.permission === undefined &&
            !['/help', '/profile', '/alerts'].includes(route.href),
        )
        .map((route) => (
          <Link
            key={route.href}
            href={route.href}
            className="panel flex justify-between items-center min-h-16 font-medium hover:bg-surface-2"
          >
            {route.label}
            <span aria-hidden="true">→</span>
          </Link>
        ))}
    </div>
  );
}
export function AdminLinks() {
  const access = useAdminAccess();
  if (!access.isAdmin) return null;
  return (
    <section className="mt-8">
      <h2 className="text-xl font-bold mb-4">Administracja</h2>
      <div className="grid sm:grid-cols-2 gap-3">
        {routes
          .filter(
            (route) =>
              route.permission !== undefined && (!route.permission || access.can(route.permission)),
          )
          .map((route) => (
            <Link key={route.href} href={route.href} className="panel font-medium">
              {route.label}
            </Link>
          ))}
      </div>
    </section>
  );
}
