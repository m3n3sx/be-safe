'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { alertsApi } from '@/lib/api/alerts';
import type { Alert } from '@/types';
import { AlertCard } from '@/components/alerts/AlertCard';
import { PageHeader } from '@/components/layout/PageHeader';
import { Skeleton } from '@/components/ui/Skeleton';
import { EmptyState } from '@/components/ui/EmptyState';
import { ErrorState } from '@/components/ui/ErrorState';
export default function MyAlertsPage() {
  const [alerts, setAlerts] = useState<Alert[] | null>(null); const [error, setError] = useState(''); const [revision, setRevision] = useState(0);
  useEffect(() => { let alive = true; alertsApi.mine().then(result => { if (alive) { setError(result.error ? 'Nie udało się pobrać Twoich zgłoszeń.' : ''); if (!result.error) setAlerts(result.alerts); } }); return () => { alive = false; }; }, [revision]);
  return <div className="form-container"><PageHeader title="Moje zgłoszenia" description="Otwórz zgłoszenie, aby edytować opis, przedłużyć ważność lub je usunąć." />{error && <ErrorState message={error} onRetry={() => setRevision(value => value + 1)} />}{!alerts && !error ? <Skeleton /> : !alerts?.length && !error ? <EmptyState title="Nie masz jeszcze zgłoszeń" description="Gdy zauważysz problem, możesz ostrzec innych."><Link href="/report" className="btn btn-primary">Dodaj zgłoszenie</Link></EmptyState> : <ul className="bg-surface border border-border rounded-xl overflow-hidden">{alerts?.map(alert => <li key={alert.id}><AlertCard alert={alert} /></li>)}</ul>}</div>;
}
