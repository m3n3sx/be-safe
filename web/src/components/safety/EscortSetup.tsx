'use client';
import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useApiResource, useMutation } from '@/hooks/useApiResource';
import api from '@/lib/api';
import type { FamilyGroup, FamilyMember } from '@/types';
import type { Escort } from '@/lib/api/escort';
import type { Place } from '@/lib/location';
import { MapProvider } from '@/components/map/MapProvider';
import { LocationPicker } from '@/components/map/LocationPicker';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { Select, TextField } from '@/components/ui/FormField';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
export function EscortSetup() {
  const { user } = useAuth(); const router = useRouter(); const mutation = useMutation();
  const [groupId, setGroupId] = useState(''); const [watcher, setWatcher] = useState(''); const [place, setPlace] = useState<Place | null>(null); const [minutes, setMinutes] = useState(15);
  const groups = useApiResource<{ groups: FamilyGroup[] }>('/family/groups');
  const members = useApiResource<{ members: FamilyMember[] }>(groupId ? `/family/groups/${groupId}/members` : null);
  const active = useApiResource<{ sessions: Escort[] }>('/escort/active', 30000);
  const mine = active.data?.sessions.find(s => s.requester_id === user?.id);
  async function start() { if (!place || !watcher || mine) return; await mutation.run(() => api.post<{ escort_id: string }>('/escort/start', { watcher_id: watcher, group_id: groupId, destination_lat: place.lat, destination_lng: place.lng, destination_name: place.label, eta_seconds: minutes * 60 }), result => { if (result.escort_id) router.push(`/escort/${result.escort_id}`); else mutation.setError('Brak potwierdzenia utworzenia sesji. Odśwież listę przed ponowną próbą.'); }); }
  return <div className="form-container space-y-5"><PageHeader title="Bezpieczny powrót" description="Wybierz osobę, cel i przewidywany czas drogi." />{active.loading && <Skeleton />}{active.error && <ErrorState message={active.error} onRetry={active.reload} />}{active.data?.sessions.map(s => <Link className="panel block hover:border-primary" href={`/escort/${s.id}`} key={s.id}><h2 className="font-bold">{s.requester_id === user?.id ? 'Twój powrót' : `Obserwujesz: ${s.requester_username}`}</h2><p>{s.destination_name || 'Wybrany cel'} · otwórz sesję →</p></Link>)}{groups.loading ? <Skeleton /> : groups.error ? <ErrorState message={groups.error} onRetry={groups.reload} /> : !groups.data?.groups.length ? <EmptyState title="Dodaj bliską osobę" description="Najpierw utwórz grupę lub dołącz kodem."><Link className="btn btn-primary" href="/family">Przejdź do Bliskich</Link></EmptyState> : !mine && <section className="panel space-y-4"><h2 className="text-xl font-bold">Nowy powrót</h2><Select label="Grupa" value={groupId} onChange={e => { setGroupId(e.target.value); setWatcher(''); }}><option value="">Wybierz grupę</option>{groups.data.groups.map(g => <option key={g.id} value={g.id}>{g.name}</option>)}</Select>{members.loading ? <Skeleton /> : <Select label="Kto będzie obserwować?" value={watcher} onChange={e => setWatcher(e.target.value)} disabled={!groupId}><option value="">Wybierz osobę</option>{members.data?.members.filter(m => m.user_id !== user?.id).map(m => <option value={m.user_id} key={m.user_id}>{m.username}</option>)}</Select>}{members.error && <ErrorState message={members.error} onRetry={members.reload} />}<h3 className="font-bold">Dokąd idziesz?</h3><MapProvider><LocationPicker value={place} onChange={setPlace} /></MapProvider><TextField label="Przewidywany czas (minuty)" type="number" min={1} max={240} value={minutes} onChange={e => setMinutes(Number(e.target.value))} /><p className="text-ink-2">Pozostaw tę stronę otwartą. W tle lokalizacja może przestać się aktualizować. Po rozpoczęciu włącz przesyłanie GPS w widoku sesji.</p>{mutation.error && <ErrorState message={mutation.error} />}<Button loading={mutation.busy} disabled={!place || !watcher || minutes < 1 || minutes > 240 || active.loading || !!active.error} onClick={start}>Rozpocznij powrót</Button></section>}</div>;
}
