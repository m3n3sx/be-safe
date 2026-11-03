'use client';
import { asArray } from '@/lib/api';
import { useState } from 'react';
import Link from 'next/link';
import { groupPath } from '@/lib/api/family';
import type { LocationHistory as HistoryPoint } from '@/types';
import { useApiResource } from '@/hooks/useApiResource';
import { GroupHeader } from './GroupHeader';
import { PlacesMap } from '@/components/map/PlacesMap';
import { TextField } from '@/components/ui/TextField';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
export function LocationHistory({ groupId, memberId }: { groupId: string; memberId: string }) {
  const [day, setDay] = useState(() => new Date().toLocaleDateString('en-CA'));
  const from = new Date(`${day}T00:00:00`),
    to = new Date(`${day}T23:59:59.999`);
  const valid = Number.isFinite(from.getTime());
  const path = `${groupPath(groupId)}/members/${memberId}/location/history`;
  const resource = useApiResource<{ history: HistoryPoint[]; hidden?: boolean }>(
    valid
      ? `${path}?from=${encodeURIComponent(from.toISOString())}&to=${encodeURIComponent(to.toISOString())}&limit=500`
      : null,
  );
  const points = [...asArray(resource.data?.history)]
    .reverse()
    .map((p) => ({ ...p, lat: Number(p.lat), lng: Number(p.lng) }));
  return (
    <div className="page-container space-y-5">
      <GroupHeader id={groupId} title="Historia lokalizacji" />
      <Link className="btn btn-quiet" href={`/family/${groupId}/members/${memberId}`}>
        ← Profil osoby
      </Link>
      <TextField
        label="Dzień (według strefy czasowej urządzenia)"
        type="date"
        value={day}
        onChange={(e) => setDay(e.target.value)}
      />
      {resource.error && <ErrorState message={resource.error} onRetry={resource.reload} />}
      {resource.loading ? (
        <Skeleton />
      ) : (
        resource.data && (
          <>
            {!points.length ? (
              <EmptyState
                title={resource.data.hidden ? 'Historia jest ukryta' : 'Brak punktów dla tego dnia'}
                description="Wybierz inny dzień lub sprawdź ustawienia udostępniania."
              />
            ) : (
              <>
                <PlacesMap
                  places={points
                    .filter((_, i) => i === 0 || i === points.length - 1)
                    .map((p, i) => ({
                      ...p,
                      id: String(i),
                      label: i === 0 ? 'Początek' : 'Koniec',
                    }))}
                  line={points}
                />
                <p className="text-ink-2">
                  Punkty: {points.length}
                  {points.length === 500 ? ' — osiągnięto limit odczytu' : ''}. To zapis
                  historyczny, nie pozycja na żywo.
                </p>
                <ol className="panel max-h-96 overflow-auto divide-y divide-border">
                  {points.map((p, i) => (
                    <li className="py-3 flex flex-wrap justify-between gap-2" key={i}>
                      <time>{new Date(p.recorded_at).toLocaleString('pl-PL')}</time>
                      <a
                        className="text-primary underline min-h-12 inline-flex items-center"
                        href={`https://www.google.com/maps?q=${p.lat},${p.lng}`}
                        target="_blank"
                        rel="noreferrer"
                      >
                        {p.lat.toFixed(5)}, {p.lng.toFixed(5)}
                      </a>
                    </li>
                  ))}
                </ol>
              </>
            )}
          </>
        )
      )}
    </div>
  );
}
