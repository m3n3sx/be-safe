'use client';
import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/AuthContext';
import { sendSos } from '@/lib/sos';
import type { Alert } from '@/types';
import type { Place } from '@/lib/location';
import { MapProvider } from '@/components/map/MapProvider';
import { LocationPicker } from '@/components/map/LocationPicker';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { ErrorState } from '@/components/ui/ErrorState';
import { Dialog } from '@/components/ui/Dialog';
import { EmergencyCall } from './EmergencyCall';
import { AudioRecorder } from './AudioRecorder';
export function SosFlow() {
  const { user } = useAuth();
  const [place, setPlace] = useState<Place | null>(null);
  const [confirm, setConfirm] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [sent, setSent] = useState<Alert | null>(null);
  const [uncertain, setUncertain] = useState(false);
  const [progress, setProgress] = useState(0);
  const lock = useRef(false);
  const timer = useRef<ReturnType<typeof setInterval> | null>(null);
  function cancelHold() {
    if (timer.current) clearInterval(timer.current);
    timer.current = null;
    setProgress(0);
  }
  useEffect(() => {
    const cancel = () => {
      if (timer.current) clearInterval(timer.current);
      timer.current = null;
      setProgress(0);
    };
    window.addEventListener('blur', cancel);
    document.addEventListener('visibilitychange', cancel);
    return () => {
      if (timer.current) clearInterval(timer.current);
      window.removeEventListener('blur', cancel);
      document.removeEventListener('visibilitychange', cancel);
    };
  }, []);
  async function send() {
    if (!place || lock.current || !user || uncertain || sent) return;
    lock.current = true;
    setBusy(true);
    setError('');
    cancelHold();
    const result = await sendSos(place);
    if (result.error || !result.id) {
      const unknown = result.httpStatus === 0 || (result.httpStatus || 0) >= 500;
      setUncertain(unknown);
      setError(
        unknown
          ? 'Nie znamy wyniku wysyłki. Sprawdź Moje zgłoszenia przed kolejną próbą.'
          : 'Nie udało się zapisać alarmu. Możesz zadzwonić pod 112.',
      );
    } else setSent(result);
    setBusy(false);
    setConfirm(false);
    lock.current = false;
  }
  function hold() {
    if (!place || busy || timer.current) return;
    const start = Date.now();
    timer.current = setInterval(() => {
      const elapsed = Date.now() - start;
      setProgress(Math.min(100, elapsed / 20));
      if (elapsed >= 2000) {
        cancelHold();
        void send();
      }
    }, 50);
  }
  return (
    <div className="form-container space-y-5">
      <PageHeader
        title="SOS — pilna pomoc"
        description="W bezpośrednim zagrożeniu życia zadzwoń pod numer 112."
      />
      <div className="sticky top-20 z-10 bg-background py-2">
        <EmergencyCall />
      </div>
      <p className="text-ink-2">
        Numer alarmowy: <strong>112</strong>. Telefon działa niezależnie od konta, mapy i alarmu
        be:Safe.
      </p>
      {sent ? (
        <section className="panel space-y-4" role="status">
          <h2 className="text-2xl font-bold">
            {sent.status === 'hidden'
              ? 'Alarm zapisany — oczekuje na sprawdzenie'
              : 'Alarm zapisany'}
          </h2>
          <p>
            {new Date(sent.created_at).toLocaleString('pl-PL')} · {place?.label}
          </p>
          <p>To nie jest potwierdzenie przyjęcia zgłoszenia przez służby.</p>
          <Link href="/family" className="btn btn-secondary">
            Skontaktuj się z bliskimi
          </Link>
          <Link href={`/alerts/${sent.id}`} className="btn btn-quiet">
            Zobacz alarm
          </Link>
        </section>
      ) : !user ? (
        <section className="panel space-y-4">
          <h2 className="text-xl font-bold">Alarm be:Safe wymaga konta</h2>
          <p>Możesz od razu zadzwonić pod 112 lub wybrać inny numer pomocy.</p>
          <Link href="/emergency" className="btn btn-secondary">
            Inne numery pomocy
          </Link>
          <Link href="/login?returnTo=%2Fsos" className="btn btn-quiet">
            Zaloguj się do be:Safe
          </Link>
        </section>
      ) : (
        <section className="space-y-4">
          <h2 className="text-xl font-bold">Wyślij alarm be:Safe</h2>
          <p>
            Alarm trafia do społeczności zgodnie z ustawieniami odbiorców. Powiadomienia rodzinne
            zależą od roli i śledzenia; samo członkostwo w grupie ich nie gwarantuje.
          </p>
          <MapProvider>
            <LocationPicker value={place} onChange={setPlace} />
          </MapProvider>
          {error && <ErrorState message={error} />}
          {uncertain ? (
            <Link href="/alerts/mine" className="btn btn-secondary">
              Sprawdź Moje zgłoszenia
            </Link>
          ) : (
            <>
              {user.app_mode !== 'senior' && (
                <>
                  <Button
                    variant="danger"
                    disabled={!place || busy}
                    className="sos-link w-full select-none touch-none"
                    onPointerDown={(event) => {
                      event.currentTarget.setPointerCapture(event.pointerId);
                      hold();
                    }}
                    onPointerUp={cancelHold}
                    onPointerCancel={cancelHold}
                    onLostPointerCapture={cancelHold}
                    onContextMenu={(event) => event.preventDefault()}
                    onKeyDown={(event) => {
                      if (event.key === 'Enter' || event.key === ' ') {
                        event.preventDefault();
                        setConfirm(true);
                      }
                    }}
                    aria-describedby="hold-help"
                  >
                    {progress
                      ? `Przytrzymaj… ${Math.ceil((100 - progress) / 50)} s`
                      : 'Przytrzymaj 2 sekundy, aby wysłać'}
                  </Button>
                  <progress
                    className="w-full accent-danger"
                    value={progress}
                    max={100}
                    aria-label="Postęp przytrzymania"
                  />
                  <p id="hold-help" className="text-sm text-ink-2">
                    Puszczenie przed upływem 2 sekund anuluje wysyłkę. Klawiatura otwiera
                    potwierdzenie.
                  </p>
                </>
              )}
              <Button
                variant={user.app_mode === 'senior' ? 'danger' : 'secondary'}
                className="w-full sos-link"
                disabled={!place || busy}
                onClick={() => setConfirm(true)}
              >
                Wyślij bez przytrzymywania
              </Button>
              {busy && <p role="status">Zapisywanie alarmu…</p>}
            </>
          )}
        </section>
      )}
      {user && <AudioRecorder />}
      <Dialog
        open={confirm}
        title="Wysłać alarm be:Safe?"
        onClose={() => {
          if (!busy) setConfirm(false);
        }}
      >
        <div className="space-y-4">
          <EmergencyCall />
          <p>Udostępnisz miejsce: {place?.label}. Alarm nie zastępuje telefonu do służb.</p>
          <Button variant="danger" loading={busy} onClick={send}>
            Potwierdzam — wyślij alarm
          </Button>
          <Button variant="secondary" disabled={busy} onClick={() => setConfirm(false)}>
            Anuluj
          </Button>
        </div>
      </Dialog>
    </div>
  );
}
