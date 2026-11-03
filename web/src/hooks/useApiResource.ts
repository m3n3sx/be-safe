'use client';
import { useCallback, useEffect, useRef, useState } from 'react';
import api from '@/lib/api';
export function apiError(result: { error?: string; httpStatus?: number }) {
  if (result.httpStatus === 403) return 'Nie masz uprawnień do tej operacji.';
  if (result.httpStatus === 404) return 'Nie znaleziono danych lub nie są już dostępne.';
  if (result.httpStatus === 409) return 'Ta operacja została już wykonana. Odśwież dane.';
  if (result.httpStatus === 429) return 'Zbyt wiele prób. Poczekaj chwilę przed ponowieniem.';
  if (result.httpStatus === 0)
    return 'Brak odpowiedzi serwera. Sprawdź połączenie i odśwież dane przed ponowną wysyłką.';
  return 'Nie udało się wykonać operacji. Sprawdź dane i spróbuj ponownie.';
}
export function useApiResource<T>(path: string | null, pollMs = 0) {
  const [state, setState] = useState<{
    path: string | null;
    data: T | null;
    loading: boolean;
    error: string;
  }>({ path, data: null, loading: !!path, error: '' });
  const generationRef = useRef({ version: 0 });
  const reload = useCallback(async () => {
    if (!path) return;
    const generation = generationRef.current;
    const current = ++generation.version;
    setState((old) => ({ ...old, loading: !old.data, error: '' }));
    const result = await api.get<T>(path);
    if (generation.version !== current) return;
    setState((old) => ({
      path,
      data: result.error ? (old.path === path ? old.data : null) : result,
      loading: false,
      error: result.error ? apiError(result) : '',
    }));
  }, [path]);
  useEffect(() => {
    const generation = generationRef.current;
    const initial = setTimeout(() => void reload(), 0);
    const poll = pollMs
      ? setInterval(() => {
          if (document.visibilityState === 'visible') void reload();
        }, pollMs)
      : undefined;
    return () => {
      ++generation.version;
      clearTimeout(initial);
      clearInterval(poll);
    };
  }, [reload, pollMs]);
  return {
    data: state.path === path ? state.data : null,
    loading: !!path && (state.path !== path || state.loading),
    error: state.path === path ? state.error : '',
    reload,
  };
}
export function useMutation() {
  const lock = useRef(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const run = async <T extends { error?: string; httpStatus?: number }>(
    operation: () => Promise<T>,
    done?: (result: T) => void | Promise<void>,
  ) => {
    if (lock.current) return;
    lock.current = true;
    setBusy(true);
    setError('');
    try {
      const result = await operation();
      if (result.error) setError(apiError(result));
      else await done?.(result);
    } catch {
      setError('Nie udało się wykonać operacji. Odśwież dane przed ponowną próbą.');
    } finally {
      lock.current = false;
      setBusy(false);
    }
  };
  return { busy, error, run, setError };
}
