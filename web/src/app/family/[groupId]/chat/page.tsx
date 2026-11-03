'use client';
import { useParams } from 'next/navigation';
import { groupPath, useGroup } from '@/lib/api/family';
import { GroupHeader } from '@/components/family/GroupHeader';
import { Chat } from '@/components/community/Chat';
import { ErrorState } from '@/components/ui/ErrorState';
export default function Page() {
  const { groupId } = useParams<{ groupId: string }>();
  const group = useGroup(groupId);
  return (
    <div className="page-container">
      <GroupHeader id={groupId} title="Czat grupy" name={group.group?.name} />
      {group.error && <ErrorState message={group.error} onRetry={group.reload} />}
      <Chat key={groupId} path={`${groupPath(groupId)}/messages`} groupId={groupId} />
    </div>
  );
}
