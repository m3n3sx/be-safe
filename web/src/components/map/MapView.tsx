'use client';

import React, { useState, useCallback, useEffect, useRef, useMemo } from 'react';
import { GoogleMap, useJsApiLoader, InfoWindow, Circle } from '@react-google-maps/api';
import { MarkerClusterer, type Renderer, type Cluster } from '@googlemaps/markerclusterer';
import { GOOGLE_MAPS_API_KEY, DEFAULT_CENTER, DEFAULT_ZOOM, DARK_MAP_STYLES, LIGHT_MAP_STYLES } from '@/lib/constants';
import { useTheme } from '@/contexts/ThemeContext';
import { useAuth } from '@/contexts/AuthContext';
import { useSocket } from '@/contexts/SocketContext';
import api from '@/lib/api';
import { t } from '@/lib/i18n';
import type { Alert, AlertCategory } from '@/types';
import { getCategoryInfo, ALERT_CATEGORIES } from '@/types';
import {
  gmapsAlertIcon,
  gmapsClusterIcon,
  gmapsUserPositionIcon,
  gmapsSosIcon,
  buildFlatCircleSvg,
  SERENITY,
} from '@/lib/markerIcons';
import AlertDetail from '@/components/alerts/AlertDetail';
import CreateAlertModal from '@/components/alerts/CreateAlertModal';
import SOSButton from '@/components/ui/SOSButton';

const containerStyle = { width: '100%', height: '100%' };
const libraries: ('places')[] = ['places'];

export default function MapView() {
  const { isLoaded } = useJsApiLoader({
    googleMapsApiKey: GOOGLE_MAPS_API_KEY,
    libraries,
  });

  const { resolvedTheme } = useTheme();
  const { user } = useAuth();
  const { onNewAlert, onAlertUpdated, onAlertExpired, updateLocation } = useSocket();

  const [map, setMap] = useState<google.maps.Map | null>(null);
  const [center, setCenter] = useState(DEFAULT_CENTER);
  const [userPos, setUserPos] = useState<{ lat: number; lng: number } | null>(null);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [selectedAlert, setSelectedAlert] = useState<Alert | null>(null);
  const [showCreate, setShowCreate] = useState(false);
  const [createPos, setCreatePos] = useState<{ lat: number; lng: number } | null>(null);
  const [categoryFilter, setCategoryFilter] = useState<Set<AlertCategory>>(new Set());
  const [showFilter, setShowFilter] = useState(false);
  const lastFetchRef = useRef<string>('');

  // Imperatively-managed markers (so MarkerClusterer can own them)
  const markerMapRef = useRef<Map<string, google.maps.Marker>>(new Map());
  const userMarkerRef = useRef<google.maps.Marker | null>(null);
  const createMarkerRef = useRef<google.maps.Marker | null>(null);
  const clustererRef = useRef<MarkerClusterer | null>(null);

  // Get user location
  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const p = { lat: pos.coords.latitude, lng: pos.coords.longitude };
          setUserPos(p);
          setCenter(p);
          updateLocation(p.lat, p.lng);
        },
        () => {},
        { enableHighAccuracy: true }
      );

      const watchId = navigator.geolocation.watchPosition(
        (pos) => {
          const p = { lat: pos.coords.latitude, lng: pos.coords.longitude };
          setUserPos(p);
          updateLocation(p.lat, p.lng);
        },
        () => {},
        { enableHighAccuracy: true }
      );

      return () => navigator.geolocation.clearWatch(watchId);
    }
  }, [updateLocation]);

  // Fetch alerts when map moves
  const fetchAlerts = useCallback(async (lat: number, lng: number, radius?: number) => {
    const key = `${lat.toFixed(4)},${lng.toFixed(4)}`;
    if (key === lastFetchRef.current) return;
    lastFetchRef.current = key;

    const r = radius || user?.alert_radius_m || 5000;
    const res = await api.get<{ alerts: Alert[] }>(`/alerts/nearby?lat=${lat}&lng=${lng}&radius=${r}`);
    if (!res.error && res.alerts) {
      setAlerts(res.alerts);
    }
  }, [user]);

  // Initial fetch
  useEffect(() => {
    if (userPos) {
      fetchAlerts(userPos.lat, userPos.lng);
    } else {
      fetchAlerts(center.lat, center.lng);
    }
  }, [userPos, center, fetchAlerts]);

  // WebSocket handlers
  useEffect(() => {
    const unsub1 = onNewAlert((alert) => {
      setAlerts(prev => {
        if (prev.find(a => a.id === alert.id)) return prev;
        return [alert, ...prev];
      });
    });
    const unsub2 = onAlertUpdated((data) => {
      setAlerts(prev => prev.map(a =>
        a.id === data.id ? { ...a, confirms: data.confirms, denies: data.denies } : a
      ));
    });
    const unsub3 = onAlertExpired((data) => {
      setAlerts(prev => prev.filter(a => a.id !== data.alert_id));
    });
    return () => { unsub1(); unsub2(); unsub3(); };
  }, [onNewAlert, onAlertUpdated, onAlertExpired]);

  const onMapLoad = useCallback((m: google.maps.Map) => setMap(m), []);

  const onIdle = useCallback(() => {
    if (map) {
      const c = map.getCenter();
      if (c) {
        fetchAlerts(c.lat(), c.lng());
      }
    }
  }, [map, fetchAlerts]);

  const handleMapClick = useCallback((e: google.maps.MapMouseEvent) => {
    if (e.latLng) {
      setCreatePos({ lat: e.latLng.lat(), lng: e.latLng.lng() });
      setShowCreate(true);
    }
  }, []);

  const filteredAlerts = useMemo(
    () => (categoryFilter.size > 0 ? alerts.filter(a => categoryFilter.has(a.category)) : alerts),
    [alerts, categoryFilter]
  );

  // Cluster renderer (custom navy/coral/mint cluster icons)
  const clusterRenderer = useMemo<Renderer>(() => ({
    render: ({ count, position }: Cluster) => {
      const g = window.google.maps;
      return new g.Marker({
        position,
        icon: gmapsClusterIcon(g, count),
        zIndex: 100 + count,
        // No label - the count is baked into the SVG
      });
    },
  }), []);

  // Tap a cluster -> zoom the map so all its markers fit comfortably on screen.
  // We compute the bounds from the cluster's own marker positions and add a
  // little padding so the pins land inside the viewport rather than at the edge.
  const handleClusterClick = useCallback(
    (
      _event: google.maps.MapMouseEvent,
      cluster: Cluster,
      mapInstance: google.maps.Map,
    ) => {
      const g = window.google.maps;
      const markers = cluster.markers ?? [];
      if (markers.length === 0) {
        if (cluster.position) mapInstance.panTo(cluster.position);
        return;
      }
      const bounds = new g.LatLngBounds();
      let pinned = 0;
      for (const m of markers) {
        const pos = (m as google.maps.Marker).getPosition?.();
        if (pos) { bounds.extend(pos); pinned += 1; }
      }
      if (pinned === 0) return;
      // All markers at the same point (e.g. duplicate report) -> just zoom in.
      if (bounds.getNorthEast().equals(bounds.getSouthWest())) {
        mapInstance.panTo(bounds.getCenter());
        mapInstance.setZoom(Math.min(18, (mapInstance.getZoom() ?? 14) + 2));
        return;
      }
      mapInstance.fitBounds(bounds, { top: 80, right: 60, bottom: 220, left: 60 });
    },
    [],
  );

  // Build/refresh the MarkerClusterer + alert markers when map or alerts change
  useEffect(() => {
    if (!map || !isLoaded) return;
    const g = window.google.maps;

    // Lazy-create clusterer once the map is ready
    if (!clustererRef.current) {
      clustererRef.current = new MarkerClusterer({
        map,
        renderer: clusterRenderer,
        onClusterClick: handleClusterClick,
      });
    }
    const clusterer = clustererRef.current;

    const existing = markerMapRef.current;
    const nextIds = new Set(filteredAlerts.map(a => a.id));

    // Remove markers no longer present
    const toRemove: google.maps.Marker[] = [];
    for (const [id, marker] of existing) {
      if (!nextIds.has(id)) {
        toRemove.push(marker);
        existing.delete(id);
      }
    }
    if (toRemove.length > 0) {
      clusterer.removeMarkers(toRemove, true);
      toRemove.forEach(m => m.setMap(null));
    }

    // Add new markers
    const toAdd: google.maps.Marker[] = [];
    for (const a of filteredAlerts) {
      if (existing.has(a.id)) continue;
      const cat = getCategoryInfo(a.category);
      const marker = new g.Marker({
        position: { lat: a.lat, lng: a.lng },
        icon: gmapsAlertIcon(g, {
          materialSymbol: cat.materialSymbol,
          variant: 'default',
        }),
        title: cat.label,
      });
      marker.addListener('click', () => setSelectedAlert(a));
      existing.set(a.id, marker);
      toAdd.push(marker);
    }
    if (toAdd.length > 0) {
      clusterer.addMarkers(toAdd, true);
    }

    clusterer.render();
  }, [map, isLoaded, filteredAlerts, clusterRenderer]);

  // Highlight the selected alert (selected variant) + drop confirmed badge when confirms outweigh denies
  useEffect(() => {
    if (!map || !isLoaded) return;
    const g = window.google.maps;
    for (const a of filteredAlerts) {
      const marker = markerMapRef.current.get(a.id);
      if (!marker) continue;
      const isSelected = selectedAlert?.id === a.id;
      const isConfirmed = a.confirms >= 3 && a.confirms > a.denies;
      const variant: 'default' | 'selected' | 'confirmed' = isSelected
        ? 'selected'
        : isConfirmed
          ? 'confirmed'
          : 'default';
      marker.setIcon(
        gmapsAlertIcon(g, {
          materialSymbol: getCategoryInfo(a.category).materialSymbol,
          variant,
        })
      );
      marker.setZIndex(isSelected ? 999 : isConfirmed ? 50 : 10);
    }
  }, [selectedAlert, filteredAlerts, map, isLoaded]);

  // Cleanup clusterer on unmount
  useEffect(() => {
    const markers = markerMapRef.current;
    return () => {
      if (clustererRef.current) {
        clustererRef.current.clearMarkers();
        clustererRef.current.setMap(null);
        clustererRef.current = null;
      }
      markers.clear();
    };
  }, []);

  // User position marker (imperative, so we can use the custom SVG)
  useEffect(() => {
    if (!map || !isLoaded) return;
    const g = window.google.maps;
    if (!userPos) {
      if (userMarkerRef.current) {
        userMarkerRef.current.setMap(null);
        userMarkerRef.current = null;
      }
      return;
    }
    if (!userMarkerRef.current) {
      userMarkerRef.current = new g.Marker({
        map,
        position: userPos,
        icon: gmapsUserPositionIcon(g),
        zIndex: 1000,
        clickable: false,
      });
    } else {
      userMarkerRef.current.setPosition(userPos);
    }
  }, [userPos, map, isLoaded]);

  // Draggable create-position marker
  useEffect(() => {
    if (!map || !isLoaded) return;
    const g = window.google.maps;
    if (!showCreate || !createPos) {
      if (createMarkerRef.current) {
        createMarkerRef.current.setMap(null);
        createMarkerRef.current = null;
      }
      return;
    }
    if (!createMarkerRef.current) {
      createMarkerRef.current = new g.Marker({
        map,
        position: createPos,
        // Reuse the SOS-styled pin to signal "you are placing an alert here"
        icon: gmapsSosIcon(g),
        zIndex: 998,
        draggable: true,
      });
      createMarkerRef.current.addListener('dragend', (e: google.maps.MapMouseEvent) => {
        if (e.latLng) setCreatePos({ lat: e.latLng.lat(), lng: e.latLng.lng() });
      });
    } else {
      createMarkerRef.current.setPosition(createPos);
    }
  }, [showCreate, createPos, map, isLoaded]);

  const toggleCategory = (cat: AlertCategory) => {
    setCategoryFilter(prev => {
      const next = new Set(prev);
      if (next.has(cat)) next.delete(cat);
      else next.add(cat);
      return next;
    });
  };

  if (!isLoaded) {
    return (
      <div className="h-full flex items-center justify-center">
        <div className="animate-pulse text-neutral-500">{t('loading')}</div>
      </div>
    );
  }

  return (
    <div className="h-full relative">
      <GoogleMap
        mapContainerStyle={containerStyle}
        center={center}
        zoom={DEFAULT_ZOOM}
        onLoad={onMapLoad}
        onIdle={onIdle}
        onClick={handleMapClick}
        options={{
          styles: resolvedTheme === 'dark' ? DARK_MAP_STYLES : LIGHT_MAP_STYLES,
          disableDefaultUI: true,
          zoomControl: true,
          zoomControlOptions: { position: 3 /* RIGHT_TOP */ },
          gestureHandling: 'greedy',
          clickableIcons: false,
        }}
      >
        {/* User position radius (the dot itself is an imperative marker, see useEffect above) */}
        {userPos && (
          <Circle
            center={userPos}
            radius={user?.alert_radius_m || 5000}
            options={{
              fillColor: SERENITY.aqua,
              fillOpacity: 0.06,
              strokeColor: SERENITY.aqua,
              strokeOpacity: 0.35,
              strokeWeight: 1,
            }}
          />
        )}

        {/* Selected alert info window */}
        {selectedAlert && (
          <InfoWindow
            position={{ lat: selectedAlert.lat, lng: selectedAlert.lng }}
            onCloseClick={() => setSelectedAlert(null)}
          >
            <div className="text-sm max-w-[240px]">
              <div className="flex items-center gap-2 mb-1">
                <span>{getCategoryInfo(selectedAlert.category).emoji}</span>
                <strong className="text-neutral-900">{selectedAlert.title}</strong>
              </div>
              <p className="text-neutral-600 text-xs mb-2">{selectedAlert.description}</p>
              <div className="flex items-center gap-3 text-xs text-neutral-500">
                <span>+{selectedAlert.confirms}</span>
                <span>-{selectedAlert.denies}</span>
              </div>
              <button
                onClick={() => {}}
                className="mt-2 text-xs text-red-500 font-medium hover:underline"
              >
                {t('details')} &rarr;
              </button>
            </div>
          </InfoWindow>
        )}
      </GoogleMap>

      {/* Category filter button */}
      <div className="absolute top-4 left-4 z-10 flex gap-2">
        <button
          onClick={() => setShowFilter(!showFilter)}
          className="flex items-center gap-2 px-4 py-2 rounded-xl bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 shadow-lg text-sm font-medium text-neutral-700 dark:text-neutral-300 hover:bg-neutral-50 dark:hover:bg-neutral-800 transition-colors"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" />
          </svg>
          {t('filter_categories')}
          {categoryFilter.size > 0 && (
            <span className="bg-red-500 text-white text-xs px-1.5 py-0.5 rounded-full">{categoryFilter.size}</span>
          )}
        </button>

        {/* Center on user */}
        {userPos && (
          <button
            onClick={() => { setCenter(userPos); map?.panTo(userPos); }}
            className="flex items-center justify-center w-10 h-10 rounded-xl bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 shadow-lg text-neutral-700 dark:text-neutral-300 hover:bg-neutral-50 dark:hover:bg-neutral-800 transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </button>
        )}
      </div>

      {/* Filter dropdown - now uses Serenity flat-circle markers as legend chips */}
      {showFilter && (
        <div className="absolute top-16 left-4 z-20 w-72 max-h-80 overflow-y-auto bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 rounded-xl shadow-xl p-3 space-y-1">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-neutral-900 dark:text-white">{t('filter_categories')}</span>
            {categoryFilter.size > 0 && (
              <button onClick={() => setCategoryFilter(new Set())} className="text-xs text-red-500 hover:underline">
                Clear
              </button>
            )}
          </div>
          {ALERT_CATEGORIES.map(cat => {
            const active = categoryFilter.has(cat.key);
            return (
              <button
                key={cat.key}
                onClick={() => toggleCategory(cat.key)}
                className={`flex items-center gap-3 w-full px-3 py-2 rounded-lg text-left text-sm transition-colors ${
                  active
                    ? 'bg-red-500/10 text-red-500'
                    : 'text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800'
                }`}
              >
                <span
                  className="inline-block w-7 h-7 flex-shrink-0"
                  style={{
                    backgroundImage: `url("data:image/svg+xml;utf8,${encodeURIComponent(
                      buildFlatCircleSvg(cat.materialSymbol, { size: 28, dimmed: !active && categoryFilter.size > 0 })
                    )}")`,
                    backgroundSize: 'contain',
                    backgroundRepeat: 'no-repeat',
                    backgroundPosition: 'center',
                  }}
                  aria-hidden="true"
                />
                <span>{cat.label}</span>
              </button>
            );
          })}
        </div>
      )}

      {/* Report button */}
      <button
        onClick={() => {
          const pos = userPos || center;
          setCreatePos(pos);
          setShowCreate(true);
        }}
        className="absolute bottom-6 right-6 lg:bottom-8 lg:right-8 z-10 flex items-center gap-2 px-5 py-3 rounded-2xl bg-red-500 text-white font-medium shadow-xl hover:bg-red-600 active:scale-95 transition-all"
      >
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
        </svg>
        {t('report')}
      </button>

      {/* SOS Button */}
      <SOSButton />

      {/* Create alert modal */}
      {showCreate && createPos && (
        <CreateAlertModal
          position={createPos}
          onClose={() => { setShowCreate(false); setCreatePos(null); }}
          onCreated={(alert) => {
            setAlerts(prev => [alert, ...prev]);
            setShowCreate(false);
            setCreatePos(null);
          }}
        />
      )}

      {/* Alert detail panel */}
      {selectedAlert && (
        <AlertDetail
          alert={selectedAlert}
          onClose={() => setSelectedAlert(null)}
          onUpdate={(updated) => {
            setAlerts(prev => prev.map(a => a.id === updated.id ? updated : a));
            setSelectedAlert(updated);
          }}
          onDelete={(id) => {
            setAlerts(prev => prev.filter(a => a.id !== id));
            setSelectedAlert(null);
          }}
        />
      )}
    </div>
  );
}
