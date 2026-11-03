import { PageHeader } from '@/components/layout/PageHeader';
import { RouteLinks } from '@/components/layout/RouteLinks';
export default function HelpPage() { return <div className="page-container"><PageHeader title="Pomoc" description="Wybierz to, czego teraz potrzebujesz." /><a className="btn btn-danger sos-link mb-6" href="tel:112">Zadzwoń 112 — zagrożenie życia</a><RouteLinks section="help" /></div>; }
