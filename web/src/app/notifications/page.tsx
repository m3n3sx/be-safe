'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import { useNotifications } from '@/contexts/NotificationsContext';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
type Notification = { id: string; title: string; body: string; is_read: boolean; created_at: string; data?: { alert_id?: string; group_id?: string } };
export default function NotificationsPage() {
  const [items, setItems] = useState<Notification[] | null>(null); const [error, setError] = useState(''); const [revision, setRevision] = useState(0); const [busy, setBusy] = useState(false); const { refresh } = useNotifications();
  useEffect(() => { let alive = true; api.get<{ notifications: Notification[] }>('/notifications?limit=100').then(res => { if (alive) { setError(res.error ? 'Nie udało się pobrać powiadomień.' : ''); if (!res.error) setItems(res.notifications); } }); return () => { alive = false; }; }, [revision]);
  async function markRead() { setBusy(true); const res = await api.post('/notifications/read'); if (res.error) setError('Nie udało się oznaczyć powiadomień.'); else { setRevision(v => v + 1); await refresh(); } setBusy(false); }
  return <div className="page-container"><PageHeader title="Powiadomienia" description="Wiadomości zapisane na Twoim koncie." /><Button onClick={markRead} loading={busy} variant="secondary">Oznacz wszystkie jako przeczytane</Button>{error && <ErrorState message={error} onRetry={() => setRevision(v => v + 1)} />}{!items && !error ? <Skeleton /> : items?.length === 0 ? <EmptyState title="Nie masz jeszcze powiadomień" /> : <ul className="space-y-3 mt-4">{items?.map(item => <li className="panel" key={item.id}><h2 className="font-bold">{!item.is_read && <span className="text-primary">Nowe · </span>}{item.title}</h2><p>{item.body}</p><p className="text-sm text-ink-2">{new Date(item.created_at).toLocaleString('pl-PL')}</p>{item.data?.alert_id ? <Link className="btn btn-quiet" href={`/alerts/${encodeURIComponent(item.data.alert_id)}`}>Zobacz zgłoszenie</Link> : item.data?.group_id ? <Link className="btn btn-quiet" href="/family">Przejdź do bliskich</Link> : null}</li>)}</ul>}</div>;
}
