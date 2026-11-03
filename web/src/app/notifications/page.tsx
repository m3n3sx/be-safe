'use client';
import { useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import { useNotifications } from '@/contexts/NotificationsContext';
import { useMutation } from '@/hooks/useApiResource';
import { notificationHref, type InboxItem } from '@/lib/notification-routes';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
import { Dialog } from '@/components/ui/Dialog';
import { BrowserNotifications } from '@/components/notifications/BrowserNotifications';
export default function Page() {
  const { items, sessionItems, loading, error, refresh, clearSession, markSessionRead } = useNotifications(); const mutation = useMutation();
  const [confirm, setConfirm] = useState(false);
  function card(item: InboxItem, local = false) { const href = notificationHref(item); return <li className="panel space-y-2" key={item.id}><h3 className="font-bold text-lg">{!item.is_read && <span className="text-primary">Nowe · </span>}{item.title}</h3><p className="whitespace-pre-wrap break-words">{item.body}</p><p className="text-sm text-ink-2">{new Date(item.created_at).toLocaleString('pl-PL')}</p><div className="flex flex-wrap gap-2">{href && <Link className="btn btn-secondary" href={href}>Otwórz szczegóły</Link>}{!local && <Button variant="quiet" disabled={mutation.busy} onClick={() => mutation.run(() => api.delete(`/notifications/${item.id}`), refresh)}>Usuń powiadomienie</Button>}</div></li>; }
  return <div className="page-container space-y-5">
    <PageHeader title="Powiadomienia" description="Wiadomości i zdarzenia wymagające Twojej uwagi."><Button variant="secondary" onClick={refresh}>Odśwież</Button></PageHeader>
    <BrowserNotifications />
    <div className="flex flex-wrap gap-2"><Button variant="secondary" loading={mutation.busy} onClick={() => mutation.run(() => api.post('/notifications/read'), async () => { markSessionRead(); await refresh(); })}>Oznacz wszystkie jako przeczytane</Button><Button variant="quiet" disabled={!items.length && !sessionItems.length} onClick={() => setConfirm(true)}>Wyczyść skrzynkę</Button></div>
    {(error || mutation.error) && <ErrorState message={mutation.error || error} onRetry={refresh} />}
    {loading ? <Skeleton /> : !items.length && !sessionItems.length && !error ? <EmptyState title="Nie masz jeszcze powiadomień" description="Nowe wiadomości pojawią się tutaj." /> : <>
      <h2 className="font-bold text-xl">Na Twoim koncie</h2><ul className="space-y-3">{items.map(i => card(i))}</ul>
      {sessionItems.length > 0 && <><h2 className="font-bold text-xl">W tej sesji przeglądarki</h2><p className="text-ink-2">Zdarzenia otrzymane na żywo. Ta lista znika po zamknięciu aplikacji.</p><ul className="space-y-3">{sessionItems.map(i => card(i, true))}</ul></>}
    </>}
    <Dialog open={confirm} title="Usunąć wszystkie powiadomienia?" onClose={() => { if (!mutation.busy) setConfirm(false); }}><p className="mb-4">Nie będzie można przywrócić wpisów.</p>{mutation.error && <ErrorState message={mutation.error} />}<Button variant="danger" loading={mutation.busy} onClick={() => mutation.run(() => api.delete('/notifications'), async () => { clearSession(); setConfirm(false); await refresh(); })}>Usuń wszystkie</Button></Dialog>
  </div>;
}
