'use client';
import { useParams } from 'next/navigation';
import { SafeRoutes } from '@/components/family/SafeRoutes';
export default function Page() { const params = useParams<{ groupId: string; memberId: string; routeId: string }>(); return <SafeRoutes {...params} />; }
