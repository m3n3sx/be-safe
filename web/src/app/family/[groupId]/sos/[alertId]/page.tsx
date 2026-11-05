'use client';
import { useParams } from 'next/navigation';
import type { Alert } from '@/types';
import api from '@/lib/api';
import { useApiResource } from '@/hooks/useApiResource';
import { GroupHeader } from '@/components/family/GroupHeader';
import { GroupPingAction } from '@/components/family/GroupPingAction';
import { PlacesMap } from '@/components/map/PlacesMap';
import AlertDetail from '@/components/alerts/AlertDetail';
import { EmergencyCall } from '@/components/safety/EmergencyCall';
import { ErrorState } from '@/components/ui/ErrorState';
import { Skeleton } from '@/components/ui/Skeleton';
import { Button } from '@/components/ui/Button';

export default function Page() {
  const { groupId, alertId } = useParams<{ groupId: string; alertId: string }>();
  const alert = useApiResource<Alert>(`/alerts/${alertId}`);
  const context = useApiResource<{
    sender_username?: string;
    sent_at?: string;
    lat?: number;
    lng?: number;
    phone?: string | null;
    status?: string;
    location_label?: string;
    notification_id?: string | null;
    acknowledged_at?: string | null;
  }>(`/alerts/${alertId}/sos-context`);
  const expired = context.data?.status && context.data.status !== 'active';
  const point =
    context.data && !context.error && context.data.lat != null && context.data.lng != null
      ? {
          id: 'sos',
          lat: Number(context.data.lat),
          lng: Number(context.data.lng),
          label: context.data.location_label || 'Miejsce wysłania alarmu',
        }
      : null;
  return (
    <div className="page-container space-y-5">
      <GroupHeader id={groupId} title="SOS w be:Safe" />
      <section className={`space-y-3 rounded-2xl p-5 text-white ${expired ? 'bg-[#5C3B3B]' : 'bg-[#7A1212]'}`}>
        <p className="text-sm font-bold">be:Safe</p>
        <h2 className="text-3xl font-bold">{expired ? 'Alarm wygasł' : 'SOS'}</h2>
        <p>
          {context.data?.sender_username || 'Bliska osoba'}
          {context.data?.sent_at ? ` · ${new Date(context.data.sent_at).toLocaleString('pl-PL')}` : ''}
        </p>
        <p className="text-sm">
          Komunikat aplikacji be:Safe. Nie jest wezwaniem służb i nie omija wyciszenia telefonu.
        </p>
        {context.data?.notification_id && !context.data.acknowledged_at && (
          <Button
            onClick={() =>
              void api.post(`/notifications/${context.data!.notification_id}/ack`).then(() => context.reload())
            }
          >
            Widzę ten alarm
          </Button>
        )}
      </section>
      <div className="max-w-xl">
        <EmergencyCall />
      </div>
      {(alert.loading || context.loading) && <Skeleton />}
      {(alert.error || context.error) && (
        <ErrorState
          message={context.error || alert.error}
          onRetry={() => {
            void alert.reload();
            void context.reload();
          }}
        />
      )}
      {context.data && !context.error && (
        <section className="panel space-y-3">
          <h2 className="font-bold text-xl">{context.data.sender_username}</h2>
          <p>{context.data.location_label || 'Miejsce wysłania alarmu'}</p>
          {context.data.phone && (
            <a className="btn btn-secondary" href={`tel:${context.data.phone}`}>
              Zadzwoń do osoby: {context.data.phone}
            </a>
          )}
          {point && (
            <>
              <PlacesMap places={[point]} />
              <a
                className="btn btn-secondary"
                href={`https://www.google.com/maps/dir/?api=1&destination=${point.lat},${point.lng}`}
                target="_blank"
                rel="noreferrer"
              >
                Trasa do miejsca alarmu
              </a>
            </>
          )}
        </section>
      )}
      <GroupPingAction groupId={groupId} />
      <AlertDetail alertId={alertId} />
    </div>
  );
}
