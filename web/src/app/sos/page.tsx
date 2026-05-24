'use client';

import React, { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api';
import { t } from '@/lib/i18n';

const HOLD_DURATION_MS = 3000;

export default function SOSPage() {
  const router = useRouter();
  const [holding, setHolding] = useState(false);
  const [progress, setProgress] = useState(0);
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState(false);
  const [notifyCommunity, setNotifyCommunity] = useState(true);
  const [notifyFamily, setNotifyFamily] = useState(true);
  const [call112, setCall112] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const startRef = useRef<number | null>(null);
  const rafRef = useRef<number | null>(null);

  const fire = async () => {
    if (sending) return;
    setSending(true);
    setError(null);
    try {
      // Vibration if supported
      if ('vibrate' in navigator) navigator.vibrate([100, 50, 100, 50, 200]);

      // Get position
      const pos = await new Promise<GeolocationPosition | null>(resolve => {
        if (!navigator.geolocation) return resolve(null);
        navigator.geolocation.getCurrentPosition(
          p => resolve(p),
          () => resolve(null),
          { enableHighAccuracy: true, timeout: 5000 }
        );
      });
      const lat = pos?.coords.latitude ?? 52.2297;
      const lng = pos?.coords.longitude ?? 21.0122;

      if (notifyCommunity || notifyFamily) {
        const res = await api.post('/alerts', {
          category: 'aggression',
          title: '🆘 SOS — Potrzebuję pomocy!',
          description: notifyFamily
            ? 'Alarm SOS — powiadomiono rodzinę i społeczność'
            : 'Alarm SOS — powiadomiono społeczność',
          lat,
          lng,
          radius_m: notifyCommunity ? 500 : 200,
        });
        if (res.error) {
          setError(res.error);
          setSending(false);
          return;
        }
      }

      if (call112) {
        window.location.href = 'tel:112';
      }

      setSent(true);
      setTimeout(() => router.push('/'), 2500);
    } catch (e: unknown) {
      setError((e as Error).message || 'Błąd wysyłania SOS');
    } finally {
      setSending(false);
    }
  };

  const start = () => {
    if (sending || sent) return;
    setHolding(true);
    startRef.current = performance.now();
    const tick = () => {
      if (startRef.current === null) return;
      const elapsed = performance.now() - startRef.current;
      const pct = Math.min(elapsed / HOLD_DURATION_MS, 1);
      setProgress(pct);
      if (pct >= 1) {
        setHolding(false);
        startRef.current = null;
        fire();
        return;
      }
      rafRef.current = requestAnimationFrame(tick);
    };
    rafRef.current = requestAnimationFrame(tick);
  };

  const stop = () => {
    if (rafRef.current) cancelAnimationFrame(rafRef.current);
    startRef.current = null;
    setHolding(false);
    setProgress(0);
  };

  useEffect(() => () => {
    if (rafRef.current) cancelAnimationFrame(rafRef.current);
  }, []);

  const ringRadius = 130;
  const circumference = 2 * Math.PI * ringRadius;
  const dashOffset = circumference * (1 - progress);

  return (
    <div className="min-h-[calc(100vh-3.5rem)] lg:min-h-screen bg-gradient-to-b from-red-50 to-white dark:from-neutral-950 dark:to-neutral-900 px-6 py-8 flex flex-col items-center">
      <div className="w-full max-w-md flex flex-col items-center">
        <h1 className="text-3xl font-light text-neutral-900 dark:text-white mb-2 text-center">
          {t('sos_hold_title') || 'Przytrzymaj, by wezwać pomoc'}
        </h1>
        <p className="text-sm text-neutral-600 dark:text-neutral-400 text-center mb-8">
          {t('sos_hold_subtitle') || 'Trzymaj koło przez 3 sekundy. Twoja lokalizacja zostanie udostępniona.'}
        </p>

        {/* SOS orb */}
        <div
          className="relative my-6 select-none"
          style={{ width: 300, height: 300 }}
        >
          <svg className="absolute inset-0" width={300} height={300} viewBox="0 0 300 300">
            {/* Track */}
            <circle
              cx={150}
              cy={150}
              r={ringRadius}
              fill="none"
              stroke="rgba(239, 68, 68, 0.15)"
              strokeWidth={16}
            />
            {/* Progress */}
            <circle
              cx={150}
              cy={150}
              r={ringRadius}
              fill="none"
              stroke="#EF4444"
              strokeWidth={16}
              strokeLinecap="round"
              strokeDasharray={circumference}
              strokeDashoffset={dashOffset}
              transform="rotate(-90 150 150)"
              style={{ transition: holding ? 'none' : 'stroke-dashoffset 200ms ease-out' }}
            />
          </svg>
          <button
            onMouseDown={start}
            onMouseUp={stop}
            onMouseLeave={stop}
            onTouchStart={e => { e.preventDefault(); start(); }}
            onTouchEnd={e => { e.preventDefault(); stop(); }}
            disabled={sending || sent}
            className={`absolute inset-6 rounded-full font-bold text-white text-2xl shadow-2xl transition-transform ${
              holding ? 'scale-95 bg-red-700' : 'bg-red-600 hover:bg-red-700'
            } ${sent ? 'bg-green-500' : ''} ${sending ? 'animate-pulse' : ''}`}
            aria-label="Przytrzymaj SOS"
          >
            {sent ? '✓ Wysłano' : sending ? 'Wysyłanie...' : '🆘 SOS'}
          </button>
        </div>

        {/* Options */}
        <div className="w-full space-y-3 mt-4">
          <OptionRow
            label="Powiadom społeczność"
            description="Alert widoczny dla wszystkich w okolicy 500m"
            checked={notifyCommunity}
            onChange={setNotifyCommunity}
          />
          <OptionRow
            label="Powiadom rodzinę"
            description="Push notification do członków grupy rodzinnej"
            checked={notifyFamily}
            onChange={setNotifyFamily}
          />
          <OptionRow
            label="Zadzwoń na 112"
            description="Otwórz dialer z numerem 112 po wysłaniu"
            checked={call112}
            onChange={setCall112}
          />
        </div>

        {/* Error */}
        {error && (
          <div className="mt-4 w-full bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300 text-sm rounded-xl p-3">
            {error}
          </div>
        )}

        {/* Cancel */}
        <button
          onClick={() => router.push('/')}
          className="mt-8 px-6 py-2 text-sm text-neutral-600 dark:text-neutral-400 hover:text-neutral-900 dark:hover:text-white"
        >
          {t('cancel') || 'Anuluj'}
        </button>

        {/* Footer info */}
        <div className="mt-6 w-full text-center text-xs text-neutral-500 dark:text-neutral-400 space-y-1">
          <p>Po wysłaniu zobaczysz potwierdzenie. Pomoc w drodze.</p>
          <a
            href="/sos/mental"
            className="block text-mint hover:underline"
            style={{ color: '#5DBC9C' }}
          >
            Potrzebujesz wsparcia psychicznego? →
          </a>
        </div>
      </div>
    </div>
  );
}

function OptionRow({
  label,
  description,
  checked,
  onChange,
}: {
  label: string;
  description: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <label className="flex items-start gap-3 p-3 rounded-xl bg-white dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-700 cursor-pointer hover:bg-neutral-50 dark:hover:bg-neutral-750 transition-colors">
      <input
        type="checkbox"
        checked={checked}
        onChange={e => onChange(e.target.checked)}
        className="mt-1 w-5 h-5 accent-red-500"
      />
      <div className="flex-1">
        <div className="text-sm font-medium text-neutral-900 dark:text-white">{label}</div>
        <div className="text-xs text-neutral-500 dark:text-neutral-400 mt-0.5">{description}</div>
      </div>
    </label>
  );
}
