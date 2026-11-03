'use client';
import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useSocket } from '@/contexts/SocketContext';
import { ALERT_CATEGORIES, type AlertCategory } from '@/types';
import { isPoint, locate, type Place, type Point } from '@/lib/location';
import { readSession, writeSession } from '@/lib/storage';
import { useNearbyAlerts } from '@/hooks/useNearbyAlerts';
import { MapProvider } from './MapProvider';
import MapView from './MapView';
import { AreaSearch } from './AreaSearch';
import { Button } from '@/components/ui/Button';
import { Chip } from '@/components/ui/Chip';
import { SegmentedControl } from '@/components/ui/SegmentedControl';
import { BottomSheet, type SheetSize } from '@/components/ui/BottomSheet';
import { EmptyState } from '@/components/ui/EmptyState';
import { ErrorState } from '@/components/ui/ErrorState';
import { Skeleton } from '@/components/ui/Skeleton';
import { AlertCard } from '@/components/alerts/AlertCard';
import AlertDetail from '@/components/alerts/AlertDetail';
type ExplorerState = { area: Place | null; radius: number; categories: AlertCategory[]; sort: 'nearest' | 'newest'; view: 'map' | 'list'; sheet: SheetSize };
const initial: ExplorerState = { area: null, radius: 2000, categories: [], sort: 'nearest', view: 'map', sheet: 'half' };
function Explorer() {
  const [state, setState] = useState<ExplorerState>(initial); const [ready, setReady] = useState(false);
  const [pendingArea, setPendingArea] = useState<Point | null>(null); const [selected, setSelected] = useState<string | null>(null); const [revision, setRevision] = useState(0); const [newAlerts, setNewAlerts] = useState(false); const [locating, setLocating] = useState(false); const [locationError, setLocationError] = useState('');
  const trigger = useRef<HTMLElement | null>(null); const { onNewAlert, onAlertUpdated, onAlertExpired } = useSocket();
  const listPosition = useRef<{ id: string; scroll: number; page: number } | null>(null);
  const { alerts, loading, error, updated } = useNearbyAlerts(state.area, state.radius, revision);
  useEffect(() => {
    const restore = () => {
      const stored = readSession<ExplorerState>('besafe.explorer'); const query = new URLSearchParams(window.location.search);
      let next = stored && (!stored.area || isPoint(stored.area)) ? { ...initial, ...stored } : { ...initial };
      const point = { lat: Number(query.get('lat')), lng: Number(query.get('lng')) };
      if (query.has('lat') && query.has('lng') && isPoint(point)) next = { ...next, area: { ...point, label: 'Wybrany obszar' } };
      if ([500, 1000, 2000, 5000, 10000].includes(Number(query.get('radius')))) next.radius = Number(query.get('radius'));
      if (query.get('view') === 'list' || query.get('view') === 'map') next.view = query.get('view') as 'map' | 'list';
      if (query.get('sort') === 'newest' || query.get('sort') === 'nearest') next.sort = query.get('sort') as 'nearest' | 'newest';
      if (query.has('categories')) next.categories = query.get('categories')!.split(',').filter(key => ALERT_CATEGORIES.some(cat => cat.key === key)) as AlertCategory[];
      setState(next); setSelected(query.get('alert')); setReady(true);
    };
    const timer = setTimeout(restore, 0); window.addEventListener('popstate', restore);
    return () => { clearTimeout(timer); window.removeEventListener('popstate', restore); };
  }, []);
  useEffect(() => {
    if (!ready) return;
    writeSession('besafe.explorer', state);
    const query = new URLSearchParams(window.location.search);
    if (state.area) { query.set('lat', String(state.area.lat)); query.set('lng', String(state.area.lng)); }
    query.set('radius', String(state.radius)); query.set('view', state.view); query.set('sort', state.sort); query.set('categories', state.categories.join(','));
    window.history.replaceState(window.history.state, '', `/?${query}`);
  }, [state, ready]);
  useEffect(() => {
    if (selected || loading || !listPosition.current) return;
    const saved = listPosition.current;
    const frame = requestAnimationFrame(() => {
      const body = document.querySelector<HTMLElement>('.sheet-body');
      if (body) body.scrollTop = saved.scroll;
      const target = trigger.current?.isConnected ? trigger.current : document.querySelector<HTMLElement>(`[data-alert-id="${CSS.escape(saved.id)}"]`);
      target?.focus({ preventScroll: true });
      window.scrollTo(0, saved.page);
      listPosition.current = null;
    });
    return () => cancelAnimationFrame(frame);
  }, [selected, loading]);
  useEffect(() => { const notify = () => setNewAlerts(true); const a = onNewAlert(notify); const b = onAlertUpdated(notify); const c = onAlertExpired(notify); return () => { a(); b(); c(); }; }, [onNewAlert, onAlertUpdated, onAlertExpired]);
  function selectArea(area: Place) { setState(current => ({ ...current, area })); setPendingArea(null); setLocationError(''); }
  async function myLocation() { setLocating(true); setLocationError(''); try { selectArea(await locate()); } catch (cause) { setLocationError((cause as Error).message); } finally { setLocating(false); } }
  function openDetail(id: string) { trigger.current = document.activeElement as HTMLElement; listPosition.current = { id, scroll: document.querySelector('.sheet-body')?.scrollTop || 0, page: window.scrollY }; setSelected(id); const query = new URLSearchParams(window.location.search); query.set('alert', id); window.history.pushState({ ...window.history.state, nearbyPanel: true }, '', `/?${query}`); }
  function closeDetail() { setSelected(null); if (window.history.state?.nearbyPanel) window.history.back(); else { const query = new URLSearchParams(window.location.search); query.delete('alert'); window.history.replaceState(window.history.state, '', `/?${query}`); } setTimeout(() => trigger.current?.focus(), 0); }
  const filtered = alerts.filter(alert => !state.categories.length || state.categories.includes(alert.category)).sort((a, b) => state.sort === 'newest' ? new Date(b.created_at).getTime() - new Date(a.created_at).getTime() : Number(a.distance_m ?? Infinity) - Number(b.distance_m ?? Infinity));
  const full = state.view === 'list' || state.sheet === 'full';
  return <div>
    <section className="p-3 lg:px-6 space-y-2 bg-surface border-b border-border">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h1 className="text-2xl font-bold">W okolicy</h1>
        <SegmentedControl label="Widok okolicy" value={state.view} onChange={view => setState(current => ({ ...current, view, sheet: 'half' }))} options={[{ value: 'map', label: 'Mapa' }, { value: 'list', label: 'Lista' }]} />
      </div>
      <div className="flex flex-wrap items-end gap-3">
        <div className="flex-1 min-w-60"><AreaSearch onSelect={selectArea} /></div>
        {full && <Button variant="secondary" loading={locating} onClick={myLocation}>⌖ Moja lokalizacja</Button>}
      </div>
      {locationError && <ErrorState message={locationError} />}
      <details>
        <summary className="cursor-pointer min-h-12 py-3 font-medium">
          Promień: {state.radius === 500 ? '500 m' : `${state.radius / 1000} km`} · Kategorie: {state.categories.length || 'wszystkie'}
        </summary>
        <div role="group" aria-label="Promień przeglądania" className="flex flex-wrap gap-2 py-2">
          {[500, 1000, 2000, 5000, 10000].map(radius => <Chip key={radius} selected={state.radius === radius} onClick={() => setState(current => ({ ...current, radius }))}>{radius === 500 ? '500 m' : `${radius / 1000} km`}</Chip>)}
        </div>
        <div role="group" aria-label="Kategorie" className="flex flex-wrap gap-2 py-3">
          {ALERT_CATEGORIES.map(cat => <Chip key={cat.key} selected={state.categories.includes(cat.key)} onClick={() => setState(current => ({ ...current, categories: current.categories.includes(cat.key) ? current.categories.filter(value => value !== cat.key) : [...current.categories, cat.key] }))}><span aria-hidden="true">{cat.emoji}</span>{cat.label}</Chip>)}
          <Button variant="quiet" onClick={() => setState(current => ({ ...current, categories: [] }))}>Wyczyść filtry</Button>
        </div>
      </details>
    </section>
    {newAlerts && <div role="status" className="p-3 bg-surface-2"><Button variant="secondary" onClick={() => { setRevision(value => value + 1); setNewAlerts(false); }}>Są nowe lub zmienione zgłoszenia — pokaż</Button></div>}
    <div className="explorer-workspace" data-full={full}>
      <div className={`explorer-map ${selected ? 'hidden lg:block' : ''}`}>
        <MapView center={state.area} alerts={filtered} radius={state.radius} selectedId={selected} onSelect={openDetail} onPan={point => { if (!state.area || Math.abs(point.lat - state.area.lat) + Math.abs(point.lng - state.area.lng) > .0005) setPendingArea(previous => previous && Math.abs(previous.lat - point.lat) + Math.abs(previous.lng - point.lng) < .00001 ? previous : point); else setPendingArea(null); }} />
        {pendingArea && <div className="absolute top-3 left-3 right-3 flex justify-center pointer-events-none"><Button className="shadow-lg pointer-events-auto" onClick={() => selectArea({ ...pendingArea, label: 'Obszar wskazany na mapie' })}>Szukaj w tym obszarze</Button></div>}
        <Button variant="secondary" className="absolute bottom-10 left-3 shadow-sm" loading={locating} onClick={myLocation}>⌖ Moja lokalizacja</Button>
      </div>
      {selected ? <section className="nearby-sheet p-4" aria-label="Szczegóły wybranego zgłoszenia">
        <Button variant="secondary" onClick={closeDetail}>← Wróć do listy</Button>
        <AlertDetail key={selected} alertId={selected} onChange={() => setRevision(value => value + 1)} />
      </section> : <BottomSheet title={`W okolicy · ${filtered.length} zgłoszeń`} size={state.sheet} onSizeChange={sheet => setState(current => ({ ...current, sheet }))}>
        <div className="px-4 py-2">
          <details><summary className="min-h-12 py-3 cursor-pointer">Sortowanie: {state.sort === 'nearest' ? 'Najbliższe' : 'Najnowsze'}</summary>
            <SegmentedControl label="Sortowanie zgłoszeń" value={state.sort} options={[{ value: 'nearest', label: 'Najbliższe' }, { value: 'newest', label: 'Najnowsze' }]} onChange={sort => setState(current => ({ ...current, sort }))} />
            <p className="text-sm text-ink-2 my-2">Odległości od środka obszaru: {state.area?.label || 'nie wybrano'}.{updated && ` Odczyt: ${updated}.`}</p>
          </details>
          <p className="text-sm text-ink-2">Odległości od wybranego obszaru</p>
        </div>
        {error && <ErrorState message={`${error}${updated ? ` Ostatni odczyt: ${updated}.` : ''}`} onRetry={() => setRevision(value => value + 1)} />}
        {!ready || loading ? <Skeleton /> : !state.area ? <EmptyState title="Od czego zaczynamy?" description="Użyj swojej lokalizacji, wyszukaj adres lub przesuń mapę i wybierz obszar."><Button onClick={myLocation} loading={locating}>Użyj mojej lokalizacji</Button></EmptyState> : filtered.length === 0 && !error ? <EmptyState title="Brak aktywnych zgłoszeń w tym obszarze" description="Zwiększ promień lub zmień filtry. Brak zgłoszeń nie oznacza braku zagrożeń."><Button variant="secondary" onClick={() => setState(current => ({ ...current, radius: 10000, categories: [] }))}>Sprawdź obszar 10 km</Button></EmptyState> : <ul>{filtered.map(alert => <li key={alert.id}><AlertCard alert={alert} onSelect={openDetail} /></li>)}</ul>}
      </BottomSheet>}
    </div><nav aria-label="Więcej w okolicy" className="flex flex-wrap gap-2 p-4 bg-surface"><Link href="/aqi" className="btn btn-quiet">Jakość powietrza</Link><Link href="/stats" className="btn btn-quiet">Statystyki</Link><Link href="/news" className="btn btn-quiet">Aktualności</Link><Link href="/pets" className="btn btn-quiet">Zaginione zwierzęta</Link></nav></div>;
}
export default function NearbyExplorer() { return <MapProvider><Explorer /></MapProvider>; }
