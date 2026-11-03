'use client';
import { useApiResource } from '@/hooks/useApiResource';
import { asArray } from '@/lib/api';
import type { RankingUser } from '@/types';
import { PageHeader } from '@/components/layout/PageHeader';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
export default function RankingPage() {
  const resource = useApiResource<{ ranking: RankingUser[] }>('/users/ranking');
  const users = asArray(resource.data?.ranking);
  return (
    <div className="form-container">
      <PageHeader
        title="Ranking społeczności"
        description="Osoby, które pomagają innym przez zgłoszenia i ich potwierdzanie."
      />
      {resource.loading && <Skeleton />}
      {resource.error && <ErrorState message={resource.error} onRetry={resource.reload} />}
      {!resource.loading && !resource.error && !users.length && (
        <EmptyState
          title="Ranking jest jeszcze pusty"
          description="Wróć tutaj, gdy pojawi się więcej aktywności."
        />
      )}
      <ol className="space-y-3">
        {users.map((user, index) => (
          <li className="panel flex flex-wrap items-center gap-3" key={user.id}>
            <span className="font-bold text-primary" aria-label={`Miejsce ${index + 1}`}>
              {index + 1}.
            </span>
            <div className="size-12 rounded-full bg-surface-2 overflow-hidden grid place-items-center font-bold">
              {user.avatar_url ? (
                <img src={user.avatar_url} alt="" className="size-12 object-cover" />
              ) : (
                user.username?.slice(0, 1).toLocaleUpperCase('pl-PL') || '?'
              )}
            </div>
            <div className="flex-1 min-w-32">
              <h2 className="font-bold break-words">{user.username}</h2>
              <p className="text-sm text-ink-2">
                Zgłoszenia: {user.alert_count ?? '—'} · Potwierdzenia: {user.total_confirms ?? '—'}
              </p>
            </div>
            <p className="text-sm">
              Reputacja: <strong>{user.reputation_score ?? '—'}</strong>
            </p>
          </li>
        ))}
      </ol>
    </div>
  );
}
