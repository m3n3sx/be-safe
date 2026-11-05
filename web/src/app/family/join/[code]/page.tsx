'use client';
import { useParams } from 'next/navigation';
import { JoinGroup } from '@/components/family/JoinGroup';

export default function Page() {
  const params = useParams<{ code: string }>();
  return <JoinGroup initial={decodeURIComponent(params.code || '')} />;
}
