'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { primaryNavigation, routeFor } from '@/lib/navigation';
import { NavIcon } from './NavIcon';
export function MobileTabBar() {
  const path = usePathname();
  const section = routeFor(path)?.section;
  return (
    <nav className="mobile-tabs" aria-label="Główna nawigacja">
      {primaryNavigation.map((item) =>
        item.href === '/report' && path === '/report' ? (
          <span key={item.href} className="nav-item text-primary" aria-current="page">
            <NavIcon name="plus" />
            Zgłaszanie
          </span>
        ) : (
          <Link
            key={item.href}
            href={item.href}
            className={`nav-item ${item.href === '/report' ? 'bg-primary text-[var(--on-primary)]' : ''}`}
            aria-current={
              item.href !== '/report' && section === item.section && path !== '/report'
                ? 'page'
                : undefined
            }
          >
            <NavIcon name={item.icon} />
            {item.label}
          </Link>
        ),
      )}
    </nav>
  );
}
