'use client';

import React, { useState, useEffect } from 'react';
import AppLayout from '@/components/ui/AppLayout';
import api from '@/lib/api';
import { t } from '@/lib/i18n';
import type { RankingUser } from '@/types';

export default function RankingPage() {
  const [users, setUsers] = useState<RankingUser[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadRanking();
  }, []);

  const loadRanking = async () => {
    setLoading(true);
    const res = await api.get<{ ranking: RankingUser[] }>('/users/ranking');
    if (!res.error && res.ranking) setUsers(res.ranking);
    setLoading(false);
  };

  const medals = ['🥇', '🥈', '🥉'];

  return (
    <AppLayout>
      <div className="max-w-2xl mx-auto px-4 py-6">
        <h1 className="text-2xl font-bold text-neutral-900 dark:text-white mb-6">{t('ranking')}</h1>

        {loading ? (
          <div className="flex justify-center py-12"><div className="animate-pulse text-neutral-500">{t('loading')}</div></div>
        ) : users.length === 0 ? (
          <p className="text-neutral-500 text-center py-12">No ranking data</p>
        ) : (
          <div className="space-y-2">
            {users.map((user, i) => (
              <div
                key={user.id}
                className={`flex items-center gap-4 px-4 py-3 rounded-2xl border transition-colors ${
                  i < 3
                    ? 'bg-gradient-to-r from-amber-500/5 to-transparent border-amber-500/20'
                    : 'bg-white dark:bg-neutral-900 border-neutral-200 dark:border-neutral-800'
                }`}
              >
                <div className="w-8 text-center">
                  {i < 3 ? (
                    <span className="text-xl">{medals[i]}</span>
                  ) : (
                    <span className="text-sm font-bold text-neutral-500">#{i + 1}</span>
                  )}
                </div>
                <div className="w-10 h-10 rounded-full bg-red-500/20 flex items-center justify-center text-red-500 font-bold text-sm flex-shrink-0">
                  {user.avatar_url ? (
                    <img src={user.avatar_url} alt="" className="w-10 h-10 rounded-full object-cover" />
                  ) : (
                    user.username?.charAt(0).toUpperCase() || '?'
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-neutral-900 dark:text-white truncate">{user.username}</p>
                  <div className="flex gap-3 text-xs text-neutral-500">
                    <span>{t('alerts_count')}: {user.alert_count}</span>
                    <span>{t('confirms_count')}: {user.total_confirms}</span>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-lg font-bold text-red-500">{user.reputation_score}</p>
                  <p className="text-[10px] text-neutral-500">{t('reputation')}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </AppLayout>
  );
}
