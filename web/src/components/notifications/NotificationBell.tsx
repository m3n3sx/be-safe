'use client';
import Link from 'next/link';
import { NavIcon } from '@/components/layout/NavIcon';
import { useNotifications } from '@/contexts/NotificationsContext';
export function NotificationBell() {
  const { unread } = useNotifications();
  return <Link href="/notifications" className="btn btn-quiet relative" aria-label={`Powiadomienia${unread ? `, nieprzeczytane: ${unread}` : ', brak nowych'}`}><NavIcon name="bell" />{unread > 0 && <span aria-hidden="true" className="absolute -top-1 -right-1 rounded-full bg-primary text-[var(--on-primary)] min-w-6 px-1 text-sm font-bold">{unread > 99 ? '99+' : unread}</span>}</Link>;
}
