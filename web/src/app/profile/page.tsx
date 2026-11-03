'use client';
import { useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useTheme } from '@/contexts/ThemeContext';
import api from '@/lib/api';
import { PageHeader } from '@/components/layout/PageHeader';
import { RouteLinks, AdminLinks } from '@/components/layout/RouteLinks';
import { Button } from '@/components/ui/Button';
import { TextField, Select } from '@/components/ui/FormField';
import { ErrorState } from '@/components/ui/ErrorState';
export default function ProfilePage() {
  const { user, logout } = useAuth(); const { theme, setTheme } = useTheme();
  const [share, setShare] = useState<{ url: string; expires_at: string } | null>(null); const [error, setError] = useState(''); const [busy, setBusy] = useState(false);
  async function shareLocation() { setBusy(true); setError(''); const res = await api.post<{ url: string; expires_at: string }>('/users/me/share-location', { hours: 1 }); if (res.error || !res.url) setError('Nie udało się utworzyć linku lokalizacji.'); else setShare(res); setBusy(false); }
  return <div className="page-container"><PageHeader title="Profil" description={`${user?.username || ''} · ${user?.email || ''}`}><Button variant="secondary" onClick={logout}>Wyloguj się</Button></PageHeader><section className="panel mb-6 space-y-4"><h2 className="text-xl font-bold">Lokalizacja i wygląd</h2><p className="text-ink-2">Promień powiadomień: {((user?.alert_radius_m || 0) / 1000).toLocaleString('pl-PL')} km. Zmienisz go w ustawieniach.</p><Button onClick={shareLocation} loading={busy} variant="secondary">Udostępnij lokalizację na godzinę</Button>{error && <ErrorState message={error} />}{share && <TextField label="Link lokalizacji do skopiowania" readOnly value={share.url} onFocus={event => event.target.select()} hint={`Ważny do ${new Date(share.expires_at).toLocaleString('pl-PL')}`} />}<Select label="Wygląd na tym urządzeniu" value={theme} onChange={event => setTheme(event.target.value as 'light' | 'dark' | 'system')}><option value="system">Zgodnie z urządzeniem</option><option value="light">Jasny</option><option value="dark">Ciemny</option></Select></section><h2 className="text-xl font-bold mb-4">Twoje konto i narzędzia</h2><RouteLinks section="profile" /><h2 className="text-xl font-bold my-4">W okolicy</h2><RouteLinks section="nearby" /><h2 className="text-xl font-bold my-4">Bliscy</h2><RouteLinks section="family" /><p className="text-ink-2 my-4">Czat, plan rodzinny i profile osób znajdziesz po wybraniu grupy w sekcji Bliscy.</p><AdminLinks /></div>;
}
