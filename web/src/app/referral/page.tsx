'use client';
import { useEffect, useState } from 'react';
import { useApiResource } from '@/hooks/useApiResource';
import { PageHeader } from '@/components/layout/PageHeader';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
import { Button } from '@/components/ui/Button';
import { TextField } from '@/components/ui/TextField';
export default function ReferralPage() {
  const resource = useApiResource<{ referral_code?: string; referrals_count?: number }>(
    '/users/me',
  );
  const [origin, setOrigin] = useState('');
  const [message, setMessage] = useState('');
  useEffect(() => {
    const timer = setTimeout(() => setOrigin(window.location.origin), 0);
    return () => clearTimeout(timer);
  }, []);
  const code = resource.data?.referral_code;
  const link = code && origin ? `${origin}/register?ref=${encodeURIComponent(code)}` : '';
  async function copy() {
    try {
      await navigator.clipboard.writeText(link);
      setMessage('Link skopiowany.');
    } catch {
      setMessage('Zaznacz link w polu i skopiuj go ręcznie.');
    }
  }
  async function share() {
    if (!navigator.share) return copy();
    try {
      await navigator.share({ title: 'be:Safe', text: 'Dołącz do mnie w be:Safe', url: link });
    } catch (error) {
      if (!(error instanceof Error && error.name === 'AbortError'))
        setMessage('Nie udało się udostępnić. Skopiuj link poniżej.');
    }
  }
  return (
    <div className="form-container">
      <PageHeader
        title="Zaproś znajomych"
        description="Łatwiej zadbać o okolicę razem. Wyślij bliskim swój link."
      />
      {resource.loading && <Skeleton />}
      {resource.error && <ErrorState message={resource.error} onRetry={resource.reload} />}
      {!resource.loading && !resource.error && !code && (
        <EmptyState
          title="Kod polecający nie jest jeszcze dostępny"
          description="Spróbuj odświeżyć dane za chwilę."
        />
      )}
      {code && (
        <section className="panel space-y-4">
          <TextField
            label="Twój kod polecający"
            value={code}
            readOnly
            onFocus={(e) => e.target.select()}
          />
          <p>
            Polecone osoby: <strong>{resource.data?.referrals_count ?? '—'}</strong>
          </p>
          <TextField
            label="Link zaproszenia"
            value={link}
            readOnly
            onFocus={(e) => e.target.select()}
          />
          <div className="flex flex-wrap gap-3">
            <Button disabled={!link} onClick={copy}>
              Kopiuj link
            </Button>
            <Button variant="secondary" disabled={!link} onClick={share}>
              Udostępnij
            </Button>
          </div>
          <p role="status">{message}</p>
        </section>
      )}
    </div>
  );
}
