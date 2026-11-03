'use client';
import { useParams } from 'next/navigation';
import { GroupOverview } from '@/components/family/GroupOverview';
export default function Page() { const { groupId } = useParams<{ groupId: string }>(); return <GroupOverview key={groupId} id={groupId} />; }
