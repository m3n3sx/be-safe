'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import api, { asArray } from '@/lib/api';
import { EmptyState } from '@/components/ui/EmptyState';
import { getCategoryInfo, type AlertCategory } from '@/types';
import { isPoint, type Place } from '@/lib/location';
import { readSession } from '@/lib/storage';
import { PageHeader } from '@/components/layout/PageHeader';
import { Skeleton } from '@/components/ui/Skeleton';
import { ErrorState } from '@/components/ui/ErrorState';
type Stats = {
  totals: { today: number; week: number; total: number };
  by_category: { category: AlertCategory; count: number }[];
  trend: { day: string; count: number }[];
};
export default function StatsPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState('');
  const [area, setArea] = useState('');
  const [revision, setRevision] = useState(0);
  useEffect(() => {
    let alive = true;
    const timer = setTimeout(async () => {
      const state = readSession<{ area: Place; radius: number }>('besafe.explorer');
      if (!state || !isPoint(state.area)) {
        setError('Najpierw wybierz obszar w sekcji W okolicy.');
        return;
      }
      setArea(`${state.area.label} · promień ${state.radius / 1000} km`);
      const result = await api.get<Stats>(
        `/alerts/stats?lat=${state.area.lat}&lng=${state.area.lng}&radius_m=${state.radius}`,
      );
      if (!alive) return;
      if (result.error) setError('Nie udało się pobrać statystyk.');
      else {
        setStats(result);
        setError('');
      }
    }, 0);
    return () => {
      alive = false;
      clearTimeout(timer);
    };
  }, [revision]);
  return (
    <div className="page-container">
      <PageHeader
        title="Statystyki okolicy"
        description={area || 'Statystyki dla obszaru wybranego na mapie.'}
      />
      <Link className="btn btn-secondary mb-4" href="/">
        Zmień obszar
      </Link>
      {error && <ErrorState message={error} onRetry={() => setRevision((value) => value + 1)} />}
      {!stats && !error ? (
        <Skeleton />
      ) : (
        stats && (
          <div className="space-y-6">
            <dl className="grid sm:grid-cols-3 gap-3">
              {[
                ['Dziś', stats.totals?.today ?? '—'],
                ['Tydzień', stats.totals?.week ?? '—'],
                ['Ogółem', stats.totals?.total ?? '—'],
              ].map(([label, count]) => (
                <div className="panel" key={label}>
                  <dt>{label}</dt>
                  <dd className="text-3xl font-bold">{count}</dd>
                </div>
              ))}
            </dl>
            <section className="panel">
              <h2 className="text-xl font-bold mb-3">Kategorie — ostatnie 30 dni</h2>
              {!asArray(stats.by_category).length && (
                <EmptyState title="Brak zgłoszeń w tym okresie" />
              )}
              <ul>
                {asArray(stats.by_category).map((item) => (
                  <li
                    className="flex justify-between py-2 border-b border-border"
                    key={item.category}
                  >
                    <span>{getCategoryInfo(item.category).label}</span>
                    <strong>{item.count}</strong>
                  </li>
                ))}
              </ul>
            </section>
            <section className="panel">
              <h2 className="text-xl font-bold mb-3">Ostatnie 14 dni</h2>
              {!asArray(stats.trend).length && (
                <EmptyState title="Brak danych o zmianach w czasie" />
              )}
              <ul>
                {asArray(stats.trend).map((item) => (
                  <li className="flex justify-between py-2 border-b border-border" key={item.day}>
                    <span>{new Date(item.day).toLocaleDateString('pl-PL')}</span>
                    <strong>{item.count}</strong>
                  </li>
                ))}
              </ul>
            </section>
          </div>
        )
      )}
    </div>
  );
}
