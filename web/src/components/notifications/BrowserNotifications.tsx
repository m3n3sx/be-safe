'use client';
import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/Button';
export function BrowserNotifications() {
  const [permission, setPermission] = useState<NotificationPermission | 'unsupported' | 'loading'>(
    'loading',
  );
  const [enabled, setEnabled] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  useEffect(() => {
    const timer = setTimeout(() => {
      setPermission('Notification' in window ? Notification.permission : 'unsupported');
      try {
        setEnabled(
          localStorage.getItem('besafe.browser-notifications') === 'enabled' &&
            'Notification' in window &&
            Notification.permission === 'granted',
        );
      } catch {}
    }, 0);
    return () => clearTimeout(timer);
  }, []);
  async function change() {
    if (!('Notification' in window)) return;
    setError('');
    setBusy(true);
    try {
      if (enabled) {
        localStorage.removeItem('besafe.browser-notifications');
        setEnabled(false);
        return;
      }
      const result = await Notification.requestPermission();
      setPermission(result);
      if (result === 'granted') {
        localStorage.setItem('besafe.browser-notifications', 'enabled');
        setEnabled(true);
      }
    } catch {
      setError('Nie udało się włączyć powiadomień. Skrzynka w aplikacji nadal działa.');
    } finally {
      setBusy(false);
    }
  }
  return (
    <section className="panel space-y-3">
      <h2 className="font-bold">Powiadomienia przeglądarki</h2>
      <p className="text-ink-2">
        {permission === 'unsupported'
          ? 'Ta przeglądarka nie obsługuje powiadomień. Skrzynka w aplikacji nadal działa.'
          : permission === 'denied'
            ? 'Powiadomienia zablokowane. Zgodę możesz zmienić w ustawieniach przeglądarki.'
            : 'Opcjonalne powiadomienia o nowych zdarzeniach podczas otwartej aplikacji.'}
      </p>
      <Button
        variant="secondary"
        disabled={
          permission === 'unsupported' || permission === 'loading' || permission === 'denied'
        }
        loading={busy}
        onClick={change}
      >
        {enabled ? 'Wyłącz na tym urządzeniu' : 'Włącz powiadomienia'}
      </Button>
      {error && (
        <p role="alert" className="text-danger">
          {error}
        </p>
      )}
    </section>
  );
}
