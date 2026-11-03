'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { primaryNavigation, routeFor } from '@/lib/navigation';
import { NavIcon } from './NavIcon';
export function DesktopRail() {
  const section = routeFor(usePathname())?.section;
  return (
    <nav className="desktop-rail" aria-label="Główna nawigacja">
      <Link
        href="/"
        className="nav-item text-primary text-lg! mb-4"
        aria-label="be:Safe — W okolicy"
      >
        be:Safe
      </Link>
      {primaryNavigation
        .filter((item) => item.href !== '/report')
        .map((item) => (
          <Link
            href={item.href}
            key={item.href}
            className="nav-item"
            aria-current={section === item.section ? 'page' : undefined}
          >
            <NavIcon name={item.icon} />
            {item.label}
          </Link>
        ))}
    </nav>
  );
}
