'use client';

import React, { useState } from 'react';
import AppLayout from '@/components/ui/AppLayout';
import { useAuth } from '@/contexts/AuthContext';
import { useTheme } from '@/contexts/ThemeContext';
import { t, getLang, setLang, availableLanguages } from '@/lib/i18n';
import api from '@/lib/api';

export default function SettingsPage() {
  const { user, logout, refreshUser } = useAuth();
  const { theme, setTheme } = useTheme();
  const [showChangeEmail, setShowChangeEmail] = useState(false);
  const [showChangePassword, setShowChangePassword] = useState(false);
  const [newEmail, setNewEmail] = useState('');
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [msg, setMsg] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleChangeEmail = async () => {
    setError(null);
    const res = await api.patch('/users/email', { email: newEmail, password: currentPassword });
    if (res.error) { setError(res.error); return; }
    await refreshUser();
    setShowChangeEmail(false);
    setNewEmail('');
    setCurrentPassword('');
    setMsg(t('success'));
    setTimeout(() => setMsg(null), 2000);
  };

  const handleChangePassword = async () => {
    setError(null);
    const res = await api.patch('/users/password', { current_password: currentPassword, new_password: newPassword });
    if (res.error) { setError(res.error); return; }
    setShowChangePassword(false);
    setCurrentPassword('');
    setNewPassword('');
    setMsg(t('success'));
    setTimeout(() => setMsg(null), 2000);
  };

  const handleDeleteAccount = async () => {
    if (!confirm(t('delete_confirm'))) return;
    if (!confirm(t('delete_confirm'))) return; // Double confirm
    const res = await api.delete('/users/me');
    if (!res.error) logout();
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

        {/* Account */}
        <Section title={t('account')}>
          <div className="space-y-2">
            <button
              onClick={() => { setShowChangeEmail(!showChangeEmail); setShowChangePassword(false); setError(null); }}
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
              onClick={() => { setShowChangePassword(!showChangePassword); setShowChangeEmail(false); setError(null); }}
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

        {/* Danger zone */}
        <div className="mt-8">
          <button
            onClick={handleDeleteAccount}
            className="w-full py-3 rounded-xl border-2 border-red-500/30 text-red-500 font-medium text-sm hover:bg-red-500/10 transition-colors"
          >
            {t('delete_account')}
          </button>
        </div>

        {/* Version */}
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
