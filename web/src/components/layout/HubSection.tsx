import Link from 'next/link';
import { Icon } from '@/components/ui/Icon';
import type { ComponentProps } from 'react';

export type HubEntry = readonly [string, string, string, ComponentProps<typeof Icon>['name']];

export function HubSection({ title, entries }: { title: string; entries: readonly HubEntry[] }) {
  return (
    <section className="my-6">
      <h2 className="text-xl font-bold mb-3">{title}</h2>
      <ul className="grid sm:grid-cols-2 gap-3">
        {entries.map(([href, label, description, icon]) => (
          <li key={href}>
            <Link href={href} className="panel flex gap-4 h-full items-start hover:border-primary">
              <span className="rounded-xl bg-surface-2 text-primary p-3 shrink-0">
                <Icon name={icon} />
              </span>
              <span>
                <span className="block font-semibold">{label}</span>
                <span className="block text-sm text-ink-2 mt-1">{description}</span>
              </span>
            </Link>
          </li>
        ))}
      </ul>
    </section>
  );
}
