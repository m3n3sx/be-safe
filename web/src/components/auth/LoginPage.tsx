'use client';

import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { t, getLang, setLang } from '@/lib/i18n';

const GOOGLE_CLIENT_ID =
  '1098119585965-1dmn79cgjbhsr84f1iu3dibvpilc906p.apps.googleusercontent.com';

export default function LoginPage() {
  const { login, register, loginWithGoogle } = useAuth();
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [username, setUsername] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const googleBtnRef = useRef<HTMLDivElement | null>(null);
  const initializedRef = useRef(false);

  useEffect(() => {
    getLang();
  }, []);

  const handleCredential = useCallback(
    async (response: { credential: string }) => {
      try {
        const payload = JSON.parse(atob(response.credential.split('.')[1]));
        setLoading(true);
        const err = await loginWithGoogle(response.credential, payload.email, payload.name, payload.picture);
        if (err) setError(err);
      } catch (e) {
        setError('Google Sign-In failed');
      } finally {
        setLoading(false);
      }
    },
    [loginWithGoogle]
  );

  // Initialize Google Identity Services once the GSI script is ready.
  useEffect(() => {
    if (initializedRef.current) return;
    let cancelled = false;

    const tryInit = () => {
      if (cancelled) return;
      const w = window as unknown as {
        google?: { accounts?: { id?: any } };
      };
      const id = w.google?.accounts?.id;
      if (!id || !googleBtnRef.current) {
        // Retry shortly — next/script might still be loading.
        setTimeout(tryInit, 200);
        return;
      }
      initializedRef.current = true;
      id.initialize({
        client_id: GOOGLE_CLIENT_ID,
        callback: handleCredential,
        use_fedcm_for_prompt: true,
      });
      id.renderButton(googleBtnRef.current, {
        type: 'standard',
        theme: 'outline',
        size: 'large',
        text: 'continue_with',
        shape: 'pill',
        logo_alignment: 'left',
        width: googleBtnRef.current.offsetWidth || 320,
      });
    };

    tryInit();
    return () => {
      cancelled = true;
    };
  }, [handleCredential]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    let err: string | null;
    if (isLogin) {
      err = await login(email, password);
    } else {
      err = await register(email, password, username);
    }
    if (err) setError(err);
    setLoading(false);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-neutral-50 dark:bg-neutral-950 px-4">
      <div className="w-full max-w-md">
        {/* Logo */}{/* GSI script is loaded in app/layout.tsx (afterInteractive). */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-red-500 text-white text-2xl font-bold mb-4">
            b:S
          </div>
          <h1 className="text-3xl font-bold text-neutral-900 dark:text-white">be:Safe</h1>
          <p className="text-neutral-500 mt-1">
            {isLogin ? t('login') : t('register')}
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="bg-white dark:bg-neutral-900 rounded-2xl p-6 shadow-lg border border-neutral-200 dark:border-neutral-800 space-y-4">
          {error && (
            <div className="px-4 py-3 rounded-xl bg-red-500/10 border border-red-500/20 text-red-500 text-sm">
              {error}
            </div>
          )}

          {!isLogin && (
            <div>
              <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-1.5">
                {t('username')}
              </label>
              <input
                type="text"
                value={username}
                onChange={e => setUsername(e.target.value)}
                required
                className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-4 py-2.5 text-sm text-neutral-900 dark:text-white focus:border-red-500 focus:outline-none focus:ring-1 focus:ring-red-500 transition-colors"
              />
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-1.5">
              {t('email')}
            </label>
            <input
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
              className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-4 py-2.5 text-sm text-neutral-900 dark:text-white focus:border-red-500 focus:outline-none focus:ring-1 focus:ring-red-500 transition-colors"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-1.5">
              {t('password')}
            </label>
            <input
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
              minLength={6}
              className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-4 py-2.5 text-sm text-neutral-900 dark:text-white focus:border-red-500 focus:outline-none focus:ring-1 focus:ring-red-500 transition-colors"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-2.5 rounded-xl bg-red-500 text-white font-medium text-sm hover:bg-red-600 disabled:opacity-50 transition-colors"
          >
            {loading ? t('loading') : (isLogin ? t('login') : t('register'))}
          </button>

          <div className="relative py-2">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-neutral-200 dark:border-neutral-800" />
            </div>
            <div className="relative flex justify-center text-xs">
              <span className="bg-white dark:bg-neutral-900 px-3 text-neutral-500">{t('or_google')}</span>
            </div>
          </div>

          {/* Google Identity Services native button (FedCM-compatible). */}
          <div ref={googleBtnRef} className="flex justify-center min-h-[44px]" />

          <p className="text-center text-sm text-neutral-500">
            {isLogin ? t('no_account') : t('have_account')}{' '}
            <button
              type="button"
              onClick={() => { setIsLogin(!isLogin); setError(null); }}
              className="text-red-500 font-medium hover:underline"
            >
              {isLogin ? t('register') : t('login')}
            </button>
          </p>
        </form>

        {/* Language switcher */}
        <div className="flex justify-center gap-2 mt-4">
          {(['pl', 'en'] as const).map(lang => (
            <button
              key={lang}
              onClick={() => { setLang(lang); window.location.reload(); }}
              className={`px-3 py-1 text-xs rounded-lg transition-colors ${getLang() === lang ? 'bg-red-500 text-white' : 'bg-neutral-200 dark:bg-neutral-800 text-neutral-600 dark:text-neutral-400'}`}
            >
              {lang.toUpperCase()}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
