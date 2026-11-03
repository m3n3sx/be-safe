'use client';
import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { useJsApiLoader } from '@react-google-maps/api';
import { GOOGLE_MAPS_API_KEY } from '@/lib/constants';
const Context = createContext({ ready: false, failed: false, configured: false });
function Loader({ children }: { children: ReactNode }) {
  const { isLoaded, loadError } = useJsApiLoader({
    id: 'besafe-google-map',
    googleMapsApiKey: GOOGLE_MAPS_API_KEY,
    language: 'pl',
    region: 'PL',
  });
  const [failed, setFailed] = useState(false);
  useEffect(() => {
    const timer = setTimeout(() => {
      if (!isLoaded) setFailed(true);
    }, 15000);
    const global = window as typeof window & { gm_authFailure?: () => void };
    const previous = global.gm_authFailure;
    global.gm_authFailure = () => setFailed(true);
    return () => {
      clearTimeout(timer);
      global.gm_authFailure = previous;
    };
  }, [isLoaded]);
  return (
    <Context.Provider
      value={{
        ready: isLoaded && !failed && !loadError,
        failed: failed || !!loadError,
        configured: true,
      }}
    >
      {children}
    </Context.Provider>
  );
}
export function MapProvider({ children }: { children: ReactNode }) {
  return GOOGLE_MAPS_API_KEY ? (
    <Loader>{children}</Loader>
  ) : (
    <Context.Provider value={{ ready: false, failed: true, configured: false }}>
      {children}
    </Context.Provider>
  );
}
export const useMapStatus = () => useContext(Context);
