import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'be:Safe — Społecznościowy system bezpieczeństwa',
  description:
    'Sprawdź zgłoszenia w okolicy, skontaktuj się z bliskimi i znajdź pomoc. Mapa i lista, 21 kategorii, SOS oraz bezpieczne strefy.',
  keywords: [
    'bezpieczeństwo',
    'zagrożenia',
    'mapa',
    'alerty',
    'SOS',
    'rodzina',
    'śledzenie',
    'geofencing',
    'Polska',
  ],
  openGraph: {
    title: 'be:Safe — Społecznościowy system bezpieczeństwa',
    description: 'Zgłoszenia w okolicy, kontakt z bliskimi i pomoc w jednym miejscu.',
    url: 'https://alert.u235.pl/landing',
    siteName: 'be:Safe',
    type: 'website',
  },
};

export default function LandingLayout({ children }: { children: React.ReactNode }) {
  return children;
}
