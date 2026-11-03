import api from '@/lib/api';
import type { Alert, AlertComment, VoteType } from '@/types';
import type { Point } from '@/lib/location';
export const alertsApi = {
  nearby: (point: Point, radius: number) => api.get<{ alerts: Alert[] }>(`/alerts/nearby?${new URLSearchParams({ lat: String(point.lat), lng: String(point.lng), radius_m: String(radius) })}`),
  detail: (id: string) => api.get<Alert>(`/alerts/${encodeURIComponent(id)}`),
  mine: () => api.get<{ alerts: Alert[] }>('/alerts/mine'),
  create: (data: FormData) => api.multipart<Alert>('/alerts', data),
  vote: (id: string, vote: VoteType) => api.post<Pick<Alert, 'confirms' | 'denies' | 'trust_score' | 'author_id'>>(`/alerts/${encodeURIComponent(id)}/vote`, { vote }),
  comments: (id: string) => api.get<{ comments: AlertComment[] }>(`/alerts/${encodeURIComponent(id)}/comments`),
  comment: (id: string, content: string) => api.post<AlertComment>(`/alerts/${encodeURIComponent(id)}/comments`, { content }),
  report: (id: string, reason: string) => api.post<{ ok: boolean }>(`/alerts/${encodeURIComponent(id)}/report`, { reason }),
  update: (id: string, data: { description?: string; extend_hours?: number }) => api.patch<Alert>(`/alerts/${encodeURIComponent(id)}`, data),
  remove: (id: string) => api.delete<{ ok: boolean }>(`/alerts/${encodeURIComponent(id)}`),
};
