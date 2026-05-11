'use client';

import { useEffect, useState, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';

type Status = 'loading' | 'success' | 'error' | 'already-verified';

function VerifyContent() {
  const params = useSearchParams();
  const token = params.get('token');
  const [status, setStatus] = useState<Status>('loading');
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (!token) {
      setStatus('error');
      setMessage('Brak tokenu weryfikacyjnego w linku.');
      return;
    }
    (async () => {
      try {
        const res = await fetch('/api/v1/auth/verify-email', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ token }),
        });
        const data = await res.json();
        if (res.ok && data.ok) {
          setStatus('success');
          setMessage('Twój email został potwierdzony. Możesz teraz w pełni korzystać z aplikacji be:Safe.');
        } else {
          setStatus('error');
          setMessage(data.error || 'Token jest nieprawidłowy lub wygasł.');
        }
      } catch {
        setStatus('error');
        setMessage('Wystąpił błąd połączenia. Spróbuj ponownie.');
      }
    })();
  }, [token]);

  return (
    <CardShell>
      {status === 'loading' && (
        <div className="flex flex-col items-center gap-4 py-8">
          <div className="h-12 w-12 rounded-full border-4 border-[#FFDAD9] border-t-[#BA002C] animate-spin" />
          <p className="text-neutral-700">Weryfikuję email…</p>
        </div>
      )}
      {status === 'success' && (
        <Result emoji="✅" title="Email potwierdzony!" message={message} variant="success">
          <Link href="/" className="inline-block mt-6 px-8 py-4 bg-[#BA002C] text-white rounded-full font-semibold hover:bg-[#920021] transition">Otwórz be:Safe</Link>
        </Result>
      )}
      {status === 'error' && (
        <Result emoji="⚠️" title="Weryfikacja nieudana" message={message} variant="error">
          <p className="text-sm text-neutral-600 mt-4">
            Wróć do aplikacji i wygeneruj nowy link w sekcji <strong>Ustawienia → Konto</strong>, lub skontaktuj się z{' '}
            <a href="mailto:wsparcie@besafe.org.pl" className="text-[#BA002C] underline">wsparcie@besafe.org.pl</a>.
          </p>
        </Result>
      )}
    </CardShell>
  );
}

export default function VerifyEmailPage() {
  return (
    <Suspense fallback={<CardShell><div className="py-8 text-center">Ładowanie…</div></CardShell>}>
      <VerifyContent />
    </Suspense>
  );
}

// ---- Shared UI ----

function CardShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-[#FFF8F7] flex items-center justify-center px-4 py-12">
      <div className="w-full max-w-md bg-white rounded-3xl shadow-[0_2px_16px_rgba(186,0,44,0.08)] overflow-hidden">
        <div className="bg-gradient-to-br from-[#BA002C] to-[#E9003A] px-6 py-8 text-center">
          <div className="text-white text-3xl font-bold tracking-tight">be:Safe</div>
          <div className="text-white/85 text-sm mt-1">Bezpieczeństwo społeczności</div>
        </div>
        <div className="p-8">{children}</div>
      </div>
    </div>
  );
}

function Result({ emoji, title, message, variant, children }: {
  emoji: string;
  title: string;
  message: string;
  variant: 'success' | 'error';
  children?: React.ReactNode;
}) {
  return (
    <div className="text-center">
      <div className="text-5xl mb-4">{emoji}</div>
      <h1 className={`text-2xl font-bold mb-3 ${variant === 'success' ? 'text-[#006E2A]' : 'text-[#BA002C]'}`}>
        {title}
      </h1>
      <p className="text-neutral-700 leading-relaxed">{message}</p>
      {children}
    </div>
  );
}
