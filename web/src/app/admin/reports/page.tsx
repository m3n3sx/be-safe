'use client';
import Link from 'next/link';
import AdminShell from '@/components/ui/AdminShell';
import { PageHeader } from '@/components/layout/PageHeader';
import { ResourceState } from '@/components/ui/ResourceState';
import { ConfirmAction } from '@/components/ui/ConfirmAction';
import { useApiResource } from '@/hooks/useApiResource';
import { useAdminAccess } from '@/hooks/useAdminAccess';
import api, { asArray } from '@/lib/api';
import { getCategoryInfo, type AlertCategory } from '@/types';
type Report = {
  id: string;
  alert_id: string;
  alert_title: string;
  alert_category: AlertCategory;
  alert_description?: string;
  reason: string;
  details?: string;
  reporter_username: string;
  created_at: string;
};
export default function ReportsPage() {
  const access = useAdminAccess();
  const resource = useApiResource<{ reports: Report[] }>(
    access.isAdmin ? '/admin/reports?status=pending' : null,
  );
  const reports = asArray(resource.data?.reports);
  return (
    <AdminShell>
      <PageHeader
        title="Zgłoszenia nadużyć"
        description="Sprawdź powód i treść zdarzenia przed rozstrzygnięciem."
      />
      <ResourceState {...resource} empty={!reports.length} onRetry={resource.reload} />
      <ul className="space-y-4">
        {reports.map((report) => (
          <li className="panel space-y-3" key={report.id}>
            <h2 className="text-xl font-bold">{report.alert_title}</h2>
            <p className="text-sm text-ink-2">{getCategoryInfo(report.alert_category).label}</p>
            <p>{report.alert_description}</p>
            <div className="bg-surface-2 rounded-xl p-4 space-y-2">
              <p>
                <strong>Powód:</strong> {report.reason}
              </p>
              <p>{report.details}</p>
              <p className="text-sm text-ink-2">
                {report.reporter_username} · {new Date(report.created_at).toLocaleString('pl-PL')}
              </p>
            </div>
            <div className="flex flex-wrap gap-3">
              <Link className="btn btn-secondary" href={`/alerts/${report.alert_id}`}>
                Zobacz zgłoszenie
              </Link>
              {access.can('reports.resolve') && (
                <>
                  {(['delete_alert', 'dismiss'] as const).map((action) => (
                    <ConfirmAction
                      key={action}
                      label={action === 'delete_alert' ? 'Usuń zdarzenie' : 'Odrzuć nadużycie'}
                      title={
                        action === 'delete_alert'
                          ? 'Usunąć zdarzenie i zamknąć nadużycie?'
                          : 'Odrzucić zgłoszenie nadużycia?'
                      }
                      description={
                        action === 'dismiss'
                          ? 'Zdarzenie pozostanie dostępne.'
                          : 'Zdarzenie zostanie usunięte.'
                      }
                      action={() => api.post(`/admin/reports/${report.id}/resolve`, { action })}
                      onDone={resource.reload}
                    />
                  ))}
                </>
              )}
            </div>
          </li>
        ))}
      </ul>
    </AdminShell>
  );
}
