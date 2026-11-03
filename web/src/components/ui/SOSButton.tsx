import Link from 'next/link';
export default function SOSButton() {
  return (
    <Link href="/sos" className="btn btn-danger sos-link">
      SOS — pomoc
    </Link>
  );
}
