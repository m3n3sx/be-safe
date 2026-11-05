'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api';
import { parseInvite } from '@/lib/safetyContracts';
import { roleLabels } from '@/lib/api/family';
import type { FamilyRole } from '@/types';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { TextField, Select } from '@/components/ui/FormField';
import { ErrorState } from '@/components/ui/ErrorState';

const joinRoles = (Object.keys(roleLabels) as FamilyRole[]).filter(
  (role) => role !== 'parent' && role !== 'guardian',
);

export function JoinGroup({ initial = '' }: { initial?: string }) {
  const router = useRouter();
  const [raw, setRaw] = useState(initial);
  const [preview, setPreview] = useState<{ group_name: string; group_id: string } | null>(null);
  const [role, setRole] = useState<FamilyRole>('family_member');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  async function check(e?: React.FormEvent) {
    e?.preventDefault();
    setError('');
    setPreview(null);
    const code = parseInvite(raw);
    if (!code) {
      setError('Kod jest nieprawidłowy lub wygasł');
      return;
    }
    setBusy(true);
    const result = await api.post<{ group_name: string; group_id: string }>('/family/groups/join/preview', {
      invite_code: code,
    });
    setBusy(false);
    if (result.error || !result.group_name) {
      setError(result.error || 'Kod jest nieprawidłowy lub wygasł');
      return;
    }
    setPreview({ group_name: result.group_name, group_id: result.group_id });
  }

  async function join() {
    if (!preview) return;
    setBusy(true);
    setError('');
    const code = parseInvite(raw);
    const result = await api.post<{ group_id: string }>('/family/groups/join', {
      invite_code: code,
      role,
    });
    setBusy(false);
    if (result.error || !result.group_id) {
      setError(result.error || 'Nie udało się dołączyć');
      return;
    }
    router.push(`/family/${result.group_id}`);
  }

  return (
    <div className="form-container space-y-5">
      <PageHeader
        title="Dołącz do grupy"
        description="Sprawdź nazwę grupy i potwierdź dołączenie. Rola rodzica jest nadawana przez właściciela."
      />
      <form className="space-y-4" onSubmit={check}>
        <TextField
          label="Kod lub link zaproszenia"
          value={raw}
          onChange={(e) => {
            setRaw(e.target.value);
            setPreview(null);
          }}
          autoCapitalize="characters"
          required
        />
        <Button type="submit" variant="secondary" loading={busy}>
          Sprawdź kod
        </Button>
      </form>
      {error && <ErrorState message={error} />}
      {preview && (
        <section className="panel space-y-4">
          <h2 className="text-2xl font-bold">{preview.group_name}</h2>
          <p>Dołączysz jako członek tej grupy dopiero po potwierdzeniu.</p>
          <Select label="Twoja rola" value={role} onChange={(e) => setRole(e.target.value as FamilyRole)}>
            {joinRoles.map((value) => (
              <option key={value} value={value}>
                {roleLabels[value]}
              </option>
            ))}
          </Select>
          <Button loading={busy} onClick={join}>
            Dołącz do {preview.group_name}
          </Button>
        </section>
      )}
    </div>
  );
}
