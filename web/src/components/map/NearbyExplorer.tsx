'use client';
import { asArray } from '@/lib/api';
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
import { BottomSheet, ModalBottomSheet, type SheetSize } from '@/components/ui/BottomSheet';
import { Icon } from '@/components/ui/Icon';
import { EmptyState } from '@/components/ui/EmptyState';
import { ErrorState } from '@/components/ui/ErrorState';
import { Skeleton } from '@/components/ui/Skeleton';
import { AlertCard } from '@/components/alerts/AlertCard';
import AlertDetail from '@/components/alerts/AlertDetail';
type ExplorerState = {
  area: Place | null;
  radius: number;
  categories: AlertCategory[];
  sort: 'nearest' | 'newest';
  view: 'map' | 'list';
  sheet: SheetSize;
};
const initial: ExplorerState = {
  area: { lat: 52.2297, lng: 21.0122, label: 'Warszawa — wybrany obszar' },
  radius: 5000,
  categories: [],
  sort: 'nearest',
  view: 'map',
  sheet: 'peek',
};
function Explorer() {
  const [state, setState] = useState<ExplorerState>(initial);
  const [ready, setReady] = useState(false);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const areaChoice = useRef(0);
  const [pendingArea, setPendingArea] = useState<Point | null>(null);
  const [selected, setSelected] = useState<string | null>(null);
  const [revision, setRevision] = useState(0);
  const [newAlerts, setNewAlerts] = useState(false);
  const [locating, setLocating] = useState(false);
  const [locationError, setLocationError] = useState('');
  const trigger = useRef<HTMLElement | null>(null);
  const { onNewAlert, onAlertUpdated, onAlertExpired } = useSocket();
  const listPosition = useRef<{ id: string; scroll: number; page: number } | null>(null);
  const { alerts, loading, error, updated } = useNearbyAlerts(state.area, state.radius, revision);
  useEffect(() => {
    const restore = () => {
      const stored = readSession<ExplorerState>('besafe.explorer');
      const query = new URLSearchParams(window.location.search);
      let next =
        stored && (!stored.area || isPoint(stored.area))
          ? { ...initial, ...stored }
          : { ...initial };
      const point = { lat: Number(query.get('lat')), lng: Number(query.get('lng')) };
      if (query.has('lat') && query.has('lng') && isPoint(point))
        next = { ...next, area: { ...point, label: 'Wybrany obszar' } };
      if ([500, 1000, 2000, 5000, 10000].includes(Number(query.get('radius'))))
        next.radius = Number(query.get('radius'));
      if (query.get('view') === 'list' || query.get('view') === 'map')
        next.view = query.get('view') as 'map' | 'list';
      if (query.get('sort') === 'newest' || query.get('sort') === 'nearest')
        next.sort = query.get('sort') as 'nearest' | 'newest';
      if (query.has('categories'))
        next.categories = query
          .get('categories')!
          .split(',')
          .filter((key) => ALERT_CATEGORIES.some((cat) => cat.key === key)) as AlertCategory[];
      next.area ||= initial.area;
      next.categories = asArray(next.categories).filter((key) =>
        ALERT_CATEGORIES.some((cat) => cat.key === key),
      );
      setState(next);
      setSelected(query.get('alert'));
      setReady(true);
    };
    const timer = setTimeout(restore, 0);
    window.addEventListener('popstate', restore);
    return () => {
      clearTimeout(timer);
      window.removeEventListener('popstate', restore);
    };
  }, []);
  useEffect(() => {
    let cancelled = false;
    const version = areaChoice.current;
    // Never prompt on entry or overwrite an explicitly deep-linked area.
    if (!navigator.permissions || new URLSearchParams(window.location.search).has('lat')) return;
    void navigator.permissions
      .query({ name: 'geolocation' })
      .then(async (permission) => {
        if (permission.state !== 'granted') return;
        try {
          const area = await locate();
          if (!cancelled && version === areaChoice.current)
            setState((current) => ({ ...current, area }));
        } catch {
          /* Default area remains usable. */
        }
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, []);
  useEffect(() => {
    if (!ready) return;
    writeSession('besafe.explorer', state);
    const query = new URLSearchParams(window.location.search);
    if (state.area) {
      query.set('lat', String(state.area.lat));
      query.set('lng', String(state.area.lng));
    }
    query.set('radius', String(state.radius));
    query.set('view', state.view);
    query.set('sort', state.sort);
    query.set('categories', state.categories.join(','));
    window.history.replaceState(window.history.state, '', `/?${query}`);
  }, [state, ready]);
  useEffect(() => {
    if (selected || loading || !listPosition.current) return;
    const saved = listPosition.current;
    const frame = requestAnimationFrame(() => {
      const body = document.querySelector<HTMLElement>('.sheet-body');
      if (body) body.scrollTop = saved.scroll;
      const target = trigger.current?.isConnected
        ? trigger.current
        : document.querySelector<HTMLElement>(`[data-alert-id="${CSS.escape(saved.id)}"]`);
      target?.focus({ preventScroll: true });
      window.scrollTo(0, saved.page);
      listPosition.current = null;
    });
    return () => cancelAnimationFrame(frame);
  }, [selected, loading]);
  useEffect(() => {
    const notify = () => setNewAlerts(true);
    const a = onNewAlert(notify);
    const b = onAlertUpdated(notify);
    const c = onAlertExpired(notify);
    return () => {
      a();
      b();
      c();
    };
  }, [onNewAlert, onAlertUpdated, onAlertExpired]);
  function selectArea(area: Place) {
    areaChoice.current++;
    setState((current) => ({ ...current, area }));
    setPendingArea(null);
    setLocationError('');
  }
  async function myLocation() {
    setLocating(true);
    setLocationError('');
    try {
      selectArea(await locate());
    } catch (cause) {
      setLocationError((cause as Error).message);
    } finally {
      setLocating(false);
    }
  }
  function openDetail(id: string) {
    trigger.current = document.activeElement as HTMLElement;
    listPosition.current = {
      id,
      scroll: document.querySelector('.sheet-body')?.scrollTop || 0,
      page: window.scrollY,
    };
    setSelected(id);
    const query = new URLSearchParams(window.location.search);
    query.set('alert', id);
    window.history.pushState({ ...window.history.state, nearbyPanel: true }, '', `/?${query}`);
  }
  function closeDetail() {
    setSelected(null);
    if (window.history.state?.nearbyPanel) window.history.back();
    else {
      const query = new URLSearchParams(window.location.search);
      query.delete('alert');
      window.history.replaceState(window.history.state, '', `/?${query}`);
    }
    setTimeout(() => trigger.current?.focus(), 0);
  }
  const filtered = alerts
    .filter((alert) => !state.categories.length || state.categories.includes(alert.category))
    .sort((a, b) =>
      state.sort === 'newest'
        ? new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
        : Number(a.distance_m ?? Infinity) - Number(b.distance_m ?? Infinity),
    );
  const full = state.view === 'list' || state.sheet === 'full';
  return (
    <div>
      <section className="nearby-toolbar p-2 lg:px-6 bg-surface border-b border-border">
        <h1 className="sr-only">W okolicy</h1>
        <div className="flex items-center gap-2">
          <div className="flex-1 min-w-0">
            <AreaSearch compact onSelect={selectArea} />
          </div>
          <Button
            variant="secondary"
            aria-label="Filtry: promień, kategorie i sortowanie"
            onClick={() => setFiltersOpen(true)}
          >
            <Icon name="filter" />
          </Button>
        </div>
        {locationError && <ErrorState message={locationError} />}
        <ModalBottomSheet
          open={filtersOpen}
          title="Filtry okolicy"
          onClose={() => setFiltersOpen(false)}
        >
          <h3 className="font-semibold">Promień przeglądania</h3>
          <div role="group" aria-label="Promień przeglądania" className="flex flex-wrap gap-2 py-2">
            {[500, 1000, 2000, 5000, 10000].map((radius) => (
              <Chip
                key={radius}
                selected={state.radius === radius}
                onClick={() => setState((current) => ({ ...current, radius }))}
              >
                {radius === 500 ? '500 m' : `${radius / 1000} km`}
              </Chip>
            ))}
          </div>
          <div role="group" aria-label="Kategorie" className="flex flex-wrap gap-2 py-3">
            {ALERT_CATEGORIES.map((cat) => (
              <Chip
                key={cat.key}
                selected={state.categories.includes(cat.key)}
                onClick={() =>
                  setState((current) => ({
                    ...current,
                    categories: current.categories.includes(cat.key)
                      ? current.categories.filter((value) => value !== cat.key)
                      : [...current.categories, cat.key],
                  }))
                }
              >
                <span aria-hidden="true">{cat.emoji}</span>
                {cat.label}
              </Chip>
            ))}
            <Button
              variant="quiet"
              onClick={() => setState((current) => ({ ...current, categories: [] }))}
            >
              Wyczyść filtry
            </Button>
          </div>
          <SegmentedControl
            label="Sortowanie zgłoszeń"
            value={state.sort}
            options={[
              { value: 'nearest', label: 'Najbliższe' },
              { value: 'newest', label: 'Najnowsze' },
            ]}
            onChange={(sort) => setState((current) => ({ ...current, sort }))}
          />
          <Button className="w-full mt-4" onClick={() => setFiltersOpen(false)}>
            Pokaż wyniki ({filtered.length})
          </Button>
        </ModalBottomSheet>
        <div className="flex flex-nowrap items-center justify-between gap-2 mt-2">
          <p className="min-w-0 flex-1 text-sm leading-snug text-ink-2">
            {state.area?.label === 'Moja lokalizacja'
              ? 'Pokazuję: okolice Twojej lokalizacji'
              : 'Pokazuję: wybrany obszar'}
          </p>
          <SegmentedControl
            label="Widok okolicy"
            value={state.view}
            onChange={(view) => setState((current) => ({ ...current, view, sheet: 'peek' }))}
            options={[
              { value: 'map', label: 'Mapa' },
              { value: 'list', label: 'Lista' },
            ]}
          />
        </div>
        {full && (
          <Button variant="secondary" loading={locating} onClick={myLocation}>
            <Icon name="location" />
            Użyj mojej lokalizacji
          </Button>
        )}
      </section>
      {newAlerts && (
        <div role="status" className="p-3 bg-surface-2">
          <Button
            variant="secondary"
            onClick={() => {
              setRevision((value) => value + 1);
              setNewAlerts(false);
            }}
          >
            Są nowe lub zmienione zgłoszenia — pokaż
          </Button>
        </div>
      )}
      <div className="explorer-workspace" data-full={full}>
        <div className={`explorer-map ${selected ? 'hidden lg:block' : ''}`}>
          <MapView
            center={state.area}
            zoom={12}
            alerts={filtered}
            radius={state.radius}
            selectedId={selected}
            onSelect={openDetail}
            onPan={(point) => {
              if (
                !state.area ||
                Math.abs(point.lat - state.area.lat) + Math.abs(point.lng - state.area.lng) > 0.0005
              )
                setPendingArea((previous) =>
                  previous &&
                  Math.abs(previous.lat - point.lat) + Math.abs(previous.lng - point.lng) < 0.00001
                    ? previous
                    : point,
                );
              else setPendingArea(null);
            }}
          />
          {pendingArea && (
            <div className="absolute top-3 left-3 right-3 flex justify-center pointer-events-none">
              <Button
                className="shadow-lg pointer-events-auto"
                onClick={() => selectArea({ ...pendingArea, label: 'Obszar wskazany na mapie' })}
              >
                Szukaj w tym obszarze
              </Button>
            </div>
          )}
          <Button
            variant="secondary"
            className="absolute bottom-10 left-3 shadow-sm"
            loading={locating}
            onClick={myLocation}
          >
            <Icon name="location" />
            Użyj mojej lokalizacji
          </Button>
        </div>
        {selected ? (
          <section className="nearby-sheet p-4" aria-label="Szczegóły wybranego zgłoszenia">
            <Button variant="secondary" onClick={closeDetail}>
              ← Wróć do listy
            </Button>
            <AlertDetail
              key={selected}
              alertId={selected}
              onChange={() => setRevision((value) => value + 1)}
            />
          </section>
        ) : (
          <BottomSheet
            title={`W okolicy · ${filtered.length} zgłoszeń`}
            size={state.sheet}
            onSizeChange={(sheet) => setState((current) => ({ ...current, sheet }))}
          >
            <p className="px-4 pt-2 text-sm text-ink-2">Odległości od środka wybranego obszaru</p>
            {error && (
              <ErrorState
                message={`${error}${updated ? ` Ostatni odczyt: ${updated}.` : ''}`}
                onRetry={() => setRevision((value) => value + 1)}
              />
            )}
            {!ready || loading ? (
              <Skeleton />
            ) : !state.area ? (
              <EmptyState
                title="Od czego zaczynamy?"
                description="Użyj swojej lokalizacji, wyszukaj adres lub przesuń mapę i wybierz obszar."
              >
                <Button onClick={myLocation} loading={locating}>
                  Użyj mojej lokalizacji
                </Button>
              </EmptyState>
            ) : filtered.length === 0 && !error ? (
              <EmptyState
                title="Brak aktywnych zgłoszeń w tym obszarze"
                description="Zwiększ promień lub zmień filtry. Brak zgłoszeń nie oznacza braku zagrożeń."
              >
                <Button
                  variant="secondary"
                  onClick={() =>
                    setState((current) => ({ ...current, radius: 10000, categories: [] }))
                  }
                >
                  Sprawdź obszar 10 km
                </Button>
              </EmptyState>
            ) : (
              <ul>
                {filtered.map((alert) => (
                  <li key={alert.id}>
                    <AlertCard alert={alert} onSelect={openDetail} />
                  </li>
                ))}
              </ul>
            )}
          </BottomSheet>
        )}
      </div>
      <nav aria-label="Więcej w okolicy" className="flex flex-wrap gap-2 p-4 bg-surface">
        <Link href="/aqi" className="btn btn-quiet">
          Jakość powietrza
        </Link>
        <Link href="/stats" className="btn btn-quiet">
          Statystyki
        </Link>
        <Link href="/news" className="btn btn-quiet">
          Aktualności
        </Link>
        <Link href="/neighborhood" className="btn btn-quiet">
          Czat sąsiedzki
        </Link>
        <Link href="/pets?view=lost" className="btn btn-quiet">
          Zaginione zwierzęta
        </Link>
      </nav>
    </div>
  );
}
export default function NearbyExplorer() {
  return (
    <MapProvider>
      <Explorer />
    </MapProvider>
  );
}
