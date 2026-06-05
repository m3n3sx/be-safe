// be:Safe — Badge (design system Serenity). Warianty kolorystyczne + RBAC role.
import React from 'react';

type Variant = 'neutral' | 'mint' | 'aqua' | 'coral' | 'navy' | 'volt';

const VARIANTS: Record<Variant, string> = {
  neutral: 'bg-surface-2 text-ink-2',
  mint: 'bg-[var(--serenity-mint)]/25 text-[#0F7252] dark:text-[var(--serenity-mint)]',
  aqua: 'bg-[var(--serenity-aqua)]/25 text-[#0a6b6c] dark:text-[var(--serenity-aqua)]',
  coral: 'bg-[var(--serenity-coral)]/20 text-[#b3261e] dark:text-[var(--serenity-coral)]',
  navy: 'bg-[var(--serenity-navy)] text-white',
  volt: 'bg-[var(--serenity-volt)] text-[#1A2206]',
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
      className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${VARIANTS[variant]} ${className}`}
    >
      {children}
    </span>
  );
}

/// Badge dla roli RBAC (kolor wg klucza roli).
export function RoleBadge({ role }: { role: string }) {
  const v: Variant =
    role === 'superadmin' ? 'coral' : role === 'moderator' ? 'navy' : role === 'support' ? 'aqua' : 'mint';
  const label =
    role === 'superadmin' ? 'Super Admin' : role === 'moderator' ? 'Moderator' : role === 'support' ? 'Wsparcie' : role === 'analyst' ? 'Analityk' : role;
  return <Badge variant={v}>{label}</Badge>;
}
