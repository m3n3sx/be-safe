'use client';
import { useEffect, useRef, useState } from 'react';
import { useSocket } from '@/contexts/SocketContext';
import { alertsApi } from '@/lib/api/alerts';
import type { AlertComment } from '@/types';
import { relativeTime } from '@/lib/format';
import { TextArea } from '@/components/ui/TextArea';
import { Button } from '@/components/ui/Button';
import { ErrorState } from '@/components/ui/ErrorState';
import { Skeleton } from '@/components/ui/Skeleton';
export function AlertComments({ alertId }: { alertId: string }) {
  const [comments, setComments] = useState<AlertComment[] | null>(null); const [text, setText] = useState(''); const [error, setError] = useState(''); const [busy, setBusy] = useState(false); const [revision, setRevision] = useState(0); const lock = useRef(false); const { connected, watchAlert } = useSocket();
  useEffect(() => {
    let alive = true;
    const load = async () => { const result = await alertsApi.comments(alertId); if (!alive) return; if (result.error) setError('Nie udało się pobrać komentarzy.'); else { setComments(result.comments); setError(''); } };
    void load(); const timer = setInterval(() => { if (document.visibilityState === 'visible') void load(); }, 30000);
    // Re-fetch rather than append: concurrent HTTP/socket deliveries cannot create duplicates.
    const stop = watchAlert(alertId, () => void load(), () => void load());
    return () => { alive = false; clearInterval(timer); stop(); };
  }, [alertId, revision, connected, watchAlert]);
  async function submit(event: React.FormEvent) {
    event.preventDefault(); if (!text.trim() || lock.current) return; lock.current = true; setBusy(true); setError('');
    const result = await alertsApi.comment(alertId, text.trim());
    if (result.error || !result.id) setError('Nie wysłano komentarza. Tekst został zachowany. Spróbuj ponownie.');
    else { setText(''); setRevision(value => value + 1); }
    lock.current = false; setBusy(false);
  }
  return <section className="space-y-4 border-t border-border pt-5"><div className="flex items-center justify-between"><h3 className="text-xl font-bold">Komentarze</h3><Button variant="quiet" onClick={() => setRevision(value => value + 1)}>Odśwież</Button></div>{error && <ErrorState message={error} />}{!comments && !error ? <Skeleton /> : !comments?.length ? <p className="text-ink-2">Brak komentarzy. Dodaj przydatną informację o sytuacji.</p> : <ul className="space-y-4">{comments.map(comment => <li key={comment.id} className="rounded-xl p-3 bg-surface-2"><p className="text-sm font-semibold">{comment.author?.username || 'Użytkownik'} <span className="text-ink-2 font-normal">· {relativeTime(comment.created_at)}</span></p><p className="whitespace-pre-wrap break-words">{comment.content}</p></li>)}</ul>}<form onSubmit={submit} className="space-y-3"><TextArea label="Twój komentarz" value={text} onChange={event => setText(event.target.value)} maxLength={5000} required rows={3} /><Button type="submit" loading={busy} disabled={!text.trim()}>Dodaj komentarz</Button></form></section>;
}
