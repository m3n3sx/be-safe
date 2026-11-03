'use client';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import type { Alert, FamilyMember } from '@/types';
import { groupPath, memberPlace } from '@/lib/api/family';
import { useApiResource } from '@/hooks/useApiResource';
import { GroupHeader } from '@/components/family/GroupHeader';
import { GroupPingAction } from '@/components/family/GroupPingAction';
import { PlacesMap } from '@/components/map/PlacesMap';
import AlertDetail from '@/components/alerts/AlertDetail';
import { EmergencyCall } from '@/components/safety/EmergencyCall';
import { ErrorState } from '@/components/ui/ErrorState';
import { Skeleton } from '@/components/ui/Skeleton';
export default function Page() {
  const { groupId, alertId } = useParams<{ groupId: string; alertId: string }>();
  const alert = useApiResource<Alert>(`/alerts/${alertId}`); const members = useApiResource<{ members: FamilyMember[] }>(`${groupPath(groupId)}/members`, 30000);
  const person = members.data?.members.find(m => m.user_id === alert.data?.author_id); const point = person ? memberPlace(person) : null;
  return <div className="page-container space-y-5"><GroupHeader id={groupId} title="SOS bliskiej osoby" /><div className="max-w-xl"><EmergencyCall /></div>{(alert.loading || members.loading) && <Skeleton />}{(alert.error || members.error) && <ErrorState message={alert.error || members.error} onRetry={() => { void alert.reload(); void members.reload(); }} />}{person && <section className="panel space-y-3"><h2 className="font-bold text-xl">{person.username}</h2><p>Ostatnia znana lokalizacja: {person.last_location_at ? new Date(person.last_location_at).toLocaleString('pl-PL') : 'brak danych'}</p>{person.phone && <a className="btn btn-secondary" href={`tel:${person.phone}`}>Zadzwoń: {person.phone}</a>}<Link className="btn btn-quiet" href={`/family/${groupId}/members/${person.user_id}`}>Profil osoby</Link>{point && <><PlacesMap places={[point]} /><a className="btn btn-secondary" href={`https://www.google.com/maps/dir/?api=1&destination=${point.lat},${point.lng}`} target="_blank" rel="noreferrer">Trasa do ostatniej pozycji ↗</a></>}</section>}<GroupPingAction groupId={groupId} /><AlertDetail alertId={alertId} /></div>;
}
