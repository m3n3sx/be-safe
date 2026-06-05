'use client';

import { useEffect, useState, useCallback } from 'react';
import AdminShell from '@/components/ui/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import api from '@/lib/api';

interface Sys {
  process?: Record<string, unknown>;
  database?: { size_pretty?: string; connections?: { total: number; active: number; idle: number }; max_connections?: number; counts?: Record<string, number>; top_tables?: { table: string; size: string }[] };
  gcp?: { available: boolean; cloud_run?: Record<string, number>; gcs?: Record<string, number>; service?: string; bucket?: string };
  time?: string;
}

export default function SystemPage() {
  const [sys, setSys] = useState<Sys | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async () => {
    setRefreshing(true);
    const r = await api.get<Sys & { error?: string }>('/admin/system');
    if (!r.error) setSys(r);
    setRefreshing(false);
  }, []);
  useEffect(() => { load(); }, [load]);

  const proc = sys?.process as Record<string, number | string> | undefined;

  return (
    <AdminShell>
      <div className="max-w-5xl mx-auto space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-ink">System</h1>
            <p className="text-sm text-ink-2">Zasoby serwera, baza i metryki GCP</p>
          </div>
          <button onClick={load} className="px-4 py-2 rounded-full bg-navy text-white text-sm disabled:opacity-50" disabled={refreshing}>
            {refreshing ? 'Odświeżam…' : 'Odśwież'}
          </button>
        </div>

        {/* Proces */}
        {proc && (
          <Card>
            <h2 className="font-medium text-ink mb-3">Proces backendu</h2>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
              <M l="Node" v={String(proc.node_version)} /><M l="Platforma" v={String(proc.platform)} />
              <M l="RAM (RSS)" v={`${proc.rss_mb} MB`} /><M l="CPU śr." v={`${proc.cpu_pct_avg}%`} />
              <M l="Heap" v={`${proc.heap_used_mb}/${proc.heap_total_mb} MB`} /><M l="Uptime" v={`${Math.floor(Number(proc.uptime_s) / 60)} min`} />
              <M l="OS RAM" v={`${proc.os_free_mem_mb}/${proc.os_total_mem_mb} MB`} /><M l="CPU rdzenie" v={String(proc.cpus)} />
            </div>
          </Card>
        )}

        {/* Baza */}
        {sys?.database && (
          <Card>
            <h2 className="font-medium text-ink mb-3">Baza danych</h2>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm mb-3">
              <M l="Rozmiar" v={sys.database.size_pretty || '—'} />
              <M l="Połączenia" v={`${sys.database.connections?.active ?? '?'} akt. / ${sys.database.connections?.total ?? '?'}`} />
              <M l="Max połączeń" v={String(sys.database.max_connections ?? '—')} />
              <M l="Użytkownicy" v={String(sys.database.counts?.users ?? '—')} />
            </div>
            {sys.database.top_tables && (
              <div className="text-sm">
                <p className="text-ink-2 text-xs mb-1">Największe tabele</p>
                {sys.database.top_tables.map((t) => (
                  <div key={t.table} className="flex justify-between py-1 border-b border-border last:border-0">
                    <span className="text-ink-2">{t.table}</span><span className="text-ink">{t.size}</span>
                  </div>
                ))}
              </div>
            )}
          </Card>
        )}

        {/* GCP */}
        <Card>
          <div className="flex items-center gap-2 mb-3">
            <h2 className="font-medium text-ink">Google Cloud</h2>
            <Badge variant={sys?.gcp?.available ? 'mint' : 'coral'}>{sys?.gcp?.available ? 'połączono' : 'niedostępne'}</Badge>
          </div>
          {sys?.gcp?.available ? (
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
              <M l="Cloud Run CPU" v={`${sys.gcp.cloud_run?.cpu_util_pct ?? '—'}%`} />
              <M l="Cloud Run RAM" v={`${sys.gcp.cloud_run?.mem_util_pct ?? '—'}%`} />
              <M l="Instancje" v={String(sys.gcp.cloud_run?.instances ?? '—')} />
              <M l="Req/min" v={String(sys.gcp.cloud_run?.req_per_min ?? '—')} />
              <M l="GCS obiekty" v={String(sys.gcp.gcs?.object_count ?? '—')} />
              <M l="GCS rozmiar" v={sys.gcp.gcs?.total_bytes != null ? `${(sys.gcp.gcs.total_bytes / 1048576).toFixed(1)} MB` : '—'} />
            </div>
          ) : <p className="text-ink-2 text-sm">Metryki GCP chwilowo niedostępne.</p>}
        </Card>
        {sys?.time && <p className="text-xs text-ink-2 text-center">Ostatnia aktualizacja: {new Date(sys.time).toLocaleTimeString('pl')}</p>}
      </div>
    </AdminShell>
  );
}

function M({ l, v }: { l: string; v: string }) {
  return <div className="rounded-xl bg-surface-2 p-3"><p className="text-ink-2 text-xs">{l}</p><p className="text-ink font-medium mt-0.5 break-words">{v}</p></div>;
}
