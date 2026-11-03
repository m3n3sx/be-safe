'use client';
import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import api from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';
import { useApiResource, useMutation } from '@/hooks/useApiResource';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { TextArea } from '@/components/ui/TextArea';
import { ErrorState } from '@/components/ui/ErrorState';
import { Skeleton } from '@/components/ui/Skeleton';
import { EmergencyCall } from '@/components/safety/EmergencyCall';
type Ping = {
  ping_id: string;
  group_id: string;
  group_name: string;
  from_username: string;
  recipient_id: string;
  sent_at: string;
  response_status?: string;
  response_message?: string;
  response_at?: string;
};
export default function Page() {
  const { pingId } = useParams<{ pingId: string }>();
  const { user } = useAuth();
  const resource = useApiResource<Ping>(`/family/pings/${pingId}`, 15000);
  const mutation = useMutation();
  const [message, setMessage] = useState('');
  const [now, setNow] = useState(0);
  useEffect(() => {
    const tick = () => setNow(Date.now());
    const initial = setTimeout(tick, 0);
    const timer = setInterval(tick, 1000);
    return () => {
      clearTimeout(initial);
      clearInterval(timer);
    };
  }, []);
  const ping = resource.data;
  const expired = !!ping && now > new Date(ping.sent_at).getTime() + 30 * 60000;
  async function respond(status: 'ok' | 'not_ok') {
    if (
      !ping ||
      ping.response_status ||
      Date.now() > new Date(ping.sent_at).getTime() + 30 * 60000
    ) {
      await resource.reload();
      return;
    }
    await mutation.run(
      () => api.post(`/family/pings/${pingId}/respond`, { status, message: message.trim() }),
      resource.reload,
    );
  }
  return (
    <div className="form-container space-y-5">
      <PageHeader title="Prośba o kontakt" description={ping?.group_name} />
      <EmergencyCall />
      {resource.loading && <Skeleton />}
      {(resource.error || mutation.error) && (
        <ErrorState message={mutation.error || resource.error} onRetry={resource.reload} />
      )}
      {ping && (
        <section className="panel space-y-4">
          <h2 className="text-xl font-bold">{ping.from_username} prosi o znak</h2>
          <p>Wysłano: {new Date(ping.sent_at).toLocaleString('pl-PL')}</p>
          {ping.response_status ? (
            <div role="status">
              <p className="font-bold">
                {ping.response_status === 'ok'
                  ? 'Odpowiedź: wszystko OK'
                  : ping.response_status === 'not_ok'
                    ? 'Odpowiedź: potrzebuję pomocy'
                    : 'Prośba wygasła'}
              </p>
              {ping.response_message && <p>{ping.response_message}</p>}
            </div>
          ) : expired ? (
            <p>Prośba wygasła. Skontaktuj się bezpośrednio z grupą.</p>
          ) : ping.recipient_id === user?.id ? (
            <>
              <TextArea
                label="Notatka (opcjonalnie)"
                maxLength={300}
                rows={3}
                value={message}
                onChange={(e) => setMessage(e.target.value)}
              />
              <div className="flex flex-wrap gap-3">
                <Button loading={mutation.busy} onClick={() => respond('ok')}>
                  Wszystko OK
                </Button>
                <Button variant="danger" disabled={mutation.busy} onClick={() => respond('not_ok')}>
                  Potrzebuję pomocy
                </Button>
              </div>
            </>
          ) : (
            <p>Oczekiwanie na odpowiedź odbiorcy.</p>
          )}
          <Link className="btn btn-secondary" href={`/family/${ping.group_id}`}>
            Przejdź do grupy
          </Link>
        </section>
      )}
    </div>
  );
}
