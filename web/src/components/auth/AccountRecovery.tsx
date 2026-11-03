'use client';
import { useEffect, useRef, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import api from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { TextField } from '@/components/ui/TextField';
import { ErrorState } from '@/components/ui/ErrorState';
import { Skeleton } from '@/components/ui/Skeleton';
export function AccountRecovery({ mode }: { mode: 'forgot' | 'reset' | 'verify' }) {
  const query = useSearchParams(); const token = query.get('token'); const { user } = useAuth();
  const [email, setEmail] = useState(''); const [password, setPassword] = useState(''); const [confirmation, setConfirmation] = useState(''); const [error, setError] = useState(''); const [success, setSuccess] = useState(''); const [busy, setBusy] = useState(false); const [verified, setVerified] = useState(false);
  const lock = useRef(false); const verification = useRef<{ token: string; promise: ReturnType<typeof api.post<{ ok: boolean }>> } | null>(null);
  useEffect(() => {
    if (mode !== 'verify' || !token) return;
    let alive = true;
    if (verification.current?.token !== token) verification.current = { token, promise: api.post<{ ok: boolean }>('/auth/verify-email', { token }) };
    verification.current.promise.then(result => {
      if (!alive) return;
      setVerified(true);
      if (result.error || !result.ok) setError('Link weryfikacyjny jest nieprawidłowy, wygasł lub nie udało się połączyć z serwerem.');
      else setSuccess('Twój adres e-mail został potwierdzony.');
    });
    return () => { alive = false; };
  }, [mode, token]);
  async function submit(event: React.FormEvent) {
    event.preventDefault(); if (lock.current) return;
    if (mode === 'reset' && password !== confirmation) { setError('Hasła nie są identyczne.'); return; }
    lock.current = true; setBusy(true); setError('');
    const result = mode === 'forgot' ? await api.post('/auth/forgot-password', { email }) : await api.post('/auth/reset-password', { token, password });
    if (result.error) setError(mode === 'reset' ? 'Nie udało się zmienić hasła. Link mógł wygasnąć — poproś o nowy.' : 'Nie udało się wysłać prośby. Spróbuj ponownie.');
    else setSuccess(mode === 'forgot' ? 'Jeśli istnieje konto z tym adresem, otrzymasz wiadomość z linkiem do zmiany hasła.' : 'Hasło zmienione. Możesz się zalogować.');
    lock.current = false; setBusy(false);
  }
  async function resend() { if (lock.current) return; lock.current = true; setBusy(true); const result = await api.post('/auth/resend-verification'); if (result.error) setError('Nie udało się wysłać nowego linku. Spróbuj później.'); else { setError(''); setSuccess('Prośba o link weryfikacyjny została przyjęta. Sprawdź pocztę.'); } lock.current = false; setBusy(false); }
  return <div className="form-container"><PageHeader title={mode === 'forgot' ? 'Nie pamiętasz hasła?' : mode === 'reset' ? 'Ustaw nowe hasło' : 'Potwierdź adres e-mail'} /><div className="panel space-y-4">{error && <ErrorState message={error} />}{success ? <p role="status" className="text-success">{success}</p> : mode === 'verify' ? token && !verified ? <Skeleton label="Weryfikowanie adresu e-mail…" /> : <p>Otwórz link z wiadomości e-mail, aby potwierdzić adres.</p> : mode === 'reset' && !token ? <ErrorState message="W tym adresie brakuje tokenu. Poproś o nowy link." /> : <form className="space-y-4" onSubmit={submit}>{mode === 'forgot' ? <TextField label="Adres e-mail" type="email" required autoComplete="email" value={email} onChange={event => setEmail(event.target.value)} /> : <><TextField label="Nowe hasło" type="password" required minLength={6} autoComplete="new-password" value={password} onChange={event => setPassword(event.target.value)} /><TextField label="Powtórz nowe hasło" type="password" required minLength={6} autoComplete="new-password" value={confirmation} onChange={event => setConfirmation(event.target.value)} /></>}<Button type="submit" loading={busy}>{mode === 'forgot' ? 'Wyślij link do zmiany hasła' : 'Zapisz nowe hasło'}</Button></form>}{mode === 'verify' && user && <Button variant="secondary" onClick={resend} loading={busy}>Wyślij ponownie link weryfikacyjny</Button>}{mode === 'reset' && <Link className="btn btn-secondary" href="/forgot-password">Poproś o nowy link</Link>}<Link className="btn btn-quiet" href="/login">Przejdź do logowania</Link></div></div>;
}
