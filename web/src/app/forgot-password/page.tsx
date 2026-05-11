'use client';

import { useState } from 'react';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!email) return;
    setLoading(true);
    setError('');
    try {
      const res = await fetch('/api/v1/auth/forgot-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });
      const data = await res.json();
      if (res.ok) {
        setSubmitted(true);
      } else {
        setError(data.error || 'Wystąpił błąd. Spróbuj ponownie.');
      }
    } catch {
      setError('Wystąpił błąd połączenia.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-[#FFF8F7] flex items-center justify-center px-4 py-12">
      <div className="w-full max-w-md bg-white rounded-3xl shadow-[0_2px_16px_rgba(186,0,44,0.08)] overflow-hidden">
        <div className="bg-gradient-to-br from-[#BA002C] to-[#E9003A] px-6 py-8 text-center">
          <div className="text-white text-3xl font-bold tracking-tight">be:Safe</div>
          <div className="text-white/85 text-sm mt-1">Resetowanie hasła</div>
        </div>

        <div className="p-8">
          {submitted ? (
            <div className="text-center">
              <div className="text-5xl mb-4">📧</div>
              <h1 className="text-2xl font-bold mb-3 text-[#291616]">Sprawdź skrzynkę</h1>
              <p className="text-neutral-700 leading-relaxed">
                Jeśli konto powiązane z tym adresem istnieje, wysłaliśmy na niego link do zresetowania hasła.
                Link jest ważny <strong>1 godzinę</strong>.
              </p>
              <p className="text-sm text-neutral-500 mt-6">
                Nie widzisz emaila? Sprawdź folder SPAM lub napisz do{' '}
                <a href="mailto:wsparcie@besafe.org.pl" className="text-[#BA002C] underline">wsparcie@besafe.org.pl</a>.
              </p>
            </div>
          ) : (
            <>
              <h1 className="text-2xl font-bold mb-2 text-[#291616]">Zapomniane hasło</h1>
              <p className="text-neutral-700 mb-6 text-sm leading-relaxed">
                Podaj email powiązany z kontem. Wyślemy link do ustawienia nowego hasła.
              </p>

              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-semibold mb-2 text-[#291616]">Email</label>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="twoj@email.pl"
                    className="w-full px-4 py-3 bg-[#FFF0EF] rounded-xl border-2 border-transparent focus:border-[#BA002C] focus:bg-white outline-none transition"
                  />
                </div>

                {error && (
                  <div className="p-3 bg-[#FFDAD6] text-[#93000A] rounded-xl text-sm">{error}</div>
                )}

                <button
                  type="submit"
                  disabled={loading || !email}
                  className="w-full py-4 bg-[#BA002C] text-white rounded-full font-semibold hover:bg-[#920021] transition disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {loading ? 'Wysyłam…' : 'Wyślij link resetujący'}
                </button>
              </form>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
