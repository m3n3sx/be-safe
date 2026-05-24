'use client';

import React, { useEffect, useState } from 'react';
import api from '@/lib/api';

interface AED {
  id: string;
  lat: number;
  lng: number;
  address?: string | null;
  description?: string | null;
  distance_m: number;
}

export default function AEDPage() {
  const [aeds, setAeds] = useState<AED[]>([]);
  const [loading, setLoading] = useState(true);
  const [pos, setPos] = useState<{ lat: number; lng: number } | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!navigator.geolocation) {
      setError('Geolokalizacja niedostępna');
      setLoading(false);
      return;
    }
    navigator.geolocation.getCurrentPosition(
      async p => {
        setPos({ lat: p.coords.latitude, lng: p.coords.longitude });
        const r = await api.get(`/aeds/nearby?lat=${p.coords.latitude}&lng=${p.coords.longitude}&radius_m=5000&limit=20`);
        setAeds((r.aeds as AED[]) || []);
        setLoading(false);
      },
      () => {
        setError('Brak dostępu do lokalizacji. Pokażę przykładowy obszar Warszawy.');
        const w = { lat: 52.2297, lng: 21.0122 };
        setPos(w);
        api.get(`/aeds/nearby?lat=${w.lat}&lng=${w.lng}&radius_m=5000&limit=20`).then(r => {
          setAeds((r.aeds as AED[]) || []);
          setLoading(false);
        });
      },
      { enableHighAccuracy: true, timeout: 8000 }
    );
  }, []);

  const navigateTo = (a: AED) => {
    const url = `https://www.google.com/maps/dir/?api=1&destination=${a.lat},${a.lng}&travelmode=walking`;
    window.open(url, '_blank');
  };

  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-neutral-950 px-4 py-6 max-w-3xl mx-auto">
      <h1 className="text-2xl font-light text-neutral-900 dark:text-white mb-2">❤️ Najbliższe AED</h1>
      <p className="text-sm text-neutral-500 mb-6">Defibrylatory automatyczne w okolicy 5km</p>

      {error && (
        <div className="bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-200 rounded-xl p-3 text-sm mb-4">
          {error}
        </div>
      )}

      {loading && <p className="text-center text-neutral-500 py-12">Wyszukiwanie AED w okolicy...</p>}

      {!loading && aeds.length === 0 && (
        <div className="bg-white dark:bg-neutral-900 rounded-2xl p-8 text-center">
          <div className="text-5xl mb-3">❤️</div>
          <p className="text-neutral-600 dark:text-neutral-300">Nie znaleziono AED w odległości 5km.</p>
        </div>
      )}

      <div className="space-y-2">
        {aeds.map((a, i) => (
          <div key={a.id} className="bg-white dark:bg-neutral-900 rounded-2xl p-4 flex items-center gap-4">
            <div className="w-10 h-10 rounded-full bg-[#FF7A7A]/15 flex items-center justify-center text-[#FF7A7A] font-bold text-sm">
              #{i + 1}
            </div>
            <div className="flex-1 min-w-0">
              <h3 className="text-sm font-semibold text-neutral-900 dark:text-white truncate">
                {a.address || 'AED'}
              </h3>
              {a.description && (
                <p className="text-xs text-neutral-500 truncate">{a.description}</p>
              )}
              <p className="text-xs text-[#9DF4CB] mt-0.5 font-medium">
                📍 {Math.round(a.distance_m)} m
              </p>
            </div>
            <button
              onClick={() => navigateTo(a)}
              className="px-3 py-2 rounded-xl bg-[#1A2027] text-white text-xs font-semibold hover:opacity-90"
            >
              Trasa →
            </button>
          </div>
        ))}
      </div>

      <div className="mt-6 text-xs text-neutral-400 text-center">
        Dane: OpenAEDMap.org (16 600+ AED w Polsce)
      </div>
    </div>
  );
}
