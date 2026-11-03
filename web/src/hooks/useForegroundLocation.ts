'use client';
import { useEffect, useRef, useState } from 'react';
import type { Place } from '@/lib/location';
export function useForegroundLocation(enabled: boolean, onLocation: (point: Place) => Promise<void>) {
  const callback = useRef(onLocation);
  useEffect(() => { callback.current = onLocation; }, [onLocation]);
  const [error, setError] = useState('');
  const [last, setLast] = useState<Place | null>(null);
  useEffect(() => {
    if (!enabled) return;
    let watch: number | undefined; let stopped = false; let inFlight = false; let lastSent = 0;
    function stop() { if (watch !== undefined) navigator.geolocation?.clearWatch(watch); watch = undefined; }
    function start() {
      stop(); if (document.visibilityState !== 'visible') return;
      if (!navigator.geolocation) { setError('Ta przeglądarka nie obsługuje GPS.'); return; }
      watch = navigator.geolocation.watchPosition(async p => {
        if (stopped || document.visibilityState !== 'visible' || inFlight || Date.now() - lastSent < 20000) return;
        if (Date.now() - p.timestamp > 60000) { setError('Pozycja jest nieaktualna. Czekamy na nowy odczyt GPS.'); return; }
        const point = { lat: p.coords.latitude, lng: p.coords.longitude, accuracy: p.coords.accuracy, timestamp: p.timestamp, label: 'Moja lokalizacja' };
        inFlight = true; lastSent = Date.now();
        try { await callback.current(point); if (!stopped) { setLast(point); setError(''); } }
        catch { if (!stopped) setError('Nie wysłano lokalizacji. Sprawdź połączenie; kolejny odczyt zostanie wysłany, gdy strona jest widoczna.'); }
        finally { inFlight = false; }
      }, () => setError('Nie można odczytać GPS. Sprawdź uprawnienia lokalizacji.'), { enableHighAccuracy: true, maximumAge: 0, timeout: 15000 });
    }
    const initial = setTimeout(start, 0); document.addEventListener('visibilitychange', start);
    return () => { stopped = true; clearTimeout(initial); stop(); document.removeEventListener('visibilitychange', start); };
  }, [enabled]);
  return { error, last };
}
