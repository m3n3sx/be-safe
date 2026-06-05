'use client';

import { useEffect, useState, useCallback } from 'react';
import AdminShell from '@/components/ui/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { useAdminAccess } from '@/hooks/useAdminAccess';
import api from '@/lib/api';
import {
  AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid,
} from 'recharts';

interface Stats {
  users: { n: number; banned: number; admins: number; new_week: number };
  alerts: { n: number; active: number; new_24h: number };
  groups: { n: number };
  pets: { n: number; lost: number };
  reports_pending: number;
}
interface SystemData {
  process?: { rss_mb: number; cpu_pct_avg: number; uptime_s: number; heap_used_mb: number; heap_total_mb: number };
  database?: { size_pretty?: string; connections?: { total: number; active: number }; max_connections?: number; counts?: Record<string, number> };
  gcp?: { available: boolean; cloud_run?: Record<string, number>; gcs?: Record<string, number> };
}
interface Health { ok_count: number; total: number; checks: { name: string; ok: boolean; latency_ms: number; last_error?: string }[] }
interface Backup { source?: string; age_hours?: number; is_stale?: boolean; latest?: { status?: string } }
interface Series { day: string; users: number; alerts: number }

export default function AdminDashboard() {
  const access = useAdminAccess();
  const [stats, setStats] = useState<Stats | null>(null);
  const [system, setSystem] = useState<SystemData | null>(null);
  const [health, setHealth] = useState<Health | null>(null);
  const [backup, setBackup] = useState<Backup | null>(null);
  const [series, setSeries] = useState<Series[]>([]);

  const load = useCallback(async () => {
    const [s, sys, h, b, a] = await Promise.all([
      api.get<Stats & { error?: string }>('/admin/stats'),
      api.get<SystemData & { error?: string }>('/admin/system'),
      api.get<Health & { error?: string }>('/admin/integrations/health'),
      api.get<Backup & { error?: string }>('/admin/backup-status'),
      api.get<{ series: Series[]; error?: string }>('/admin/analytics?days=14'),
    ]);
    if (!s.error) setStats(s);
    if (!sys.error) setSystem(sys);
    if (!h.error) setHealth(h);
    if (!b.error) setBackup(b);
    if (!a.error && a.series) setSeries(a.series);
  }, []);

  useEffect(() => { if (access.isAdmin) load(); }, [access.isAdmin, load]);

  return (
    <AdminShell>
      <div className="max-w-7xl mx-auto space-y-6">
        <div>
          <h1 className="text-2xl font-semibold text-ink">Dashboard</h1>
          <p className="text-sm text-ink-2">Przegląd systemu be:Safe</p>
        </div>

        {/* KPI */}
        {stats && (
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
            <Kpi label="Użytkownicy" value={stats.users.n} sub={`+${stats.users.new_week} / tydz.`} accent="mint" />
            <Kpi label="Alerty aktywne" value={stats.alerts.active} sub={`+${stats.alerts.new_24h} / 24h`} accent="aqua" />
            <Kpi label="Grupy" value={stats.groups.n} sub={`${stats.pets.n} zwierząt`} accent="navy" />
            <Kpi label="Do moderacji" value={stats.reports_pending} sub={`${stats.users.banned} ban`} accent="coral" alert={stats.reports_pending > 0} />
          </div>
        )}

        {/* Wykres wzrostu */}
        <Card>
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-medium text-ink">Wzrost (14 dni)</h2>
            <div className="flex gap-3 text-xs text-ink-2">
              <span className="flex items-center gap-1"><i className="w-2.5 h-2.5 rounded-full inline-block" style={{ background: 'var(--serenity-mint)' }} /> użytkownicy</span>
              <span className="flex items-center gap-1"><i className="w-2.5 h-2.5 rounded-full inline-block" style={{ background: 'var(--serenity-coral)' }} /> alerty</span>
            </div>
          </div>
          <div style={{ width: '100%', height: 220 }}>
            <ResponsiveContainer>
              <AreaChart data={series} margin={{ top: 4, right: 8, left: -16, bottom: 0 }}>
                <defs>
                  <linearGradient id="gU" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#9DF4CB" stopOpacity={0.6} /><stop offset="100%" stopColor="#9DF4CB" stopOpacity={0} /></linearGradient>
                  <linearGradient id="gA" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#FF7A7A" stopOpacity={0.5} /><stop offset="100%" stopColor="#FF7A7A" stopOpacity={0} /></linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                <XAxis dataKey="day" tick={{ fontSize: 10, fill: 'var(--ink-2)' }} tickFormatter={(d: string) => d.slice(5)} />
                <YAxis tick={{ fontSize: 10, fill: 'var(--ink-2)' }} allowDecimals={false} />
                <Tooltip contentStyle={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 12, color: 'var(--ink)' }} />
                <Area type="monotone" dataKey="users" stroke="#9DF4CB" fill="url(#gU)" strokeWidth={2} />
                <Area type="monotone" dataKey="alerts" stroke="#FF7A7A" fill="url(#gA)" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <div className="grid lg:grid-cols-2 gap-3">
          {/* System resources */}
          {system?.process && (
            <Card>
              <h2 className="font-medium text-ink mb-3">Zasoby serwera</h2>
              <div className="grid grid-cols-2 gap-3 text-sm">
                <Metric label="RAM (RSS)" value={`${system.process.rss_mb} MB`} />
                <Metric label="CPU śr." value={`${system.process.cpu_pct_avg}%`} />
                <Metric label="Heap" value={`${system.process.heap_used_mb}/${system.process.heap_total_mb} MB`} />
                <Metric label="Uptime" value={`${Math.floor(system.process.uptime_s / 60)} min`} />
                {system.database?.size_pretty && <Metric label="Baza" value={system.database.size_pretty} />}
                {system.database?.connections && <Metric label="Połączenia DB" value={`${system.database.connections.active}/${system.database.connections.total}`} />}
                {system.gcp?.cloud_run?.instances != null && <Metric label="Instancje" value={`${system.gcp.cloud_run.instances}`} />}
                {system.gcp?.cloud_run?.mem_util_pct != null && <Metric label="Cloud Run RAM" value={`${system.gcp.cloud_run.mem_util_pct}%`} />}
              </div>
            </Card>
          )}

          {/* Integracje + backup */}
          <Card>
            <h2 className="font-medium text-ink mb-3">Integracje {health && <span className="text-ink-2 text-sm font-normal">({health.ok_count}/{health.total})</span>}</h2>
            <div className="space-y-1.5">
              {health?.checks.map((c) => (
                <div key={c.name} className="flex items-center justify-between text-sm">
                  <span className="text-ink-2 capitalize">{c.name}</span>
                  <span className="flex items-center gap-2">
                    <span className="text-ink-2 text-xs">{c.latency_ms}ms</span>
                    <Badge variant={c.ok ? 'mint' : 'coral'}>{c.ok ? 'OK' : 'błąd'}</Badge>
                  </span>
                </div>
              ))}
            </div>
            {backup && (
              <div className={`mt-3 pt-3 border-t border-border text-sm flex items-center gap-2`}>
                <span>{backup.is_stale ? '⚠️' : '✅'}</span>
                <span className="text-ink-2">Backup DB:</span>
                <span className="text-ink">{backup.age_hours != null ? `${backup.age_hours}h temu` : '—'} ({backup.latest?.status || '?'})</span>
              </div>
            )}
          </Card>
        </div>
      </div>
    </AdminShell>
  );
}

function Kpi({ label, value, sub, accent, alert }: { label: string; value: number; sub?: string; accent: 'mint' | 'aqua' | 'navy' | 'coral'; alert?: boolean }) {
  const c = { mint: '#9DF4CB', aqua: '#9EEBEC', navy: '#1A2027', coral: '#FF7A7A' }[accent];
  return (
    <Card className={`relative overflow-hidden ${alert ? 'ring-1 ring-coral' : ''}`}>
      <div className="absolute -top-6 -right-6 w-20 h-20 rounded-full opacity-30" style={{ background: `radial-gradient(circle, ${c} 0%, transparent 70%)` }} />
      <p className="text-xs text-ink-2 relative">{label}</p>
      <p className="text-3xl font-semibold text-ink mt-1 relative">{value}</p>
      {sub && <p className="text-xs text-ink-2 mt-1 relative">{sub}</p>}
    </Card>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl bg-surface-2 p-3">
      <p className="text-ink-2 text-xs">{label}</p>
      <p className="text-ink font-medium mt-0.5">{value}</p>
    </div>
  );
}
