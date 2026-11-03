'use client';
import { useRef, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/AuthContext';
import api from '@/lib/api';
import type { Alert } from '@/types';
import type { Place } from '@/lib/location';
import { MapProvider } from '@/components/map/MapProvider';
import { LocationPicker } from '@/components/map/LocationPicker';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { ErrorState } from '@/components/ui/ErrorState';
import { Dialog } from '@/components/ui/Dialog';
export default function SosPage() {
  const { user } = useAuth(); const [place, setPlace] = useState<Place | null>(null); const [confirm, setConfirm] = useState(false); const [busy, setBusy] = useState(false); const [error, setError] = useState(''); const [sent, setSent] = useState<Alert | null>(null); const [uncertain, setUncertain] = useState(false); const lock = useRef(false);
  async function send() {
    if (!place || lock.current || !user) return; lock.current = true; setBusy(true); setError('');
    const result = await api.post<Alert>('/alerts', { category: 'aggression', title: '🆘 SOS — Potrzebuję pomocy!', description: 'Alarm SOS wysłany z be:Safe.', lat: place.lat, lng: place.lng, radius_m: 500 });
    if (result.error || !result.id) { setUncertain(result.httpStatus === 0 || (result.httpStatus || 0) >= 500); setError(result.httpStatus === 0 ? 'Nie znamy wyniku wysyłki. Sprawdź Moje zgłoszenia przed kolejną próbą.' : 'Nie udało się zapisać alarmu. Możesz zadzwonić pod 112.'); } else setSent(result);
    setBusy(false); setConfirm(false); lock.current = false;
  }
  return <div className="form-container"><PageHeader title="SOS — pilna pomoc" description="W bezpośrednim zagrożeniu życia zadzwoń pod numer 112." /><a href="tel:112" className="btn btn-danger sos-link w-full mb-6 text-xl">Zadzwoń 112</a><p className="mb-6 text-ink-2">Numer alarmowy: <strong>112</strong>. Telefon działa niezależnie od logowania i mapy.</p>{sent ? <section className="panel space-y-4" role="status"><h2 className="text-2xl font-bold">Alarm zapisany</h2><p>{new Date(sent.created_at).toLocaleString('pl-PL')} · {place?.label}</p><p>To nie jest potwierdzenie przyjęcia zgłoszenia przez służby.</p><Link href="/family" className="btn btn-secondary">Skontaktuj się z bliskimi</Link><Link href={`/alerts/${sent.id}`} className="btn btn-quiet">Zobacz alarm</Link></section> : !user ? <section className="panel space-y-4"><h2 className="text-xl font-bold">Alarm be:Safe</h2><p>Wysłanie alarmu w aplikacji wymaga konta. Numer 112 i pomoc są dostępne od razu.</p><Link href="/login?returnTo=%2Fsos" className="btn btn-primary">Zaloguj się do be:Safe</Link><Link href="/emergency" className="btn btn-secondary">Inne numery pomocy</Link></section> : <section className="space-y-4"><h2 className="text-xl font-bold">Wyślij alarm be:Safe</h2><p>Alarm trafia do społeczności zgodnie z ustawieniami odbiorców. Osobne powiadomienia rodzinne zależą od roli i śledzenia; samo członkostwo w grupie ich nie gwarantuje.</p><MapProvider><LocationPicker value={place} onChange={setPlace} /></MapProvider>{error && <ErrorState message={error} />}{uncertain ? <Link href="/alerts/mine" className="btn btn-secondary">Sprawdź Moje zgłoszenia</Link> : <Button variant="danger" disabled={!place || busy} className="sos-link w-full" onClick={() => setConfirm(true)}>Wyślij alarm — przejdź do potwierdzenia</Button>}</section>}<Dialog open={confirm} title="Wysłać alarm be:Safe?" onClose={() => { if (!busy) setConfirm(false); }}><div className="space-y-4"><p>Udostępnisz miejsce: {place?.label}. Wysłanie alarmu nie zastępuje telefonu do służb.</p><Button variant="danger" loading={busy} onClick={send}>Tak, wyślij alarm</Button><Button variant="secondary" disabled={busy} onClick={() => setConfirm(false)}>Anuluj</Button><a href="tel:112" className="btn btn-danger">Zadzwoń 112</a></div></Dialog></div>;
}
