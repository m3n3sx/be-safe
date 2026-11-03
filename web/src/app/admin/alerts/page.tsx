'use client';
import { useState } from 'react';
import Link from 'next/link';
import AdminShell from '@/components/ui/AdminShell';
import { PageHeader } from '@/components/layout/PageHeader';
import { ResourceState } from '@/components/ui/ResourceState';
import { ConfirmAction } from '@/components/ui/ConfirmAction';
import { Select } from '@/components/ui/Select';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { useApiResource } from '@/hooks/useApiResource';
import { useAdminAccess } from '@/hooks/useAdminAccess';
import api, { asArray } from '@/lib/api';
import { getCategoryInfo, type Alert } from '@/types';
type AdminAlert = Alert & { reports_count?: number; author_username?: string };
export default function AdminAlertsPage() {
  const access = useAdminAccess();
  const [status, setStatus] = useState('active');
  const resource = useApiResource<{ alerts: AdminAlert[] }>(
    access.isAdmin ? `/admin/alerts?status=${status}&limit=200` : null,
  );
  const alerts = asArray(resource.data?.alerts);
  return (
    <AdminShell>
      <PageHeader
        title="Zgłoszenia w okolicy"
        description="Przeglądaj zdarzenia i moderuj ich treść."
      />
      <div className="max-w-sm mb-4">
        <Select label="Stan zgłoszenia" value={status} onChange={(e) => setStatus(e.target.value)}>
          {[
            ['active', 'Aktywne'],
            ['expired', 'Wygasłe'],
            ['removed', 'Usunięte'],
            ['hidden', 'Ukryte'],
            ['', 'Wszystkie'],
          ].map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </Select>
      </div>
      <ResourceState {...resource} empty={!alerts.length} onRetry={resource.reload} />
      <ul className="space-y-3">
        {alerts.map((alert) => (
          <li key={alert.id} className="panel space-y-3">
            <div className="flex flex-wrap gap-3 items-center">
              <h2 className="text-xl font-bold">{alert.title}</h2>
              <StatusBadge status={alert.status} />
            </div>
            <p className="text-sm text-ink-2">
              {getCategoryInfo(alert.category).label} · Autor:{' '}
              {alert.author_username || 'Brak danych'}
            </p>
            <p>{alert.description}</p>
            <p className="text-sm">
              Potwierdzenia: {alert.confirms ?? 0} · Nieaktualne: {alert.denies ?? 0} · Nadużycia:{' '}
              {alert.reports_count ?? 0}
            </p>
            <div className="flex flex-wrap gap-3">
              <Link href={`/alerts/${alert.id}`} className="btn btn-secondary">
                Szczegóły zgłoszenia
              </Link>
              {access.can('alerts.delete') && (
                <ConfirmAction
                  label="Usuń zgłoszenie"
                  title="Usunąć zgłoszenie?"
                  description="Zgłoszenie przestanie być dostępne dla użytkowników."
                  action={() => api.delete(`/admin/alerts/${alert.id}`)}
                  onDone={resource.reload}
                />
              )}
            </div>
          </li>
        ))}
      </ul>
    </AdminShell>
  );
}
