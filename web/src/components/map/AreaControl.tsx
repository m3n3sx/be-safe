'use client';
import { useState } from 'react';
import { locate, type Place } from '@/lib/location';
import { MapProvider } from './MapProvider';
import { AreaSearch } from './AreaSearch';
import { Button } from '@/components/ui/Button';
import { Icon } from '@/components/ui/Icon';
import { ErrorState } from '@/components/ui/ErrorState';
export const defaultArea: Place = { lat: 52.2297, lng: 21.0122, label: 'Warszawa — wybrany obszar' };
export function AreaControl({ area, onChange }: { area: Place; onChange: (area: Place) => void }) {
  const [busy, setBusy] = useState(false); const [error, setError] = useState('');
  async function current() { setBusy(true); setError(''); try { onChange(await locate()); } catch (e) { setError((e as Error).message); } finally { setBusy(false); } }
  return <section className="panel space-y-3"><MapProvider><AreaSearch onSelect={onChange} /></MapProvider><Button variant="secondary" loading={busy} onClick={current}><Icon name="location" />Użyj mojej lokalizacji</Button><p className="text-sm text-ink-2">Odległości od: {area.label}</p>{error && <ErrorState message={error} />}</section>;
}
