'use client';
import AdminShell from '@/components/ui/AdminShell';
import { PageHeader } from '@/components/layout/PageHeader';
import { ResourceState } from '@/components/ui/ResourceState';
import { useApiResource } from '@/hooks/useApiResource';
import { useAdminAccess } from '@/hooks/useAdminAccess';
import { asArray } from '@/lib/api';
type Entry = {
  id: string;
  admin_username?: string;
  action: string;
  target_type?: string;
  target_id?: string;
  payload?: unknown;
  created_at: string;
};
const labels: Record<string, string> = {
  'user.ban': 'Blokada konta',
  'user.unban': 'Odblokowanie konta',
  'user.set_admin': 'Zmiana administratora',
  'user.update': 'Edycja konta',
  'alert.delete': 'Usunięcie zdarzenia',
  'alert.update': 'Edycja zdarzenia',
  'report.resolve': 'Rozstrzygnięcie nadużycia',
  'group.delete': 'Usunięcie grupy',
  'config.update': 'Zmiana konfiguracji',
  'flag.update': 'Zmiana dostępności funkcji',
  'broadcast.send': 'Wysłanie komunikatu',
};
export default function AuditPage() {
  const access = useAdminAccess();
  const resource = useApiResource<{ entries: Entry[] }>(
    access.isAdmin ? '/admin/audit-log?limit=200' : null,
  );
  const entries = asArray(resource.data?.entries);
  return (
    <AdminShell>
      <PageHeader title="Dziennik działań" description="Ostatnie 200 operacji administracyjnych." />
      <ResourceState {...resource} empty={!entries.length} onRetry={resource.reload} />
      <ol className="space-y-3">
        {entries.map((entry) => (
          <li key={entry.id} className="panel space-y-2">
            <h2 className="font-bold">{labels[entry.action] || 'Operacja administracyjna'}</h2>
            <p className="text-sm text-ink-2">
              {entry.admin_username || 'Administrator'} ·{' '}
              {new Date(entry.created_at).toLocaleString('pl-PL')}
            </p>
            <p className="text-sm break-all">
              Obiekt: {entry.target_type || '—'} · {entry.target_id || '—'}
            </p>
            <details>
              <summary className="min-h-12 flex items-center cursor-pointer text-primary">
                Szczegóły techniczne operacji
              </summary>
              <p className="text-sm">{entry.action}</p>
              <pre className="bg-surface-2 rounded-xl p-3 text-sm overflow-auto">
                {JSON.stringify(entry.payload ?? {}, null, 2)}
              </pre>
            </details>
          </li>
        ))}
      </ol>
    </AdminShell>
  );
}
