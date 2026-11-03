'use client';
import { asArray } from '@/lib/api';
import { useEffect, useRef } from 'react';
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
  if (failed) return <MapUnavailable />;
  if (!ready) return <Skeleton label="Ładowanie mapy…" />;
  return (
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
      {valid.map((p) => (
        <MarkerF key={p.id} position={p} title={p.label} onClick={() => onSelect?.(p.id)} />
      ))}
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
