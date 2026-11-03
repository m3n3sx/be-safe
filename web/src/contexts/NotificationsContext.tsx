'use client';
import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react';
import api from '@/lib/api';
import { useAuth } from './AuthContext';
const Context = createContext({ unread: 0, refresh: async () => {} });
export function NotificationsProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth(); const [count, setCount] = useState({ userId: '', value: 0 });
  const refresh = useCallback(async () => {
    if (!user) return;
    const result = await api.get<{ count: number }>('/notifications/unread-count');
    if (!result.error) setCount({ userId: user.id, value: result.count || 0 });
  }, [user]);
  useEffect(() => { const initial = setTimeout(() => void refresh(), 0); const timer = setInterval(() => { if (document.visibilityState === 'visible') void refresh(); }, 60000); return () => { clearTimeout(initial); clearInterval(timer); }; }, [refresh]);
  return <Context.Provider value={{ unread: user?.id === count.userId ? count.value : 0, refresh }}>{children}</Context.Provider>;
}
export const useNotifications = () => useContext(Context);
