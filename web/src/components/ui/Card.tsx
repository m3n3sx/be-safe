// be:Safe — bazowa karta (design system Serenity). Theme-aware przez tokeny.
import React from 'react';

export function Card({
  children,
  className = '',
  padded = true,
  as: Tag = 'div',
}: {
  children: React.ReactNode;
  className?: string;
  padded?: boolean;
  as?: React.ElementType;
}) {
  return (
    <Tag
      className={`rounded-card bg-surface border border-border ${padded ? 'p-4' : ''} ${className}`}
    >
      {children}
    </Tag>
  );
}

export function CardTitle({ children, className = '' }: { children: React.ReactNode; className?: string }) {
  return <h3 className={`text-ink font-medium ${className}`}>{children}</h3>;
}

export function CardSubtitle({ children, className = '' }: { children: React.ReactNode; className?: string }) {
  return <p className={`text-ink-2 text-sm ${className}`}>{children}</p>;
}
