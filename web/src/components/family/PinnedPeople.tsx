'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/AuthContext';
import { useApiResource } from '@/hooks/useApiResource';
import type { FamilyMember } from '@/types';
import { Skeleton } from '@/components/ui/Skeleton';
import { ErrorState } from '@/components/ui/ErrorState';
function Person({ path }: { path: string }) {
  const [, , groupId, , memberId] = path.split('/');
  const resource = useApiResource<{ members: FamilyMember[] }>(`/family/groups/${groupId}/members`);
  const member = resource.data?.members.find(m => m.user_id === memberId);
  return <li>{resource.loading ? <Skeleton /> : resource.error ? <ErrorState message={resource.error} onRetry={resource.reload} /> : <Link href={path} className="panel block hover:border-primary"><strong>{member?.username || 'Osoba niedostępna'}</strong><p className="text-sm text-ink-2">Przypięta na tym urządzeniu · Otwórz profil</p></Link>}</li>;
}
export function PinnedPeople() {
  const { user } = useAuth(); const [paths, setPaths] = useState<string[]>([]);
  useEffect(() => { const timer = setTimeout(() => { try { const saved = JSON.parse(localStorage.getItem(`besafe.pinned.${user?.id}`) || '[]'); if (Array.isArray(saved)) setPaths(saved.filter((p): p is string => typeof p === 'string' && /^\/family\/[^/]+\/members\/[^/]+$/.test(p)).slice(0, 3)); } catch {} }, 0); return () => clearTimeout(timer); }, [user?.id]);
  return paths.length ? <section className="space-y-3"><h2 className="font-bold text-xl">Przypięte osoby</h2><ul className="grid sm:grid-cols-3 gap-3">{paths.map(path => <Person key={path} path={path} />)}</ul></section> : null;
}
