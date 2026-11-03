'use client';
import Link from 'next/link';
import type { Alert } from '@/types';
import { Dialog } from '@/components/ui/Dialog';
// Legacy entry point delegates to the single, routable report flow.
export default function CreateAlertModal({
  onClose,
}: {
  lat: number;
  lng: number;
  onClose: () => void;
  onCreated: (alert: Alert) => void;
}) {
  return (
    <Dialog open title="Zgłoś zdarzenie" onClose={onClose}>
      <p className="mb-4">Wybierz kategorię, potwierdź miejsce i dodaj szczegóły.</p>
      <Link className="btn btn-primary" href="/report" onClick={onClose}>
        Przejdź do zgłoszenia
      </Link>
    </Dialog>
  );
}
