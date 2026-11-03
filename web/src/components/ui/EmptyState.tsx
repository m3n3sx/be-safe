import type { ReactNode } from 'react';
export function EmptyState({ title, description, children }: { title: string; description?: string; children?: ReactNode }) { return <div className="p-6 space-y-3 text-center"><h2 className="text-lg font-semibold">{title}</h2>{description && <p className="text-ink-2">{description}</p>}{children}</div>; }
