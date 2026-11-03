import type { ButtonHTMLAttributes } from 'react';
export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> { variant?: 'primary' | 'secondary' | 'quiet' | 'danger'; loading?: boolean }
export function Button({ variant = 'primary', loading, disabled, className = '', children, type = 'button', ...props }: ButtonProps) {
  return <button type={type} className={`btn btn-${variant} ${className}`} disabled={disabled || loading} aria-busy={loading || undefined} {...props}>{loading ? 'Proszę czekać…' : children}</button>;
}
