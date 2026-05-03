'use client';

import React, { useState, useEffect } from 'react';
import AppLayout from '@/components/ui/AppLayout';
import api from '@/lib/api';
import { t } from '@/lib/i18n';
import type { FamilyGroup, FamilyMember, Geofence } from '@/types';

export default function FamilyPage() {
  const [groups, setGroups] = useState<FamilyGroup[]>([]);
  const [selectedGroup, setSelectedGroup] = useState<FamilyGroup | null>(null);
  const [members, setMembers] = useState<FamilyMember[]>([]);
  const [geofences, setGeofences] = useState<Geofence[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [showJoin, setShowJoin] = useState(false);
  const [showGeofence, setShowGeofence] = useState(false);
  const [groupName, setGroupName] = useState('');
  const [inviteCode, setInviteCode] = useState('');
  const [geoName, setGeoName] = useState('');
  const [geoRadius, setGeoRadius] = useState(200);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => { loadGroups(); }, []);

  const loadGroups = async () => {
    setLoading(true);
    const res = await api.get<{ groups: FamilyGroup[] }>('/family/groups');
    if (!res.error && res.groups) setGroups(res.groups);
    setLoading(false);
  };

  const loadMembers = async (groupId: string) => {
    const res = await api.get<{ members: FamilyMember[] }>(`/family/groups/${groupId}/members`);
    if (!res.error && res.members) setMembers(res.members);
  };

  const loadGeofences = async (groupId: string) => {
    const res = await api.get<{ geofences: Geofence[] }>(`/family/groups/${groupId}/geofences`);
    if (!res.error && res.geofences) setGeofences(res.geofences);
  };

  const selectGroup = (g: FamilyGroup) => {
    setSelectedGroup(g);
    loadMembers(g.id);
    loadGeofences(g.id);
  };

  const createGroup = async () => {
    if (!groupName.trim()) return;
    setError(null);
    const res = await api.post<FamilyGroup>('/family/groups', { name: groupName });
    if (res.error) { setError(res.error); return; }
    setGroups(prev => [...prev, res as FamilyGroup]);
    setShowCreate(false);
    setGroupName('');
  };

  const joinGroup = async () => {
    if (!inviteCode.trim()) return;
    setError(null);
    const res = await api.post<FamilyGroup>('/family/groups/join', { invite_code: inviteCode });
    if (res.error) { setError(res.error); return; }
    loadGroups();
    setShowJoin(false);
    setInviteCode('');
  };

  const createGeofence = async () => {
    if (!selectedGroup || !geoName.trim()) return;
    setError(null);
    // Default location - center of map or user position
    const res = await api.post<Geofence>(`/family/groups/${selectedGroup.id}/geofences`, {
      name: geoName,
      lat: 52.2297,
      lng: 21.0122,
      radius_m: geoRadius,
    });
    if (res.error) { setError(res.error); return; }
    setGeofences(prev => [...prev, res as Geofence]);
    setShowGeofence(false);
    setGeoName('');
  };

  const deleteGeofence = async (id: string) => {
    if (!selectedGroup) return;
    const res = await api.delete(`/family/groups/${selectedGroup.id}/geofences/${id}`);
    if (!res.error) setGeofences(prev => prev.filter(g => g.id !== id));
  };

  return (
    <AppLayout>
      <div className="max-w-4xl mx-auto px-4 py-6">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-neutral-900 dark:text-white">{t('family')}</h1>
          <div className="flex gap-2">
            <button onClick={() => setShowCreate(true)} className="px-4 py-2 rounded-xl bg-red-500 text-white text-sm font-medium hover:bg-red-600 transition-colors">
              {t('create_group')}
            </button>
            <button onClick={() => setShowJoin(true)} className="px-4 py-2 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 text-sm font-medium hover:bg-neutral-200 dark:hover:bg-neutral-700 transition-colors">
              {t('join_group')}
            </button>
          </div>
        </div>

        {loading ? (
          <div className="flex justify-center py-12"><div className="animate-pulse text-neutral-500">{t('loading')}</div></div>
        ) : groups.length === 0 ? (
          <div className="text-center py-12">
            <div className="text-4xl mb-3">👨‍👩‍👧‍👦</div>
            <p className="text-neutral-500 mb-4">No family groups yet</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Groups list */}
            <div className="space-y-2">
              {groups.map(g => (
                <button
                  key={g.id}
                  onClick={() => selectGroup(g)}
                  className={`w-full text-left px-4 py-3 rounded-xl border transition-colors ${
                    selectedGroup?.id === g.id
                      ? 'bg-red-500/10 border-red-500/30 text-red-500'
                      : 'bg-white dark:bg-neutral-900 border-neutral-200 dark:border-neutral-800 text-neutral-900 dark:text-white hover:bg-neutral-50 dark:hover:bg-neutral-800'
                  }`}
                >
                  <p className="font-medium text-sm">{g.name}</p>
                  <p className="text-xs text-neutral-500 mt-0.5">Code: {g.invite_code}</p>
                </button>
              ))}
            </div>

            {/* Group details */}
            {selectedGroup && (
              <div className="lg:col-span-2 space-y-6">
                {/* Members */}
                <div className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-4">
                  <h3 className="font-medium text-neutral-900 dark:text-white mb-3">{t('members')}</h3>
                  <div className="space-y-2">
                    {members.map(m => (
                      <div key={m.id} className="flex items-center justify-between px-3 py-2 rounded-xl bg-neutral-50 dark:bg-neutral-800">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-red-500/20 flex items-center justify-center text-red-500 text-xs font-bold">
                            {m.username?.charAt(0).toUpperCase()}
                          </div>
                          <div>
                            <p className="text-sm font-medium text-neutral-900 dark:text-white">{m.username}</p>
                            <p className="text-xs text-neutral-500">
                              {m.role === 'parent' ? t('parent') : t('child')}
                              {m.lat && m.lng && ` · ${m.lat.toFixed(3)}, ${m.lng.toFixed(3)}`}
                            </p>
                          </div>
                        </div>
                        <span className={`w-2 h-2 rounded-full ${m.tracking_enabled ? 'bg-green-500' : 'bg-neutral-400'}`} />
                      </div>
                    ))}
                  </div>
                </div>

                {/* Geofences */}
                <div className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-4">
                  <div className="flex items-center justify-between mb-3">
                    <h3 className="font-medium text-neutral-900 dark:text-white">{t('safe_zones')}</h3>
                    <button onClick={() => setShowGeofence(true)} className="text-xs text-red-500 font-medium hover:underline">
                      + {t('add_safe_zone')}
                    </button>
                  </div>
                  <div className="space-y-2">
                    {geofences.map(g => (
                      <div key={g.id} className="flex items-center justify-between px-3 py-2 rounded-xl bg-neutral-50 dark:bg-neutral-800">
                        <div>
                          <p className="text-sm font-medium text-neutral-900 dark:text-white">{g.name}</p>
                          <p className="text-xs text-neutral-500">{t('radius')}: {g.radius_m}m</p>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className={`w-2 h-2 rounded-full ${g.is_active ? 'bg-green-500' : 'bg-neutral-400'}`} />
                          <button onClick={() => deleteGeofence(g.id)} className="p-1 hover:text-red-500 text-neutral-400">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                            </svg>
                          </button>
                        </div>
                      </div>
                    ))}
                    {geofences.length === 0 && (
                      <p className="text-sm text-neutral-500 py-2">{t('no_alerts')}</p>
                    )}
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Create Group Modal */}
        {showCreate && (
          <Modal onClose={() => setShowCreate(false)}>
            <h3 className="text-lg font-bold text-neutral-900 dark:text-white mb-4">{t('create_group')}</h3>
            {error && <div className="mb-3 px-3 py-2 rounded-lg bg-red-500/10 text-red-500 text-sm">{error}</div>}
            <input
              type="text"
              value={groupName}
              onChange={e => setGroupName(e.target.value)}
              placeholder={t('group_name')}
              className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-4 py-2.5 text-sm mb-4"
            />
            <button onClick={createGroup} className="w-full py-2.5 rounded-xl bg-red-500 text-white font-medium text-sm">{t('create_group')}</button>
          </Modal>
        )}

        {/* Join Group Modal */}
        {showJoin && (
          <Modal onClose={() => setShowJoin(false)}>
            <h3 className="text-lg font-bold text-neutral-900 dark:text-white mb-4">{t('join_group')}</h3>
            {error && <div className="mb-3 px-3 py-2 rounded-lg bg-red-500/10 text-red-500 text-sm">{error}</div>}
            <input
              type="text"
              value={inviteCode}
              onChange={e => setInviteCode(e.target.value)}
              placeholder={t('invite_code')}
              className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-4 py-2.5 text-sm mb-4"
            />
            <button onClick={joinGroup} className="w-full py-2.5 rounded-xl bg-red-500 text-white font-medium text-sm">{t('join_group')}</button>
          </Modal>
        )}

        {/* Create Geofence Modal */}
        {showGeofence && (
          <Modal onClose={() => setShowGeofence(false)}>
            <h3 className="text-lg font-bold text-neutral-900 dark:text-white mb-4">{t('add_safe_zone')}</h3>
            {error && <div className="mb-3 px-3 py-2 rounded-lg bg-red-500/10 text-red-500 text-sm">{error}</div>}
            <input
              type="text"
              value={geoName}
              onChange={e => setGeoName(e.target.value)}
              placeholder={t('geofence_name')}
              className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-4 py-2.5 text-sm mb-3"
            />
            <div className="mb-4">
              <label className="text-sm text-neutral-700 dark:text-neutral-300 mb-1 block">{t('radius')}: {geoRadius}m</label>
              <input
                type="range"
                min={50}
                max={2000}
                step={50}
                value={geoRadius}
                onChange={e => setGeoRadius(Number(e.target.value))}
                className="w-full accent-red-500"
              />
            </div>
            <button onClick={createGeofence} className="w-full py-2.5 rounded-xl bg-red-500 text-white font-medium text-sm">{t('add_safe_zone')}</button>
          </Modal>
        )}
      </div>
    </AppLayout>
  );
}

function Modal({ children, onClose }: { children: React.ReactNode; onClose: () => void }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative bg-white dark:bg-neutral-900 rounded-2xl p-6 mx-4 max-w-sm w-full shadow-2xl border border-neutral-200 dark:border-neutral-800">
        {children}
      </div>
    </div>
  );
}
