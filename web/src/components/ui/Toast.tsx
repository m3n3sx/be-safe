'use client';
import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react';
import { IconButton } from './IconButton';
const ToastContext = createContext<(message: string) => void>(() => {});
export function ToastProvider({ children }: { children: ReactNode }) {
  const [message, setMessage] = useState('');
  const show = useCallback((text: string) => setMessage(text), []);
  useEffect(() => {
    if (!message) return;
    const timer = setTimeout(() => setMessage(''), 6000);
    return () => clearTimeout(timer);
  }, [message]);
  return (
    <ToastContext.Provider value={show}>
      {children}
      <div
        role="status"
        aria-live="polite"
        className="fixed z-50 bottom-28 lg:bottom-6 left-4 right-4 pointer-events-none"
      >
        {message && (
          <div className="panel mx-auto max-w-lg flex items-center gap-3 pointer-events-auto">
            <p className="flex-1">{message}</p>
            <IconButton label="Zamknij komunikat" onClick={() => setMessage('')}>
              ✕
            </IconButton>
          </div>
        )}
      </div>
    </ToastContext.Provider>
  );
}
export const useToast = () => useContext(ToastContext);
