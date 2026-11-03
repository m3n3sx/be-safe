'use client';
import { useCallback, useEffect, useState } from 'react';
import api from '@/lib/api';
import { useApiResource, useMutation } from '@/hooks/useApiResource';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { ErrorState } from '@/components/ui/ErrorState';
import { Skeleton } from '@/components/ui/Skeleton';
import { Icon } from '@/components/ui/Icon';

const permissions = [
  [
    'location',
    'geolocation',
    'Lokalizacja',
    'Pozwala wybrać okolicę i świadomie udostępniać pozycję.',
  ],
  [
    'notifications',
    'notifications',
    'Powiadomienia',
    'Komunikaty w otwartej aplikacji, bez gwarancji działania w tle.',
  ],
  ['camera', 'camera', 'Kamera', 'Dodawanie zdjęć do zgłoszeń.'],
  ['microphone', 'microphone', 'Mikrofon', 'Dobrowolne nagranie przy SOS, przechowywane lokalnie.'],
] as const;
const labels: Record<string, string> = {
  granted: 'Dozwolone',
  denied: 'Zablokowane',
  prompt: 'Zapytaj przy użyciu',
  unknown: 'Brak odczytu stanu',
  unsupported: 'Niedostępne',
};
export default function PermissionsPage() {
  const account = useApiResource<{ capabilities: Record<string, boolean> }>('/permissions');
  const mutation = useMutation();
  const [status, setStatus] = useState<Record<string, string>>({});
  const [error, setError] = useState('');
  const [busy, setBusy] = useState('');
  const check = useCallback(async () => {
    const next: Record<string, string> = {};
    for (const [, name] of permissions) {
      const supported =
        name === 'geolocation'
          ? !!navigator.geolocation
          : name === 'notifications'
            ? 'Notification' in window
            : !!navigator.mediaDevices?.getUserMedia;
      if (!supported) {
        next[name] = 'unsupported';
        continue;
      }
      try {
        next[name] =
          name === 'notifications'
            ? Notification.permission === 'default'
              ? 'prompt'
              : Notification.permission
            : (await navigator.permissions.query({ name: name as PermissionName })).state;
      } catch {
        next[name] = 'unknown';
      }
    }
    setStatus(next);
  }, []);
  useEffect(() => {
    const timer = setTimeout(() => void check(), 0);
    window.addEventListener('focus', check);
    return () => {
      clearTimeout(timer);
      window.removeEventListener('focus', check);
    };
  }, [check]);
  async function request(name: string) {
    setError('');
    setBusy(name);
    try {
      if (name === 'geolocation')
        await new Promise((resolve, reject) =>
          navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 10000 }),
        );
      else if (name === 'notifications') await Notification.requestPermission();
      else {
        const stream = await navigator.mediaDevices.getUserMedia(
          name === 'camera' ? { video: true } : { audio: true },
        );
        stream.getTracks().forEach((track) => track.stop());
      }
    } catch {
      setError('Nie uzyskano dostępu. Sprawdź ustawienia tej witryny w przeglądarce.');
    }
    await check();
    setBusy('');
  }
  return (
    <div className="form-container space-y-4">
      <PageHeader
        title="Uprawnienia i zgody"
        description="Zgoda na koncie i dostęp na tym urządzeniu to dwa osobne ustawienia. Cofnięcie zgody nie zmienia uprawnień przeglądarki."
      />
      {account.loading && <Skeleton />}
      {account.error && <ErrorState message={account.error} onRetry={account.reload} />}
      {(error || mutation.error) && <ErrorState message={error || mutation.error} />}
      {permissions.map(([capability, name, label, description]) => (
        <section key={name} className="panel space-y-3">
          <div className="flex gap-3 items-center">
            <Icon name="shield" />
            <h2 className="text-xl font-bold">{label}</h2>
          </div>
          <p>{description}</p>
          <p className="text-sm text-ink-2">
            Przeglądarka: {labels[status[name]] || 'Sprawdzanie…'}
          </p>
          <Button
            variant="secondary"
            disabled={!!busy || ['unsupported', 'denied', 'granted'].includes(status[name])}
            loading={busy === name}
            onClick={() => void request(name)}
          >
            Poproś o dostęp: {label.toLocaleLowerCase('pl-PL')}
          </Button>
          {status[name] === 'denied' && (
            <p className="text-sm">Odblokuj dostęp w ustawieniach witryny w przeglądarce.</p>
          )}
          <label className="flex items-center gap-3 min-h-12">
            <input
              className="size-5"
              type="checkbox"
              disabled={!account.data || mutation.busy}
              checked={account.data?.capabilities?.[capability] === true}
              onChange={(e) =>
                void mutation.run(
                  () => api.put('/permissions', { capability, granted: e.target.checked }),
                  account.reload,
                )
              }
            />
            Zgoda zapisana na koncie: {label.toLocaleLowerCase('pl-PL')}
          </label>
        </section>
      ))}
      <section className="panel">
        <h2 className="font-bold mb-2">Blokada i czujniki</h2>
        <p>
          Ta wersja korzysta z hasła lub logowania Google. Nie wykrywa upadków ani potrząśnięcia.
          SOS pozostaje dostępne w górnym pasku; do ochrony urządzenia użyj jego blokady ekranu.
        </p>
      </section>
    </div>
  );
}
