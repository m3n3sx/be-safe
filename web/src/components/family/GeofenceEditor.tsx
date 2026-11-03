'use client';
import { useState } from 'react';
import api, { asArray } from '@/lib/api';
import type { Geofence } from '@/types';
import type { Place } from '@/lib/location';
import { groupPath, useGroup } from '@/lib/api/family';
import { useApiResource, useMutation } from '@/hooks/useApiResource';
import { GroupHeader } from './GroupHeader';
import { PlacesMap } from '@/components/map/PlacesMap';
import { MapProvider } from '@/components/map/MapProvider';
import { LocationPicker } from '@/components/map/LocationPicker';
import { Button } from '@/components/ui/Button';
import { TextField } from '@/components/ui/TextField';
import { Dialog } from '@/components/ui/Dialog';
import { ConfirmAction } from '@/components/ui/ConfirmAction';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
export function GeofenceEditor({ groupId }: { groupId: string }) {
  const group = useGroup(groupId);
  const resource = useApiResource<{ geofences: Geofence[] }>(`${groupPath(groupId)}/geofences`);
  const mutation = useMutation();
  const [open, setOpen] = useState(false);
  const [name, setName] = useState('');
  const [radius, setRadius] = useState(200);
  const [place, setPlace] = useState<Place | null>(null);
  async function save() {
    if (!place || !name.trim()) return;
    await mutation.run(
      () =>
        api.post(`${groupPath(groupId)}/geofences`, {
          name: name.trim(),
          lat: place.lat,
          lng: place.lng,
          radius_m: radius,
        }),
      async () => {
        setOpen(false);
        setName('');
        setPlace(null);
        await resource.reload();
      },
    );
  }
  return (
    <div className="page-container space-y-5">
      <GroupHeader id={groupId} title="Bezpieczne strefy" name={group.group?.name} />
      {group.guardian && <Button onClick={() => setOpen(true)}>Dodaj strefę</Button>}
      {(resource.error || group.error) && (
        <ErrorState
          message={resource.error || group.error}
          onRetry={() => {
            void resource.reload();
            void group.reload();
          }}
        />
      )}
      {resource.loading ? (
        <Skeleton />
      ) : (
        resource.data && (
          <>
            <PlacesMap
              places={asArray(resource.data.geofences).map((g) => ({
                id: g.id,
                lat: Number(g.lat),
                lng: Number(g.lng),
                label: g.name,
                radius: g.radius_m,
              }))}
            />
            {!asArray(resource.data.geofences).length && (
              <EmptyState
                title="Nie ma jeszcze stref"
                description="Rodzic lub opiekun może oznaczyć dom, szkołę albo inne miejsce."
              />
            )}
            <ul className="grid sm:grid-cols-2 gap-4">
              {asArray(resource.data.geofences).map((g) => (
                <li className="panel space-y-2" key={g.id}>
                  <h2 className="font-bold text-xl">{g.name}</h2>
                  <p>
                    Promień: {g.radius_m} m · {g.is_active ? 'Włączona' : 'Wyłączona'}
                  </p>
                  {group.guardian && (
                    <div className="flex flex-wrap gap-2">
                      <Button
                        variant="secondary"
                        disabled={mutation.busy}
                        onClick={() =>
                          mutation.run(
                            () =>
                              api.patch(`${groupPath(groupId)}/geofences/${g.id}`, {
                                is_active: !g.is_active,
                              }),
                            resource.reload,
                          )
                        }
                      >
                        {g.is_active ? 'Wyłącz' : 'Włącz'}
                      </Button>
                      <ConfirmAction
                        label={`Usuń strefę ${g.name}`}
                        description="Strefa zostanie trwale usunięta."
                        action={() => api.delete(`${groupPath(groupId)}/geofences/${g.id}`)}
                        onDone={resource.reload}
                      />
                    </div>
                  )}
                </li>
              ))}
            </ul>
          </>
        )
      )}
      {mutation.error && <ErrorState message={mutation.error} />}
      <Dialog
        open={open}
        title="Nowa bezpieczna strefa"
        onClose={() => {
          if (!mutation.busy) setOpen(false);
        }}
      >
        <div className="space-y-4">
          <TextField
            label="Nazwa strefy"
            value={name}
            maxLength={100}
            onChange={(e) => setName(e.target.value)}
          />
          <MapProvider>
            <LocationPicker value={place} onChange={setPlace} />
          </MapProvider>
          <TextField
            label="Promień (metry)"
            type="number"
            min={50}
            max={5000}
            value={radius}
            onChange={(e) => setRadius(Number(e.target.value))}
          />
          {mutation.error && <ErrorState message={mutation.error} />}
          <Button
            loading={mutation.busy}
            disabled={!place || !name.trim() || radius < 50 || radius > 5000}
            onClick={save}
          >
            Zapisz strefę
          </Button>
        </div>
      </Dialog>
    </div>
  );
}
