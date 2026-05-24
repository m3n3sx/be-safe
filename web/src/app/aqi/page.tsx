'use client';

import React, { useEffect, useState } from 'react';
import api from '@/lib/api';

interface Station {
  id: number;
  name: string;
  city?: string | null;
  address?: string | null;
  lat: number;
  lng: number;
  distance_m: number;
  aqi_index?: number | null;
  aqi_label?: string | null;
  pm10?: number | null;
  pm25?: number | null;
  no2?: number | null;
  so2?: number | null;
  o3?: number | null;
  measured_at?: string | null;
}

function aqiColor(idx: number | null | undefined): { bg: string; text: string; label: string } {
  if (idx === null || idx === undefined || idx < 0) return { bg: 'bg-neutral-400', text: 'text-white', label: 'Brak danych' };
  if (idx === 0) return { bg: 'bg-[#9DF4CB]', text: 'text-[#1A2027]', label: 'Bardzo dobry' };
  if (idx === 1) return { bg: 'bg-green-400', text: 'text-white', label: 'Dobry' };
  if (idx === 2) return { bg: 'bg-yellow-400', text: 'text-[#1A2027]', label: 'Umiarkowany' };
  if (idx === 3) return { bg: 'bg-orange-500', text: 'text-white', label: 'Dostateczny' };
  if (idx === 4) return { bg: 'bg-red-500', text: 'text-white', label: 'Zły' };
  if (idx >= 5) return { bg: 'bg-purple-700', text: 'text-white', label: 'Bardzo zły' };
  return { bg: 'bg-neutral-400', text: 'text-white', label: 'Brak danych' };
}

export default function AQIPage() {
  const [stations, setStations] = useState<Station[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!navigator.geolocation) {
      setError('Geolokalizacja niedostępna');
      setLoading(false);
      return;
    }
    navigator.geolocation.getCurrentPosition(
      async p => {
        const r = await api.get(`/aqi/nearby?lat=${p.coords.latitude}&lng=${p.coords.longitude}&radius_m=50000&limit=5`);
        setStations((r.stations as Station[]) || []);
        setLoading(false);
      },
      () => {
        setError('Brak dostępu do lokalizacji. Pokażę okolice Warszawy.');
        api.get('/aqi/nearby?lat=52.2297&lng=21.0122&radius_m=50000&limit=5').then(r => {
          setStations((r.stations as Station[]) || []);
          setLoading(false);
        });
      },
      { enableHighAccuracy: true, timeout: 8000 }
    );
  }, []);

  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-neutral-950 px-4 py-6 max-w-3xl mx-auto">
      <h1 className="text-2xl font-light text-neutral-900 dark:text-white mb-2">💨 Jakość powietrza</h1>
      <p className="text-sm text-neutral-500 mb-6">Najbliższe stacje GIOŚ</p>

      {error && (
        <div className="bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-200 rounded-xl p-3 text-sm mb-4">
          {error}
        </div>
      )}

      {loading && <p className="text-center text-neutral-500 py-12">Ładowanie stacji...</p>}

      <div className="space-y-3">
        {stations.map(s => {
          const c = aqiColor(s.aqi_index);
          return (
            <div key={s.id} className="bg-white dark:bg-neutral-900 rounded-2xl overflow-hidden">
              <div className={`${c.bg} ${c.text} px-4 py-3 flex items-center justify-between`}>
                <div>
                  <div className="font-semibold">{s.name}</div>
                  <div className="text-xs opacity-90">{s.city} · {Math.round(s.distance_m / 1000)} km</div>
                </div>
                <div className="text-right">
                  <div className="text-2xl font-light">{s.aqi_label || c.label}</div>
                  {s.aqi_index !== null && s.aqi_index !== undefined && s.aqi_index >= 0 && (
                    <div className="text-xs opacity-90">Index {s.aqi_index}/5</div>
                  )}
                </div>
              </div>
              <div className="px-4 py-3 grid grid-cols-3 gap-3 text-xs">
                <Metric label="PM10" value={s.pm10} unit="μg/m³" />
                <Metric label="PM2.5" value={s.pm25} unit="μg/m³" />
                <Metric label="NO₂" value={s.no2} unit="μg/m³" />
              </div>
              {s.measured_at && (
                <div className="px-4 pb-3 text-[10px] text-neutral-400">
                  Pomiar: {new Date(s.measured_at).toLocaleString('pl-PL')}
                </div>
              )}
            </div>
          );
        })}
      </div>

      <div className="mt-6 text-xs text-neutral-400 text-center">
        Dane: Główny Inspektorat Ochrony Środowiska (GIOŚ)
      </div>
    </div>
  );
}

function Metric({ label, value, unit }: { label: string; value: number | null | undefined; unit: string }) {
  return (
    <div>
      <div className="text-neutral-500">{label}</div>
      <div className="text-neutral-900 dark:text-white font-semibold">
        {value !== null && value !== undefined ? Math.round(value) : '—'}
        {value !== null && value !== undefined && <span className="text-[10px] text-neutral-400 ml-1">{unit}</span>}
      </div>
    </div>
  );
}
