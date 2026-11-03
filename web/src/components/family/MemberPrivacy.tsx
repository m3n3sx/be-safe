'use client';
import api, { asArray } from '@/lib/api';
import { groupPath } from '@/lib/api/family';
import { useApiResource, useMutation } from '@/hooks/useApiResource';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
const labels: Record<string, string> = {
  location: 'Lokalizacja',
  history: 'Historia lokalizacji',
  battery: 'Bateria',
  online: 'Ostatnia aktywność',
  phone: 'Telefon',
  alerts: 'Zgłoszenia',
  checkin: 'Meldunki',
};
export function MemberPrivacy({ groupId, memberId }: { groupId: string; memberId: string }) {
  const resource = useApiResource<{
    matrix: { viewer_id: string; viewer_username: string; visibility: Record<string, boolean> }[];
  }>(`${groupPath(groupId)}/visibility-matrix/${memberId}`);
  const mutation = useMutation();
  return (
    <section className="panel space-y-4">
      <h2 className="font-bold text-xl">Kto widzi dane dziecka</h2>
      {resource.loading && <Skeleton />}
      {(resource.error || mutation.error) && (
        <ErrorState message={mutation.error || resource.error} onRetry={resource.reload} />
      )}
      {!resource.loading && !resource.error && !asArray(resource.data?.matrix).length && (
        <EmptyState title="Brak odbiorców ustawień" />
      )}
      {asArray(resource.data?.matrix).map((row) => (
        <fieldset className="border border-border rounded-xl p-3" key={row.viewer_id}>
          <legend className="font-bold px-2">{row.viewer_username}</legend>
          <div className="grid sm:grid-cols-2 gap-2">
            {Object.entries(row.visibility || {}).map(([field, granted]) => (
              <label className="flex items-center gap-3 min-h-12" key={field}>
                <input
                  type="checkbox"
                  className="size-5"
                  checked={granted}
                  disabled={mutation.busy}
                  onChange={() =>
                    mutation.run(
                      () =>
                        api.put(`${groupPath(groupId)}/visibility/${memberId}`, {
                          viewer_id: row.viewer_id,
                          field,
                          granted: !granted,
                        }),
                      resource.reload,
                    )
                  }
                />
                {labels[field] || field}
              </label>
            ))}
          </div>
        </fieldset>
      ))}
    </section>
  );
}
