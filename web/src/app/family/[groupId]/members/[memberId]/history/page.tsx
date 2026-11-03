'use client';
import { useParams } from 'next/navigation';
import { LocationHistory } from '@/components/family/LocationHistory';
export default function Page() {
  const { groupId, memberId } = useParams<{ groupId: string; memberId: string }>();
  return <LocationHistory key={`${groupId}/${memberId}`} groupId={groupId} memberId={memberId} />;
}
