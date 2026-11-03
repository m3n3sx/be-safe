'use client';
import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import api, { asArray } from '@/lib/api';
import { groupPath, useGroup } from '@/lib/api/family';
import type { Point, Place } from '@/lib/location';
import { useApiResource, useMutation } from '@/hooks/useApiResource';
import { GroupHeader } from './GroupHeader';
import { PlacesMap } from '@/components/map/PlacesMap';
import { MapProvider } from '@/components/map/MapProvider';
import { AreaSearch } from '@/components/map/AreaSearch';
import { Button } from '@/components/ui/Button';
import { TextField } from '@/components/ui/TextField';
import { ConfirmAction } from '@/components/ui/ConfirmAction';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
type SafeRoute = {
  id: string;
  name: string;
  points: [number, number][];
  threshold_m: number;
  is_active: boolean;
};
type Props = { groupId: string; memberId: string; routeId?: string; create?: boolean };
export function SafeRoutes({ groupId, memberId, routeId, create }: Props) {
  const group = useGroup(groupId);
  const path = `${groupPath(groupId)}/members/${memberId}/safe-routes`;
  const base = `/family/${groupId}/members/${memberId}/safe-routes`;
  const resource = useApiResource<{ routes: SafeRoute[] }>(path);
  const route = asArray(resource.data?.routes).find((r) => r.id === routeId);
  return (
    <div className="page-container space-y-5">
      <GroupHeader
        id={groupId}
        title={create ? 'Nowa bezpieczna trasa' : route?.name || 'Bezpieczne trasy'}
        name={group.group?.name}
      />
      <Link className="btn btn-quiet" href={`/family/${groupId}/members/${memberId}`}>
        ← Profil osoby
      </Link>
      <p className="text-ink-2">
        Trasa ustalona przez opiekuna nie gwarantuje bezpieczeństwa. Monitorowanie wymaga
        aktualizacji lokalizacji z urządzenia.
      </p>
      {(resource.error || group.error) && (
        <ErrorState
          message={resource.error || group.error}
          onRetry={() => {
            void resource.reload();
            void group.reload();
          }}
        />
      )}
      {resource.loading || group.loading ? (
        <Skeleton />
      ) : create ? (
        group.guardian ? (
          <SafeRouteEditor path={path} base={base} />
        ) : (
          <EmptyState title="Dodawanie tras jest dostępne dla rodzica lub opiekuna" />
        )
      ) : routeId ? (
        route ? (
          <SafeRouteDetails
            route={route}
            path={path}
            base={base}
            editable={group.guardian}
            reload={resource.reload}
          />
        ) : (
          !resource.error && <EmptyState title="Trasa niedostępna" />
        )
      ) : (
        <>
          {group.guardian && (
            <Link className="btn btn-primary" href={`${base}/new`}>
              Dodaj trasę
            </Link>
          )}
          {!asArray(resource.data?.routes).length && (
            <EmptyState
              title="Nie ma jeszcze ustalonych tras"
              description="Rodzic lub opiekun może dodać trasę, wskazując kolejne punkty."
            />
          )}
          <ul className="grid sm:grid-cols-2 gap-4">
            {asArray(resource.data?.routes).map((r) => (
              <li key={r.id}>
                <Link className="panel block hover:border-primary" href={`${base}/${r.id}`}>
                  <h2 className="text-xl font-bold">{r.name}</h2>
                  <p>
                    {r.is_active ? 'Włączona' : 'Wyłączona'} · tolerancja {r.threshold_m} m ·{' '}
                    {asArray(r.points).length} punktów
                  </p>
                </Link>
              </li>
            ))}
          </ul>
        </>
      )}
    </div>
  );
}
function SafeRouteEditor({ path, base }: { path: string; base: string }) {
  const [name, setName] = useState('');
  const [threshold, setThreshold] = useState(100);
  const [points, setPoints] = useState<Point[]>([]);
  const [lat, setLat] = useState('');
  const [lng, setLng] = useState('');
  const mutation = useMutation();
  const router = useRouter();
  function add(p: Point | Place) {
    setPoints((old) => [...old, { lat: p.lat, lng: p.lng }]);
  }
  function move(index: number, offset: number) {
    setPoints((old) => {
      const next = [...old];
      [next[index], next[index + offset]] = [next[index + offset], next[index]];
      return next;
    });
  }
  return (
    <section className="panel space-y-4">
      <TextField
        label="Nazwa trasy"
        value={name}
        maxLength={120}
        onChange={(e) => setName(e.target.value)}
      />
      <TextField
        label="Tolerancja zejścia z trasy (metry)"
        type="number"
        min={30}
        max={1000}
        value={threshold}
        onChange={(e) => setThreshold(Number(e.target.value))}
      />
      <p>
        Klikaj mapę albo wyszukuj adresy w kolejności od początku do końca trasy. Każdy wybrany
        adres dodaje punkt.
      </p>
      <MapProvider>
        <AreaSearch onSelect={add} />
      </MapProvider>
      <PlacesMap
        places={points.map((p, i) => ({ ...p, id: String(i), label: `Punkt ${i + 1}` }))}
        line={points}
        onPick={add}
      />
      <details>
        <summary className="min-h-12 py-3 cursor-pointer">
          Dodaj punkt współrzędnymi (bez mapy)
        </summary>
        <div className="grid sm:grid-cols-2 gap-3">
          <TextField
            label="Szerokość"
            type="number"
            min={-90}
            max={90}
            step="any"
            value={lat}
            onChange={(e) => setLat(e.target.value)}
          />
          <TextField
            label="Długość"
            type="number"
            min={-180}
            max={180}
            step="any"
            value={lng}
            onChange={(e) => setLng(e.target.value)}
          />
        </div>
        <Button
          variant="secondary"
          disabled={
            !lat ||
            !lng ||
            !Number.isFinite(Number(lat)) ||
            !Number.isFinite(Number(lng)) ||
            Math.abs(Number(lat)) > 90 ||
            Math.abs(Number(lng)) > 180
          }
          onClick={() => add({ lat: Number(lat), lng: Number(lng) })}
        >
          Dodaj punkt
        </Button>
      </details>
      <ol className="space-y-3">
        {points.map((p, i) => (
          <li className="border border-border rounded-xl p-3" key={i}>
            <p>
              Punkt {i + 1}: {p.lat.toFixed(5)}, {p.lng.toFixed(5)}
            </p>
            <div className="flex flex-wrap gap-2">
              <Button
                variant="quiet"
                disabled={i === 0}
                onClick={() => move(i, -1)}
                aria-label={`Przenieś punkt ${i + 1} wcześniej`}
              >
                Wcześniej
              </Button>
              <Button
                variant="quiet"
                disabled={i === points.length - 1}
                onClick={() => move(i, 1)}
                aria-label={`Przenieś punkt ${i + 1} później`}
              >
                Później
              </Button>
              <Button
                variant="quiet"
                onClick={() => setPoints((old) => old.filter((_, j) => j !== i))}
                aria-label={`Usuń punkt ${i + 1}`}
              >
                Usuń
              </Button>
            </div>
          </li>
        ))}
      </ol>
      {mutation.error && <ErrorState message={mutation.error} />}
      <Button
        loading={mutation.busy}
        disabled={!name.trim() || points.length < 2 || threshold < 30 || threshold > 1000}
        onClick={() =>
          mutation.run(
            () =>
              api.post<{ route: { id: string } }>(path, {
                name: name.trim(),
                threshold_m: threshold,
                points: points.map((p) => [p.lat, p.lng]),
              }),
            (r) => {
              if (r.route?.id) router.push(`${base}/${r.route.id}`);
            },
          )
        }
      >
        Zapisz trasę ({points.length} punktów)
      </Button>
    </section>
  );
}
function SafeRouteDetails({
  route,
  path,
  base,
  editable,
  reload,
}: {
  route: SafeRoute;
  path: string;
  base: string;
  editable: boolean;
  reload: () => Promise<void>;
}) {
  const alerts = useApiResource<{
    alerts: { id: string; title: string; distance_to_route_m: number }[];
  }>(route.is_active ? `${path}/${route.id}/alerts-near?buffer_m=200` : null);
  const mutation = useMutation();
  const router = useRouter();
  const points = asArray(route.points)
    .filter((point) => Array.isArray(point) && point.length === 2)
    .map(([lat, lng]) => ({ lat: Number(lat), lng: Number(lng) }));
  return (
    <>
      <PlacesMap
        places={points.map((p, i) => ({ ...p, id: String(i), label: `Punkt ${i + 1}` }))}
        line={points}
      />
      <section className="panel space-y-3">
        <h2 className="text-xl font-bold">{route.name}</h2>
        <p>
          {route.is_active ? 'Trasa włączona' : 'Trasa wyłączona'} · tolerancja {route.threshold_m}{' '}
          m
        </p>
        {editable && (
          <div className="flex flex-wrap gap-2">
            <Button
              variant="secondary"
              loading={mutation.busy}
              onClick={() =>
                mutation.run(
                  () => api.patch(`${path}/${route.id}`, { is_active: !route.is_active }),
                  reload,
                )
              }
            >
              {route.is_active ? 'Wyłącz trasę' : 'Włącz trasę'}
            </Button>
            <ConfirmAction
              label="Usuń trasę"
              description="Trasa zostanie trwale usunięta."
              action={() => api.delete(`${path}/${route.id}`)}
              onDone={() => router.push(base)}
            />
          </div>
        )}
        {mutation.error && <ErrorState message={mutation.error} />}
        <details>
          <summary className="min-h-12 py-3 cursor-pointer">Punkty trasy ({points.length})</summary>
          <ol className="list-decimal pl-5">
            {points.map((p, i) => (
              <li key={i}>
                {p.lat.toFixed(5)}, {p.lng.toFixed(5)}
              </li>
            ))}
          </ol>
        </details>
      </section>
      <section className="space-y-3">
        <h2 className="font-bold text-xl">Zgłoszenia przy trasie</h2>
        {!route.is_active ? (
          <p>Włącz trasę, aby sprawdzić pobliskie zgłoszenia.</p>
        ) : alerts.loading ? (
          <Skeleton />
        ) : alerts.error ? (
          <ErrorState message={alerts.error} onRetry={alerts.reload} />
        ) : !asArray(alerts.data?.alerts).length ? (
          <EmptyState
            title="Brak aktywnych zgłoszeń przy trasie"
            description="Brak zgłoszeń nie jest gwarancją bezpieczeństwa."
          />
        ) : (
          <ul className="space-y-3">
            {asArray(alerts.data?.alerts).map((a) => (
              <li key={a.id}>
                <Link className="panel block" href={`/alerts/${a.id}`}>
                  <strong>{a.title}</strong>
                  <p>{Math.round(a.distance_to_route_m)} m od trasy</p>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>
    </>
  );
}
