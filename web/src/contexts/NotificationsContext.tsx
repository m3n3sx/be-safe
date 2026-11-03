'use client';
import { asArray } from '@/lib/api';
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import { useAuth } from './AuthContext';
import { useSocket } from './SocketContext';
import { useApiResource } from '@/hooks/useApiResource';
import type { InboxItem } from '@/lib/notification-routes';
type State = {
  unread: number;
  items: InboxItem[];
  sessionItems: InboxItem[];
  loading: boolean;
  error: string;
  refresh: () => Promise<void>;
  clearSession: () => void;
  markSessionRead: () => void;
};
const Context = createContext<State>({
  unread: 0,
  items: [],
  sessionItems: [],
  loading: false,
  error: '',
  refresh: async () => {},
  clearSession: () => {},
  markSessionRead: () => {},
});
function StateProvider({ userId, children }: { userId?: string; children: ReactNode }) {
  const inbox = useApiResource<{ notifications: InboxItem[] }>(
    userId ? '/notifications?limit=100' : null,
    30000,
  );
  const count = useApiResource<{ count: number }>(
    userId ? '/notifications/unread-count' : null,
    30000,
  );
  const [sessionItems, setSessionItems] = useState<InboxItem[]>([]);
  const { onEvent } = useSocket();
  const inboxReload = inbox.reload,
    countReload = count.reload;
  const refresh = useCallback(async () => {
    await Promise.all([inboxReload(), countReload()]);
  }, [inboxReload, countReload]);
  const seen = useRef(new Set<string>());
  useEffect(() => {
    if (!userId) return;
    let timer: ReturnType<typeof setTimeout> | undefined;
    const events = [
      'alert:new',
      'family:ping',
      'family:ping_response',
      'family:message',
      'family:checkin',
      'family:geofence_exit',
      'family:low_battery',
      'escort:started',
      'escort:completed',
      'escort:cancelled',
      'escort:panic',
    ];
    const off = events.map((event) =>
      onEvent(event, (data) => {
        if (!data || typeof data !== 'object' || Array.isArray(data)) return;
        clearTimeout(timer);
        timer = setTimeout(() => void refresh(), 1000);
        const key = `${event}:${data.id || data.ping_id || data.escort_id || data.user_id || ''}:${data.sent_at || data.created_at || data.status || ''}`;
        if (seen.current.has(key)) return;
        seen.current.add(key);
        const title =
          event === 'alert:new'
            ? 'Nowe zgłoszenie w be:Safe'
            : event.startsWith('escort:')
              ? 'Aktualizacja bezpiecznego powrotu'
              : 'Wiadomość od bliskich';
        if (
          ['alert:new', 'family:checkin', 'family:geofence_exit', 'escort:cancelled'].includes(
            event,
          )
        ) {
          const item: InboxItem = {
            id: key,
            title,
            body:
              typeof data.title === 'string'
                ? data.title
                : event === 'family:checkin'
                  ? `${data.username || 'Bliska osoba'} przesłała meldunek.`
                  : event === 'escort:cancelled'
                    ? 'Sesja powrotu została anulowana.'
                    : `${data.username || 'Bliska osoba'} opuściła strefę ${data.geofence_name || ''}.`,
            type: event.replace(':', '_'),
            is_read: false,
            created_at: new Date().toISOString(),
            data: { ...data, ...(event === 'alert:new' ? { alert_id: data.id } : {}) },
          };
          setSessionItems((old) => [item, ...old].slice(0, 100));
        }
        try {
          if (
            'Notification' in window &&
            Notification.permission === 'granted' &&
            localStorage.getItem('besafe.browser-notifications') === 'enabled' &&
            localStorage.getItem(
              event === 'alert:new' ? 'besafe.notif.alerts' : 'besafe.notif.family',
            ) !== '0'
          ) {
            const notification = new Notification(title, {
              body: 'Otwórz centrum powiadomień w be:Safe.',
              tag: key,
              silent: localStorage.getItem('besafe.notif.sound') === '0',
            });
            if (
              document.visibilityState === 'visible' &&
              localStorage.getItem('besafe.notif.vibration') !== '0'
            )
              navigator.vibrate?.(150);
            notification.onclick = () => {
              window.focus();
              window.location.assign('/notifications');
              notification.close();
            };
          }
        } catch {
          /* In-app inbox remains available. */
        }
      }),
    );
    const visible = () => {
      if (document.visibilityState === 'visible') void refresh();
    };
    document.addEventListener('visibilitychange', visible);
    return () => {
      clearTimeout(timer);
      off.forEach((fn) => fn());
      document.removeEventListener('visibilitychange', visible);
    };
  }, [userId, onEvent, refresh]);
  const items = asArray(inbox.data?.notifications);
  const local = sessionItems.filter(
    (item) =>
      !items.some((saved) => item.data?.alert_id && saved.data?.alert_id === item.data.alert_id),
  );
  return (
    <Context.Provider
      value={{
        unread: (Number(count.data?.count) || 0) + local.filter((i) => !i.is_read).length,
        items,
        sessionItems: local,
        loading: inbox.loading,
        error: inbox.error || count.error,
        refresh,
        clearSession: () => setSessionItems([]),
        markSessionRead: () => setSessionItems((old) => old.map((i) => ({ ...i, is_read: true }))),
      }}
    >
      {children}
    </Context.Provider>
  );
}
export function NotificationsProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  return (
    <StateProvider key={user?.id || 'guest'} userId={user?.id}>
      {children}
    </StateProvider>
  );
}
export const useNotifications = () => useContext(Context);
