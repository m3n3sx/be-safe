import type { FamilyRole, FamilyMember } from '@/types';
import { useApiResource } from '@/hooks/useApiResource';
import type { FamilyGroup } from '@/types';
import { useAuth } from '@/contexts/AuthContext';
export const roleLabels: Record<FamilyRole, string> = { parent: 'Rodzic', child: 'Dziecko', senior: 'Senior', guardian: 'Opiekun', family_member: 'Członek rodziny', partner: 'Partner / partnerka', friend: 'Znajomy', other: 'Inna osoba' };
export const groupPath = (id: string) => `/family/groups/${encodeURIComponent(id)}`;
export function memberPlace(member: FamilyMember) { return member.lat != null && member.lng != null ? { id: member.user_id, lat: Number(member.lat), lng: Number(member.lng), label: `${member.username} — ostatnia znana pozycja` } : null; }
export function useGroup(id: string) { const { user } = useAuth(); const resource = useApiResource<{ groups: FamilyGroup[] }>('/family/groups'); const group = resource.data?.groups.find(g => g.id === id); return { ...resource, group, owner: !!group && group.owner_id === user?.id, guardian: group?.your_role === 'parent' || group?.your_role === 'guardian' }; }
