import type { AlertStatus } from '@/types';
const labels: Record<AlertStatus, string> = { active: 'Aktywne', expired: 'Wygasłe', hidden: 'Czeka na sprawdzenie', removed: 'Usunięte' };
export function StatusBadge({ status }: { status: AlertStatus }) { return <span className={`inline-block rounded-lg px-2 py-1 text-sm font-medium bg-surface-2 ${status === 'hidden' ? 'text-warning' : 'text-ink'}`}>{labels[status] || status}</span>; }
