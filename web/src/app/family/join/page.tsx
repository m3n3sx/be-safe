'use client';
import { useSearchParams } from 'next/navigation';
import { Suspense } from 'react';
import { JoinGroup } from '@/components/family/JoinGroup';
import { Skeleton } from '@/components/ui/Skeleton';

function JoinFromQuery() {
  const params = useSearchParams();
  return <JoinGroup initial={params.get('code') || ''} />;
}

export default function Page() {
  return (
    <Suspense fallback={<Skeleton label="Ładowanie zaproszenia…" />}>
      <JoinFromQuery />
    </Suspense>
  );
}
