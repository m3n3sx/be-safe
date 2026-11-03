'use client';
import api from '@/lib/api';
import { useApiResource, useMutation } from '@/hooks/useApiResource';
import { Button } from '@/components/ui/Button';
import { ErrorState } from '@/components/ui/ErrorState';
import { Skeleton } from '@/components/ui/Skeleton';
export function CheckinAction({ onDone }: { onDone?: () => void }) {
  const resource = useApiResource<{ checked_in_today: boolean; last_at: string | null }>('/users/me/checkin/today', 60000); const mutation = useMutation();
  return <section className="panel space-y-3"><h2 className="text-xl font-bold">Daj znak bliskim</h2>{resource.loading ? <Skeleton /> : resource.data && <p>{resource.data.checked_in_today && resource.data.last_at ? `Dzisiejszy meldunek: ${new Date(resource.data.last_at).toLocaleTimeString('pl-PL', { timeZone: 'Europe/Warsaw', hour: '2-digit', minute: '2-digit' })}` : 'Nie masz jeszcze dzisiejszego meldunku.'}</p>}<Button className="sos-link" loading={mutation.busy} onClick={() => mutation.run(() => api.post('/users/me/checkin', { status: 'safe' }), async () => { await resource.reload(); onDone?.(); })}>Jestem bezpieczny / bezpieczna</Button>{(resource.error || mutation.error) && <ErrorState message={mutation.error || resource.error} onRetry={resource.reload} />}</section>;
}
