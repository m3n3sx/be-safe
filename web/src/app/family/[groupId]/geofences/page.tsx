'use client';
import { useParams } from 'next/navigation';
import { GeofenceEditor } from '@/components/family/GeofenceEditor';
export default function Page() { const { groupId } = useParams<{ groupId: string }>(); return <GeofenceEditor key={groupId} groupId={groupId} />; }
