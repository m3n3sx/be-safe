'use client';
import { asArray } from '@/lib/api';
import { useEffect, useRef, useState } from 'react';
import { clusterItems, mercatorProject } from '@/lib/markerCollision';
import { GoogleMap, MarkerF, PolylineF, CircleF } from '@react-google-maps/api';
import { MapProvider, useMapStatus } from './MapProvider';
import { MapUnavailable } from './MapUnavailable';
import { Skeleton } from '@/components/ui/Skeleton';
import { useTheme } from '@/contexts/ThemeContext';
import { DARK_MAP_STYLES } from '@/lib/constants';
import { isPoint, type Point } from '@/lib/location';
export type MapPlace = Point & { id: string; label: string; radius?: number };
type Props = {
  places: MapPlace[];
  line?: Point[];
  onSelect?: (id: string) => void;
  onPick?: (point: Point) => void;
};
function Canvas({ places, line: rawLine = [], onSelect, onPick }: Props) {
  const { ready, failed } = useMapStatus();
  const { resolvedTheme } = useTheme();
  const map = useRef<google.maps.Map | null>(null);
  const box = useRef<HTMLDivElement>(null);
  const [size, setSize] = useState({ w: 360, h: 320 });
  const [sheet, setSheet] = useState<MapPlace[] | null>(null);
  const valid = asArray(places).filter(isPoint);
  const line = asArray(rawLine).filter(isPoint);
  const boundsKey = JSON.stringify([...valid, ...line].map((p) => [p.lat, p.lng]));
  useEffect(() => {
    if (!map.current) return;
    const points: number[][] = JSON.parse(boundsKey);
    if (!points.length) return;
    const bounds = new google.maps.LatLngBounds();
    points.forEach(([lat, lng]) => bounds.extend({ lat, lng }));
    map.current.fitBounds(bounds, 48);
    if (points.length === 1) map.current.setZoom(14);
  }, [boundsKey, ready]);
  useEffect(() => {
    const el = box.current;
    if (!el || typeof ResizeObserver === 'undefined') return;
    const apply = () => setSize({ w: el.clientWidth || 360, h: el.clientHeight || 320 });
    apply();
    const obs = new ResizeObserver(apply);
    obs.observe(el);
    return () => obs.disconnect();
  }, [ready]);
  if (failed) return <MapUnavailable />;
  if (!ready) return <Skeleton label="Ładowanie mapy…" />;
  const origin = valid[0] || { lat: 52.2297, lng: 21.0122 };
  const groups = clusterItems(
    valid.map((place) => ({ ...place, kind: 'member' })),
    { project: mercatorProject(origin, 14, size.w, size.h) },
  );
  return (
    <div ref={box} className="relative h-full w-full">
    <GoogleMap
      mapContainerStyle={{ width: '100%', height: '100%' }}
      center={valid[0] || { lat: 52.2297, lng: 21.0122 }}
      zoom={12}
      onLoad={(instance) => {
        map.current = instance;
        const bounds = new google.maps.LatLngBounds();
        [...valid, ...line].forEach((p) => bounds.extend(p));
        if (valid.length + line.length > 1) instance.fitBounds(bounds, 48);
      }}
      onUnmount={() => {
        map.current = null;
      }}
      onClick={(event) => {
        if (event.latLng) onPick?.(event.latLng.toJSON());
      }}
      options={{
        styles: resolvedTheme === 'dark' ? DARK_MAP_STYLES : [],
        mapTypeControl: false,
        streetViewControl: false,
        fullscreenControl: false,
        gestureHandling: 'cooperative',
      }}
    >
      {groups.map((group) => {
        const members = valid.filter((place) => group.ids.includes(place.id));
        const first = members[0];
        if (!first) return null;
        return (
          <MarkerF
            key={group.ids.join(':')}
            position={group.displayOnly ? group.anchor : first}
            title={group.displayOnly ? `W tym miejscu: ${group.items.length}` : first.label}
            label={group.displayOnly ? { text: String(group.items.length), color: '#fff', fontWeight: '700' } : undefined}
            onClick={() => {
              if (group.displayOnly) setSheet(members);
              else onSelect?.(first.id);
            }}
          />
        );
      })}
      {valid
        .filter((p) => p.radius)
        .map((p) => (
          <CircleF
            key={p.id}
            center={p}
            radius={p.radius}
            options={{ fillOpacity: 0.08, strokeColor: '#1559b7', strokeWeight: 2 }}
          />
        ))}
      {line.length > 1 && (
        <PolylineF
          path={line}
          options={{
            strokeColor: resolvedTheme === 'dark' ? '#96c2ff' : '#1559b7',
            strokeWeight: 4,
          }}
        />
      )}
    </GoogleMap>
    {sheet && (
      <ul className="absolute bottom-3 left-3 right-3 z-10 max-h-48 overflow-auto rounded-2xl bg-white p-3 text-ink shadow-lg" aria-label="Osoby w tym punkcie">
        {sheet.map((place) => (
          <li key={place.id}>
            <button type="button" className="block w-full px-2 py-2 text-left" onClick={() => { setSheet(null); onSelect?.(place.id); }}>
              <strong>{place.label}</strong>
              <span className="block text-sm text-ink-2">{place.lat.toFixed(5)}, {place.lng.toFixed(5)}</span>
            </button>
          </li>
        ))}
      </ul>
    )}
    </div>
  );
}
export function PlacesMap(props: Props) {
  return (
    <div
      className="h-80 lg:h-96 overflow-hidden rounded-2xl border border-border"
      aria-label="Mapa miejsc; te same dane znajdują się na liście"
    >
      <MapProvider>
        <Canvas {...props} />
      </MapProvider>
    </div>
  );
}
