'use client';
import { useParams } from 'next/navigation';
import { FamilyPlanner } from '@/components/family/FamilyPlanner';
export default function Page() { const { groupId } = useParams<{ groupId: string }>(); return <FamilyPlanner key={groupId} groupId={groupId} />; }
