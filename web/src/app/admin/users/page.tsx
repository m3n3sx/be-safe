'use client';
import { useState } from 'react';
import AdminShell from '@/components/ui/AdminShell';
import { PageHeader } from '@/components/layout/PageHeader';
import { ResourceState } from '@/components/ui/ResourceState';
import { ConfirmAction } from '@/components/ui/ConfirmAction';
import { Button } from '@/components/ui/Button';
import { TextField } from '@/components/ui/TextField';
import { Dialog } from '@/components/ui/Dialog';
import { ErrorState } from '@/components/ui/ErrorState';
import { useApiResource, useMutation } from '@/hooks/useApiResource';
import { useAdminAccess } from '@/hooks/useAdminAccess';
import { useAuth } from '@/contexts/AuthContext';
import api, { asArray } from '@/lib/api';
import type { User } from '@/types';
type AdminUser = User & {
  is_banned: boolean;
  ban_reason?: string;
  is_verified: boolean;
  verified_role?: string;
};
export default function AdminUsersPage() {
  const access = useAdminAccess();
  const { user } = useAuth();
  const [search, setSearch] = useState('');
  const [query, setQuery] = useState('');
  const resource = useApiResource<{ users: AdminUser[] }>(
    access.isAdmin ? `/admin/users?q=${encodeURIComponent(query)}&limit=100` : null,
  );
  const users = asArray(resource.data?.users);
  const [target, setTarget] = useState<AdminUser | null>(null);
  const [reason, setReason] = useState('');
  const mutation = useMutation();
  return (
    <AdminShell>
      <PageHeader
        title="Użytkownicy"
        description="Wyszukiwanie kont, blokady i uprawnienia administratora."
      />
      <form
        className="flex flex-wrap items-end gap-3 mb-5"
        onSubmit={(event) => {
          event.preventDefault();
          setQuery(search.trim());
        }}
      >
        <TextField
          label="Nazwa użytkownika lub e-mail"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <Button>Szukaj</Button>
      </form>
      <ResourceState {...resource} empty={!users.length} onRetry={resource.reload} />
      <ul className="space-y-3">
        {users.map((person) => (
          <li key={person.id} className="panel space-y-4">
            <div className="flex items-center gap-3">
              <div className="size-12 shrink-0 rounded-full overflow-hidden bg-surface-2 grid place-items-center font-bold">
                {person.avatar_url ? (
                  <img src={person.avatar_url} alt="" className="size-12 object-cover" />
                ) : (
                  person.username?.slice(0, 1).toLocaleUpperCase('pl-PL') || '?'
                )}
              </div>
              <div className="min-w-0">
                <h2 className="font-bold break-words">{person.username}</h2>
                <p className="text-sm text-ink-2 break-all">{person.email}</p>
              </div>
            </div>
            <div className="flex flex-wrap gap-2 text-sm">
              {person.is_admin && (
                <span className="bg-surface-2 p-2 rounded-lg">Administrator</span>
              )}
              {person.is_banned && <span className="text-danger">Konto zablokowane</span>}
              {person.is_verified && <span>Zweryfikowano: {person.verified_role || 'konto'}</span>}
              {person.is_child && <span>Konto dziecka</span>}
            </div>
            {person.ban_reason && (
              <p className="text-sm text-danger">Powód blokady: {person.ban_reason}</p>
            )}
            {person.id !== user?.id && (
              <div className="flex flex-wrap gap-3">
                {access.can('users.ban') &&
                  (person.is_banned ? (
                    <ConfirmAction
                      label="Odblokuj konto"
                      description={`Przywrócisz dostęp osobie ${person.username}.`}
                      action={() => api.patch(`/admin/users/${person.id}`, { is_banned: false })}
                      onDone={resource.reload}
                    />
                  ) : (
                    <Button
                      variant="secondary"
                      onClick={() => {
                        setTarget(person);
                        setReason('');
                        mutation.setError('');
                      }}
                    >
                      Zablokuj konto
                    </Button>
                  ))}
                {access.can('rbac.manage') && (
                  <ConfirmAction
                    label={
                      person.is_admin
                        ? 'Odbierz uprawnienia administratora'
                        : 'Nadaj uprawnienia administratora'
                    }
                    description={`Zmienisz uprawnienia konta ${person.username}.`}
                    action={() =>
                      api.patch(`/admin/users/${person.id}`, { is_admin: !person.is_admin })
                    }
                    onDone={resource.reload}
                  />
                )}
              </div>
            )}
          </li>
        ))}
      </ul>
      <Dialog
        open={!!target}
        title="Zablokować konto?"
        onClose={() => {
          if (!mutation.busy) setTarget(null);
        }}
      >
        <form
          className="space-y-4"
          onSubmit={(event) => {
            event.preventDefault();
            if (!target) return;
            void mutation.run(
              () =>
                api.patch(`/admin/users/${target.id}`, {
                  is_banned: true,
                  ban_reason: reason.trim(),
                }),
              async () => {
                setTarget(null);
                await resource.reload();
              },
            );
          }}
        >
          <p>Konto: {target?.username}</p>
          <TextField
            label="Powód blokady"
            required
            value={reason}
            onChange={(e) => setReason(e.target.value)}
          />
          {mutation.error && <ErrorState message={mutation.error} />}
          <Button variant="danger" disabled={!reason.trim()} loading={mutation.busy}>
            Zablokuj konto
          </Button>
        </form>
      </Dialog>
    </AdminShell>
  );
}
