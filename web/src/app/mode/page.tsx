'use client';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import api from '@/lib/api';
import { useMutation } from '@/hooks/useApiResource';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { Icon } from '@/components/ui/Icon';
import { ErrorState } from '@/components/ui/ErrorState';

const options = [
  ['normal', 'Standardowy', 'Mapa i lista okolicy jako główny widok.'],
  ['kids', 'Dla dziecka', 'Skróty do bliskich, meldunku i pomocy na stronie głównej.'],
  ['senior', 'Dla seniora', 'Meldunek na stronie głównej i SOS bez konieczności przytrzymywania.'],
] as const;
export default function ModePage() {
  const { user, refreshUser } = useAuth();
  const router = useRouter();
  const mutation = useMutation();
  return (
    <div className="form-container space-y-4">
      <PageHeader
        title="Widok aplikacji"
        description="W każdym widoku masz dostęp do wszystkich funkcji. Wybór nie zmienia uprawnień ani odbiorców powiadomień."
      />
      {mutation.error && <ErrorState message={mutation.error} />}
      {options.map(([mode, title, description]) => (
        <section key={mode} className="panel space-y-3">
          <Icon name="people" />
          <h2 className="text-xl font-bold">{title}</h2>
          <p className="text-ink-2">{description}</p>
          <Button
            variant={user?.app_mode === mode ? 'primary' : 'secondary'}
            disabled={mutation.busy}
            aria-pressed={user?.app_mode === mode}
            onClick={() =>
              void mutation.run(
                () => api.patch('/users/me', { app_mode: mode }),
                async () => {
                  await refreshUser();
                  router.push('/');
                },
              )
            }
          >
            {user?.app_mode === mode ? 'Wybrany widok' : 'Wybierz ten widok'}
          </Button>
        </section>
      ))}
    </div>
  );
}
