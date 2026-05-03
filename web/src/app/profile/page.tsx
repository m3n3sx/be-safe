'use client';

import React, { useState } from 'react';
import AppLayout from '@/components/ui/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import api from '@/lib/api';
import { t } from '@/lib/i18n';

export default function ProfilePage() {
  const { user, refreshUser } = useAuth();
  const [radius, setRadius] = useState(user?.alert_radius_m || 5000);
  const [saving, setSaving] = useState(false);
  const [shareLink, setShareLink] = useState<string | null>(null);
  const [msg, setMsg] = useState<string | null>(null);

  const handleSaveRadius = async () => {
    setSaving(true);
    const res = await api.patch('/users/me', { alert_radius_m: radius });
    if (!res.error) {
      await refreshUser();
      setMsg(t('success'));
      setTimeout(() => setMsg(null), 2000);
    }
    setSaving(false);
  };

  const handleShareLocation = async () => {
    const res = await api.post<{ link: string }>('/users/share-location');
    if (!res.error && res.link) {
      setShareLink(res.link);
    }
  };

  const copyLink = () => {
    if (shareLink) {
      navigator.clipboard.writeText(shareLink);
      setMsg('Link copied!');
      setTimeout(() => setMsg(null), 2000);
    }
  };

  if (!user) return null;

  return (
    <AppLayout>
      <div className="max-w-2xl mx-auto px-4 py-6">
        <h1 className="text-2xl font-bold text-neutral-900 dark:text-white mb-6">{t('profile')}</h1>

        {msg && (
          <div className="mb-4 px-4 py-3 rounded-xl bg-green-500/10 text-green-600 text-sm">{msg}</div>
        )}

        {/* User card */}
        <div className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-6 mb-6">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-2xl bg-red-500/20 flex items-center justify-center text-red-500 font-bold text-2xl">
              {user.avatar_url ? (
                <img src={user.avatar_url} alt="" className="w-16 h-16 rounded-2xl object-cover" />
              ) : (
                user.username?.charAt(0).toUpperCase()
              )}
            </div>
            <div>
              <h2 className="text-xl font-bold text-neutral-900 dark:text-white">{user.username}</h2>
              <p className="text-sm text-neutral-500">{user.email}</p>
              <div className="flex items-center gap-1 mt-1">
                <span className="text-xs text-neutral-500">{t('reputation')}:</span>
                <span className="text-sm font-bold text-red-500">{user.reputation_score}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Alert radius */}
        <div className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-5 mb-6">
          <h3 className="text-sm font-medium text-neutral-900 dark:text-white mb-3">{t('alert_radius')}</h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between text-sm">
              <span className="text-neutral-500">500m</span>
              <span className="font-bold text-neutral-900 dark:text-white">{(radius / 1000).toFixed(1)} km</span>
              <span className="text-neutral-500">20km</span>
            </div>
            <input
              type="range"
              min={500}
              max={20000}
              step={500}
              value={radius}
              onChange={e => setRadius(Number(e.target.value))}
              className="w-full accent-red-500"
            />
            <button
              onClick={handleSaveRadius}
              disabled={saving}
              className="w-full py-2.5 rounded-xl bg-red-500 text-white font-medium text-sm hover:bg-red-600 disabled:opacity-50 transition-colors"
            >
              {saving ? t('loading') : t('save')}
            </button>
          </div>
        </div>

        {/* Share location */}
        <div className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-5">
          <h3 className="text-sm font-medium text-neutral-900 dark:text-white mb-3">{t('share_location')}</h3>
          {shareLink ? (
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <input
                  type="text"
                  value={shareLink}
                  readOnly
                  className="flex-1 rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-3 py-2 text-xs"
                />
                <button
                  onClick={copyLink}
                  className="px-4 py-2 rounded-xl bg-red-500 text-white text-sm font-medium hover:bg-red-600 transition-colors"
                >
                  {t('copy_link')}
                </button>
              </div>
            </div>
          ) : (
            <button
              onClick={handleShareLocation}
              className="w-full py-2.5 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 font-medium text-sm hover:bg-neutral-200 dark:hover:bg-neutral-700 transition-colors"
            >
              {t('share_location')}
            </button>
          )}
        </div>
      </div>
    </AppLayout>
  );
}
