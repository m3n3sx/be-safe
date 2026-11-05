'use client';
import { asArray } from '@/lib/api';
import { useRef, useEffect, useState } from 'react';
import { GoogleMap, MarkerF, CircleF } from '@react-google-maps/api';
import { useTheme } from '@/contexts/ThemeContext';
import { DARK_MAP_STYLES, DEFAULT_CENTER } from '@/lib/constants';
import { getCategoryInfo, type Alert } from '@/types';
import type { Point } from '@/lib/location';
import { useMapStatus } from './MapProvider';
import { MapUnavailable } from './MapUnavailable';
import { Skeleton } from '@/components/ui/Skeleton';
import { clusterItems, mercatorProject } from '@/lib/markerCollision';

type Placed = { id: string; lat: number; lng: number; kind: string; alert: Alert };

export default function MapView({
  center,
  alerts = [],
  radius,
  selectedId,
  onSelect,
  onPan,
  onPick,
  point,
  zoom = 14,
}: {
  center?: Point | null;
  alerts?: Alert[];
  radius?: number;
  selectedId?: string | null;
  onSelect?: (id: string) => void;
  onPan?: (point: Point) => void;
  onPick?: (point: Point) => void;
  point?: Point | null;
  zoom?: number;
}) {
  const { ready, failed } = useMapStatus();
  const { resolvedTheme } = useTheme();
  const map = useRef<google.maps.Map | null>(null);
  const box = useRef<HTMLDivElement>(null);
  const [size, setSize] = useState({ w: 360, h: 480 });
  const [sheet, setSheet] = useState<Placed[] | null>(null);
  const alertList = asArray(alerts);
  const selectedAlert = alertList.find((alert) => alert.id === selectedId);
  const selectedLat = selectedAlert?.lat;
  const selectedLng = selectedAlert?.lng;
  useEffect(() => {
    if (selectedLat !== undefined && selectedLng !== undefined)
      map.current?.panTo({ lat: Number(selectedLat), lng: Number(selectedLng) });
  }, [selectedLat, selectedLng]);
  useEffect(() => {
    const el = box.current;
    if (!el || typeof ResizeObserver === 'undefined') return;
    const apply = () => setSize({ w: el.clientWidth || 360, h: el.clientHeight || 480 });
    apply();
    const obs = new ResizeObserver(apply);
    obs.observe(el);
    return () => obs.disconnect();
  }, [ready]);
  if (failed) return <MapUnavailable />;
  if (!ready) return <Skeleton label="Ładowanie mapy…" />;
  const origin = center || DEFAULT_CENTER;
  const mapZoom = center ? zoom : 12;
  const project = mercatorProject(origin, mapZoom, size.w, size.h);
  const groups = clusterItems(
    alertList.map((alert) => ({
      id: alert.id,
      lat: Number(alert.lat),
      lng: Number(alert.lng),
      kind:
        alert.kind === 'sos' ||
        (alert.category === 'aggression' && String(alert.title || '').includes('🆘'))
          ? 'sos'
          : 'hazard',
      alert,
    })),
    { project },
  );
  return (
    <div ref={box} className="relative h-full w-full">
      <GoogleMap
        mapContainerStyle={{ width: '100%', height: '100%' }}
        center={center || DEFAULT_CENTER}
        zoom={mapZoom}
        options={{
          styles: resolvedTheme === 'dark' ? DARK_MAP_STYLES : [],
          mapTypeControl: false,
          streetViewControl: false,
          fullscreenControl: false,
          clickableIcons: false,
          gestureHandling: 'cooperative',
          keyboardShortcuts: true,
        }}
        onLoad={(instance) => {
          map.current = instance;
        }}
        onUnmount={() => {
          map.current = null;
        }}
        onIdle={() => {
          const position = map.current?.getCenter();
          if (position) onPan?.(position.toJSON());
        }}
        onClick={(event) => {
          setSheet(null);
          if (event.latLng) onPick?.(event.latLng.toJSON());
        }}
      >
        {center && radius && (
          <CircleF
            center={center}
            radius={radius}
            options={{
              fillColor: '#1559b7',
              fillOpacity: 0.04,
              strokeColor: resolvedTheme === 'dark' ? '#96c2ff' : '#1559b7',
              strokeOpacity: 0.65,
              strokeWeight: 1,
              clickable: false,
            }}
          />
        )}
        {groups.map((group) => {
          const first = group.items[0] as Placed;
          const sos = group.items.some((item) => item.kind === 'sos');
          const cat = getCategoryInfo(first.alert.category);
          return (
            <MarkerF
              key={group.ids.join(':')}
              position={group.displayOnly ? group.anchor : { lat: first.lat, lng: first.lng }}
              title={group.displayOnly ? `W tym miejscu: ${group.items.length}` : `${cat.label}: ${first.alert.title}`}
              label={{
                text: group.displayOnly ? String(group.items.length) : cat.emoji,
                color: group.displayOnly ? '#fff' : undefined,
                fontSize: group.displayOnly ? '14px' : '20px',
                fontWeight: group.displayOnly ? '700' : undefined,
              }}
              icon={{
                path: google.maps.SymbolPath.CIRCLE,
                scale: group.displayOnly ? 18 : selectedId === first.id ? 24 : 20,
                fillColor: sos ? '#8E1B1B' : resolvedTheme === 'dark' ? '#192530' : '#fff',
                fillOpacity: 1,
                strokeWeight: selectedId === first.id ? 5 : 3,
                strokeColor: sos ? '#FFD2D2' : cat.color,
              }}
              onClick={() => {
                if (group.displayOnly) setSheet(group.items as Placed[]);
                else onSelect?.(first.id);
              }}
            />
          );
        })}
        {point && <MarkerF position={point} title="Wybrane miejsce zgłoszenia" />}
      </GoogleMap>
      {sheet && (
        <ul
          className="absolute bottom-3 left-3 right-3 z-10 max-h-64 overflow-auto rounded-2xl bg-white p-3 text-ink shadow-lg"
          aria-label="Zgłoszenia w tym punkcie"
        >
          {sheet.map((item) => (
            <li key={item.id}>
              <button
                type="button"
                className="block w-full rounded-xl px-2 py-2 text-left hover:bg-surface-2"
                onClick={() => {
                  setSheet(null);
                  onSelect?.(item.id);
                }}
              >
                <strong>{item.kind === 'sos' ? 'SOS · ' : ''}{item.alert.title}</strong>
                <span className="block text-sm text-ink-2">
                  {Number(item.lat).toFixed(5)}, {Number(item.lng).toFixed(5)}
                </span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
