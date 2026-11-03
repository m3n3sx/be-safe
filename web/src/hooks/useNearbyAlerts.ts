'use client';
import { useEffect, useState } from 'react';
import { alertsApi } from '@/lib/api/alerts';
import type { Point } from '@/lib/location';
import type { Alert } from '@/types';
import { asArray } from '@/lib/api';
export function useNearbyAlerts(point: Point | null, radius: number, revision: number) {
  const key = point ? `${point.lat},${point.lng},${radius}` : '';
  const [state, setState] = useState<{
    key: string;
    revision: number;
    alerts: Alert[];
    error: string;
    updated: string;
  }>({ key: '', revision: -1, alerts: [], error: '', updated: '' });
  const lat = point?.lat;
  const lng = point?.lng;
  useEffect(() => {
    if (lat === undefined || lng === undefined) return;
    let alive = true;
    alertsApi.nearby({ lat, lng }, radius).then((result) => {
      if (!alive) return;
      setState((previous) =>
        result.error
          ? {
              ...previous,
              key,
              revision,
              alerts: previous.key === key ? previous.alerts : [],
              error: 'Nie udało się odświeżyć zgłoszeń. Sprawdź połączenie.',
            }
          : {
              key,
              revision,
              alerts: asArray(result.alerts),
              error: '',
              updated: new Date().toLocaleTimeString('pl-PL', {
                hour: '2-digit',
                minute: '2-digit',
              }),
            },
      );
    });
    return () => {
      alive = false;
    };
  }, [lat, lng, radius, revision, key]);
  return {
    alerts: state.key === key ? state.alerts : [],
    error: state.key === key ? state.error : '',
    loading: !!point && (state.key !== key || state.revision !== revision),
    updated: state.key === key ? state.updated : '',
  };
}
