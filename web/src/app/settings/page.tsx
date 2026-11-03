'use client';
import { useEffect, useState, type FormEvent } from 'react';
import Link from 'next/link';
import api from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';
import { useTheme } from '@/contexts/ThemeContext';
import { useMutation } from '@/hooks/useApiResource';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { TextField, Select } from '@/components/ui/FormField';
import { ErrorState } from '@/components/ui/ErrorState';
import { Dialog } from '@/components/ui/Dialog';
import { BrowserNotifications } from '@/components/notifications/BrowserNotifications';
import { GhostModeControl } from '@/components/family/GhostModeControl';
import { AccessibilitySettings } from '@/components/settings/AccessibilitySettings';
import { NotificationPreferences } from '@/components/settings/NotificationPreferences';
import { getLang, setLang } from '@/lib/i18n';

export default function SettingsPage() {
  const { user, logout, refreshUser } = useAuth();
  const { theme, setTheme } = useTheme();
  const mutation = useMutation();
  const [message, setMessage] = useState('');
  const [editing, setEditing] = useState<'username' | 'email' | 'password' | 'delete' | null>(null);
  const [value, setValue] = useState('');
  const [password, setPassword] = useState('');
  const [language, setLanguage] = useState('pl');
  useEffect(() => {
    const timer = setTimeout(() => setLanguage(getLang()), 0);
    return () => clearTimeout(timer);
  }, []);
  function open(kind: typeof editing) {
    setEditing(kind);
    setValue('');
    setPassword('');
    mutation.setError('');
  }
  async function saveAccount(event: FormEvent) {
    event.preventDefault();
    await mutation.run(
      () => {
        if (editing === 'username') return api.patch('/users/me', { username: value });
        if (editing === 'email') return api.post('/users/me/email', { email: value, password });
        if (editing === 'password')
          return api.post('/users/me/password', {
            current_password: password,
            new_password: value,
          });
        return api.post('/users/me/delete', { password });
      },
      async () => {
        if (editing === 'delete') logout();
        else {
          await refreshUser();
          setMessage('Zmiana została zapisana na koncie.');
        }
        open(null);
      },
    );
  }
  const titles = {
    username: 'Zmień nazwę użytkownika',
    email: 'Zmień adres e-mail',
    password: 'Zmień hasło',
    delete: 'Usuń konto',
  };
  return (
    <div className="form-container space-y-6">
      <PageHeader title="Ustawienia" description="Dopasuj konto i aplikację do swoich potrzeb." />
      {message && (
        <p role="status" className="panel text-success">
          {message}
        </p>
      )}
      {!editing && mutation.error && <ErrorState message={mutation.error} />}
      <section className="panel space-y-4">
        <h2 className="text-xl font-bold">Konto</h2>
        <p className="text-ink-2 break-words">
          {user?.username} · {user?.email}
        </p>
        <div className="flex flex-wrap gap-2">
          {(['username', 'email', 'password'] as const).map((kind) => (
            <Button key={kind} variant="secondary" onClick={() => open(kind)}>
              {titles[kind]}
            </Button>
          ))}
        </div>
        <form
          className="space-y-3"
          onSubmit={(event) => {
            event.preventDefault();
            const form = new FormData(event.currentTarget);
            void mutation.run(
              () =>
                api.patch('/users/me', {
                  phone: String(form.get('phone') || ''),
                  is_kpp: form.get('is_kpp') === 'on',
                }),
              async () => {
                await refreshUser();
                setMessage('Dane kontaktowe zapisane na koncie.');
              },
            );
          }}
        >
          <TextField
            key={user?.phone || 'phone'}
            label="Numer telefonu"
            name="phone"
            type="tel"
            autoComplete="tel"
            defaultValue={user?.phone || ''}
          />
          <label className="flex items-center gap-3 min-h-12">
            <input
              key={String(user?.is_kpp)}
              name="is_kpp"
              type="checkbox"
              defaultChecked={user?.is_kpp}
              className="size-5"
            />
            Mam kwalifikacje pierwszej pomocy (KPP)
          </label>
          <Button loading={mutation.busy}>Zapisz dane kontaktowe</Button>
        </form>
        <Link href="/verify-email" className="btn btn-quiet">
          Potwierdź adres e-mail
        </Link>
      </section>
      <section className="panel space-y-4">
        <h2 className="text-xl font-bold">Powiadomienia i promień</h2>
        <BrowserNotifications />
        <NotificationPreferences />
        <p className="text-sm text-ink-2">
          Powiadomienia przeglądarki działają w otwartej aplikacji. Dźwięk i wibracje zależą od
          ustawień urządzenia.
        </p>
        <form
          className="space-y-3"
          onSubmit={(event) => {
            event.preventDefault();
            const form = new FormData(event.currentTarget);
            void mutation.run(
              () => api.patch('/users/me', { alert_radius_m: Number(form.get('radius')) }),
              async () => {
                await refreshUser();
                setMessage('Promień powiadomień zapisany na koncie.');
              },
            );
          }}
        >
          <Select
            key={user?.alert_radius_m}
            label="Promień powiadomień na koncie"
            name="radius"
            defaultValue={user?.alert_radius_m || 2000}
          >
            {[
              500,
              1000,
              2000,
              5000,
              10000,
              ...(user?.alert_radius_m &&
              ![500, 1000, 2000, 5000, 10000].includes(user.alert_radius_m)
                ? [user.alert_radius_m]
                : []),
            ].map((radius) => (
              <option key={radius} value={radius}>
                {(radius / 1000).toLocaleString('pl-PL')} km
              </option>
            ))}
          </Select>
          <p className="text-sm text-ink-2">Nie zmienia chwilowego obszaru przeglądania mapy.</p>
          <Button loading={mutation.busy}>Zapisz promień</Button>
        </form>
      </section>
      <section className="panel space-y-4">
        <h2 className="text-xl font-bold">Prywatność</h2>
        <GhostModeControl />
        <div className="flex flex-wrap gap-2">
          <Link className="btn btn-secondary" href="/permissions">
            Uprawnienia urządzenia i zgody
          </Link>
          <Link className="btn btn-secondary" href="/profile">
            Udostępnij lokalizację
          </Link>
          <Link className="btn btn-quiet" href="/privacy">
            Polityka prywatności
          </Link>
          <Link className="btn btn-quiet" href="/terms">
            Regulamin
          </Link>
        </div>
      </section>
      <section className="panel space-y-4" id="accessibility">
        <h2 className="text-xl font-bold">Wygląd i dostępność</h2>
        <Select
          label="Motyw na tym urządzeniu"
          value={theme}
          onChange={(e) => setTheme(e.target.value as 'light' | 'dark' | 'system')}
        >
          <option value="system">Zgodnie z urządzeniem</option>
          <option value="light">Jasny</option>
          <option value="dark">Ciemny</option>
        </Select>
        <AccessibilitySettings />
        <Select
          label="Preferowany język starszych tłumaczeń"
          value={language}
          onChange={(e) => {
            const lang = e.target.value === 'en' ? 'en' : 'pl';
            setLanguage(lang);
            setLang(lang);
            setMessage(
              'Preferencję języka zapisano na urządzeniu. Nowy interfejs jest dostępny po polsku.',
            );
          }}
        >
          <option value="pl">Polski</option>
          <option value="en">Angielski (częściowe tłumaczenie)</option>
        </Select>
        <div className="flex flex-wrap gap-2">
          <Link href="/mode" className="btn btn-secondary">
            Widok aplikacji
          </Link>
          <Link href="/onboarding" className="btn btn-secondary">
            Pierwsze kroki
          </Link>
          <Link href="/cyber" className="btn btn-quiet">
            Bezpieczeństwo w sieci
          </Link>
          <Link href="/parental-controls" className="btn btn-quiet">
            Dziecko w sieci
          </Link>
        </div>
        <p className="text-sm text-ink-2">
          Interfejs w języku polskim. Ustawienia czytelności zapisujemy na tym urządzeniu.
        </p>
      </section>
      <section className="panel space-y-4">
        <h2 className="text-xl font-bold">Niebezpieczna strefa</h2>
        <p>Usunięcie konta jest nieodwracalne i wymaga potwierdzenia hasłem.</p>
        <div className="flex flex-wrap gap-3">
          <Button variant="secondary" onClick={logout}>
            Wyloguj się
          </Button>
          <Button variant="danger" onClick={() => open('delete')}>
            Usuń konto
          </Button>
        </div>
      </section>
      <Dialog
        open={!!editing}
        title={editing ? titles[editing] : ''}
        onClose={() => {
          if (!mutation.busy) open(null);
        }}
      >
        <form className="space-y-4" onSubmit={saveAccount}>
          {editing === 'delete' ? (
            <p>Trwale usuniesz konto i utracisz dostęp do jego danych.</p>
          ) : (
            <TextField
              label={
                editing === 'username'
                  ? 'Nowa nazwa'
                  : editing === 'email'
                    ? 'Nowy adres e-mail'
                    : 'Nowe hasło'
              }
              type={editing === 'email' ? 'email' : editing === 'password' ? 'password' : 'text'}
              autoComplete={editing === 'password' ? 'new-password' : undefined}
              required
              minLength={editing === 'password' ? 8 : 3}
              value={value}
              onChange={(e) => setValue(e.target.value)}
            />
          )}
          {editing !== 'username' && (
            <TextField
              label="Aktualne hasło"
              type="password"
              autoComplete="current-password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          )}
          {mutation.error && <ErrorState message={mutation.error} />}
          <Button loading={mutation.busy} variant={editing === 'delete' ? 'danger' : 'primary'}>
            {editing === 'delete' ? 'Usuń konto na zawsze' : 'Zapisz zmianę'}
          </Button>
          <Button
            type="button"
            variant="secondary"
            disabled={mutation.busy}
            onClick={() => open(null)}
          >
            Anuluj
          </Button>
        </form>
      </Dialog>
    </div>
  );
}
