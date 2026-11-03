// Semantic badges; legacy variant names are retained for existing callers.
import React from 'react';

type Variant = 'neutral' | 'mint' | 'aqua' | 'coral' | 'navy' | 'volt';

const VARIANTS: Record<Variant, string> = {
  neutral: 'bg-surface-2 text-ink-2',
  mint: 'bg-surface-2 text-success',
  aqua: 'bg-surface-2 text-primary',
  coral: 'bg-surface-2 text-danger',
  navy: 'bg-surface-2 text-ink',
  volt: 'bg-surface-2 text-warning',
};

export function Badge({
  children,
  variant = 'neutral',
  className = '',
}: {
  children: React.ReactNode;
  variant?: Variant;
  className?: string;
}) {
  return (
    <span
      className={`inline-flex items-center px-2.5 py-1 rounded-lg text-sm font-medium ${VARIANTS[variant]} ${className}`}
    >
      {children}
    </span>
  );
}

/// Badge dla roli RBAC (kolor wg klucza roli).
export function RoleBadge({ role }: { role: string }) {
  const v: Variant =
    role === 'superadmin'
      ? 'coral'
      : role === 'moderator'
        ? 'navy'
        : role === 'support'
          ? 'aqua'
          : 'mint';
  const label =
    role === 'superadmin'
      ? 'Super Admin'
      : role === 'moderator'
        ? 'Moderator'
        : role === 'support'
          ? 'Wsparcie'
          : role === 'analyst'
            ? 'Analityk'
            : role;
  return <Badge variant={v}>{label}</Badge>;
}
