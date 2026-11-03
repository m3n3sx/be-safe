'use client';
import { useParams } from 'next/navigation';
import { MemberProfile } from '@/components/family/MemberProfile';
export default function Page() { const { groupId, memberId } = useParams<{ groupId: string; memberId: string }>(); return <MemberProfile key={`${groupId}/${memberId}`} groupId={groupId} memberId={memberId} />; }
