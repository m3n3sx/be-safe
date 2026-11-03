'use client';
export function SegmentedControl<T extends string>({ label, value, options, onChange }: { label: string; value: T; options: { value: T; label: string }[]; onChange: (value: T) => void }) {
  return <div role="group" aria-label={label} className="inline-flex flex-wrap gap-2 rounded-xl bg-surface-2 p-1">{options.map(option => <button type="button" key={option.value} aria-pressed={value === option.value} className={`btn ${value === option.value ? 'btn-primary' : 'btn-quiet'}`} onClick={() => onChange(option.value)}>{option.label}</button>)}</div>;
}
