'use client';
import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { ALERT_CATEGORIES, getCategoryInfo, type Alert, type AlertCategory } from '@/types';
import { alertsApi } from '@/lib/api/alerts';
import { isPoint, type Place } from '@/lib/location';
import { preparePhoto } from '@/lib/photo';
import { readSession, removeSession, writeSession } from '@/lib/storage';
import { MapProvider } from '@/components/map/MapProvider';
import { LocationPicker } from '@/components/map/LocationPicker';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { TextField, TextArea, Select } from '@/components/ui/FormField';
import { ErrorState } from '@/components/ui/ErrorState';
import { Dialog } from '@/components/ui/Dialog';
import { Skeleton } from '@/components/ui/Skeleton';
type Draft = { category: AlertCategory | null; place: Place | null; title: string; description: string; duration: number; anonymous: boolean };
const initial: Draft = { category: null, place: null, title: '', description: '', duration: 3, anonymous: false };
function Wizard() {
  const router = useRouter(); const [draft, setDraft] = useState<Draft>(initial); const [ready, setReady] = useState(false); const [step, setStep] = useState(1); const [search, setSearch] = useState(''); const [photo, setPhoto] = useState<File | null>(null); const [preview, setPreview] = useState(''); const [photoBusy, setPhotoBusy] = useState(false);
  const [error, setError] = useState(''); const [busy, setBusy] = useState(false); const [success, setSuccess] = useState<Alert | null>(null); const [uncertain, setUncertain] = useState(false); const [checkedMine, setCheckedMine] = useState(false); const [leaveTo, setLeaveTo] = useState(''); const [saved, setSaved] = useState(false); const [restored, setRestored] = useState(false); const lock = useRef(false); const heading = useRef<HTMLHeadingElement>(null); const fileRequest = useRef(0);
  useEffect(() => { const timer = setTimeout(() => { const value = readSession<Draft>('besafe.report'); if (value && (!value.place || isPoint(value.place)) && ALERT_CATEGORIES.some(cat => cat.key === value.category)) { setDraft({ ...initial, ...value }); setRestored(true); } setReady(true); }, 0); return () => clearTimeout(timer); }, []);
  useEffect(() => { if (ready && !success && draft.category) writeSession('besafe.report', draft); }, [draft, ready, success]);
  useEffect(() => { if (!photo) return; const url = URL.createObjectURL(photo); const timer = setTimeout(() => setPreview(url), 0); return () => { clearTimeout(timer); URL.revokeObjectURL(url); }; }, [photo]);
  useEffect(() => { heading.current?.focus(); }, [step]);
  useEffect(() => {
    if (!draft.category || success) return;
    const beforeUnload = (event: BeforeUnloadEvent) => { event.preventDefault(); };
    const navigation = (event: MouseEvent) => {
      if (event.defaultPrevented || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey || event.button !== 0) return;
      const link = (event.target as HTMLElement).closest<HTMLAnchorElement>('a[href]');
      if (!link || link.target === '_blank') return;
      const url = new URL(link.href, window.location.href);
      if (url.origin !== window.location.origin || url.pathname === '/report' || url.pathname === '/sos' || url.protocol !== 'http:' && url.protocol !== 'https:') return;
      event.preventDefault(); event.stopPropagation(); setLeaveTo(`${url.pathname}${url.search}`);
    };
    window.addEventListener('beforeunload', beforeUnload); document.addEventListener('click', navigation, true);
    return () => { window.removeEventListener('beforeunload', beforeUnload); document.removeEventListener('click', navigation, true); };
  }, [draft.category, success]);
  function update(values: Partial<Draft>) { setDraft(current => ({ ...current, ...values })); setError(''); }
  async function selectPhoto(file?: File) {
    const request = ++fileRequest.current; setError(''); if (!file) return; setPhotoBusy(true);
    try { const processed = await preparePhoto(file); if (request === fileRequest.current) setPhoto(processed); } catch (cause) { if (request === fileRequest.current) setError(cause instanceof Error ? cause.message : 'Nie udało się odczytać zdjęcia.'); } finally { if (request === fileRequest.current) setPhotoBusy(false); }
  }
  async function submit(event: React.FormEvent) {
    event.preventDefault(); if (lock.current || !draft.category || !draft.place || !draft.title.trim() || photoBusy || uncertain && !checkedMine) return;
    lock.current = true; setBusy(true); setError(''); const started = Date.now();
    const data = new FormData(); data.set('category', draft.category); data.set('title', draft.title.trim()); data.set('description', draft.description.trim()); data.set('lat', String(draft.place.lat)); data.set('lng', String(draft.place.lng)); data.set('radius_m', '100'); data.set('duration_hours', String(draft.duration)); data.set('is_anonymous', String(draft.anonymous)); if (photo) data.set('photo', photo);
    const result = await alertsApi.create(data);
    if (!result.error && result.id) { setSuccess(result); removeSession('besafe.report'); }
    else if (result.httpStatus === 0 || !result.error || (result.httpStatus || 0) >= 500) {
      setUncertain(true); setCheckedMine(false);
      const mine = await alertsApi.mine();
      const match = !mine.error && mine.alerts?.find(alert => alert.title === draft.title.trim() && alert.category === draft.category && Math.abs(Number(alert.lat) - draft.place!.lat) < .00001 && Math.abs(Number(alert.lng) - draft.place!.lng) < .00001 && new Date(alert.created_at).getTime() >= started - 10000);
      if (match) { setSuccess(match); removeSession('besafe.report'); } else setError('Nie znamy wyniku wysyłki. Sprawdź Moje zgłoszenia przed ponowną próbą, aby nie dodać tego samego zdarzenia dwa razy.');
    } else if (result.httpStatus === 422) setError('Treść lub zdjęcie zostały odrzucone przez moderację. Popraw zgłoszenie i spróbuj ponownie.');
    else if (result.httpStatus === 429) setError(`Osiągnięto limit zgłoszeń. Spróbuj później.${result.retryAfter ? ` Ponowienie według serwera: ${result.retryAfter} (Retry-After).` : ''}`);
    else if (result.httpStatus === 401) setError('Sesja wygasła. Zaloguj się ponownie — szkic jest zachowany na tej karcie.');
    else setError('Nie wysłano zgłoszenia. Sprawdź połączenie i spróbuj ponownie. Szkic został zachowany.');
    lock.current = false; setBusy(false);
  }
  if (!ready) return <Skeleton />;
  if (success) return <div className="form-container"><PageHeader title={success.status === 'hidden' ? 'Zgłoszenie czeka na sprawdzenie' : 'Zgłoszenie dodane'} description={success.status === 'hidden' ? 'Zostanie opublikowane po akceptacji moderacji.' : 'Dziękujemy za informację dla innych osób w okolicy.'} /><div className="panel space-y-4" role="status"><h2 className="text-xl font-bold">{success.title}</h2><p>{draft.place?.label}</p><Link href={`/alerts/${encodeURIComponent(success.id)}`} className="btn btn-primary">Zobacz zgłoszenie</Link><Link href="/alerts/mine" className="btn btn-secondary">Moje zgłoszenia</Link><Link href="/" className="btn btn-quiet">Wróć do okolicy</Link></div></div>;
  return <div className="form-container"><PageHeader title="Zgłoś zdarzenie" description="Ostrzeż innych w trzech prostych krokach." /><ol className="flex gap-3 mb-6 text-sm" aria-label="Etapy zgłoszenia">{['Co się stało?', 'Gdzie?', 'Szczegóły'].map((title, index) => <li className={`flex-1 border-b-4 pb-3 ${step === index + 1 ? 'border-primary font-bold' : 'border-border text-ink-2'}`} key={title} aria-current={step === index + 1 ? 'step' : undefined}>{index + 1}. {title}</li>)}</ol>{restored && <p role="status" className="panel mb-4">Przywrócono szkic z tej karty. Zdjęcie dodaj ponownie.</p>}<h2 ref={heading} tabIndex={-1} className="text-2xl font-bold mb-4">{step === 1 ? 'Co się stało?' : step === 2 ? 'Gdzie to się dzieje?' : 'Sprawdź i wyślij'}</h2>{error && <div className="mb-4"><ErrorState message={error} /></div>}{step === 1 && <div className="space-y-4"><TextField label="Szukaj kategorii" value={search} onChange={event => setSearch(event.target.value)} /><div className="grid grid-cols-2 sm:grid-cols-3 gap-3">{ALERT_CATEGORIES.filter(cat => cat.label.toLocaleLowerCase('pl').includes(search.toLocaleLowerCase('pl'))).map(cat => <button className={`min-h-28 p-3 rounded-xl border-2 flex flex-col items-center justify-center gap-2 ${draft.category === cat.key ? 'border-primary bg-surface-2' : 'border-border bg-surface'}`} key={cat.key} aria-pressed={draft.category === cat.key} onClick={() => update({ category: cat.key, title: !draft.title || draft.title === (draft.category ? getCategoryInfo(draft.category).label : '') ? cat.label : draft.title })}><span aria-hidden="true" className="text-3xl">{cat.emoji}</span><span className="font-medium">{cat.label}</span></button>)}</div><Button disabled={!draft.category} onClick={() => setStep(2)}>Dalej — wybierz miejsce</Button></div>}{step === 2 && <><LocationPicker value={draft.place} onChange={place => update({ place })} /><div className="flex flex-wrap gap-2 mt-6"><Button variant="secondary" onClick={() => setStep(1)}>Wstecz</Button><Button disabled={!draft.place} onClick={() => setStep(3)}>To tutaj — dalej</Button></div></>}{step === 3 && <form onSubmit={submit} className="space-y-4"><div className="panel"><p className="font-bold">{draft.category && getCategoryInfo(draft.category).label}</p><p>{draft.place?.label}</p><p className="text-sm text-ink-2">{draft.place?.lat.toFixed(5)}, {draft.place?.lng.toFixed(5)}</p><Button variant="quiet" onClick={() => setStep(2)}>Zmień miejsce</Button></div><TextField label="Tytuł" required maxLength={200} value={draft.title} onChange={event => update({ title: event.target.value })} /><TextArea label="Opis (opcjonalnie)" rows={4} maxLength={5000} value={draft.description} onChange={event => update({ description: event.target.value })} /><TextField label="Zdjęcie (opcjonalnie)" type="file" accept="image/jpeg,image/png,image/webp" onChange={event => { void selectPhoto(event.target.files?.[0]); event.target.value = ''; }} hint="JPEG, PNG lub WebP, maksymalnie 5 MB. Możesz zrobić zdjęcie lub wybrać je z urządzenia." disabled={photoBusy || busy} />{photoBusy && <p role="status">Przygotowywanie zdjęcia…</p>}{photo && <div className="space-y-2">{preview && <img src={preview} alt="Podgląd zdjęcia do zgłoszenia" className="max-h-56 rounded-xl" />}<p className="text-sm">{photo.name} · {Math.round(photo.size / 1024)} KB</p><Button variant="secondary" onClick={() => { setPhoto(null); setPreview(''); }}>Usuń zdjęcie</Button></div>}<Select label="Czas ważności" value={draft.duration} onChange={event => update({ duration: Number(event.target.value) })}>{[1, 3, 6, 12, 24].map(hours => <option key={hours} value={hours}>{hours} godz.</option>)}</Select><label className="flex gap-3 items-start min-h-12"><input type="checkbox" className="mt-1 size-5" checked={draft.anonymous} onChange={event => update({ anonymous: event.target.checked })} /><span>Ukryj moją nazwę przy zgłoszeniu<span className="block text-sm text-ink-2">Twoja nazwa nie będzie widoczna dla innych użytkowników. Zgłoszenie nadal jest powiązane z Twoim kontem.</span></span></label>{uncertain && <div className="panel space-y-3"><Link href="/alerts/mine" target="_blank" className="btn btn-secondary">Sprawdź Moje zgłoszenia ↗</Link><label className="flex gap-3"><input type="checkbox" checked={checkedMine} onChange={event => setCheckedMine(event.target.checked)} /><span>Sprawdziłem/am listę — tego zgłoszenia nie ma.</span></label></div>}<div className="flex flex-wrap gap-2"><Button variant="secondary" onClick={() => setStep(2)} disabled={busy}>Wstecz</Button><Button type="submit" loading={busy} disabled={!draft.title.trim() || photoBusy || uncertain && !checkedMine}>Wyślij zgłoszenie</Button></div><Link className="btn btn-quiet" href="/login?returnTo=%2Freport">Zaloguj się ponownie, jeśli sesja wygasła</Link></form>}<div className="mt-6 border-t border-border pt-4"><Button variant="quiet" onClick={() => { setSaved(writeSession('besafe.report', draft)); }}>Zachowaj szkic na tej karcie</Button>{saved && <p role="status" className="text-sm text-success">Szkic zapisany. Zdjęcia nie są zapisywane w szkicu.</p>}</div><Dialog open={!!leaveTo} title="Co zrobić ze zgłoszeniem?" onClose={() => setLeaveTo('')}><p className="mb-4">Możesz wrócić do szkicu później na tej karcie. Zdjęcie będzie trzeba dodać ponownie.</p><div className="flex flex-wrap gap-2"><Button onClick={() => { writeSession('besafe.report', draft); router.push(leaveTo); setLeaveTo(''); }}>Zachowaj szkic i wyjdź</Button><Button variant="danger" onClick={() => { removeSession('besafe.report'); router.push(leaveTo); setLeaveTo(''); }}>Porzuć zgłoszenie</Button><Button variant="secondary" onClick={() => setLeaveTo('')}>Wróć do formularza</Button></div></Dialog></div>;
}
export default function ReportWizard() { return <MapProvider><Wizard /></MapProvider>; }
