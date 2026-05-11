'use client';

import { Suspense, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';

function ResetContent() {
  const params = useSearchParams();
  const token = params.get('token');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState('');

  if (!token) {
    return (
      <div className="text-center">
        <div className="text-5xl mb-4">⚠️</div>
        <h1 className="text-2xl font-bold mb-3 text-[#BA002C]">Brak tokenu</h1>
        <p className="text-neutral-700">Link do resetu hasła jest nieprawidłowy. Wygeneruj nowy w aplikacji.</p>
        <Link href="/forgot-password" className="inline-block mt-6 px-8 py-3 bg-[#BA002C] text-white rounded-full font-semibold hover:bg-[#920021] transition">
          Wyślij nowy link
        </Link>
      </div>
    );
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    if (password.length < 6) {
      setError('Hasło musi mieć co najmniej 6 znaków.');
      return;
    }
    if (password !== confirm) {
      setError('Hasła nie są identyczne.');
      return;
    }
    setLoading(true);
    try {
      const res = await fetch('/api/v1/auth/reset-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token, password }),
      });
      const data = await res.json();
      if (res.ok && data.ok) {
        setSuccess(true);
      } else {
        setError(data.error === 'Invalid or expired token'
          ? 'Token wygasł lub został już użyty. Wygeneruj nowy link.'
          : data.error === 'Password too short'
          ? 'Hasło musi mieć co najmniej 6 znaków.'
          : data.error || 'Wystąpił błąd. Spróbuj ponownie.');
      }
    } catch {
      setError('Wystąpił błąd połączenia.');
    } finally {
      setLoading(false);
    }
  }

  if (success) {
    return (
      <div className="text-center">
        <div className="text-5xl mb-4">✅</div>
        <h1 className="text-2xl font-bold mb-3 text-[#006E2A]">Hasło zmienione!</h1>
        <p className="text-neutral-700 leading-relaxed">
          Twoje hasło zostało pomyślnie zaktualizowane. Możesz się teraz zalogować w aplikacji.
        </p>
        <Link href="/" className="inline-block mt-6 px-8 py-4 bg-[#BA002C] text-white rounded-full font-semibold hover:bg-[#920021] transition">
          Otwórz be:Safe
        </Link>
      </div>
    );
  }

  return (
    <>
      <h1 className="text-2xl font-bold mb-2 text-[#291616]">Ustaw nowe hasło</h1>
      <p className="text-neutral-700 mb-6 text-sm leading-relaxed">
        Wybierz bezpieczne hasło — minimum 6 znaków.
      </p>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-sm font-semibold mb-2 text-[#291616]">Nowe hasło</label>
          <input
            type="password"
            required
            minLength={6}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            className="w-full px-4 py-3 bg-[#FFF0EF] rounded-xl border-2 border-transparent focus:border-[#BA002C] focus:bg-white outline-none transition"
          />
        </div>

        <div>
          <label className="block text-sm font-semibold mb-2 text-[#291616]">Potwierdź hasło</label>
          <input
            type="password"
            required
            minLength={6}
            value={confirm}
            onChange={(e) => setConfirm(e.target.value)}
            placeholder="••••••••"
            className="w-full px-4 py-3 bg-[#FFF0EF] rounded-xl border-2 border-transparent focus:border-[#BA002C] focus:bg-white outline-none transition"
          />
        </div>

        {error && (
          <div className="p-3 bg-[#FFDAD6] text-[#93000A] rounded-xl text-sm">{error}</div>
        )}

        <button
          type="submit"
          disabled={loading || !password || !confirm}
          className="w-full py-4 bg-[#BA002C] text-white rounded-full font-semibold hover:bg-[#920021] transition disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {loading ? 'Zapisywanie…' : 'Ustaw nowe hasło'}
        </button>
      </form>
    </>
  );
}

export default function ResetPasswordPage() {
  return (
    <div className="min-h-screen bg-[#FFF8F7] flex items-center justify-center px-4 py-12">
      <div className="w-full max-w-md bg-white rounded-3xl shadow-[0_2px_16px_rgba(186,0,44,0.08)] overflow-hidden">
        <div className="bg-gradient-to-br from-[#BA002C] to-[#E9003A] px-6 py-8 text-center">
          <div className="text-white text-3xl font-bold tracking-tight">be:Safe</div>
          <div className="text-white/85 text-sm mt-1">Reset hasła</div>
        </div>
        <div className="p-8">
          <Suspense fallback={<div className="py-8 text-center">Ładowanie…</div>}>
            <ResetContent />
          </Suspense>
        </div>
      </div>
    </div>
  );
}
