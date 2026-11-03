'use client';
import { useState } from 'react';
import api from '@/lib/api';
import { useApiResource, useMutation } from '@/hooks/useApiResource';
import { Select } from '@/components/ui/Select';
import { Button } from '@/components/ui/Button';
import { ErrorState } from '@/components/ui/ErrorState';
import { Skeleton } from '@/components/ui/Skeleton';
export function GhostModeControl() {
  const resource = useApiResource<{ ghost_until?: string | null }>('/users/me', 60000);
  const mutation = useMutation();
  const [hours, setHours] = useState(1);
  return (
    <section className="panel space-y-3">
      <h2 className="text-xl font-bold">Prywatność lokalizacji</h2>
      {resource.loading ? (
        <Skeleton />
      ) : (
        resource.data && (
          <p>
            {resource.data.ghost_until
              ? `Ustawiony koniec ukrywania: ${new Date(resource.data.ghost_until).toLocaleString('pl-PL')}. Po tym czasie ukrywanie wygasa.`
              : 'Czasowe ukrywanie lokalizacji jest wyłączone.'}
          </p>
        )
      )}
      <Select
        label="Ukryj moją lokalizację na"
        value={hours}
        onChange={(e) => setHours(Number(e.target.value))}
      >
        {[1, 2, 4, 8, 24].map((h) => (
          <option key={h} value={h}>
            {h} godz.
          </option>
        ))}
      </Select>
      <div className="flex flex-wrap gap-2">
        <Button
          variant="secondary"
          loading={mutation.busy}
          onClick={() => mutation.run(() => api.put('/users/me/ghost', { hours }), resource.reload)}
        >
          Ukryj lokalizację
        </Button>
        <Button
          variant="quiet"
          disabled={mutation.busy || !resource.data?.ghost_until}
          onClick={() => mutation.run(() => api.delete('/users/me/ghost'), resource.reload)}
        >
          Wyłącz ukrywanie
        </Button>
      </div>
      {(resource.error || mutation.error) && (
        <ErrorState message={mutation.error || resource.error} onRetry={resource.reload} />
      )}
    </section>
  );
}
