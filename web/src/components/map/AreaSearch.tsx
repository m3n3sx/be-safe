'use client';
import { useRef, useState } from 'react';
import { Button } from '@/components/ui/Button';
import { TextField } from '@/components/ui/TextField';
import { useMapStatus } from './MapProvider';
import type { Place } from '@/lib/location';
export function AreaSearch({ onSelect }: { onSelect: (place: Place) => void }) {
  const { ready, failed } = useMapStatus(); const [query, setQuery] = useState(''); const [results, setResults] = useState<Place[]>([]); const [error, setError] = useState(''); const [busy, setBusy] = useState(false); const request = useRef(0);
  async function search(event: React.FormEvent) {
    event.preventDefault(); if (!ready || !query.trim()) return;
    const version = ++request.current; setBusy(true); setError(''); setResults([]);
    try { const response = await new google.maps.Geocoder().geocode({ address: query, region: 'pl' }); if (version !== request.current) return; setResults(response.results.slice(0, 5).map(result => ({ ...result.geometry.location.toJSON(), label: result.formatted_address }))); if (!response.results.length) setError('Nie znaleziono adresu. Spróbuj podać miejscowość i ulicę.'); }
    catch { if (version === request.current) setError('Nie udało się wyszukać adresu. Użyj lokalizacji lub wskaż miejsce na mapie.'); }
    finally { if (version === request.current) setBusy(false); }
  }
  return <div><form onSubmit={search} className="flex flex-wrap items-end gap-2"><div className="flex-1 min-w-48"><TextField label="Miejscowość lub adres" placeholder="np. Łódź, Piotrkowska 100" value={query} onChange={event => { ++request.current; setBusy(false); setQuery(event.target.value); setResults([]); }} disabled={!ready} /></div><Button type="submit" variant="secondary" loading={busy} disabled={!ready || !query.trim()}>Szukaj</Button></form>{failed && <p className="text-sm text-ink-2 mt-2">Wyszukiwanie adresu jest niedostępne razem z mapą.</p>}{error && <p role="alert" className="text-danger mt-2">{error}</p>}{results.length > 0 && <ul aria-label="Wyniki wyszukiwania" className="border border-border rounded-xl mt-2 bg-surface">{results.map((place, index) => <li key={index}><button className="w-full text-left min-h-12 p-3 hover:bg-surface-2" onClick={() => { onSelect(place); setQuery(place.label); setResults([]); }}>{place.label}</button></li>)}</ul>}</div>;
}
