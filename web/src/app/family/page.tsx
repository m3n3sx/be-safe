'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import api, { asArray } from '@/lib/api';
import type { FamilyGroup, FamilyRole } from '@/types';
import { roleLabels } from '@/lib/api/family';
import { useApiResource, useMutation } from '@/hooks/useApiResource';
import { useSocket } from '@/contexts/SocketContext';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { TextField, Select } from '@/components/ui/FormField';
import { Dialog } from '@/components/ui/Dialog';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
import { CheckinAction } from '@/components/family/CheckinAction';
import { GhostModeControl } from '@/components/family/GhostModeControl';
import { PinnedPeople } from '@/components/family/PinnedPeople';
export default function Page() {
  const router = useRouter();
  const resource = useApiResource<{ groups: FamilyGroup[] }>('/family/groups');
  const mutation = useMutation();
  const { onEvent } = useSocket();
  const pending = useApiResource<{
    pings: { ping_id: string; from_username: string; group_name: string }[];
  }>('/family/pings/pending', 30000);
  const [mode, setMode] = useState<'create' | 'join' | null>(null);
  const [name, setName] = useState('');
  const [code, setCode] = useState('');
  const [role, setRole] = useState<FamilyRole>('family_member');
  const reloadPings = pending.reload;
  useEffect(() => onEvent('family:ping', () => void reloadPings()), [onEvent, reloadPings]);
  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (mode === 'create')
      await mutation.run(
        () => api.post<FamilyGroup>('/family/groups', { name: name.trim() }),
        (r) => {
          if (r.id) router.push(`/family/${r.id}`);
        },
      );
    else
      await mutation.run(
        () =>
          api.post<{ group_id: string }>('/family/groups/join', {
            invite_code: code.trim().toUpperCase(),
            role,
          }),
        (r) => {
          if (r.group_id) router.push(`/family/${r.group_id}`);
        },
      );
  }
  return (
    <div className="page-container space-y-6">
      <PageHeader title="Bliscy" description="Twoje grupy i szybki kontakt z ważnymi osobami." />
      <PinnedPeople />
      <div className="flex flex-wrap gap-3">
        <Button
          onClick={() => {
            mutation.setError('');
            setMode('create');
          }}
        >
          Utwórz grupę
        </Button>
        <Button
          variant="secondary"
          onClick={() => {
            mutation.setError('');
            setMode('join');
          }}
        >
          Dołącz kodem
        </Button>
        <Link href="/family/join" className="btn btn-quiet">
          Sprawdź kod lub link
        </Link>
      </div>
      {pending.error && <ErrorState message={pending.error} onRetry={pending.reload} />}
      {asArray(pending.data?.pings).map((p) => (
        <Link
          key={p.ping_id}
          className="panel block border-primary"
          href={`/family/pings/${p.ping_id}`}
        >
          <strong>{p.from_username} prosi o kontakt</strong>
          <p>{p.group_name} · Odpowiedz →</p>
        </Link>
      ))}
      {resource.error && <ErrorState message={resource.error} onRetry={resource.reload} />}
      {resource.loading ? (
        <Skeleton />
      ) : resource.data && !asArray(resource.data.groups).length ? (
        <EmptyState
          title="Zaproś pierwszą bliską osobę"
          description="Utwórz wspólną grupę lub wpisz otrzymany kod zaproszenia."
        />
      ) : (
        <ul className="grid sm:grid-cols-2 gap-4">
          {asArray(resource.data?.groups).map((g) => (
            <li key={g.id}>
              <Link className="panel block hover:border-primary" href={`/family/${g.id}`}>
                <h2 className="font-bold text-xl">{g.name}</h2>
                <p className="text-ink-2 mt-2">
                  {g.your_role ? roleLabels[g.your_role] : 'Członek grupy'} · Otwórz grupę →
                </p>
              </Link>
            </li>
          ))}
        </ul>
      )}
      <div className="grid lg:grid-cols-2 gap-4">
        <CheckinAction />
        <GhostModeControl />
      </div>
      <nav className="flex flex-wrap gap-2" aria-label="Więcej dla bliskich">
        <Link href="/pets" className="btn btn-secondary">
          Zwierzęta
        </Link>
        <Link href="/escort" className="btn btn-secondary">
          Bezpieczny powrót
        </Link>
        <Link href="/parental-controls" className="btn btn-quiet">
          Dziecko w sieci
        </Link>
      </nav>
      <Dialog
        open={!!mode}
        title={mode === 'create' ? 'Utwórz grupę' : 'Dołącz kodem'}
        onClose={() => {
          if (!mutation.busy) setMode(null);
        }}
      >
        <form className="space-y-4" onSubmit={submit}>
          {mode === 'create' ? (
            <TextField
              label="Nazwa grupy"
              required
              maxLength={100}
              value={name}
              onChange={(e) => setName(e.target.value)}
            />
          ) : (
            <>
              <TextField
                label="Kod zaproszenia"
                required
                value={code}
                onChange={(e) => setCode(e.target.value)}
                autoCapitalize="characters"
              />
              <Select
                label="Twoja rola"
                value={role}
                onChange={(e) => setRole(e.target.value as FamilyRole)}
              >
                {Object.entries(roleLabels)
                  .filter(([value]) => value !== 'parent' && value !== 'guardian')
                  .map(([value, label]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </Select>
            </>
          )}
          {mutation.error && <ErrorState message={mutation.error} />}
          <Button type="submit" loading={mutation.busy}>
            {mode === 'create' ? 'Utwórz grupę' : 'Dołącz'}
          </Button>
        </form>
      </Dialog>
    </div>
  );
}
