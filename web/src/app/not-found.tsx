import Link from 'next/link';
export default function NotFound() {
  return (
    <div className="form-container space-y-4">
      <h1 className="text-2xl font-bold">Nie znaleziono strony</h1>
      <p>Sprawdź adres lub wybierz zadanie z nawigacji.</p>
      <Link href="/" className="btn btn-primary">
        Wróć do okolicy
      </Link>
      <Link href="/help" className="btn btn-secondary">
        Pomoc
      </Link>
    </div>
  );
}
