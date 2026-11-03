import Link from 'next/link';
import { CheckinAction } from '@/components/family/CheckinAction';
export function ModeQuickActions() {
  return (
    <section className="page-container space-y-4" aria-label="Szybkie działania">
      <h1 className="text-2xl font-bold">Co chcesz teraz zrobić?</h1>
      <div className="grid sm:grid-cols-3 gap-3">
        <Link className="btn btn-secondary min-h-16" href="/family">
          Skontaktuj się z bliskimi
        </Link>
        <Link className="btn btn-secondary min-h-16" href="/help">
          Znajdź pomoc
        </Link>
        <Link className="btn btn-danger min-h-16" href="/sos">
          Potrzebuję pomocy — SOS
        </Link>
      </div>
      <CheckinAction />
    </section>
  );
}
