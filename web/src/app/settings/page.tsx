'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import AppLayout from '@/components/ui/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import { useTheme } from '@/contexts/ThemeContext';
import { t, getLang, setLang, availableLanguages } from '@/lib/i18n';
import api from '@/lib/api';

const NOTIF_KEYS = {
  alerts: 'besafe.notif.alerts',
  family: 'besafe.notif.family',
  sound: 'besafe.notif.sound',
  vibration: 'besafe.notif.vibration',
};

function loadBool(key: string, fallback = true) {
  if (typeof window === 'undefined') return fallback;
  const v = localStorage.getItem(key);
  return v === null ? fallback : v === '1';
}

export default function SettingsPage() {
  const { user, logout, refreshUser } = useAuth();
  const { theme, setTheme } = useTheme();
  const [showChangeEmail, setShowChangeEmail] = useState(false);
  const [showChangePassword, setShowChangePassword] = useState(false);
  const [showChangeUsername, setShowChangeUsername] = useState(false);
  const [newEmail, setNewEmail] = useState('');
  const [newUsername, setNewUsername] = useState('');
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [msg, setMsg] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const [notifAlerts, setNotifAlerts] = useState(true);
  const [notifFamily, setNotifFamily] = useState(true);
  const [notifSound, setNotifSound] = useState(true);
  const [notifVibration, setNotifVibration] = useState(true);
  const [alertRadius, setAlertRadius] = useState<number>(user?.alert_radius_m ?? 2000);

  useEffect(() => {
    setNotifAlerts(loadBool(NOTIF_KEYS.alerts));
    setNotifFamily(loadBool(NOTIF_KEYS.family));
    setNotifSound(loadBool(NOTIF_KEYS.sound));
    setNotifVibration(loadBool(NOTIF_KEYS.vibration));
  }, []);

  useEffect(() => {
    if (user?.alert_radius_m) setAlertRadius(user.alert_radius_m);
  }, [user?.alert_radius_m]);

  const toggleNotif = (key: keyof typeof NOTIF_KEYS, value: boolean, setter: (v: boolean) => void) => {
    setter(value);
    localStorage.setItem(NOTIF_KEYS[key], value ? '1' : '0');
    flash(t('success'));
  };

  function flash(text: string) {
    setMsg(text);
    setTimeout(() => setMsg(null), 1800);
  }

  const handleChangeEmail = async () => {
    setError(null);
    const res = await api.patch('/users/email', { email: newEmail, password: currentPassword });
    if ((res as { error?: string }).error) { setError((res as { error?: string }).error || 'Error'); return; }
    await refreshUser();
    setShowChangeEmail(false);
    setNewEmail('');
    setCurrentPassword('');
    flash(t('success'));
  };

  const handleChangeUsername = async () => {
    setError(null);
    const res = await api.patch('/users/me', { username: newUsername });
    if ((res as { error?: string }).error) { setError((res as { error?: string }).error || 'Error'); return; }
    await refreshUser();
    setShowChangeUsername(false);
    setNewUsername('');
    flash(t('success'));
  };

  const handleChangePassword = async () => {
    setError(null);
    const res = await api.patch('/users/password', { current_password: currentPassword, new_password: newPassword });
    if ((res as { error?: string }).error) { setError((res as { error?: string }).error || 'Error'); return; }
    setShowChangePassword(false);
    setCurrentPassword('');
    setNewPassword('');
    flash(t('success'));
  };

  const handleDeleteAccount = async () => {
    if (!confirm(t('delete_confirm'))) return;
    if (!confirm(t('delete_confirm'))) return;
    const res = await api.delete('/users/me');
    if (!(res as { error?: string }).error) logout();
  };

  const saveAlertRadius = async () => {
    const res = await api.patch('/users/me', { alert_radius_m: alertRadius });
    if (!(res as { error?: string }).error) {
      await refreshUser();
      flash(t('success'));
    }
  };

  return (
    <AppLayout>
      <div className="max-w-2xl mx-auto px-4 py-6">
        <h1 className="text-2xl font-bold text-neutral-900 dark:text-white mb-6">{t('settings')}</h1>

        {msg && <div className="mb-4 px-4 py-3 rounded-xl bg-green-500/10 text-green-600 text-sm">{msg}</div>}

        {/* Theme */}
        <Section title={t('theme')}>
          <div className="flex gap-2">
            {(['light', 'dark', 'system'] as const).map(mode => (
              <button
                key={mode}
                onClick={() => setTheme(mode)}
                className={`flex-1 py-2.5 rounded-xl text-sm font-medium transition-colors ${
                  theme === mode
                    ? 'bg-red-500 text-white'
                    : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 hover:bg-neutral-200 dark:hover:bg-neutral-700'
                }`}
              >
                {t(mode)}
              </button>
            ))}
          </div>
        </Section>

        {/* Language */}
        <Section title={t('language')}>
          <div className="flex gap-2">
            {availableLanguages.map(l => (
              <button
                key={l.code}
                onClick={() => { setLang(l.code); window.location.reload(); }}
                className={`flex-1 py-2.5 rounded-xl text-sm font-medium transition-colors ${
                  getLang() === l.code
                    ? 'bg-red-500 text-white'
                    : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 hover:bg-neutral-200 dark:hover:bg-neutral-700'
                }`}
              >
                {l.name}
              </button>
            ))}
          </div>
        </Section>

        {/* Powiadomienia */}
        <Section title="Powiadomienia">
          <div className="space-y-3">
            <ToggleRow
              label="Alerty w okolicy"
              hint="Nowe zgłoszenia w promieniu"
              value={notifAlerts}
              onChange={v => toggleNotif('alerts', v, setNotifAlerts)}
            />
            <ToggleRow
              label="Powiadomienia rodzinne"
              hint="Wiadomości, eskorta, geofence"
              value={notifFamily}
              onChange={v => toggleNotif('family', v, setNotifFamily)}
            />
            <ToggleRow
              label="Dźwięk"
              hint="Sygnał dźwiękowy przy alercie"
              value={notifSound}
              onChange={v => toggleNotif('sound', v, setNotifSound)}
            />
            <ToggleRow
              label="Wibracja"
              hint="Wibracja na urządzeniach mobilnych"
              value={notifVibration}
              onChange={v => toggleNotif('vibration', v, setNotifVibration)}
            />
          </div>
        </Section>

        {/* Promien alertow */}
        <Section title="Promień alertów">
          <div className="space-y-3">
            <p className="text-xs text-neutral-500">Pokazuj alerty w okolicy {(alertRadius / 1000).toFixed(1)} km od mojej lokalizacji.</p>
            <input
              type="range"
              min={500}
              max={10000}
              step={500}
              value={alertRadius}
              onChange={e => setAlertRadius(parseInt(e.target.value))}
              className="w-full accent-red-500"
            />
            <div className="flex justify-between text-xs text-neutral-500">
              <span>500m</span>
              <span>10km</span>
            </div>
            <button onClick={saveAlertRadius} className="w-full py-2.5 rounded-xl bg-red-500 text-white text-sm font-medium">Zapisz</button>
          </div>
        </Section>

        {/* Skroty bezpieczenstwa */}
        <Section title="Bezpieczeństwo">
          <div className="grid grid-cols-2 gap-2">
            <SafetyLink href="/permissions" label="Uprawnienia" emoji="🔐" />
            <SafetyLink href="/parental-controls" label="Kontrola rodzicielska" emoji="🛡️" />
            <SafetyLink href="/cyber" label="Cyberbezpieczeństwo" emoji="💻" />
            <SafetyLink href="/sos" label="SOS" emoji="🆘" />
          </div>
        </Section>

        {/* Account */}
        <Section title={t('account')}>
          <div className="space-y-2">
            <button
              onClick={() => { setShowChangeUsername(!showChangeUsername); setShowChangeEmail(false); setShowChangePassword(false); setError(null); }}
              className="w-full text-left px-4 py-3 rounded-xl bg-neutral-50 dark:bg-neutral-800 text-sm text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-700 transition-colors"
            >
              Zmień nazwę użytkownika
            </button>

            {showChangeUsername && (
              <div className="px-4 py-3 space-y-3">
                {error && <div className="px-3 py-2 rounded-lg bg-red-500/10 text-red-500 text-sm">{error}</div>}
                <input
                  type="text"
                  value={newUsername}
                  onChange={e => setNewUsername(e.target.value)}
                  placeholder={user?.username || 'nowa nazwa'}
                  className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-4 py-2.5 text-sm"
                />
                <button onClick={handleChangeUsername} className="w-full py-2.5 rounded-xl bg-red-500 text-white text-sm font-medium">{t('save')}</button>
              </div>
            )}

            <button
              onClick={() => { setShowChangeEmail(!showChangeEmail); setShowChangePassword(false); setShowChangeUsername(false); setError(null); }}
              className="w-full text-left px-4 py-3 rounded-xl bg-neutral-50 dark:bg-neutral-800 text-sm text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-700 transition-colors"
            >
              {t('change_email')}
            </button>

            {showChangeEmail && (
              <div className="px-4 py-3 space-y-3">
                {error && <div className="px-3 py-2 rounded-lg bg-red-500/10 text-red-500 text-sm">{error}</div>}
                <input
                  type="email"
                  value={newEmail}
                  onChange={e => setNewEmail(e.target.value)}
                  placeholder={t('new_email')}
                  className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-4 py-2.5 text-sm"
                />
                <input
                  type="password"
                  value={currentPassword}
                  onChange={e => setCurrentPassword(e.target.value)}
                  placeholder={t('current_password')}
                  className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-4 py-2.5 text-sm"
                />
                <button onClick={handleChangeEmail} className="w-full py-2.5 rounded-xl bg-red-500 text-white text-sm font-medium">{t('save')}</button>
              </div>
            )}

            <button
              onClick={() => { setShowChangePassword(!showChangePassword); setShowChangeEmail(false); setShowChangeUsername(false); setError(null); }}
              className="w-full text-left px-4 py-3 rounded-xl bg-neutral-50 dark:bg-neutral-800 text-sm text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-700 transition-colors"
            >
              {t('change_password')}
            </button>

            {showChangePassword && (
              <div className="px-4 py-3 space-y-3">
                {error && <div className="px-3 py-2 rounded-lg bg-red-500/10 text-red-500 text-sm">{error}</div>}
                <input
                  type="password"
                  value={currentPassword}
                  onChange={e => setCurrentPassword(e.target.value)}
                  placeholder={t('current_password')}
                  className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-4 py-2.5 text-sm"
                />
                <input
                  type="password"
                  value={newPassword}
                  onChange={e => setNewPassword(e.target.value)}
                  placeholder={t('new_password')}
                  className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-4 py-2.5 text-sm"
                />
                <button onClick={handleChangePassword} className="w-full py-2.5 rounded-xl bg-red-500 text-white text-sm font-medium">{t('save')}</button>
              </div>
            )}
          </div>
        </Section>

        {/* Prawne */}
        <Section title="Prawne i prywatność">
          <div className="grid gap-2">
            <Link href="/privacy" className="px-4 py-3 rounded-xl bg-neutral-50 dark:bg-neutral-800 text-sm hover:bg-neutral-100 dark:hover:bg-neutral-700 transition-colors">📜 Polityka prywatności</Link>
            <Link href="/terms" className="px-4 py-3 rounded-xl bg-neutral-50 dark:bg-neutral-800 text-sm hover:bg-neutral-100 dark:hover:bg-neutral-700 transition-colors">📄 Regulamin</Link>
            <Link href="/verify-email" className="px-4 py-3 rounded-xl bg-neutral-50 dark:bg-neutral-800 text-sm hover:bg-neutral-100 dark:hover:bg-neutral-700 transition-colors">✉️ Weryfikacja e-mail</Link>
          </div>
        </Section>

        {/* Danger zone */}
        <div className="mt-8 space-y-2">
          <button
            onClick={logout}
            className="w-full py-3 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-200 font-medium text-sm hover:bg-neutral-200 dark:hover:bg-neutral-700 transition-colors"
          >
            Wyloguj się
          </button>
          <button
            onClick={handleDeleteAccount}
            className="w-full py-3 rounded-xl border-2 border-red-500/30 text-red-500 font-medium text-sm hover:bg-red-500/10 transition-colors"
          >
            {t('delete_account')}
          </button>
        </div>

        <p className="text-center text-xs text-neutral-500 mt-6">{t('version')} 1.0.0 (web)</p>
      </div>
    </AppLayout>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-5 mb-4">
      <h3 className="text-sm font-medium text-neutral-900 dark:text-white mb-3">{title}</h3>
      {children}
    </div>
  );
}

function ToggleRow({ label, hint, value, onChange }: { label: string; hint: string; value: boolean; onChange: (v: boolean) => void }) {
  return (
    <button
      onClick={() => onChange(!value)}
      className="w-full flex items-center justify-between text-left"
    >
      <div className="flex-1">
        <div className="text-sm font-medium text-neutral-900 dark:text-white">{label}</div>
        <div className="text-xs text-neutral-500">{hint}</div>
      </div>
      <span
        className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
          value ? 'bg-red-500' : 'bg-neutral-300 dark:bg-neutral-700'
        }`}
      >
        <span className={`inline-block h-5 w-5 rounded-full bg-white transition-transform ${value ? 'translate-x-5' : 'translate-x-0.5'}`} />
      </span>
    </button>
  );
}

function SafetyLink({ href, label, emoji }: { href: string; label: string; emoji: string }) {
  return (
    <Link
      href={href}
      className="flex flex-col items-center gap-1 px-3 py-4 rounded-xl bg-neutral-50 dark:bg-neutral-800 hover:bg-neutral-100 dark:hover:bg-neutral-700 transition-colors text-center"
    >
      <span className="text-2xl">{emoji}</span>
      <span className="text-xs font-medium text-neutral-700 dark:text-neutral-200">{label}</span>
    </Link>
  );
}
