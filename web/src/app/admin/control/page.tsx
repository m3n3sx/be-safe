'use client';
import { useState } from 'react';
import AdminShell from '@/components/ui/AdminShell';
import { Card } from '@/components/ui/Card';
import { PageHeader } from '@/components/layout/PageHeader';
import { ResourceState } from '@/components/ui/ResourceState';
import { Button } from '@/components/ui/Button';
import { TextField, TextArea, Select } from '@/components/ui/FormField';
import { Dialog } from '@/components/ui/Dialog';
import { ErrorState } from '@/components/ui/ErrorState';
import { useApiResource, useMutation } from '@/hooks/useApiResource';
import { useAdminAccess } from '@/hooks/useAdminAccess';
import api, { asArray } from '@/lib/api';
type Config = { key: string; value: unknown; description?: string };
type Flag = { key: string; enabled: boolean; description?: string; segment?: string };
export default function ControlPage() {
  const access = useAdminAccess();
  const config = useApiResource<{ config: Config[] }>(access.isAdmin ? '/admin/config' : null);
  const flags = useApiResource<{ flags: Flag[] }>(access.isAdmin ? '/admin/flags' : null);
  const mutation = useMutation();
  const [message, setMessage] = useState('');
  return (
    <AdminShell>
      <PageHeader
        title="Konfiguracja"
        description="Ustawienia działania aplikacji i komunikaty do użytkowników."
      />
      {message && (
        <p role="status" className="panel mb-4 text-success">
          {message}
        </p>
      )}
      {mutation.error && <ErrorState message={mutation.error} />}
      <div className="space-y-5">
        <Card>
          <h2 className="text-xl font-bold mb-4">Dostępność funkcji</h2>
          <ResourceState
            {...flags}
            empty={!asArray(flags.data?.flags).length}
            onRetry={flags.reload}
          />
          <ul className="space-y-4">
            {asArray(flags.data?.flags).map((flag) => (
              <li
                key={flag.key}
                className="flex flex-wrap items-center gap-3 border-b border-border py-3"
              >
                <div className="flex-1 min-w-40">
                  <h3 className="font-bold break-all">{flag.key}</h3>
                  <p className="text-ink-2">{flag.description}</p>
                  {flag.segment && (
                    <p className="text-sm">
                      Grupa odbiorców:{' '}
                      {(
                        {
                          all: 'Wszyscy',
                          normal: 'Standardowy widok',
                          kids: 'Dzieci',
                          senior: 'Seniorzy',
                        } as Record<string, string>
                      )[flag.segment] || flag.segment}
                    </p>
                  )}
                </div>
                <Button
                  variant="secondary"
                  aria-pressed={flag.enabled === true}
                  disabled={!access.can('flags.write') || mutation.busy}
                  onClick={() =>
                    void mutation.run(
                      () =>
                        api.put(`/admin/flags/${flag.key}`, {
                          enabled: !flag.enabled,
                          segment: flag.segment,
                        }),
                      async () => {
                        setMessage('Zapisano dostępność funkcji.');
                        await flags.reload();
                      },
                    )
                  }
                >
                  {flag.enabled ? 'Włączona — wyłącz' : 'Wyłączona — włącz'}
                </Button>
              </li>
            ))}
          </ul>
        </Card>
        <Card>
          <h2 className="text-xl font-bold mb-4">Parametry aplikacji</h2>
          <ResourceState
            {...config}
            empty={!asArray(config.data?.config).length}
            onRetry={config.reload}
          />
          <div className="space-y-5">
            {asArray(config.data?.config).map((item) => (
              <ConfigRow
                key={`${item.key}:${JSON.stringify(item.value)}`}
                config={item}
                editable={access.can('config.write')}
                onDone={config.reload}
              />
            ))}
          </div>
        </Card>
        {access.can('broadcast.send') && <Broadcast />}
      </div>
    </AdminShell>
  );
}
function ConfigRow({
  config,
  editable,
  onDone,
}: {
  config: Config;
  editable: boolean;
  onDone: () => Promise<void>;
}) {
  const [value, setValue] = useState(JSON.stringify(config.value) ?? '');
  const [message, setMessage] = useState('');
  const mutation = useMutation();
  return (
    <form
      className="space-y-3 border-b border-border pb-4"
      onSubmit={(e) => {
        e.preventDefault();
        let parsed: unknown = value;
        try {
          parsed = JSON.parse(value);
        } catch {
          /* Plain strings are supported by the existing API. */
        }
        void mutation.run(
          () => api.put(`/admin/config/${config.key}`, { value: parsed }),
          async () => {
            setMessage('Zapisano parametr.');
            await onDone();
          },
        );
      }}
    >
      <TextField
        label={config.key}
        hint={config.description}
        value={value}
        onChange={(e) => setValue(e.target.value)}
        disabled={!editable}
      />
      {mutation.error && <ErrorState message={mutation.error} />}
      {message && <p role="status">{message}</p>}
      {editable && (
        <Button variant="secondary" loading={mutation.busy}>
          Zapisz parametr
        </Button>
      )}
    </form>
  );
}
function Broadcast() {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [segment, setSegment] = useState('all');
  const [open, setOpen] = useState(false);
  const [message, setMessage] = useState('');
  const mutation = useMutation();
  return (
    <Card>
      <h2 className="text-xl font-bold mb-4">Komunikat do użytkowników</h2>
      <form
        className="space-y-4"
        onSubmit={(e) => {
          e.preventDefault();
          mutation.setError('');
          setOpen(true);
        }}
      >
        <TextField
          label="Tytuł powiadomienia"
          required
          value={title}
          onChange={(e) => setTitle(e.target.value)}
        />
        <TextArea
          label="Treść komunikatu"
          required
          value={body}
          onChange={(e) => setBody(e.target.value)}
        />
        <Select label="Odbiorcy" value={segment} onChange={(e) => setSegment(e.target.value)}>
          <option value="all">Wszyscy</option>
          <option value="normal">Widok standardowy</option>
          <option value="kids">Widok dziecka</option>
          <option value="senior">Widok seniora</option>
        </Select>
        <Button disabled={!title.trim() || !body.trim()}>Sprawdź i wyślij</Button>
        <p className="text-sm text-ink-2">
          Komunikat trafia do skrzynki i obsługiwanych urządzeń. Obowiązuje limit wysyłek; przyjęcie
          nie potwierdza odczytu.
        </p>
        {message && <p role="status">{message}</p>}
      </form>
      <Dialog
        open={open}
        title="Wysłać komunikat?"
        onClose={() => {
          if (!mutation.busy) setOpen(false);
        }}
      >
        <div className="space-y-4">
          <p className="font-bold">{title}</p>
          <p className="whitespace-pre-wrap">{body}</p>
          {mutation.error && <ErrorState message={mutation.error} />}
          <Button
            loading={mutation.busy}
            onClick={() =>
              void mutation.run(
                () =>
                  api.post<{ recipients?: number }>('/admin/broadcast', {
                    title,
                    body,
                    segment,
                    confirm: true,
                  }),
                (result) => {
                  setMessage(
                    `Przyjęto komunikat. Liczba odbiorców: ${result.recipients ?? 'brak danych'}.`,
                  );
                  setOpen(false);
                  setTitle('');
                  setBody('');
                },
              )
            }
          >
            Potwierdzam wysyłkę
          </Button>
          <Button variant="secondary" disabled={mutation.busy} onClick={() => setOpen(false)}>
            Anuluj
          </Button>
        </div>
      </Dialog>
    </Card>
  );
}
