export type InboxItem = { id: string; type: string; title: string; body: string; created_at: string; is_read: boolean; data?: Record<string, unknown> };
export function notificationHref(item: Pick<InboxItem, 'type' | 'data'>): string | null {
  const d = item.data || {}; const id = (key: string) => typeof d[key] === 'string' && d[key] ? encodeURIComponent(d[key] as string) : '';
  const group = id('group_id'), member = id('child_id') || id('user_id') || id('from_user_id');
  if (id('ping_id')) return `/family/pings/${id('ping_id')}`;
  if (id('escort_id')) return `/escort/${id('escort_id')}`;
  if (item.type === 'family_sos' && group && id('alert_id')) return `/family/${group}/sos/${id('alert_id')}`;
  if (id('alert_id')) return `/alerts/${id('alert_id')}`;
  if (item.type === 'family_message' && group) return `/family/${group}/chat`;
  if (item.type === 'family_event_reminder' && group) return `/family/${group}/planner${id('event_id') ? `#event-${id('event_id')}` : ''}`;
  if (id('route_id') && group && member) return `/family/${group}/members/${member}/safe-routes/${id('route_id')}`;
  if (item.type.startsWith('pet_')) {
    const query = new URLSearchParams();
    if (item.type === 'pet_lost_nearby') { query.set('view', 'lost'); if (Number.isFinite(Number(d.lat)) && Number.isFinite(Number(d.lng))) { query.set('lat', String(d.lat)); query.set('lng', String(d.lng)); } }
    return `/pets?${query}${id('pet_id') ? `#pet-${id('pet_id')}` : ''}`;
  }
  if (group && member) return `/family/${group}/members/${member}`;
  if (group) return `/family/${group}`;
  if (item.type.includes('checkin') || item.type.startsWith('family_') || item.type === 'child_low_battery') return '/family';
  return null;
}
