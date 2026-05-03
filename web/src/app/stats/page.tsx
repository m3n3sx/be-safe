'use client';

import React, { useState, useEffect } from 'react';
import AppLayout from '@/components/ui/AppLayout';
import api from '@/lib/api';
import { t, getLang } from '@/lib/i18n';
import type { AlertStats } from '@/types';
import { getCategoryInfo } from '@/types';

export default function StatsPage() {
  const [stats, setStats] = useState<AlertStats | null>(null);
  const [loading, setLoading] = useState(true);
  const lang = getLang();

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    setLoading(true);
    // Try to get stats based on user position or default
    let lat = 52.2297, lng = 21.0122;
    if (navigator.geolocation) {
      try {
        const pos = await new Promise<GeolocationPosition>((resolve, reject) => {
          navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 5000 });
        });
        lat = pos.coords.latitude;
        lng = pos.coords.longitude;
      } catch {}
    }
    const res = await api.get<AlertStats>(`/alerts/stats?lat=${lat}&lng=${lng}&radius=10000`);
    if (!res.error) setStats(res as AlertStats);
    setLoading(false);
  };

  const maxTrend = stats?.trend ? Math.max(...stats.trend.map(d => d.count), 1) : 1;

  return (
    <AppLayout>
      <div className="max-w-3xl mx-auto px-4 py-6">
        <h1 className="text-2xl font-bold text-neutral-900 dark:text-white mb-6">{t('stats')}</h1>

        {loading ? (
          <div className="flex justify-center py-12"><div className="animate-pulse text-neutral-500">{t('loading')}</div></div>
        ) : !stats ? (
          <p className="text-neutral-500 text-center py-12">{t('error')}</p>
        ) : (
          <div className="space-y-6">
            {/* Summary cards */}
            <div className="grid grid-cols-3 gap-4">
              <StatCard label={t('today')} value={stats.today} color="red" />
              <StatCard label={t('week')} value={stats.week} color="orange" />
              <StatCard label={t('total')} value={stats.total} color="blue" />
            </div>

            {/* Trend chart */}
            <div className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-5">
              <h3 className="text-sm font-medium text-neutral-900 dark:text-white mb-4">{t('trend_14d')}</h3>
              <div className="flex items-end gap-1 h-32">
                {stats.trend?.map((day, i) => (
                  <div key={i} className="flex-1 flex flex-col items-center gap-1">
                    <div
                      className="w-full bg-red-500/80 rounded-t-md transition-all min-h-[2px]"
                      style={{ height: `${(day.count / maxTrend) * 100}%` }}
                    />
                    <span className="text-[8px] text-neutral-500 -rotate-45 origin-center">
                      {new Date(day.date).toLocaleDateString(lang, { day: '2-digit', month: '2-digit' })}
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* Top categories */}
            <div className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-5">
              <h3 className="text-sm font-medium text-neutral-900 dark:text-white mb-4">{t('top_threats')}</h3>
              <div className="space-y-3">
                {stats.top_categories?.map((item, i) => {
                  const cat = getCategoryInfo(item.category);
                  const maxCat = stats.top_categories?.[0]?.count || 1;
                  return (
                    <div key={i} className="flex items-center gap-3">
                      <span className="text-lg w-8 text-center">{cat.emoji}</span>
                      <div className="flex-1">
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-sm text-neutral-700 dark:text-neutral-300">
                            {lang === 'en' ? cat.labelEn : cat.label}
                          </span>
                          <span className="text-xs font-medium text-neutral-900 dark:text-white">{item.count}</span>
                        </div>
                        <div className="h-2 rounded-full bg-neutral-100 dark:bg-neutral-800 overflow-hidden">
                          <div
                            className="h-full rounded-full transition-all"
                            style={{ width: `${(item.count / maxCat) * 100}%`, backgroundColor: cat.color }}
                          />
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}
      </div>
    </AppLayout>
  );
}

function StatCard({ label, value, color }: { label: string; value: number; color: string }) {
  const colors: Record<string, string> = {
    red: 'bg-red-500/10 text-red-500',
    orange: 'bg-orange-500/10 text-orange-500',
    blue: 'bg-blue-500/10 text-blue-500',
  };
  return (
    <div className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-4 text-center">
      <p className="text-xs text-neutral-500 mb-1">{label}</p>
      <p className={`text-3xl font-bold ${colors[color]?.split(' ')[1] || 'text-neutral-900 dark:text-white'}`}>
        {value}
      </p>
    </div>
  );
}
