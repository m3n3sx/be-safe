'use client';
import { useEffect, useState } from 'react';
import { Select } from '@/components/ui/Select';

export function AccessibilitySettings() {
  const [large, setLarge] = useState(false);
  const [reduced, setReduced] = useState(false);
  useEffect(() => {
    const timer = setTimeout(() => {
      setLarge(localStorage.getItem('besafe.large-text') === '1');
      setReduced(localStorage.getItem('besafe.reduced-motion') === '1');
    }, 0);
    return () => clearTimeout(timer);
  }, []);
  function save(key: 'large-text' | 'reduced-motion', enabled: boolean) {
    localStorage.setItem(`besafe.${key}`, enabled ? '1' : '0');
    document.documentElement.classList.toggle(key, enabled);
    if (key === 'large-text') setLarge(enabled);
    else setReduced(enabled);
  }
  return (
    <div className="space-y-3">
      <Select
        label="Rozmiar tekstu"
        value={large ? 'large' : 'normal'}
        onChange={(e) => save('large-text', e.target.value === 'large')}
      >
        <option value="normal">Standardowy</option>
        <option value="large">Powiększony</option>
      </Select>
      <label className="flex items-center gap-3 min-h-12">
        <input
          type="checkbox"
          className="size-5"
          checked={reduced}
          onChange={(e) => save('reduced-motion', e.target.checked)}
        />
        Ogranicz animacje
      </label>
      <p className="text-sm text-ink-2">
        Respektujemy też systemowe ograniczenie ruchu i tryb wymuszonego kontrastu.
      </p>
    </div>
  );
}
