'use client';
import AdminShell from '@/components/ui/AdminShell';
import { PageHeader } from '@/components/layout/PageHeader';
import { ResourceState } from '@/components/ui/ResourceState';
import { ConfirmAction } from '@/components/ui/ConfirmAction';
import { useApiResource } from '@/hooks/useApiResource';
import { useAdminAccess } from '@/hooks/useAdminAccess';
import api, { asArray } from '@/lib/api';
type Group = {
  id: string;
  name: string;
  owner_username: string;
  invite_code: string;
  members_count: number;
};
export default function AdminGroupsPage() {
  const access = useAdminAccess();
  const resource = useApiResource<{ groups: Group[] }>(access.isAdmin ? '/admin/groups' : null);
  const groups = asArray(resource.data?.groups);
  return (
    <AdminShell>
      <PageHeader title="Grupy rodzinne" description="Przegląd grup i ich właścicieli." />
      <ResourceState {...resource} empty={!groups.length} onRetry={resource.reload} />
      <ul className="space-y-3">
        {groups.map((group) => (
          <li className="panel flex flex-wrap items-center gap-4" key={group.id}>
            <div className="flex-1 min-w-40">
              <h2 className="font-bold">{group.name}</h2>
              <p className="text-sm text-ink-2">
                Właściciel: {group.owner_username || 'Brak danych'} · Członkowie:{' '}
                {group.members_count ?? '—'}
              </p>
              <p className="text-sm">Kod: {group.invite_code}</p>
            </div>
            {access.can('groups.delete') && (
              <ConfirmAction
                label="Usuń grupę"
                title={`Usunąć grupę „${group.name}”?`}
                description="Usuniesz grupę i jej powiązania z członkami. Konta tych osób pozostaną."
                action={() => api.delete(`/admin/groups/${group.id}`)}
                onDone={resource.reload}
              />
            )}
          </li>
        ))}
      </ul>
    </AdminShell>
  );
}
