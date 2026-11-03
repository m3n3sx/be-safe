'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';

type ThemeMode = 'dark' | 'light' | 'system';

interface ThemeContextType {
  theme: ThemeMode;
  resolvedTheme: 'dark' | 'light';
  setTheme: (t: ThemeMode) => void;
}

const ThemeContext = createContext<ThemeContextType | null>(null);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setThemeState] = useState<ThemeMode>('system');
  const [systemDark, setSystemDark] = useState(false);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    for (const key of ['large-text', 'reduced-motion']) {
      document.documentElement.classList.toggle(key, localStorage.getItem(`besafe.${key}`) === '1');
    }
    const stored = localStorage.getItem('theme_mode') as ThemeMode | null;
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    const timer = setTimeout(() => {
      if (stored === 'light' || stored === 'dark' || stored === 'system') setThemeState(stored);
      setSystemDark(mq.matches);
      setReady(true);
    }, 0);
    const handler = (e: MediaQueryListEvent) => setSystemDark(e.matches);
    mq.addEventListener('change', handler);
    return () => {
      clearTimeout(timer);
      mq.removeEventListener('change', handler);
    };
  }, []);

  const resolvedTheme = theme === 'system' ? (systemDark ? 'dark' : 'light') : theme;

  useEffect(() => {
    if (ready) document.documentElement.classList.toggle('dark', resolvedTheme === 'dark');
  }, [resolvedTheme, ready]);

  const setTheme = (t: ThemeMode) => {
    setThemeState(t);
    localStorage.setItem('theme_mode', t);
  };

  return (
    <ThemeContext.Provider value={{ theme, resolvedTheme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used within ThemeProvider');
  return ctx;
}
