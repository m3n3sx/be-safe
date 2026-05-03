'use client';

import React, { useState, useEffect } from 'react';
import AppLayout from '@/components/ui/AppLayout';
import api from '@/lib/api';
import { t, getLang } from '@/lib/i18n';
import type { Alert } from '@/types';
import { getCategoryInfo } from '@/types';

export default function MyAlertsPage() {
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [loading, setLoading] = useState(true);
  const lang = getLang();

  useEffect(() => {
    loadAlerts();
  }, []);

  const loadAlerts = async () => {
    setLoading(true);
    const res = await api.get<{ alerts: Alert[] }>('/alerts/mine');
    if (!res.error && res.alerts) setAlerts(res.alerts);
    setLoading(false);
  };

  const handleDelete = async (id: string) => {
    if (!confirm(t('delete_confirm'))) return;
    const res = await api.delete(`/alerts/${id}`);
    if (!res.error) setAlerts(prev => prev.filter(a => a.id !== id));
  };

  const timeAgo = (date: string) => {
    const diff = Date.now() - new Date(date).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 60) return `${mins} ${t('min')} ${t('ago')}`;
    const hrs = Math.floor(mins / 60);
    return `${hrs}h ${t('ago')}`;
  };

  return (
    <AppLayout>
      <div className="max-w-3xl mx-auto px-4 py-6">
        <h1 className="text-2xl font-bold text-neutral-900 dark:text-white mb-6">{t('my_alerts')}</h1>

        {loading ? (
          <div className="flex justify-center py-12">
            <div className="animate-pulse text-neutral-500">{t('loading')}</div>
          </div>
        ) : alerts.length === 0 ? (
          <div className="text-center py-12">
            <div className="text-4xl mb-3">📭</div>
            <p className="text-neutral-500">{t('no_alerts')}</p>
          </div>
        ) : (
          <div className="space-y-3">
            {alerts.map(alert => {
              const cat = getCategoryInfo(alert.category);
              const isExpired = alert.status === 'expired';
              return (
                <div
                  key={alert.id}
                  className={`bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-4 ${isExpired ? 'opacity-50' : ''}`}
                >
                  <div className="flex items-start gap-3">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center text-lg flex-shrink-0"
                      style={{ backgroundColor: cat.color + '20' }}
                    >
                      {cat.emoji}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-medium text-neutral-900 dark:text-white text-sm truncate">{alert.title}</h3>
                        <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium ${
                          isExpired
                            ? 'bg-neutral-100 dark:bg-neutral-800 text-neutral-500'
                            : 'bg-green-500/10 text-green-600'
                        }`}>
                          {alert.status}
                        </span>
                      </div>
                      <p className="text-xs text-neutral-500 mb-2 truncate">{alert.description}</p>
                      <div className="flex items-center gap-4 text-xs text-neutral-500">
                        <span>{timeAgo(alert.created_at)}</span>
                        <span className="text-green-600">+{alert.confirms}</span>
                        <span className="text-red-500">-{alert.denies}</span>
                      </div>
                    </div>
                    <button
                      onClick={() => handleDelete(alert.id)}
                      className="p-2 rounded-lg hover:bg-red-500/10 text-neutral-400 hover:text-red-500 transition-colors"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                      </svg>
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </AppLayout>
  );
}
