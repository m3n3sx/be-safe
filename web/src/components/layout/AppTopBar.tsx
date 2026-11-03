'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { NavIcon } from './NavIcon';
import { useNotifications } from '@/contexts/NotificationsContext';
export function AppTopBar() {
  const { user } = useAuth(); const path = usePathname(); const { unread } = useNotifications();
  return <header className="topbar"><Link href="/" className="font-bold text-xl tracking-tight mr-auto">be:Safe<span className="hidden sm:inline text-sm font-normal text-ink-2 ml-4">Blisko Ciebie</span></Link>{user ? <><Link href="/notifications" className="btn btn-quiet relative" aria-label={`Powiadomienia${unread ? `, nieprzeczytane: ${unread}` : ''}`}><NavIcon name="bell" />{unread > 0 && <span className="text-sm font-bold">{unread}</span>}</Link>{path !== '/report' && <Link href="/report" className="btn btn-primary hidden! lg:inline-flex!"><NavIcon name="plus" />Zgłoś</Link>}</> : <Link href="/help" className="btn btn-quiet">Pomoc</Link>}<Link href="/sos" className="btn btn-danger sos-link" aria-label="SOS — otwórz pomoc">SOS</Link></header>;
}
