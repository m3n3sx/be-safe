'use client';
import { useState } from 'react';
import { Button } from './Button';
import { Dialog } from './Dialog';
import { ErrorState } from './ErrorState';
import { useMutation } from '@/hooks/useApiResource';
export function ConfirmAction({
  label,
  title,
  description,
  action,
  onDone,
}: {
  label: string;
  title?: string;
  description: string;
  action: () => Promise<{ error?: string; httpStatus?: number }>;
  onDone: () => void | Promise<void>;
}) {
  const [open, setOpen] = useState(false);
  const mutation = useMutation();
  return (
    <>
      <Button variant="quiet" onClick={() => setOpen(true)}>
        {label}
      </Button>
      <Dialog
        open={open}
        title={title || label}
        onClose={() => {
          if (!mutation.busy) setOpen(false);
        }}
      >
        <p className="mb-4">{description}</p>
        {mutation.error && <ErrorState message={mutation.error} />}
        <div className="flex flex-wrap gap-2">
          <Button
            variant="danger"
            loading={mutation.busy}
            onClick={() =>
              mutation.run(action, async () => {
                setOpen(false);
                await onDone();
              })
            }
          >
            Potwierdzam
          </Button>
          <Button variant="secondary" disabled={mutation.busy} onClick={() => setOpen(false)}>
            Anuluj
          </Button>
        </div>
      </Dialog>
    </>
  );
}
