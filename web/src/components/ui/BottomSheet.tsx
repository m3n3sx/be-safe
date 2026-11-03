'use client';
import type { ReactNode } from 'react';
import { SegmentedControl } from './SegmentedControl';
export type SheetSize = 'peek' | 'half' | 'full';
export function BottomSheet({ title, size, onSizeChange, children }: { title: string; size: SheetSize; onSizeChange: (size: SheetSize) => void; children: ReactNode }) {
  return <section className="nearby-sheet" data-size={size} aria-label={title}><div className="p-4 border-b border-border"><h2 className="font-bold text-lg mb-2">{title}</h2><div className="lg:hidden"><SegmentedControl label="Wysokość listy" value={size} onChange={onSizeChange} options={[{ value: 'peek', label: 'Zwiń' }, { value: 'half', label: 'Podgląd' }, { value: 'full', label: 'Pełna lista' }]} /></div></div><div className="sheet-body">{children}</div></section>;
}
