'use client';
import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/AuthContext';
import { alertsApi } from '@/lib/api/alerts';
import { relativeTime } from '@/lib/format';
import { getCategoryInfo, type Alert, type VoteType } from '@/types';
import { Button } from '@/components/ui/Button';
import { TextArea, TextField } from '@/components/ui/FormField';
import { Dialog } from '@/components/ui/Dialog';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { useToast } from '@/components/ui/Toast';
import { AlertComments } from './AlertComments';
export default function AlertDetail({ alertId, onChange }: { alertId: string; onChange?: () => void }) {
  const { user } = useAuth(); const toast = useToast(); const [alert, setAlert] = useState<Alert | null>(null); const [error, setError] = useState(''); const [notFound, setNotFound] = useState(false); const [revision, setRevision] = useState(0);
  const [action, setAction] = useState<VoteType | 'delete' | 'report' | 'edit' | null>(null); const [actionError, setActionError] = useState(''); const [reason, setReason] = useState(''); const [description, setDescription] = useState(''); const [busy, setBusy] = useState(false); const [voted, setVoted] = useState(false); const [shareLink, setShareLink] = useState(''); const lock = useRef(false); const heading = useRef<HTMLHeadingElement>(null);
  useEffect(() => { let alive = true; alertsApi.detail(alertId).then(result => { if (!alive) return; if (result.error || !result.id) { setNotFound(result.httpStatus === 404); setError('To zgłoszenie jest niedostępne lub nie udało się go pobrać.'); } else { setAlert(result); setError(''); } }); return () => { alive = false; }; }, [alertId, revision]);
  const loadedId = alert?.id;
  useEffect(() => { if (loadedId) heading.current?.focus(); }, [loadedId]);
  function refresh() { setRevision(value => value + 1); onChange?.(); }
  function open(next: typeof action) { setAction(next); setActionError(''); setDescription(alert?.description || ''); }
  async function perform() {
    if (lock.current || !action || !alert) return; lock.current = true; setBusy(true); setActionError('');
    let message = '';
    if (action === 'confirm' || action === 'deny') {
      const result = await alertsApi.vote(alertId, action);
      if (result.httpStatus === 409) { setVoted(true); message = 'Twój głos został już zapisany.'; }
      else if (result.error) setActionError('Nie udało się zapisać głosu. Spróbuj ponownie.');
      else { setVoted(true); message = 'Głos zapisany.'; }
    } else if (action === 'delete') {
      const result = await alertsApi.remove(alertId);
      if (result.error || !result.ok) setActionError('Nie udało się usunąć zgłoszenia.'); else { setAlert({ ...alert, status: 'removed' }); message = 'Zgłoszenie usunięte.'; }
    } else if (action === 'report') {
      const result = await alertsApi.report(alertId, reason.trim());
      if (result.httpStatus === 409) message = 'To nadużycie zostało już przez Ciebie zgłoszone.';
      else if (result.error || !result.ok) setActionError('Nie udało się zgłosić nadużycia.'); else message = 'Zgłoszenie nadużycia przekazane do sprawdzenia.';
    } else {
      const result = await alertsApi.update(alertId, { description });
      if (result.error || !result.id) setActionError('Nie udało się zapisać opisu.'); else message = 'Opis zapisany.';
    }
    if (message) { setAction(null); toast(message); refresh(); }
    setBusy(false); lock.current = false;
  }
  async function extend() { if (lock.current) return; lock.current = true; setBusy(true); const result = await alertsApi.update(alertId, { extend_hours: 3 }); if (result.error) setError('Nie udało się przedłużyć zgłoszenia.'); else { toast('Zgłoszenie przedłużone o 3 godziny.'); refresh(); } lock.current = false; setBusy(false); }
  async function share() {
    const url = `${window.location.origin}/alerts/${encodeURIComponent(alertId)}`; setShareLink(url);
    try { if (navigator.share) await navigator.share({ title: alert?.title, url }); else if (navigator.clipboard) { await navigator.clipboard.writeText(url); toast('Link skopiowany.'); } } catch { /* The selectable link remains available when sharing is cancelled or blocked. */ }
  }
  if (notFound || alert?.status === 'removed') return <EmptyState title="Zgłoszenie jest niedostępne" description="Mogło zostać usunięte."><Link href="/" className="btn btn-secondary">Wróć do okolicy</Link></EmptyState>;
  if (!alert) return error ? <ErrorState message={error} onRetry={() => setRevision(value => value + 1)} /> : <Skeleton />;
  const cat = getCategoryInfo(alert.category); const isOwner = user?.id === alert.author_id;
  const titles = { confirm: 'Potwierdzić zdarzenie?', deny: 'Oznaczyć jako nieaktualne?', delete: 'Usunąć zgłoszenie?', report: 'Zgłoś nadużycie', edit: 'Edytuj opis' };
  return <article className="py-4 space-y-5">{error && <ErrorState message={error} onRetry={() => setRevision(value => value + 1)} />}<div><p className="text-ink-2"><span aria-hidden="true">{cat.emoji} </span>{cat.label}</p><h2 ref={heading} tabIndex={-1} className="text-2xl font-bold mt-2">{alert.title}</h2><div className="my-3"><StatusBadge status={alert.status} /></div><p className="text-sm text-ink-2">{relativeTime(alert.created_at)} · {new Date(alert.created_at).toLocaleString('pl-PL')}</p><p className="text-sm text-ink-2">Ważne do: {new Date(alert.expires_at).toLocaleString('pl-PL')}</p><p className="text-sm text-ink-2">Autor: {alert.is_anonymous || !alert.author ? 'Nazwa ukryta' : alert.author.username}</p></div>{alert.description && <p className="whitespace-pre-wrap break-words">{alert.description}</p>}{alert.photo_url && <img src={alert.photo_url} alt={`Zdjęcie zgłoszenia: ${alert.title}`} className="w-full max-h-96 object-contain rounded-xl bg-surface-2" />}<a className="btn btn-secondary" target="_blank" rel="noreferrer" href={`https://www.google.com/maps/search/?api=1&query=${alert.lat},${alert.lng}`}>Otwórz miejsce w mapach ↗</a><p className="text-sm text-ink-2">Miejsce: {Number(alert.lat).toFixed(5)}, {Number(alert.lng).toFixed(5)}</p><div className="panel space-y-3"><p>Potwierdzenia: <strong>{alert.confirms}</strong> · Nieaktualne: <strong>{alert.denies}</strong></p><div className="flex flex-wrap gap-2"><Button disabled={voted || busy || alert.status !== 'active'} onClick={() => open('confirm')}>Potwierdzam</Button><Button disabled={voted || busy || alert.status !== 'active'} variant="secondary" onClick={() => open('deny')}>Już nieaktualne</Button></div>{voted && <p role="status" className="text-success">Twój głos został zapisany.</p>}</div><div className="flex flex-wrap gap-2"><Button variant="secondary" onClick={share}>Udostępnij</Button><Button variant="quiet" onClick={() => open('report')}>Zgłoś nadużycie</Button><Link href={`/alerts/${encodeURIComponent(alertId)}`} className="btn btn-quiet">Otwórz stronę zgłoszenia</Link></div>{shareLink && <TextField label="Link do zgłoszenia" readOnly value={shareLink} onFocus={event => event.target.select()} />}{isOwner && <details><summary className="py-3 min-h-12 cursor-pointer font-semibold">Zarządzaj swoim zgłoszeniem</summary><div className="flex flex-wrap gap-2"><Button variant="secondary" onClick={() => open('edit')}>Edytuj opis</Button><Button variant="secondary" disabled={busy || alert.status === 'hidden'} onClick={extend}>Przedłuż o 3 godziny</Button><Button variant="danger" onClick={() => open('delete')}>Usuń</Button></div></details>}<AlertComments alertId={alertId} /><Dialog open={!!action} title={action ? titles[action] : ''} onClose={() => { if (!busy) setAction(null); }}><div className="space-y-4">{(action === 'confirm' || action === 'deny') && <p>Głosu nie można cofnąć. Zapisz go, jeśli znasz aktualną sytuację w tym miejscu.</p>}{action === 'delete' && <p>Zgłoszenie zniknie z listy. Tej operacji nie można cofnąć.</p>}{action === 'report' && <TextArea label="Powód zgłoszenia" value={reason} onChange={event => setReason(event.target.value)} maxLength={2000} />}{action === 'edit' && <TextArea label="Opis" value={description} onChange={event => setDescription(event.target.value)} maxLength={5000} />}{actionError && <ErrorState message={actionError} />}<div className="flex flex-wrap gap-2"><Button loading={busy} variant={action === 'delete' ? 'danger' : 'primary'} onClick={perform} disabled={action === 'report' && !reason.trim()}>Zapisz</Button><Button variant="secondary" disabled={busy} onClick={() => setAction(null)}>Anuluj</Button></div></div></Dialog></article>;
}
