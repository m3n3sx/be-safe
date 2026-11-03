'use client';
import { useEffect, useRef, useState } from 'react';
import api from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';
import { useSocket } from '@/contexts/SocketContext';
import { useApiResource, useMutation } from '@/hooks/useApiResource';
import { Button } from '@/components/ui/Button';
import { TextArea } from '@/components/ui/TextArea';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
type Message = { id: string; author_id: string; author_username: string; body: string; created_at: string; distance_m?: number };
export function Chat({ path, query = '', groupId, location }: { path: string; query?: string; groupId?: string; location?: { lat: number; lng: number } }) {
  const resource = useApiResource<{ messages: Message[] }>(`${path}?limit=100${query}`, 15000); const mutation = useMutation(); const { user } = useAuth(); const { onEvent } = useSocket(); const [body, setBody] = useState(''); const [sent, setSent] = useState(''); const list = useRef<HTMLUListElement>(null); const reload = resource.reload;
  useEffect(() => onEvent(groupId ? 'family:message' : 'neighborhood:message', data => { if (!groupId || data.group_id === groupId) void reload(); }), [groupId, onEvent, reload]);
  async function send(e: React.FormEvent) { e.preventDefault(); const text = body.trim(); if (!text) return; await mutation.run(() => api.post<Message>(path, { body: text, ...location }), async r => { if (!r.id) { mutation.setError('Brak potwierdzenia wysłania. Odśwież rozmowę.'); return; } setBody(''); setSent('Wiadomość wysłana.'); await reload(); requestAnimationFrame(() => { if (list.current) list.current.scrollTop = list.current.scrollHeight; }); }); }
  return <section className="space-y-4"><div className="flex justify-between items-center gap-2"><h2 className="font-bold">Wiadomości</h2><Button variant="quiet" onClick={reload}>Odśwież rozmowę</Button></div>{resource.error && <ErrorState message={resource.error} onRetry={reload} />}{resource.loading ? <Skeleton /> : resource.data?.messages.length === 0 ? <EmptyState title="Rozpocznij rozmowę" description="Nie ma jeszcze wiadomości. Napisz pierwszą." /> : <ul ref={list} className="panel space-y-4 max-h-[55dvh] overflow-auto" aria-label="Historia rozmowy">{resource.data?.messages.map(m => <li className={`rounded-xl p-4 max-w-[95%] sm:max-w-[85%] ${m.author_id === user?.id ? 'ml-auto bg-surface-2' : 'border border-border'}`} key={m.id}><p className="font-bold text-sm">{m.author_id === user?.id ? 'Ty' : m.author_username}</p><p className="whitespace-pre-wrap break-words my-2">{m.body}</p><p className="text-sm text-ink-2">{new Date(m.created_at).toLocaleString('pl-PL')}{m.distance_m != null && ` · ${Math.round(m.distance_m)} m od wybranego obszaru`}</p></li>)}</ul>}<form onSubmit={send} className="panel space-y-3"><TextArea label="Twoja wiadomość" rows={3} maxLength={groupId ? 2000 : 1000} value={body} onChange={e => { setBody(e.target.value); setSent(''); }} required disabled={mutation.busy} />{mutation.error && <ErrorState message={mutation.error} />}<Button type="submit" loading={mutation.busy} disabled={!body.trim()}>Wyślij wiadomość</Button><p role="status" className="text-sm">{sent}</p></form></section>;
}
