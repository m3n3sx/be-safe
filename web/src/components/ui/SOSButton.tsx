'use client';

import React, { useState } from 'react';
import api from '@/lib/api';
import { t } from '@/lib/i18n';

export default function SOSButton() {
  const [sending, setSending] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  const handleSOS = async () => {
    setSending(true);
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          await api.post('/alerts', {
            category: 'aggression',
            title: 'SOS!',
            description: 'Emergency SOS alert sent from be:Safe web',
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
            duration_hours: 1,
          });
          setSending(false);
          setShowConfirm(false);
        },
        async () => {
          // Fallback without precise location
          await api.post('/alerts', {
            category: 'aggression',
            title: 'SOS!',
            description: 'Emergency SOS alert (no GPS)',
            lat: 0,
            lng: 0,
            duration_hours: 1,
          });
          setSending(false);
          setShowConfirm(false);
        },
        { enableHighAccuracy: true, timeout: 5000 }
      );
    }
  };

  return (
    <>
      {/* SOS Button */}
      <button
        onClick={() => setShowConfirm(true)}
        className="absolute bottom-6 left-6 lg:bottom-8 lg:left-8 z-10 w-14 h-14 rounded-full bg-red-600 text-white font-bold text-lg shadow-xl shadow-red-600/30 hover:bg-red-700 active:scale-90 transition-all animate-pulse hover:animate-none flex items-center justify-center"
      >
        SOS
      </button>

      {/* Confirm dialog */}
      {showConfirm && (
        <div className="absolute inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/50" onClick={() => setShowConfirm(false)} />
          <div className="relative bg-white dark:bg-neutral-900 rounded-2xl p-6 mx-4 max-w-sm shadow-2xl border border-neutral-200 dark:border-neutral-800">
            <div className="text-center">
              <div className="w-16 h-16 rounded-full bg-red-500/10 flex items-center justify-center mx-auto mb-4">
                <span className="text-3xl">🆘</span>
              </div>
              <h3 className="text-lg font-bold text-neutral-900 dark:text-white mb-2">{t('sos')}</h3>
              <p className="text-sm text-neutral-600 dark:text-neutral-400 mb-6">{t('sos_confirm')}</p>
              <div className="flex gap-3">
                <button
                  onClick={() => setShowConfirm(false)}
                  className="flex-1 py-2.5 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 font-medium text-sm hover:bg-neutral-200 dark:hover:bg-neutral-700 transition-colors"
                >
                  {t('cancel')}
                </button>
                <button
                  onClick={handleSOS}
                  disabled={sending}
                  className="flex-1 py-2.5 rounded-xl bg-red-600 text-white font-bold text-sm hover:bg-red-700 disabled:opacity-50 transition-colors"
                >
                  {sending ? '...' : t('sos')}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
