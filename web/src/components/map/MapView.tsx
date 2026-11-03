'use client';
import { asArray } from '@/lib/api';
import { useRef, useEffect } from 'react';
import { GoogleMap, MarkerF, CircleF, MarkerClustererF } from '@react-google-maps/api';
import { useTheme } from '@/contexts/ThemeContext';
import { DARK_MAP_STYLES, DEFAULT_CENTER } from '@/lib/constants';
import { getCategoryInfo, type Alert } from '@/types';
import type { Point } from '@/lib/location';
import { useMapStatus } from './MapProvider';
import { MapUnavailable } from './MapUnavailable';
import { Skeleton } from '@/components/ui/Skeleton';
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
  const alertList = asArray(alerts);
  const selectedAlert = alertList.find((alert) => alert.id === selectedId);
  const selectedLat = selectedAlert?.lat;
  const selectedLng = selectedAlert?.lng;
  useEffect(() => {
    if (selectedLat !== undefined && selectedLng !== undefined)
      map.current?.panTo({ lat: Number(selectedLat), lng: Number(selectedLng) });
  }, [selectedLat, selectedLng]);
  if (failed) return <MapUnavailable />;
  if (!ready) return <Skeleton label="Ładowanie mapy…" />;
  return (
    <GoogleMap
      mapContainerStyle={{ width: '100%', height: '100%' }}
      center={center || DEFAULT_CENTER}
      zoom={center ? zoom : 12}
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
      <MarkerClustererF options={{ minimumClusterSize: 3 }}>
        {(clusterer) => (
          <>
            {alertList.map((alert) => {
              const cat = getCategoryInfo(alert.category);
              return (
                <MarkerF
                  key={alert.id}
                  clusterer={clusterer}
                  position={{ lat: Number(alert.lat), lng: Number(alert.lng) }}
                  title={`${cat.label}: ${alert.title}`}
                  label={{ text: cat.emoji, fontSize: '20px' }}
                  icon={{
                    path: google.maps.SymbolPath.CIRCLE,
                    scale: selectedId === alert.id ? 24 : 20,
                    fillColor: resolvedTheme === 'dark' ? '#192530' : '#fff',
                    fillOpacity: 1,
                    strokeWeight: selectedId === alert.id ? 5 : 3,
                    strokeColor: cat.color,
                  }}
                  onClick={() => onSelect?.(alert.id)}
                />
              );
            })}
          </>
        )}
      </MarkerClustererF>
      {point && <MarkerF position={point} title="Wybrane miejsce zgłoszenia" />}
    </GoogleMap>
  );
}
