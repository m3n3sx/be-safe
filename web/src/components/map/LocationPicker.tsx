'use client';
import { useState } from 'react';
import { locate, type Place } from '@/lib/location';
import { Button } from '@/components/ui/Button';
import { TextField } from '@/components/ui/TextField';
import { ErrorState } from '@/components/ui/ErrorState';
import { Icon } from '@/components/ui/Icon';
import { AreaSearch } from './AreaSearch';
import MapView from './MapView';
export function LocationPicker({
  value,
  onChange,
}: {
  value: Place | null;
  onChange: (point: Place) => void;
}) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [lat, setLat] = useState('');
  const [lng, setLng] = useState('');
  async function current() {
    setBusy(true);
    setError('');
    try {
      onChange(await locate());
    } catch (cause) {
      setError((cause as Error).message);
    } finally {
      setBusy(false);
    }
  }
  return (
    <div className="space-y-4">
      <Button variant="secondary" onClick={current} loading={busy}>
        <Icon name="location" />
        Użyj mojej lokalizacji
      </Button>
      {error && <ErrorState message={error} />}
      <AreaSearch onSelect={onChange} />
      <p className="text-ink-2">
        Wybierz adres lub punkt na mapie. Przesunięcie mapy nie zmienia miejsca.
      </p>
      <div className="h-64 rounded-xl overflow-hidden border border-border">
        <MapView
          center={value}
          point={value}
          onPick={(point) => onChange({ ...point, label: 'Miejsce wskazane na mapie' })}
        />
      </div>
      {value && (
        <div role="status" className="panel">
          <p className="font-semibold">{value.label}</p>
          <p>
            {value.lat.toFixed(5)}, {value.lng.toFixed(5)}
          </p>
          {value.accuracy !== undefined && (
            <p className="text-sm text-ink-2">
              Dokładność: około {Math.round(value.accuracy)} m · odczyt{' '}
              {new Date(value.timestamp!).toLocaleTimeString('pl-PL')}
            </p>
          )}
        </div>
      )}
      <details>
        <summary className="min-h-12 py-3 cursor-pointer">
          Wpisz współrzędne (także bez mapy)
        </summary>
        <div className="grid sm:grid-cols-2 gap-3">
          <TextField
            label="Szerokość geograficzna"
            type="number"
            step="any"
            min={-90}
            max={90}
            value={lat}
            onChange={(event) => setLat(event.target.value)}
          />
          <TextField
            label="Długość geograficzna"
            type="number"
            step="any"
            min={-180}
            max={180}
            value={lng}
            onChange={(event) => setLng(event.target.value)}
          />
        </div>
        <Button
          className="mt-3"
          variant="secondary"
          disabled={
            !lat.trim() ||
            !lng.trim() ||
            !Number.isFinite(Number(lat)) ||
            !Number.isFinite(Number(lng)) ||
            Math.abs(Number(lat)) > 90 ||
            Math.abs(Number(lng)) > 180
          }
          onClick={() =>
            onChange({ lat: Number(lat), lng: Number(lng), label: 'Miejsce podane współrzędnymi' })
          }
        >
          Użyj tego miejsca
        </Button>
      </details>
    </div>
  );
}
