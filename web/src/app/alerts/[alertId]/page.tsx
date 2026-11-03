import AlertDetail from '@/components/alerts/AlertDetail';
import Link from 'next/link';
export default async function AlertPage({ params }: { params: Promise<{ alertId: string }> }) {
  const { alertId } = await params;
  return <div className="form-container"><Link href="/" className="btn btn-secondary">← Wróć do okolicy</Link><h1 className="sr-only">Szczegóły zgłoszenia</h1><AlertDetail key={alertId} alertId={alertId} /></div>;
}
