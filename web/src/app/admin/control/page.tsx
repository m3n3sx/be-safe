'use client';

import { useEffect, useState, useCallback } from 'react';
import AdminShell from '@/components/ui/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { useAdminAccess } from '@/hooks/useAdminAccess';
import api from '@/lib/api';

interface Cfg { key: string; value: unknown; description?: string }
interface Flag { key: string; enabled: boolean; description?: string; segment?: string }

export default function ControlPage() {
  const access = useAdminAccess();
  const [config, setConfig] = useState<Cfg[]>([]);
  const [flags, setFlags] = useState<Flag[]>([]);
  const [msg, setMsg] = useState<string | null>(null);

  const load = useCallback(async () => {
    const [c, f] = await Promise.all([
      api.get<{ config: Cfg[]; error?: string }>('/admin/config'),
      api.get<{ flags: Flag[]; error?: string }>('/admin/flags'),
    ]);
    if (!c.error) setConfig(c.config);
    if (!f.error) setFlags(f.flags);
  }, []);
  useEffect(() => { if (access.isAdmin) load(); }, [access.isAdmin, load]);

  const flash = (m: string) => { setMsg(m); setTimeout(() => setMsg(null), 2500); };

  const saveConfig = async (key: string, raw: string) => {
    let value: unknown = raw;
    try { value = JSON.parse(raw); } catch { /* string */ }
    const r = await api.put(`/admin/config/${key}`, { value });
    if (r.error) flash(`Błąd: ${r.error}`); else { flash(`Zapisano ${key}`); load(); }
  };

  const toggleFlag = async (f: Flag) => {
    const r = await api.put(`/admin/flags/${f.key}`, { enabled: !f.enabled, segment: f.segment });
    if (r.error) flash(`Błąd: ${r.error}`); else { flash(`${f.key}: ${!f.enabled ? 'ON' : 'OFF'}`); load(); }
  };

  const canConfigWrite = access.can('config.write');
  const canFlags = access.can('flags.write');
  const canBroadcast = access.can('broadcast.send');

  return (
    <AdminShell>
      <div className="max-w-4xl mx-auto space-y-6">
        <div>
          <h1 className="text-2xl font-semibold text-ink">Kontrola</h1>
          <p className="text-sm text-ink-2">Konfiguracja runtime, feature flags i broadcast</p>
        </div>
        {msg && <div className="rounded-xl bg-mint/20 text-ink px-4 py-2 text-sm">{msg}</div>}

        {/* Feature flags */}
        <Card>
          <h2 className="font-medium text-ink mb-3">Feature flags</h2>
          <div className="space-y-2">
            {flags.map((f) => (
              <div key={f.key} className="flex items-center justify-between py-1.5">
                <div className="min-w-0">
                  <p className="text-ink text-sm font-medium">{f.key} {f.segment && <Badge variant="aqua">{f.segment}</Badge>}</p>
                  {f.description && <p className="text-ink-2 text-xs">{f.description}</p>}
                </div>
                <button disabled={!canFlags} onClick={() => toggleFlag(f)}
                  className={`relative w-12 h-7 rounded-full transition disabled:opacity-40 ${f.enabled ? 'bg-mint' : 'bg-surface-2'}`}>
                  <span className={`absolute top-1 w-5 h-5 rounded-full bg-navy transition-all ${f.enabled ? 'left-6' : 'left-1'}`} />
                </button>
              </div>
            ))}
            {!canFlags && <p className="text-ink-2 text-xs">Brak uprawnienia flags.write — podgląd tylko.</p>}
          </div>
        </Card>

        {/* Config */}
        <Card>
          <h2 className="font-medium text-ink mb-3">Konfiguracja runtime</h2>
          <div className="space-y-3">
            {config.map((c) => (
              <ConfigRow key={c.key} cfg={c} editable={canConfigWrite} onSave={saveConfig} />
            ))}
          </div>
        </Card>

        {/* Broadcast */}
        {canBroadcast && <BroadcastCard onFlash={flash} />}
      </div>
    </AdminShell>
  );
}

function ConfigRow({ cfg, editable, onSave }: { cfg: Cfg; editable: boolean; onSave: (k: string, v: string) => void }) {
  const [val, setVal] = useState(JSON.stringify(cfg.value));
  return (
    <div className="flex items-center gap-3">
      <div className="flex-1 min-w-0">
        <p className="text-ink text-sm font-medium">{cfg.key}</p>
        {cfg.description && <p className="text-ink-2 text-xs">{cfg.description}</p>}
      </div>
      <input value={val} onChange={(e) => setVal(e.target.value)} disabled={!editable}
        className="w-28 px-3 py-1.5 rounded-lg bg-surface-2 text-ink text-sm border border-border disabled:opacity-50" />
      {editable && <button onClick={() => onSave(cfg.key, val)} className="px-3 py-1.5 rounded-lg bg-navy text-white text-xs">Zapisz</button>}
    </div>
  );
}

function BroadcastCard({ onFlash }: { onFlash: (m: string) => void }) {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [segment, setSegment] = useState('all');
  const [sending, setSending] = useState(false);

  const send = async () => {
    if (!title || !body) return onFlash('Wypełnij tytuł i treść');
    if (!confirm(`Wysłać broadcast do segmentu "${segment}"?`)) return;
    setSending(true);
    const r = await api.post('/admin/broadcast', { title, body, segment, confirm: true });
    setSending(false);
    if (r.error) onFlash(`Błąd: ${r.error}`);
    else { onFlash(`Wysłano do ${(r as { recipients?: number }).recipients ?? '?'} odbiorców`); setTitle(''); setBody(''); }
  };

  return (
    <Card>
      <h2 className="font-medium text-ink mb-3">📢 Broadcast</h2>
      <div className="space-y-2">
        <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Tytuł powiadomienia"
          className="w-full px-3 py-2 rounded-lg bg-surface-2 text-ink text-sm border border-border" />
        <textarea value={body} onChange={(e) => setBody(e.target.value)} placeholder="Treść" rows={3}
          className="w-full px-3 py-2 rounded-lg bg-surface-2 text-ink text-sm border border-border" />
        <div className="flex items-center gap-3">
          <select value={segment} onChange={(e) => setSegment(e.target.value)}
            className="px-3 py-2 rounded-lg bg-surface-2 text-ink text-sm border border-border">
            <option value="all">Wszyscy</option><option value="normal">Normal</option>
            <option value="kids">Dzieci</option><option value="senior">Seniorzy</option>
          </select>
          <button onClick={send} disabled={sending} className="ml-auto px-5 py-2 rounded-full bg-coral text-white text-sm disabled:opacity-50">
            {sending ? 'Wysyłam…' : 'Wyślij broadcast'}
          </button>
        </div>
        <p className="text-ink-2 text-xs">Push trafia do powiadomień + urządzeń. Rate-limit obowiązuje.</p>
      </div>
    </Card>
  );
}
