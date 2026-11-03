'use client';
import { useEffect, useRef, useState } from 'react';
import { Button } from '@/components/ui/Button';
import { ErrorState } from '@/components/ui/ErrorState';
export function AudioRecorder() {
  const [supported, setSupported] = useState(false); const [consent, setConsent] = useState(false); const [recording, setRecording] = useState(false); const [busy, setBusy] = useState(false); const [url, setUrl] = useState(''); const [error, setError] = useState('');
  const recorder = useRef<MediaRecorder | null>(null); const stream = useRef<MediaStream | null>(null); const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined); const alive = useRef(true); const discard = useRef(false); const objectUrl = useRef('');
  function stop() { clearTimeout(timer.current); if (recorder.current?.state === 'recording') recorder.current.stop(); stream.current?.getTracks().forEach(t => t.stop()); }
  useEffect(() => { alive.current = true; const initial = setTimeout(() => setSupported(typeof MediaRecorder !== 'undefined' && !!navigator.mediaDevices?.getUserMedia), 0); return () => { alive.current = false; clearTimeout(initial); clearTimeout(timer.current); if (recorder.current?.state === 'recording') recorder.current.stop(); stream.current?.getTracks().forEach(t => t.stop()); URL.revokeObjectURL(objectUrl.current); }; }, []);
  useEffect(() => { const hidden = () => { if (document.visibilityState !== 'visible') { clearTimeout(timer.current); if (recorder.current?.state === 'recording') recorder.current.stop(); stream.current?.getTracks().forEach(t => t.stop()); } }; document.addEventListener('visibilitychange', hidden); return () => document.removeEventListener('visibilitychange', hidden); }, []);
  async function start() {
    if (!consent || busy || recording) return; setBusy(true); setError(''); discard.current = false;
    try {
      const media = await navigator.mediaDevices.getUserMedia({ audio: true });
      if (!alive.current || discard.current) { media.getTracks().forEach(t => t.stop()); return; }
      stream.current = media; const r = new MediaRecorder(media); recorder.current = r; const chunks: BlobPart[] = [];
      r.ondataavailable = e => { if (e.data.size) chunks.push(e.data); };
      r.onstop = () => { media.getTracks().forEach(t => t.stop()); if (!alive.current) return; setRecording(false); if (discard.current) return; URL.revokeObjectURL(objectUrl.current); objectUrl.current = URL.createObjectURL(new Blob(chunks, { type: r.mimeType })); setUrl(objectUrl.current); };
      r.start(); setRecording(true); timer.current = setTimeout(stop, 30000);
    } catch { setError('Nie udało się uruchomić mikrofonu. Sprawdź uprawnienia. Alarm SOS nadal możesz wysłać.'); stream.current?.getTracks().forEach(t => t.stop()); }
    finally { if (alive.current) setBusy(false); }
  }
  function remove() { discard.current = true; stop(); URL.revokeObjectURL(objectUrl.current); objectUrl.current = ''; setUrl(''); }
  return <details className="panel"><summary className="min-h-12 py-3 cursor-pointer font-bold">Nagranie na tym urządzeniu (opcjonalnie)</summary><div className="space-y-3"><p>Do 30 sekund dźwięku w aktywnej karcie. Nagranie nie jest wysyłane do be:Safe, bliskich ani służb. Znika po opuszczeniu strony, chyba że pobierzesz plik.</p>{supported ? <><label className="flex gap-3 min-h-12 items-center"><input className="size-5" type="checkbox" checked={consent} onChange={e => { setConsent(e.target.checked); if (!e.target.checked) remove(); }} />Zgadzam się na lokalne nagranie mikrofonu</label><div className="flex flex-wrap gap-2"><Button variant="secondary" disabled={!consent || !!url} loading={busy} onClick={recording ? stop : start}>{recording ? 'Zatrzymaj nagrywanie' : 'Nagraj do 30 sekund'}</Button>{url && <><a href={url} download="besafe-nagranie" className="btn btn-secondary">Pobierz nagranie</a><Button variant="quiet" onClick={remove}>Usuń nagranie</Button></>}</div>{recording && <p role="status">Nagrywanie trwa. Zatrzyma się po 30 sekundach.</p>}{url && <audio className="w-full" controls src={url} aria-label="Odsłuch lokalnego nagrania" />}</> : <p>Nagrywanie nie jest dostępne w tej przeglądarce.</p>}{error && <ErrorState message={error} />}</div></details>;
}
