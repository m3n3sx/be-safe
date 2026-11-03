'use client';
import type { ReactNode } from 'react';
import { Dialog } from './Dialog';
export function ModalBottomSheet(props: { open: boolean; title: string; onClose: () => void; children: ReactNode }) { return <Dialog {...props} sheet />; }
export type SheetSize = 'peek' | 'half' | 'full';
export function BottomSheet({ title, size, onSizeChange, children }: { title: string; size: SheetSize; onSizeChange: (size: SheetSize) => void; children: ReactNode }) {
  return <section className="nearby-sheet" data-size={size} aria-label={title}><div className="px-3 py-2 border-b border-border flex items-center justify-between gap-2"><h2 className="font-bold">{title}</h2><select className="field-control w-auto! lg:hidden" aria-label="Wysokość listy" value={size} onChange={e => onSizeChange(e.target.value as SheetSize)}><option value="peek">Podgląd</option><option value="half">Więcej</option><option value="full">Pełna lista</option></select></div><div className="sheet-body">{children}</div></section>;
}
