'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { PageHeader } from '@/components/layout/PageHeader';
import { Button } from '@/components/ui/Button';
import { Icon } from '@/components/ui/Icon';

const steps = [
  [
    'Witaj w be:Safe',
    'Sprawdź zgłoszenia w okolicy, skontaktuj się z bliskimi i znajdź pomoc.',
    '/help',
    'Poznaj dostępne formy pomocy',
  ],
  [
    'Twoja okolica',
    'Wpisz miejscowość albo użyj lokalizacji. Mapa i lista pokazują ten sam obszar.',
    '/',
    'Otwórz okolicę',
  ],
  [
    'Powiadomienia po Twojemu',
    'Wybierz promień na koncie. Przeglądarka może pokazywać powiadomienia, gdy aplikacja jest otwarta.',
    '/settings',
    'Ustaw promień i powiadomienia',
  ],
  [
    'Bliżej bliskich',
    'Utwórz grupę albo dołącz kodem. Udostępniane lokalizacje mają czas ostatniej aktualizacji.',
    '/family',
    'Utwórz grupę lub dołącz',
  ],
  [
    'Pomoc zawsze pod ręką',
    'SOS w górnym pasku otwiera wybór pomocy. Telefon 112 działa bez konta. Wysłanie alarmu wymaga osobnego potwierdzenia.',
    '/mode',
    'Dopasuj widok aplikacji',
  ],
] as const;
export default function OnboardingPage() {
  const [index, setIndex] = useState(0);
  const router = useRouter();
  function finish() {
    localStorage.setItem('besafe.onboarded', '1');
    router.push('/');
  }
  const [title, description, href, label] = steps[index];
  return (
    <div className="form-container">
      <PageHeader
        title="Pierwsze kroki"
        description="Możesz pominąć wprowadzenie i wrócić do niego w ustawieniach."
      />
      <section className="panel space-y-5">
        <p className="text-sm text-ink-2" role="status">
          Krok {index + 1} z {steps.length}
        </p>
        <Icon name="book" />
        <h2 className="text-2xl font-bold">{title}</h2>
        <p>{description}</p>
        <Link className="btn btn-secondary" href={href}>
          {label}
        </Link>
        <div className="flex flex-wrap gap-3">
          <Button variant="secondary" disabled={index === 0} onClick={() => setIndex((i) => i - 1)}>
            Wstecz
          </Button>
          <Button onClick={() => (index === steps.length - 1 ? finish() : setIndex((i) => i + 1))}>
            {index === steps.length - 1 ? 'Gotowe' : 'Dalej'}
          </Button>
          <Button variant="quiet" onClick={finish}>
            Pomiń
          </Button>
        </div>
      </section>
    </div>
  );
}
