'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import AppLayout from '@/components/ui/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import api from '@/lib/api';
import type { FamilyMember } from '@/types';

interface LocationHistoryPoint {
  lat: number;
  lng: number;
  recorded_at: string;
}

interface VisibilityMap {
  location: boolean;
  history: boolean;
  battery: boolean;
  online: boolean;
  phone: boolean;
  alerts: boolean;
  checkin: boolean;
}

interface MatrixRow {
  viewer_id: string;
  viewer_username: string;
  avatar_url?: string | null;
  role: string;
  visibility: VisibilityMap;
}

interface GroupSummary {
  id: string;
  name: string;
  owner_id: string;
  your_role?: string;
}

const FIELD_LABELS: Record<string, { label: string; icon: string; desc: string }> = {
  location: { label: 'Lokalizacja', icon: '📍', desc: 'Aktualna pozycja na mapie' },
  history: { label: 'Historia tras', icon: '🕐', desc: 'Ślady z ostatnich 24h' },
  battery: { label: 'Bateria', icon: '🔋', desc: 'Poziom naładowania telefonu' },
  online: { label: 'Status online', icon: '🟢', desc: 'Czy jest aktywny' },
  phone: { label: 'Numer telefonu', icon: '📞', desc: 'Możliwość zadzwonienia' },
  alerts: { label: 'Zgłoszenia', icon: '⚠️', desc: 'Alerty które wysyłam' },
  checkin: { label: 'Check-in', icon: '✅', desc: 'Senior check-in' },
};

export default function MemberProfilePage() {
  const params = useParams<{ groupId: string; memberId: string }>();
  const router = useRouter();
  const { user } = useAuth();
  const [member, setMember] = useState<FamilyMember | null>(null);
  const [history, setHistory] = useState<LocationHistoryPoint[]>([]);
  const [group, setGroup] = useState<GroupSummary | null>(null);
  const [howOthersSeeMe, setHowOthersSeeMe] = useState<VisibilityMap | null>(null);
  // matryca dla dziecka: jak każdy członek widzi to dziecko (gdy ja jestem parent/guardian)
  const [childMatrix, setChildMatrix] = useState<MatrixRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [pinging, setPinging] = useState(false);
  const [removing, setRemoving] = useState(false);
  const [savingField, setSavingField] = useState<string | null>(null);

  const meId = user?.id;
  const isSelf = meId === params.memberId;
  const isOwner = group?.owner_id === meId;
  const guardianRoles = new Set(['parent', 'guardian']);
  const myRole = group?.your_role;
  const targetRole = member?.role;
  const canSeePrivacyOfChild = !!(myRole && guardianRoles.has(myRole) && targetRole === 'child' && !isSelf);

  const load = useCallback(async () => {
    if (!params.groupId || !params.memberId) return;
    setLoading(true);
    // members + group meta
    const [m, g] = await Promise.all([
      api.get<{ members: FamilyMember[] }>(`/family/groups/${params.groupId}/members`),
      api.get<{ groups: GroupSummary[] }>(`/family/groups`),
    ]);
    if (!m.error && m.members) {
      const found = m.members.find((x) => x.user_id === params.memberId);
      if (found) setMember(found);
    }
    if (!g.error && g.groups) {
      const found = g.groups.find((x) => x.id === params.groupId);
      if (found) setGroup(found);
    }
    // history (24h) — może wrócić [] jeśli ukryte
    const fromIso = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
    const h = await api.get<{ history: LocationHistoryPoint[] }>(
      `/family/groups/${params.groupId}/members/${params.memberId}/location/history?from=${encodeURIComponent(fromIso)}&limit=200`
    );
    if (!h.error && h.history) setHistory(h.history);
    setLoading(false);
  }, [params.groupId, params.memberId]);

  useEffect(() => {
    load();
  }, [load]);

  // Po ustawieniu member: pobierz dodatkowe ekrany visibility
  useEffect(() => {
    if (!member || !meId || !params.groupId) return;
    (async () => {
      // 1. Jak inni widzą MNIE (gdy oglądam swój profil) — pomijamy bo isSelf w UI obsłuży
      // 2. Jak ja widzę tego użytkownika (default - zawsze fetch)
      // 3. Matryca dla dziecka (gdy targetRole=child i ja jestem guardian)
      if (canSeePrivacyOfChild) {
        const r = await api.get<{ matrix: MatrixRow[] }>(`/family/groups/${params.groupId}/visibility-matrix/${params.memberId}`);
        if (!r.error && r.matrix) setChildMatrix(r.matrix);
      }
      if (isSelf) {
        // Ja widzę swój profil: jak inni widzą mnie. To samo żądanie matrix ale dla mnie.
        const r = await api.get<{ matrix: MatrixRow[] }>(`/family/groups/${params.groupId}/visibility-matrix/${meId}`);
        if (!r.error && r.matrix) setChildMatrix(r.matrix);
      }
      // pojedyncza visibility (jak ja widzę target) - dla informacji
      const v = await api.get<{ visibility: VisibilityMap }>(`/family/groups/${params.groupId}/visibility/${params.memberId}`);
      if (!v.error && v.visibility) setHowOthersSeeMe(v.visibility);
    })();
  }, [member, meId, params.groupId, params.memberId, canSeePrivacyOfChild, isSelf]);

  const ping = async () => {
    setPinging(true);
    await api.post(`/family/groups/${params.groupId}/ping`, { target_user_id: params.memberId, kind: 'where_are_you' });
    setPinging(false);
    alert('Wysłano sygnał do członka rodziny');
  };

  const removeMember = async () => {
    if (!confirm(`Usunąć ${member?.username} z grupy ${group?.name}?`)) return;
    setRemoving(true);
    const r = await api.delete(`/family/groups/${params.groupId}/members/${params.memberId}`);
    setRemoving(false);
    if (r?.error) {
      alert('Nie udało się usunąć: ' + r.error);
      return;
    }
    router.push('/family');
  };

  const toggleVisibility = async (viewerId: string, field: keyof VisibilityMap, current: boolean, targetId: string) => {
    const key = `${viewerId}:${field}:${targetId}`;
    setSavingField(key);
    const r = await api.put<{ ok?: boolean; error?: string }>(`/family/groups/${params.groupId}/visibility/${targetId}`, {
      viewer_id: viewerId,
      field,
      granted: !current,
    });
    setSavingField(null);
    if (r?.error) {
      alert('Błąd: ' + r.error);
      return;
    }
    // optimistic update
    setChildMatrix((prev) =>
      prev.map((row) =>
        row.viewer_id === viewerId
          ? { ...row, visibility: { ...row.visibility, [field]: !current } }
          : row
      )
    );
  };

  const formatTime = (iso: string) => {
    const d = new Date(iso);
    const diff = Date.now() - d.getTime();
    const min = Math.floor(diff / 60000);
    if (min < 1) return 'teraz';
    if (min < 60) return `${min} min temu`;
    const h = Math.floor(min / 60);
    if (h < 24) return `${h}h temu`;
    return d.toLocaleString('pl-PL', { dateStyle: 'short', timeStyle: 'short' });
  };

  if (loading) return <AppLayout><div className="text-center py-12 text-neutral-500">Ładowanie…</div></AppLayout>;
  if (!member) return <AppLayout><div className="text-center py-12 text-neutral-500">Nie znaleziono</div></AppLayout>;

  const online = member.last_location_at && (Date.now() - new Date(member.last_location_at).getTime() < 300000);

  return (
    <AppLayout>
      <div className="max-w-3xl mx-auto px-4 py-6">
        <div className="flex items-center gap-3 mb-6">
          <button onClick={() => router.push('/family')} className="text-2xl">←</button>
          <h1 className="text-2xl font-bold">Profil członka</h1>
        </div>

        {/* HERO */}
        <div className="bg-white dark:bg-neutral-900 rounded-3xl p-6 border border-neutral-200 dark:border-neutral-800 mb-4">
          <div className="flex items-center gap-4">
            <div className={`w-20 h-20 rounded-full ${online ? 'bg-[#9DF4CB]' : 'bg-neutral-300 dark:bg-neutral-700'} flex items-center justify-center text-3xl font-bold text-[#1A2027] overflow-hidden`}>
              {member.avatar_url ? <img src={member.avatar_url} alt="" className="w-full h-full object-cover" /> : (member.username?.[0]?.toUpperCase() || '?')}
            </div>
            <div className="flex-1">
              <h2 className="text-xl font-bold">{member.username}</h2>
              <p className="text-sm text-neutral-500">Rola: {member.role}</p>
              <p className="text-sm mt-1">
                {online ? <span className="text-emerald-600 font-medium">● Online</span> :
                  member.last_location_at ? `Ostatnio: ${formatTime(member.last_location_at)}` : 'Brak lokalizacji'}
              </p>
              {member.last_battery_level !== undefined && member.last_battery_level !== null && (
                <p className="text-xs text-neutral-500 mt-1">🔋 {member.last_battery_level}%</p>
              )}
            </div>
          </div>
        </div>

        {/* Akcje */}
        {!isSelf && (
          <div className="grid grid-cols-2 gap-3 mb-4">
            <button onClick={ping} disabled={pinging} className="py-3 rounded-2xl bg-[#1A2027] text-white font-medium disabled:opacity-40">
              {pinging ? 'Wysyłanie…' : '📡 Wyślij sygnał'}
            </button>
            {member.phone ? (
              <a href={`tel:${member.phone}`} className="py-3 rounded-2xl bg-[#FF7A7A] text-white font-medium text-center">📞 Zadzwoń</a>
            ) : (
              <div className="py-3 rounded-2xl bg-neutral-200 dark:bg-neutral-800 text-neutral-500 font-medium text-center text-sm">📞 Numer ukryty</div>
            )}
          </div>
        )}

        {/* Lokalizacja */}
        {member.lat !== undefined && member.lng !== undefined && member.lat !== null && member.lng !== null && (
          <div className="bg-white dark:bg-neutral-900 rounded-2xl p-4 border border-neutral-200 dark:border-neutral-800 mb-4">
            <h3 className="font-semibold mb-2">📍 Ostatnia lokalizacja</h3>
            <p className="text-sm text-neutral-600 dark:text-neutral-400">{member.lat.toFixed(5)}, {member.lng.toFixed(5)}</p>
            <a href={`https://www.google.com/maps?q=${member.lat},${member.lng}`} target="_blank" rel="noopener noreferrer" className="text-[#1A2027] dark:text-[#9DF4CB] underline text-sm mt-1 inline-block">Otwórz w Google Maps →</a>
          </div>
        )}

        {/* Historia */}
        {!isSelf && history.length > 0 && (
          <div className="bg-white dark:bg-neutral-900 rounded-2xl p-4 border border-neutral-200 dark:border-neutral-800 mb-4">
            <h3 className="font-semibold mb-3">🕐 Historia (24h)</h3>
            <div className="space-y-2 max-h-96 overflow-y-auto">
              {history.map((p, i) => (
                <div key={i} className="flex justify-between items-center text-sm py-2 border-b border-neutral-100 dark:border-neutral-800 last:border-0">
                  <span className="font-mono text-xs">{p.lat.toFixed(4)}, {p.lng.toFixed(4)}</span>
                  <span className="text-xs text-neutral-500">{formatTime(p.recorded_at)}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Prywatność: gdy oglądam SWÓJ profil — jak inni mnie widzą */}
        {isSelf && childMatrix.length > 0 && (
          <div className="bg-white dark:bg-neutral-900 rounded-2xl p-4 border border-neutral-200 dark:border-neutral-800 mb-4">
            <h3 className="font-semibold mb-1">🔒 Twoja prywatność</h3>
            <p className="text-xs text-neutral-500 mb-3">Wybierz co poszczególne osoby mogą o Tobie widzieć.</p>
            <PrivacyMatrix
              matrix={childMatrix}
              targetId={meId!}
              savingField={savingField}
              onToggle={toggleVisibility}
            />
          </div>
        )}

        {/* Prywatność jako rodzic: gdy oglądam dziecko — jak inni widzą to dziecko */}
        {canSeePrivacyOfChild && childMatrix.length > 0 && (
          <div className="bg-white dark:bg-neutral-900 rounded-2xl p-4 border border-[#9DF4CB] mb-4">
            <h3 className="font-semibold mb-1">🛡️ Prywatność dziecka</h3>
            <p className="text-xs text-neutral-500 mb-3">
              Jako rodzic/opiekun ustaw, co inni członkowie widzą o {member.username}.
            </p>
            <PrivacyMatrix
              matrix={childMatrix}
              targetId={params.memberId!}
              savingField={savingField}
              onToggle={toggleVisibility}
            />
          </div>
        )}

        {/* Informacja: jak ja widzę tego usera (debug/diag) */}
        {!isSelf && howOthersSeeMe && (
          <div className="text-xs text-neutral-500 mb-4 px-2">
            Jak Ty widzisz {member.username}:{' '}
            {(Object.keys(FIELD_LABELS) as Array<keyof VisibilityMap>).map((f) => (
              <span key={f} className={howOthersSeeMe[f] ? 'text-emerald-600' : 'text-neutral-400 line-through'}>
                {FIELD_LABELS[f].label}{' · '}
              </span>
            ))}
          </div>
        )}

        {/* Niebezpieczna strefa: usuń z grupy */}
        {isOwner && !isSelf && (
          <div className="bg-red-50 dark:bg-red-950/20 rounded-2xl p-4 border border-red-200 dark:border-red-900">
            <h3 className="font-semibold text-red-700 dark:text-red-400 mb-2">⚠️ Strefa właściciela</h3>
            <p className="text-xs text-red-700/80 dark:text-red-300/80 mb-3">
              Tylko Ty jako właściciel grupy {group?.name} możesz usunąć tę osobę.
            </p>
            <button
              onClick={removeMember}
              disabled={removing}
              className="w-full py-3 rounded-2xl bg-red-600 text-white font-medium disabled:opacity-40"
            >
              {removing ? 'Usuwanie…' : `Usuń ${member.username} z grupy`}
            </button>
          </div>
        )}
      </div>
    </AppLayout>
  );
}

function PrivacyMatrix({
  matrix,
  targetId,
  savingField,
  onToggle,
}: {
  matrix: MatrixRow[];
  targetId: string;
  savingField: string | null;
  onToggle: (viewerId: string, field: keyof VisibilityMap, current: boolean, targetId: string) => void;
}) {
  const fields = Object.keys(FIELD_LABELS) as Array<keyof VisibilityMap>;
  return (
    <div className="space-y-3">
      {matrix.map((row) => (
        <div key={row.viewer_id} className="border border-neutral-200 dark:border-neutral-800 rounded-xl p-3">
          <div className="flex items-center gap-2 mb-2">
            <div className="w-8 h-8 rounded-full bg-neutral-200 dark:bg-neutral-700 flex items-center justify-center text-sm font-bold overflow-hidden">
              {row.avatar_url ? <img src={row.avatar_url} alt="" className="w-full h-full object-cover" /> : (row.viewer_username?.[0]?.toUpperCase() || '?')}
            </div>
            <span className="font-medium text-sm">{row.viewer_username}</span>
            <span className="text-xs text-neutral-500">({row.role})</span>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
            {fields.map((f) => {
              const granted = row.visibility[f];
              const key = `${row.viewer_id}:${f}:${targetId}`;
              const saving = savingField === key;
              return (
                <button
                  key={f}
                  disabled={saving}
                  onClick={() => onToggle(row.viewer_id, f, granted, targetId)}
                  className={`text-left text-xs px-2 py-2 rounded-lg border transition ${
                    granted
                      ? 'bg-[#9DF4CB]/30 border-[#9DF4CB] text-[#1A2027]'
                      : 'bg-neutral-100 dark:bg-neutral-800 border-neutral-200 dark:border-neutral-700 text-neutral-400 line-through'
                  } ${saving ? 'opacity-50' : ''}`}
                >
                  <span className="mr-1">{FIELD_LABELS[f].icon}</span>
                  {FIELD_LABELS[f].label}
                </button>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  );
}
