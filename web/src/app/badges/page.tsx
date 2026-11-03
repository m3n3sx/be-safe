'use client';
import { useApiResource } from '@/hooks/useApiResource';
import { asArray } from '@/lib/api';
import { PageHeader } from '@/components/layout/PageHeader';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
import { Icon } from '@/components/ui/Icon';
type Badge = { id: string; name: string; description: string; awarded_at?: string };
export default function BadgesPage() {
  const resource = useApiResource<{ earned: Badge[]; available: Badge[] }>('/me/badges');
  const earned = asArray(resource.data?.earned);
  const available = asArray(resource.data?.available).filter(
    (b) => !earned.some((e) => e.id === b.id),
  );
  return (
    <div className="page-container">
      <PageHeader title="Odznaki" description="Doceniamy Twoją pomoc społeczności." />
      {resource.loading && <Skeleton />}
      {resource.error && <ErrorState message={resource.error} onRetry={resource.reload} />}
      {!resource.loading && !resource.error && (
        <div className="space-y-6">
          {[
            ['Zdobyte', earned],
            ['Do zdobycia', available],
          ].map(([title, items]) => (
            <section key={String(title)}>
              <h2 className="text-xl font-bold mb-3">{String(title)}</h2>
              {!(items as Badge[]).length ? (
                <EmptyState
                  title={title === 'Zdobyte' ? 'Jeszcze nie masz odznak' : 'Brak kolejnych odznak'}
                  description="Odznaki pojawią się tutaj, gdy będą dostępne."
                />
              ) : (
                <ul className="grid sm:grid-cols-2 lg:grid-cols-3 gap-3">
                  {(items as Badge[]).map((b) => (
                    <li className="panel space-y-2" key={b.id}>
                      <Icon name="heart" />
                      <h3 className="font-bold">{b.name}</h3>
                      <p className="text-ink-2">{b.description}</p>
                      {b.awarded_at && (
                        <p className="text-sm">
                          Zdobyta {new Date(b.awarded_at).toLocaleDateString('pl-PL')}
                        </p>
                      )}
                    </li>
                  ))}
                </ul>
              )}
            </section>
          ))}
        </div>
      )}
    </div>
  );
}
