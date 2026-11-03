import { Icon } from '@/components/ui/Icon';
export function PhoneDirectory({
  numbers,
}: {
  numbers: readonly (readonly [string, string, string, string])[];
}) {
  return (
    <ul className="grid sm:grid-cols-2 gap-3">
      {numbers.map(([number, display, title, description]) => (
        <li key={number} className="panel space-y-2">
          <h2 className="text-lg font-bold">{title}</h2>
          <p className="text-ink-2">{description}</p>
          <p className="text-2xl font-bold select-text">{display}</p>
          <a
            className={`btn ${number === '112' ? 'btn-danger' : 'btn-secondary'} w-full`}
            href={`tel:${number}`}
            aria-label={`Zadzwoń ${display} — ${title}`}
          >
            <Icon name="phone" />
            Zadzwoń
          </a>
        </li>
      ))}
    </ul>
  );
}
