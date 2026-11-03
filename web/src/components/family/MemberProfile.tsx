'use client';
import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import api, { asArray } from '@/lib/api';
import type { FamilyMember } from '@/types';
import { groupPath, memberPlace, roleLabels, useGroup } from '@/lib/api/family';
import { useAuth } from '@/contexts/AuthContext';
import { useApiResource, useMutation } from '@/hooks/useApiResource';
import { GroupHeader } from './GroupHeader';
import { GroupPingAction } from './GroupPingAction';
import { MemberPrivacy } from './MemberPrivacy';
import { GhostModeControl } from './GhostModeControl';
import { PlacesMap } from '@/components/map/PlacesMap';
import { Button } from '@/components/ui/Button';
import { Select, TextField } from '@/components/ui/FormField';
import { ConfirmAction } from '@/components/ui/ConfirmAction';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
export function MemberProfile({ groupId, memberId }: { groupId: string; memberId: string }) {
  const { user } = useAuth();
  const group = useGroup(groupId);
  const resource = useApiResource<{ members: FamilyMember[] }>(
    `${groupPath(groupId)}/members`,
    30000,
  );
  const mutation = useMutation();
  const router = useRouter();
  const [pinMessage, setPinMessage] = useState('');
  const member = asArray(resource.data?.members).find((m) => m.user_id === memberId);
  const self = user?.id === memberId;
  const point = member ? memberPlace(member) : null;
  const base = `/family/${groupId}/members/${memberId}`;
  const patch = (body: Record<string, unknown>) =>
    mutation.run(
      () => api.patch(`${groupPath(groupId)}/members/${memberId}`, body),
      resource.reload,
    );
  function pin() {
    try {
      const key = `besafe.pinned.${user?.id}`;
      const saved: string[] = JSON.parse(localStorage.getItem(key) || '[]');
      const pins = Array.isArray(saved) ? saved : [];
      if (pins.includes(base)) {
        localStorage.setItem(key, JSON.stringify(pins.filter((p) => p !== base)));
        setPinMessage('Osoba odpięta.');
      } else if (pins.length < 3) {
        localStorage.setItem(key, JSON.stringify([...pins, base]));
        setPinMessage('Osoba przypięta na tym urządzeniu.');
      } else setPinMessage('Możesz przypiąć do 3 osób. Najpierw odepnij jedną z nich.');
    } catch {
      setPinMessage('Nie udało się zapisać przypięcia.');
    }
  }
  return (
    <div className="page-container space-y-5">
      <GroupHeader
        id={groupId}
        title={member?.username || 'Bliska osoba'}
        name={group.group?.name}
      />
      {(resource.loading || group.loading) && <Skeleton />}
      {(resource.error || group.error) && (
        <ErrorState
          message={resource.error || group.error}
          onRetry={() => {
            void resource.reload();
            void group.reload();
          }}
        />
      )}
      {!resource.loading && !resource.error && !member && (
        <EmptyState title="Nie znaleziono osoby w grupie" />
      )}
      {member && (
        <>
          <section className="panel space-y-3">
            <div className="flex items-center gap-4">
              {member.avatar_url && (
                <img
                  src={member.avatar_url}
                  alt={`Zdjęcie: ${member.username}`}
                  className="size-20 rounded-full object-cover"
                />
              )}
              <div>
                <h2 className="text-xl font-bold">{member.username}</h2>
                <p>{roleLabels[member.role]}</p>
              </div>
            </div>
            <dl className="space-y-2">
              <div>
                <dt className="text-ink-2">Ostatnia lokalizacja</dt>
                <dd>
                  {member.is_ghosting
                    ? 'Czasowo ukryta'
                    : member.last_location_at
                      ? new Date(member.last_location_at).toLocaleString('pl-PL')
                      : 'Brak danych'}
                </dd>
              </div>
              <div>
                <dt className="text-ink-2">Ostatnia aktywność</dt>
                <dd>
                  {member.last_seen_at
                    ? new Date(member.last_seen_at).toLocaleString('pl-PL')
                    : 'Brak danych'}
                </dd>
              </div>
              <div>
                <dt className="text-ink-2">Bateria</dt>
                <dd>
                  {member.last_battery_level == null
                    ? 'Brak danych'
                    : `${member.last_battery_level}%`}
                </dd>
              </div>
            </dl>
            <div className="flex flex-wrap gap-2">
              {member.phone ? (
                <a className="btn btn-secondary" href={`tel:${member.phone}`}>
                  Zadzwoń: {member.phone}
                </a>
              ) : (
                <p>Telefon: brak udostępnionego numeru</p>
              )}
              <Button variant="secondary" onClick={pin}>
                Przypnij / odepnij osobę
              </Button>
            </div>
            <p role="status">{pinMessage}</p>
            <GroupPingAction groupId={groupId} />
          </section>
          {point ? (
            <>
              <PlacesMap places={[point]} />
              <a
                className="btn btn-secondary"
                href={`https://www.google.com/maps/dir/?api=1&destination=${point.lat},${point.lng}`}
                target="_blank"
                rel="noreferrer"
              >
                Trasa do ostatniej znanej pozycji ↗
              </a>
            </>
          ) : (
            <EmptyState
              title="Brak udostępnionej lokalizacji"
              description="Brak danych nie oznacza zagrożenia ani braku aktywności."
            />
          )}
          <nav className="flex flex-wrap gap-2" aria-label="Narzędzia osoby">
            {group.guardian && (
              <Link className="btn btn-secondary" href={`${base}/history`}>
                Historia lokalizacji
              </Link>
            )}
            <Link className="btn btn-secondary" href={`${base}/safe-routes`}>
              Bezpieczne trasy
            </Link>
          </nav>
          {(group.owner || group.guardian || self) && (
            <section className="panel space-y-4">
              <h2 className="font-bold text-xl">Ustawienia osoby</h2>
              {group.owner && (
                <Select
                  label="Rola w grupie"
                  value={member.role}
                  disabled={mutation.busy}
                  onChange={(e) => patch({ role: e.target.value })}
                >
                  {Object.entries(roleLabels).map(([value, label]) => (
                    <option key={value} value={value}>
                      {label}
                    </option>
                  ))}
                </Select>
              )}
              {group.guardian && (
                <>
                  {(['tracking_enabled', 'school_hours_silent'] as const).map((field) => (
                    <label className="flex items-center gap-3 min-h-12" key={field}>
                      <input
                        className="size-5"
                        type="checkbox"
                        checked={!!member[field]}
                        disabled={mutation.busy}
                        onChange={(e) => patch({ [field]: e.target.checked })}
                      />
                      {field === 'tracking_enabled'
                        ? 'Śledzenie w grupie'
                        : 'Cisza w godzinach szkolnych'}
                    </label>
                  ))}
                  <p className="text-sm text-ink-2">
                    Te ustawienia nie uruchamiają GPS w zamkniętej przeglądarce.
                  </p>
                </>
              )}
              {(self || (group.guardian && member.role === 'child')) && (
                <TextField
                  label="Zmień zdjęcie (JPEG, PNG lub WebP, do 2 MB)"
                  type="file"
                  accept="image/jpeg,image/png,image/webp"
                  disabled={mutation.busy}
                  onChange={(e) => {
                    const file = e.target.files?.[0];
                    if (!file) return;
                    if (
                      file.size > 2 * 1024 * 1024 ||
                      !['image/jpeg', 'image/png', 'image/webp'].includes(file.type)
                    ) {
                      mutation.setError('Wybierz zdjęcie JPEG, PNG lub WebP do 2 MB.');
                      return;
                    }
                    const form = new FormData();
                    form.append('avatar', file);
                    void mutation.run(
                      () => api.multipart(`/users/${memberId}/avatar`, form),
                      resource.reload,
                    );
                  }}
                />
              )}
              {mutation.error && <ErrorState message={mutation.error} />}
            </section>
          )}
          {group.guardian && member.role === 'child' && (
            <MemberPrivacy groupId={groupId} memberId={memberId} />
          )}
          {self && (
            <>
              <section className="panel">
                <h2 className="font-bold text-xl mb-2">Kto widzi moje dane</h2>
                <p>
                  Odczyt pełnej listy Twoich ustawień udostępniania nie jest obecnie dostępny.
                  Możesz czasowo ukryć lokalizację poniżej.
                </p>
              </section>
              <GhostModeControl />
            </>
          )}
          {group.owner && !self && (
            <ConfirmAction
              label="Usuń osobę z grupy"
              description={`Usunąć ${member.username} z grupy?`}
              action={() => api.delete(`${groupPath(groupId)}/members/${memberId}`)}
              onDone={() => router.push(`/family/${groupId}`)}
            />
          )}
        </>
      )}
    </div>
  );
}
