'use client';
import { useEffect, useState } from 'react';
const choices = [
  ['alerts', 'Powiadomienia przeglądarki o zgłoszeniach'],
  ['family', 'Powiadomienia przeglądarki od bliskich'],
  ['sound', 'Zezwalaj na dźwięk powiadomień'],
  ['vibration', 'Zezwalaj na wibracje'],
] as const;
export function NotificationPreferences() {
  const [values, setValues] = useState<Record<string, boolean>>({});
  const [message, setMessage] = useState('');
  useEffect(() => {
    const timer = setTimeout(
      () =>
        setValues(
          Object.fromEntries(
            choices.map(([key]) => [key, localStorage.getItem(`besafe.notif.${key}`) !== '0']),
          ),
        ),
      0,
    );
    return () => clearTimeout(timer);
  }, []);
  return (
    <div className="space-y-2">
      {choices.map(([key, label]) => (
        <label key={key} className="flex min-h-12 items-center gap-3">
          <input
            className="size-5"
            type="checkbox"
            checked={values[key] ?? true}
            onChange={(event) => {
              const checked = event.target.checked;
              localStorage.setItem(`besafe.notif.${key}`, checked ? '1' : '0');
              setValues((old) => ({ ...old, [key]: checked }));
              setMessage('Zapisano na tym urządzeniu.');
            }}
          />
          {label}
        </label>
      ))}
      <p className="text-sm text-ink-2">
        Te ustawienia dotyczą powiadomień przeglądarki w aktywnej aplikacji. Skrzynka zachowuje
        wszystkie komunikaty. Dźwięk i wibracja wymagają wsparcia i zgody urządzenia.
      </p>
      <p role="status" className="text-sm">
        {message}
      </p>
    </div>
  );
}
