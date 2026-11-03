'use client';
import { ErrorState } from '@/components/ui/ErrorState';
import Link from 'next/link';
export default function ErrorPage({ reset }: { reset: () => void }) {
  return (
    <div className="form-container">
      <h1 className="text-2xl font-bold mb-4">Nie udało się wyświetlić strony</h1>
      <ErrorState message="Wystąpił błąd. Spróbuj ponownie lub wróć do okolicy." onRetry={reset} />
      <Link href="/" className="btn btn-secondary mt-4">
        Wróć do okolicy
      </Link>
      <Link href="/sos" className="btn btn-danger mt-4 ml-2">
        SOS
      </Link>
    </div>
  );
}
