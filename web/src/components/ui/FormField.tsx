'use client';
import {
  useId,
  type InputHTMLAttributes,
  type TextareaHTMLAttributes,
  type SelectHTMLAttributes,
} from 'react';
type Field = { label: string; error?: string; hint?: string };
export function TextField({
  label,
  error,
  hint,
  id,
  ...props
}: Field & InputHTMLAttributes<HTMLInputElement>) {
  const generated = useId();
  const key = id || generated;
  return (
    <div className="field">
      <label htmlFor={key}>{label}</label>
      <input
        {...props}
        id={key}
        className={`field-control ${props.className || ''}`}
        aria-invalid={!!error}
        aria-describedby={error || hint ? `${key}-help` : undefined}
      />
      {(error || hint) && (
        <p
          id={`${key}-help`}
          className={`text-sm ${error ? 'text-danger' : 'text-ink-2'}`}
          role={error ? 'alert' : undefined}
        >
          {error || hint}
        </p>
      )}
    </div>
  );
}
export function TextArea({
  label,
  error,
  hint,
  id,
  ...props
}: Field & TextareaHTMLAttributes<HTMLTextAreaElement>) {
  const generated = useId();
  const key = id || generated;
  return (
    <div className="field">
      <label htmlFor={key}>{label}</label>
      <textarea
        {...props}
        id={key}
        className="field-control"
        aria-invalid={!!error}
        aria-describedby={error || hint ? `${key}-help` : undefined}
      />
      {(error || hint) && (
        <p
          id={`${key}-help`}
          className={`text-sm ${error ? 'text-danger' : 'text-ink-2'}`}
          role={error ? 'alert' : undefined}
        >
          {error || hint}
        </p>
      )}
    </div>
  );
}
export function Select({
  label,
  error,
  hint,
  id,
  children,
  ...props
}: Field & SelectHTMLAttributes<HTMLSelectElement>) {
  const generated = useId();
  const key = id || generated;
  return (
    <div className="field">
      <label htmlFor={key}>{label}</label>
      <select
        {...props}
        id={key}
        className="field-control"
        aria-invalid={!!error}
        aria-describedby={error || hint ? `${key}-help` : undefined}
      >
        {children}
      </select>
      {(error || hint) && (
        <p id={`${key}-help`} className="text-sm text-ink-2">
          {error || hint}
        </p>
      )}
    </div>
  );
}
