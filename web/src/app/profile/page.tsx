'use client';
import { useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useTheme } from '@/contexts/ThemeContext';
import api from '@/lib/api';
import { PageHeader } from '@/components/layout/PageHeader';
import { HubSection } from '@/components/layout/HubSection';
import { useAdminAccess } from '@/hooks/useAdminAccess';
import { useApiResource } from '@/hooks/useApiResource';
import { asArray } from '@/lib/api';
import type { Alert } from '@/types';
import { CheckinAction } from '@/components/family/CheckinAction';
import { Button } from '@/components/ui/Button';
import { TextField, Select } from '@/components/ui/FormField';
import { ErrorState } from '@/components/ui/ErrorState';
export default function ProfilePage() {
  const { user, logout } = useAuth();
  const { theme, setTheme } = useTheme();
  const access = useAdminAccess();
  const activity = useApiResource<{ alerts: Alert[] }>('/alerts/mine');
  const alerts = asArray(activity.data?.alerts);
  const [share, setShare] = useState<{ url: string; expires_at: string } | null>(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  async function shareLocation() {
    setBusy(true);
    setError('');
    const res = await api.post<{ url: string; expires_at: string }>('/users/me/share-location', {
      hours: 1,
    });
    if (res.error || !res.url) setError('Nie udało się utworzyć linku lokalizacji.');
    else setShare(res);
    setBusy(false);
  }
  return (
    <div className="page-container">
      <PageHeader title="Profil" description={`${user?.username || ''} · ${user?.email || ''}`}>
        <Button variant="secondary" onClick={logout}>
          Wyloguj się
        </Button>
      </PageHeader>
      <section className="panel mb-6">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-full bg-surface-2 text-primary grid place-items-center text-2xl font-bold overflow-hidden shrink-0">
            {user?.avatar_url ? (
              <img src={user.avatar_url} alt="" className="w-full h-full object-cover" />
            ) : (
              user?.username?.slice(0, 2).toLocaleUpperCase('pl-PL') || '?'
            )}
          </div>
          <div>
            <h2 className="text-xl font-bold">{user?.username || 'Twoje konto'}</h2>
            <p className="text-ink-2">Reputacja: {user?.reputation_score ?? 'Brak danych'}</p>
          </div>
        </div>
        <dl className="grid grid-cols-3 gap-3 mt-5 border-t border-border pt-4 text-sm">
          <div>
            <dt>Zgłoszenia</dt>
            <dd className="text-xl font-bold">{activity.data ? alerts.length : '—'}</dd>
          </div>
          <div>
            <dt>Aktywne</dt>
            <dd className="text-xl font-bold">
              {activity.data ? alerts.filter((a) => a.status === 'active').length : '—'}
            </dd>
          </div>
          <div>
            <dt>Potwierdzenia zgłoszeń</dt>
            <dd className="text-xl font-bold">
              {activity.data ? alerts.reduce((sum, a) => sum + (Number(a.confirms) || 0), 0) : '—'}
            </dd>
          </div>
        </dl>
        {activity.error && <ErrorState message={activity.error} onRetry={activity.reload} />}
      </section>
      <HubSection
        title="Moja aktywność"
        entries={[
          [
            '/alerts/mine',
            'Moje zgłoszenia',
            'Sprawdź, edytuj lub zakończ swoje zgłoszenia.',
            'pin',
          ],
          ['/badges', 'Odznaki', 'Zobacz osiągnięcia za pomoc innym.', 'heart'],
        ]}
      />
      <section className="panel mb-6 space-y-4">
        <h2 className="text-xl font-bold">Bezpieczeństwo i prywatność</h2>
        <p className="text-ink-2">
          Promień powiadomień: {((user?.alert_radius_m || 0) / 1000).toLocaleString('pl-PL')} km.
          Zmienisz go w ustawieniach.
        </p>
        <Button onClick={shareLocation} loading={busy} variant="secondary">
          Udostępnij lokalizację na godzinę
        </Button>
        {error && <ErrorState message={error} />}
        {share && (
          <TextField
            label="Link lokalizacji do skopiowania"
            readOnly
            value={share.url}
            onFocus={(event) => event.target.select()}
            hint={`Ważny do ${new Date(share.expires_at).toLocaleString('pl-PL')}`}
          />
        )}
        <Select
          label="Wygląd na tym urządzeniu"
          value={theme}
          onChange={(event) => setTheme(event.target.value as 'light' | 'dark' | 'system')}
        >
          <option value="system">Zgodnie z urządzeniem</option>
          <option value="light">Jasny</option>
          <option value="dark">Ciemny</option>
        </Select>
      </section>
      <CheckinAction />
      <HubSection
        title="Ustawienia aplikacji"
        entries={[
          ['/settings', 'Ustawienia', 'Konto, powiadomienia, prywatność i czytelność.', 'settings'],
          ['/mode', 'Widok aplikacji', 'Wybierz standardowy lub uproszczony widok.', 'people'],
          [
            '/permissions',
            'Uprawnienia',
            'Sprawdź dostęp do lokalizacji, kamery i mikrofonu.',
            'shield',
          ],
          [
            '/onboarding',
            'Pierwsze kroki',
            'Poznaj aplikację i skonfiguruj ją po swojemu.',
            'book',
          ],
        ]}
      />
      <HubSection
        title="Społeczność"
        entries={[
          ['/ranking', 'Ranking', 'Poznaj osoby aktywnie pomagające w okolicy.', 'people'],
          ['/referral', 'Zaproś znajomych', 'Skopiuj swój kod lub wyślij zaproszenie.', 'heart'],
          ['/news', 'Aktualności', 'Przeczytaj wiadomości od be:Safe.', 'book'],
          ['/stats', 'Statystyki okolicy', 'Zobacz liczbę i rodzaje zgłoszeń.', 'pin'],
          ['/neighborhood', 'Rozmowy sąsiedzkie', 'Porozmawiaj z osobami w pobliżu.', 'people'],
        ]}
      />
      <HubSection
        title="Informacje"
        entries={[
          ['/privacy', 'Polityka prywatności', 'Dowiedz się, jak przetwarzamy dane.', 'shield'],
          ['/terms', 'Regulamin', 'Poznaj zasady korzystania z be:Safe.', 'book'],
          [
            '/verify-email',
            'Potwierdź adres e-mail',
            'Sprawdź lub ponów weryfikację konta.',
            'check',
          ],
          ['/landing', 'O aplikacji', 'Dowiedz się więcej i pobierz wersję na Androida.', 'heart'],
        ]}
      />
      {access.isAdmin && (
        <HubSection
          title="Administracja"
          entries={[
            [
              '/admin',
              'Panel administratora',
              'Moderacja, użytkownicy i stan aplikacji.',
              'settings',
            ],
          ]}
        />
      )}
    </div>
  );
}
