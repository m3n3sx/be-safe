'use client';
import Link from 'next/link';
import api from '@/lib/api';
import { notificationHref } from '@/lib/notification-routes';
import { useNotifications } from '@/contexts/NotificationsContext';

export function SignalLayer() {
  const { banner, sos, dismissBanner, dismissSos, refresh } = useNotifications();
  if (sos) {
    const href = notificationHref(sos);
    return (
      <div
        role="alertdialog"
        aria-label="Alarm SOS w be:Safe"
        className="fixed inset-0 z-[80] overflow-auto bg-[#7A1212] p-6 text-white"
      >
        <p className="text-sm font-bold tracking-wide">be:Safe</p>
        <h2 className="mt-3 text-4xl font-bold">SOS</h2>
        <p className="mt-4 text-2xl font-semibold">{sos.title}</p>
        <p className="mt-2 text-lg">{sos.body}</p>
        <p className="mt-4 max-w-xl text-sm">
          To jest komunikat wewnątrz aplikacji be:Safe. Nie jest komunikatem służb ratunkowych ani
          systemu operacyjnego i nie omija wyciszenia telefonu.
        </p>
        <div className="mt-6 flex flex-wrap gap-3">
          {href && (
            <Link className="btn bg-white text-[#7A1212]" href={href} onClick={dismissSos}>
              Zobacz miejsce
            </Link>
          )}
          <button
            type="button"
            className="btn border border-white"
            onClick={async () => {
              if (sos.id) await api.post(`/notifications/${sos.id}/ack`);
              dismissSos();
              await refresh();
            }}
          >
            Widzę ten alarm
          </button>
          <button type="button" className="btn border border-white" onClick={dismissSos}>
            Zamknij
          </button>
        </div>
      </div>
    );
  }
  if (!banner) return null;
  const href = notificationHref(banner);
  return (
    <div role="status" className="fixed left-3 right-3 top-20 z-50 rounded-2xl bg-[#14324F] p-4 text-white shadow-lg">
      <p className="text-sm font-bold">be:Safe</p>
      <p className="text-lg font-semibold">{banner.title}</p>
      <p>{banner.body}</p>
      <div className="mt-3 flex gap-2">
        {href && (
          <Link className="btn bg-white text-[#14324F]" href={href} onClick={dismissBanner}>
            Otwórz
          </Link>
        )}
        <button type="button" className="btn border border-white" onClick={dismissBanner}>
          Zamknij
        </button>
      </div>
    </div>
  );
}
