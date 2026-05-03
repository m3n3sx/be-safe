import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "be:Safe — Społecznościowy system bezpieczeństwa",
  description: "Zgłaszaj i monitoruj zagrożenia w czasie rzeczywistym. Chroń siebie i swoją rodzinę. 18 kategorii zagrożeń, mapa w real-time, SOS, śledzenie rodziny, geofencing. Za darmo.",
  keywords: ["bezpieczeństwo", "zagrożenia", "mapa", "alerty", "SOS", "rodzina", "śledzenie", "geofencing", "Polska"],
  openGraph: {
    title: "be:Safe — Społecznościowy system bezpieczeństwa",
    description: "Zgłaszaj i monitoruj zagrożenia w czasie rzeczywistym. Chroń siebie i swoją rodzinę.",
    url: "https://alert.u235.pl/landing",
    siteName: "be:Safe",
    type: "website",
  },
};

export default function LandingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
