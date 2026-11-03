'use client';
import { useEffect, useId, useRef, type ReactNode } from 'react';
import Link from 'next/link';
import { IconButton } from './IconButton';
export function Dialog({
  open,
  title,
  onClose,
  children,
  sheet = false,
}: {
  open: boolean;
  title: string;
  onClose: () => void;
  children: ReactNode;
  sheet?: boolean;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  const id = useId();
  useEffect(() => {
    if (!open) return;
    const previous = document.activeElement as HTMLElement | null;
    const dialog = ref.current;
    const overflow = document.body.style.overflow;
    dialog?.showModal();
    document.body.style.overflow = 'hidden';
    return () => {
      dialog?.close();
      document.body.style.overflow = overflow;
      previous?.focus();
    };
  }, [open]);
  return (
    <dialog
      ref={ref}
      className={`dialog${sheet ? ' modal-sheet' : ''}`}
      aria-labelledby={id}
      onCancel={(event) => {
        event.preventDefault();
        onClose();
      }}
    >
      <div className="mb-4 flex items-center justify-between gap-2">
        <h2 id={id} className="text-xl font-bold">
          {title}
        </h2>
        <Link className="btn btn-danger sos-link" href="/sos" onClick={onClose}>
          SOS
        </Link>
        <IconButton label="Zamknij okno" onClick={onClose}>
          ✕
        </IconButton>
      </div>
      {open && children}
    </dialog>
  );
}
