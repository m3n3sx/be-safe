'use client';
import { useCallback, useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { safeReturnTo } from '@/lib/routes';
import { Button } from '@/components/ui/Button';
import { TextField } from '@/components/ui/TextField';
import { ErrorState } from '@/components/ui/ErrorState';

const GOOGLE_CLIENT_ID =
  process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ||
  '1098119585965-1dmn79cgjbhsr84f1iu3dibvpilc906p.apps.googleusercontent.com';
const authError = (text: string) =>
  ({
    'Invalid credentials': 'Nieprawidłowy e-mail lub hasło.',
    'Email or username taken': 'Ten e-mail lub nazwa są już zajęte.',
    'Password too short': 'Hasło musi mieć co najmniej 6 znaków.',
  })[text] || 'Nie udało się zalogować lub utworzyć konta. Sprawdź dane i połączenie.';
export default function LoginPage({ mode = 'login' }: { mode?: 'login' | 'register' }) {
  const { login, register, loginWithGoogle, user } = useAuth();
  const router = useRouter();
  const path = usePathname();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [username, setUsername] = useState('');
  const [referral, setReferral] = useState('');
  const [returnTo, setReturnTo] = useState('/');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [visible, setVisible] = useState(false);
  const [consent, setConsent] = useState(false);
  const [googleFailed, setGoogleFailed] = useState(false);
  const googleRef = useRef<HTMLDivElement>(null);
  const lock = useRef(false);
  const registering = mode === 'register';
  useEffect(() => {
    const query = new URLSearchParams(window.location.search);
    const timer = setTimeout(() => {
      setReturnTo(
        safeReturnTo(
          query.get('returnTo') ||
            (!['/', '/login', '/register'].includes(path)
              ? `${path}${window.location.search}`
              : '/'),
        ),
      );
      setReferral(query.get('ref') || '');
    }, 0);
    return () => clearTimeout(timer);
  }, [path]);
  useEffect(() => {
    if (user && ['/login', '/register'].includes(path))
      router.replace(safeReturnTo(new URLSearchParams(window.location.search).get('returnTo')));
  }, [user, path, router]);
  const credential = useCallback(
    async (response: { credential: string }) => {
      if (lock.current) return;
      lock.current = true;
      setBusy(true);
      setError('');
      try {
        const encoded = response.credential.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
        const payload = JSON.parse(
          new TextDecoder().decode(Uint8Array.from(atob(encoded), (char) => char.charCodeAt(0))),
        );
        const err = await loginWithGoogle(
          response.credential,
          payload.email,
          payload.name,
          payload.picture,
        );
        if (err) setError(authError(err));
        else router.replace(returnTo);
      } catch {
        setError('Nie udało się zalogować przez Google. Spróbuj ponownie.');
      } finally {
        lock.current = false;
        setBusy(false);
      }
    },
    [loginWithGoogle, returnTo, router],
  );
  useEffect(() => {
    if (registering && !consent) return;
    let attempts = 0;
    const timer = setInterval(() => {
      const id = window.google?.accounts?.id;
      if (id && googleRef.current) {
        clearInterval(timer);
        id.initialize({ client_id: GOOGLE_CLIENT_ID, callback: credential });
        googleRef.current.replaceChildren();
        id.renderButton(googleRef.current, {
          theme: 'outline',
          size: 'large',
          text: 'continue_with',
          locale: 'pl',
          width: 280,
        });
      } else if (++attempts >= 40) {
        clearInterval(timer);
        setGoogleFailed(true);
      }
    }, 250);
    return () => clearInterval(timer);
  }, [credential, registering, consent]);
  async function submit(event: React.FormEvent) {
    event.preventDefault();
    if (lock.current) return;
    lock.current = true;
    setBusy(true);
    setError('');
    const err = registering
      ? await register(email, password, username, referral.trim())
      : await login(email, password);
    if (err) setError(authError(err));
    else router.replace(returnTo);
    setBusy(false);
    lock.current = false;
  }
  return (
    <div className="max-w-5xl mx-auto px-4 py-8 lg:py-16 grid lg:grid-cols-2 gap-8 lg:gap-16">
      <section className="self-center space-y-5">
        <p className="text-primary font-semibold">Twoja okolica. Twoi bliscy.</p>
        <h1 className="text-3xl lg:text-4xl font-bold leading-tight">
          Wiedz, co dzieje się blisko Ciebie.
        </h1>
        <p className="text-ink-2 text-lg">
          Sprawdzaj lokalne zgłoszenia, ostrzegaj innych i miej pomoc pod ręką.
        </p>
        <p className="text-ink-2">
          Zaloguj się, aby zobaczyć mapę i zgłoszenia.
          {returnTo === '/report' && ' Po zalogowaniu wrócisz do formularza zgłoszenia.'}
        </p>
        <Link href="/help" className="btn btn-secondary">
          Potrzebujesz pomocy? Bez logowania →
        </Link>
      </section>
      <section className="panel space-y-5">
        <h2 className="text-2xl font-bold">
          {registering ? 'Utwórz konto' : 'Dobrze Cię widzieć'}
        </h2>
        <form onSubmit={submit} className="space-y-4">
          {registering && (
            <TextField
              label="Twoja nazwa"
              autoComplete="nickname"
              required
              value={username}
              onChange={(event) => setUsername(event.target.value)}
            />
          )}
          <TextField
            label="Adres e-mail"
            type="email"
            autoComplete="email"
            required
            value={email}
            onChange={(event) => setEmail(event.target.value)}
          />
          <TextField
            label="Hasło"
            type={visible ? 'text' : 'password'}
            minLength={6}
            autoComplete={registering ? 'new-password' : 'current-password'}
            required
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            hint={registering ? 'Co najmniej 6 znaków.' : undefined}
          />
          <Button variant="quiet" onClick={() => setVisible(!visible)} aria-pressed={visible}>
            {visible ? 'Ukryj hasło' : 'Pokaż hasło'}
          </Button>
          {registering && (
            <>
              <TextField
                label="Kod polecenia (opcjonalnie)"
                value={referral}
                onChange={(event) => setReferral(event.target.value)}
              />
              <label className="flex items-start gap-3 min-h-12">
                <input
                  className="mt-1 size-5"
                  type="checkbox"
                  required
                  checked={consent}
                  onChange={(event) => setConsent(event.target.checked)}
                />
                <span>
                  Mam co najmniej 13 lat i akceptuję{' '}
                  <Link className="underline" href="/terms">
                    regulamin
                  </Link>
                  . Zapoznałem/am się z{' '}
                  <Link className="underline" href="/privacy">
                    polityką prywatności
                  </Link>
                  .
                </span>
              </label>
            </>
          )}
          {error && <ErrorState message={error} />}
          <Button type="submit" loading={busy} className="w-full">
            {registering ? 'Utwórz konto' : 'Zaloguj się'}
          </Button>
          {!registering && (
            <Link href="/forgot-password" className="btn btn-quiet w-full">
              Nie pamiętam hasła
            </Link>
          )}
        </form>
        <div className="border-t border-border pt-4">
          <p className="text-center text-ink-2 mb-3">lub kontynuuj z Google</p>
          {registering && !consent ? (
            <p className="text-sm text-ink-2">Najpierw zaznacz deklarację powyżej.</p>
          ) : (
            <div ref={googleRef} className="flex justify-center min-h-12" />
          )}
          {googleFailed && (
            <p className="text-sm text-ink-2">
              Google jest teraz niedostępne. Możesz użyć e-maila i hasła.
            </p>
          )}
        </div>
        <Link
          className="btn btn-secondary w-full"
          href={`${registering ? '/login' : '/register'}?returnTo=${encodeURIComponent(returnTo)}${referral ? `&ref=${encodeURIComponent(referral)}` : ''}`}
        >
          {registering ? 'Masz konto? Zaloguj się' : 'Nie masz konta? Zarejestruj się'}
        </Link>
      </section>
    </div>
  );
}
