'use client';
import { asArray } from '@/lib/api';
import { useState } from 'react';
import { PageHeader } from '@/components/layout/PageHeader';
import { AreaControl, defaultArea } from '@/components/map/AreaControl';
import { PlacesMap } from '@/components/map/PlacesMap';
import { EmergencyCall } from '@/components/safety/EmergencyCall';
import { useApiResource } from '@/hooks/useApiResource';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
import { distance } from '@/lib/format';
type AED = {
  id: string;
  lat: number;
  lng: number;
  address?: string;
  description?: string;
  operator?: string;
  opening_hours?: string;
  indoor?: boolean | string | null;
  distance_m: number;
};
export default function Page() {
  const [area, setArea] = useState(defaultArea);
  // This router uses radius (unlike alerts and AQI, which use radius_m).
  const { data, loading, error, reload } = useApiResource<{ aeds: AED[] }>(
    `/aeds/nearby?lat=${area.lat}&lng=${area.lng}&radius=5000`,
  );
  const aeds = [...asArray(data?.aeds)].sort((a, b) => Number(a.distance_m) - Number(b.distance_m));
  return (
    <div className="page-container space-y-5">
      <PageHeader
        title="Znajdź defibrylator AED"
        description="Urządzenia w promieniu 5 km, od najbliższego."
      />
      <div className="max-w-xl">
        <EmergencyCall />
      </div>
      <AreaControl area={area} onChange={setArea} />
      {error && <ErrorState message={error} onRetry={reload} />}
      {loading ? (
        <Skeleton />
      ) : (
        data && (
          <>
            <PlacesMap
              places={aeds.map((a) => ({
                id: a.id,
                lat: Number(a.lat),
                lng: Number(a.lng),
                label: a.address || 'Defibrylator AED',
              }))}
              onSelect={(id) => document.getElementById(`aed-${id}`)?.focus()}
            />
            {!aeds.length && !error && (
              <EmptyState
                title="Brak AED w tym obszarze"
                description="Wybierz inny obszar. W pilnej sytuacji pozostań w kontakcie z operatorem 112."
              />
            )}
            <ul className="grid md:grid-cols-2 gap-4">
              {aeds.map((a, i) => (
                <li key={a.id} id={`aed-${a.id}`} tabIndex={-1} className="panel space-y-2">
                  <h2 className="text-xl font-bold">
                    {i + 1}. {a.address || 'Defibrylator AED'}
                  </h2>
                  <p className="font-semibold text-primary">{distance(Number(a.distance_m))}</p>
                  {a.description && <p>{a.description}</p>}
                  <p className="text-ink-2">Operator: {a.operator || 'brak danych'}</p>
                  <p>Godziny dostępu: {a.opening_hours || 'brak danych'}</p>
                  <p>
                    {a.indoor === true || a.indoor === 'yes'
                      ? 'Wewnątrz budynku'
                      : a.indoor === false || a.indoor === 'no'
                        ? 'Na zewnątrz'
                        : 'Umiejscowienie: brak danych'}
                  </p>
                  <a
                    className="btn btn-secondary"
                    target="_blank"
                    rel="noreferrer"
                    href={`https://www.google.com/maps/dir/?api=1&destination=${a.lat},${a.lng}&travelmode=walking`}
                  >
                    Pokaż trasę pieszą ↗
                  </a>
                </li>
              ))}
            </ul>
          </>
        )
      )}
      <p className="text-sm text-ink-2">
        Dane: OpenAEDMap. Dostępność urządzenia może się zmieniać.
      </p>
    </div>
  );
}
