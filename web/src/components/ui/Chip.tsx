import type { ButtonHTMLAttributes } from 'react';
export function Chip({
  selected = false,
  children,
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { selected?: boolean }) {
  return (
    <button
      type="button"
      {...props}
      aria-pressed={selected}
      className={`btn shrink-0 !rounded-full ${selected ? 'btn-primary' : 'btn-secondary'}`}
    >
      {children}
    </button>
  );
}
