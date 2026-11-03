import type { ReactNode } from 'react';
export function PageHeader({
  title,
  description,
  children,
}: {
  title: string;
  description?: string;
  children?: ReactNode;
}) {
  return (
    <div className="mb-6 flex flex-wrap justify-between items-start gap-4">
      <div>
        <h1 className="text-2xl lg:text-3xl font-bold tracking-tight">{title}</h1>
        {description && <p className="text-ink-2 mt-2">{description}</p>}
      </div>
      {children}
    </div>
  );
}
