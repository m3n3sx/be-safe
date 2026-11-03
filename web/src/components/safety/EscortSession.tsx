'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import type { Escort } from '@/lib/api/escort';
import { useAuth } from '@/contexts/AuthContext';
import { useSocket } from '@/contexts/SocketContext';
import { useApiResource, useMutation } from '@/hooks/useApiResource';
import { useForegroundLocation } from '@/hooks/useForegroundLocation';
import { PlacesMap } from '@/components/map/PlacesMap';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { ErrorState } from '@/components/ui/ErrorState';
import { Skeleton } from '@/components/ui/Skeleton';
import { Dialog } from '@/components/ui/Dialog';
export function EscortSession({ id }: { id: string }) {
  const { user } = useAuth();
  const { onEvent } = useSocket();
  const { data: session, loading, error, reload } = useApiResource<Escort>(`/escort/${id}`, 15000);
  const mutation = useMutation();
  const [sharing, setSharing] = useState(false);
  const [cancel, setCancel] = useState(false);
  const [now, setNow] = useState(0);
  const mine = session?.requester_id === user?.id;
  const active = session?.status === 'active';
  const gps = useForegroundLocation(sharing && !!mine && active, async (p) => {
    const r = await api.patch(`/escort/${id}/location`, { lat: p.lat, lng: p.lng });
    if (r.error) throw new Error(r.error);
  });
  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);
  useEffect(() => {
    const off = ['escort:location', 'escort:completed', 'escort:cancelled'].map((event) =>
      onEvent(event, (data) => {
        if (data.escort_id === id) void reload();
      }),
    );
    return () => off.forEach((fn) => fn());
  }, [id, onEvent, reload]);
  const remaining =
    session && now
      ? Math.ceil(
          (new Date(session.started_at).getTime() + session.eta_seconds * 1000 - now) / 60000,
        )
      : null;
  const phone = mine ? session?.watcher_phone : session?.requester_phone;
  return (
    <div className="form-container space-y-5">
      <PageHeader
        title="Bezpieczny powrót"
        description={session?.destination_name || 'Szczegóły sesji'}
      />
      {loading && <Skeleton />}
      {error && <ErrorState message={error} onRetry={reload} />}
      {session && (
        <>
          <section className="panel space-y-3">
            <h2 className="font-bold text-xl">
              {active
                ? 'Powrót trwa'
                : session.status === 'completed'
                  ? 'Dotarcie potwierdzone'
                  : 'Sesja zakończona'}
            </h2>
            <p>
              {session.requester_username} → {session.watcher_username}
            </p>
            <p>Rozpoczęto: {new Date(session.started_at).toLocaleString('pl-PL')}</p>
            {active && remaining !== null && (
              <p className={remaining < 0 ? 'text-warning' : ''}>
                {remaining >= 0
                  ? `Do planowanego dotarcia: ${remaining} min`
                  : `Planowany czas minął ${-remaining} min temu`}
              </p>
            )}
            <p className="text-ink-2">
              Ostatnia aktualizacja:{' '}
              {session.last_update_at
                ? new Date(session.last_update_at).toLocaleString('pl-PL')
                : 'brak danych'}
            </p>
            {phone && (
              <a className="btn btn-secondary" href={`tel:${phone}`}>
                Zadzwoń: {phone}
              </a>
            )}
          </section>
          <PlacesMap
            places={[
              {
                id: 'destination',
                lat: Number(session.destination_lat),
                lng: Number(session.destination_lng),
                label: 'Cel drogi',
              },
              ...(session.last_location_lat != null && session.last_location_lng != null
                ? [
                    {
                      id: 'last',
                      lat: Number(session.last_location_lat),
                      lng: Number(session.last_location_lng),
                      label: 'Ostatnia znana pozycja',
                    },
                  ]
                : []),
            ]}
          />
          {mine && active && (
            <section className="panel space-y-3">
              <h2 className="font-bold">Udostępnianie GPS</h2>
              <p>Pozostaw kartę widoczną. W tle przesyłanie jest wstrzymane.</p>
              <Button variant="secondary" onClick={() => setSharing(!sharing)}>
                {sharing ? 'Wstrzymaj przesyłanie GPS' : 'Włącz przesyłanie GPS'}
              </Button>
              {gps.last && sharing && (
                <p className="text-sm">
                  Wysłano: {new Date(gps.last.timestamp!).toLocaleTimeString('pl-PL')} · dokładność
                  około {Math.round(gps.last.accuracy!)} m
                </p>
              )}
              {gps.error && <ErrorState message={gps.error} />}
              <Button
                loading={mutation.busy}
                onClick={() =>
                  mutation.run(
                    () => api.patch(`/escort/${id}/complete`),
                    async () => {
                      setSharing(false);
                      await reload();
                    },
                  )
                }
              >
                Dotarłem / dotarłam
              </Button>
            </section>
          )}
          {mutation.error && <ErrorState message={mutation.error} />}
          {active && (
            <Button variant="secondary" onClick={() => setCancel(true)}>
              Anuluj powrót
            </Button>
          )}
          <Link className="btn btn-quiet" href="/escort">
            Wszystkie sesje
          </Link>
        </>
      )}
      <Dialog
        open={cancel}
        title="Anulować powrót?"
        onClose={() => {
          if (!mutation.busy) setCancel(false);
        }}
      >
        <p className="mb-4">To zakończy sesję bez potwierdzenia dotarcia.</p>
        {mutation.error && <ErrorState message={mutation.error} />}
        <Button
          variant="danger"
          loading={mutation.busy}
          onClick={() =>
            mutation.run(
              () => api.delete(`/escort/${id}`),
              async () => {
                setSharing(false);
                setCancel(false);
                await reload();
              },
            )
          }
        >
          Potwierdzam anulowanie
        </Button>
      </Dialog>
    </div>
  );
}
