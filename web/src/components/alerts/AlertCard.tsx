'use client';
import Link from 'next/link';
import { getCategoryInfo, type Alert } from '@/types';
import { distance, relativeTime } from '@/lib/format';
import { StatusBadge } from '@/components/ui/StatusBadge';
export function AlertCard({
  alert,
  onSelect,
  selected = false,
}: {
  alert: Alert;
  onSelect?: (id: string) => void;
  selected?: boolean;
}) {
  const cat = getCategoryInfo(alert.category);
  const content = (
    <>
      <span
        className="category-icon"
        style={{ '--category-color': cat.color } as React.CSSProperties}
        aria-hidden="true"
      >
        {cat.emoji}
      </span>
      <span className="min-w-0 flex-1">
        <span className="block text-sm text-ink-2">{cat.label}</span>
        <span className="block font-bold break-words">{alert.title}</span>
        <span className="block text-sm text-ink-2 my-1">
          {alert.distance_m !== undefined && `${distance(alert.distance_m)} · `}
          {relativeTime(alert.created_at)}
        </span>
        <span className="block text-sm">Potwierdzenia: {alert.confirms ?? 0}</span>
        <StatusBadge status={alert.status} />
      </span>
      <span aria-hidden="true">→</span>
    </>
  );
  return onSelect ? (
    <button
      className="alert-card"
      data-alert-id={alert.id}
      onClick={() => onSelect(alert.id)}
      aria-pressed={selected}
      aria-label={`Zobacz zgłoszenie: ${alert.title}`}
    >
      {content}
    </button>
  ) : (
    <Link className="alert-card" href={`/alerts/${encodeURIComponent(alert.id)}`}>
      {content}
    </Link>
  );
}
