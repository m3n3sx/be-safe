'use client';
import { useState } from 'react';
import { PageHeader } from '@/components/layout/PageHeader';
import { AreaControl, defaultArea } from '@/components/map/AreaControl';
import { useApiResource } from '@/hooks/useApiResource';
import { Button } from '@/components/ui/Button';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
import { distance } from '@/lib/format';
type Station = { id: number; name: string; city?: string; address?: string; distance_m: number; aqi_index?: number | null; aqi_label?: string; pm10?: number | null; pm25?: number | null; no2?: number | null; so2?: number | null; o3?: number | null; measured_at?: string };
export default function Page() {
  const [area, setArea] = useState(defaultArea);
  const { data, loading, error, reload } = useApiResource<{ stations: Station[] }>(`/aqi/nearby?lat=${area.lat}&lng=${area.lng}&radius_m=50000&limit=5`);
  return <div className="page-container space-y-5"><PageHeader title="Jakość powietrza" description="Najbliższe stacje GIOŚ w promieniu 50 km."><Button variant="secondary" onClick={reload}>Odśwież pomiary</Button></PageHeader><AreaControl area={area} onChange={setArea} />{error && <ErrorState message={error} onRetry={reload} />}{loading ? <Skeleton /> : data && !data.stations.length && !error ? <EmptyState title="Brak stacji w wybranym obszarze" description="Spróbuj wybrać inną miejscowość." /> : <div className="grid md:grid-cols-2 gap-4">{data?.stations.map(s => <article className="panel space-y-3" key={s.id}><h2 className="text-xl font-bold">{s.name}</h2><p className="text-ink-2">{s.city} {s.address} · {distance(Number(s.distance_m))}</p><p className="text-xl font-semibold">{s.aqi_label || (s.aqi_index != null ? ['Bardzo dobry', 'Dobry', 'Umiarkowany', 'Dostateczny', 'Zły', 'Bardzo zły'][s.aqi_index] : null) || 'Brak aktualnego indeksu'}</p><dl className="grid grid-cols-2 sm:grid-cols-3 gap-4">{([['PM10', s.pm10], ['PM2,5', s.pm25], ['NO₂', s.no2], ['SO₂', s.so2], ['O₃', s.o3]] as const).map(([label, value]) => <div key={label}><dt className="text-ink-2">{label}</dt><dd className="font-semibold">{value == null ? 'Brak danych' : `${Number(value).toLocaleString('pl-PL', { maximumFractionDigits: 1 })} µg/m³`}</dd></div>)}</dl><p className="text-sm text-ink-2">{s.measured_at ? `Pomiar: ${new Date(s.measured_at).toLocaleString('pl-PL')}` : 'Brak czasu pomiaru'}</p></article>)}</div>}<p className="text-sm text-ink-2">Źródło: Główny Inspektorat Ochrony Środowiska. Pomiar opisuje warunki przy stacji.</p></div>;
}
