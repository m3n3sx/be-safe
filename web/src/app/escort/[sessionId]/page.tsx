'use client';
import { useParams } from 'next/navigation';
import { EscortSession } from '@/components/safety/EscortSession';
export default function Page() { const { sessionId } = useParams<{ sessionId: string }>(); return <EscortSession key={sessionId} id={sessionId} />; }
