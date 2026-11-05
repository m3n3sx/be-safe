'use client';
import { useState } from 'react';
import api from '@/lib/api';
import { groupPath } from '@/lib/api/family';
import { useMutation } from '@/hooks/useApiResource';
import { Button } from '@/components/ui/Button';
import { Dialog } from '@/components/ui/Dialog';
import { ErrorState } from '@/components/ui/ErrorState';
export function GroupPingAction({ groupId }: { groupId: string }) {
  const [open, setOpen] = useState(false);
  const [result, setResult] = useState<number | null>(null);
  const [message, setMessage] = useState('');
  const mutation = useMutation();
  return (
    <div>
      <Button variant="secondary" onClick={() => setOpen(true)}>
        Poproś grupę o kontakt
      </Button>
      {result !== null && (
        <p role="status" className="mt-2 text-sm">
          {message || `Zapisano prośbę dla ${result} osób. To nie jest potwierdzenie odczytania.`}
        </p>
      )}
      <Dialog
        open={open}
        title="Poprosić grupę o kontakt?"
        onClose={() => {
          if (!mutation.busy) setOpen(false);
        }}
      >
        <p className="mb-4">Prośba trafi do wszystkich pozostałych członków grupy.</p>
        {mutation.error && <ErrorState message={mutation.error} />}
        <Button
          loading={mutation.busy}
          onClick={() =>
            mutation.run(
              () => api.post<{ recipients: number; message?: string }>(`${groupPath(groupId)}/ping`),
              (r) => {
                setResult(r.recipients);
                setMessage(r.message || '');
                setOpen(false);
              },
            )
          }
        >
          Wyślij prośbę do grupy
        </Button>
      </Dialog>
    </div>
  );
}
