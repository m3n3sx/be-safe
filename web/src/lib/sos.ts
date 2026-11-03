import api from './api';
import type { Alert } from '@/types';
import type { Point } from './location';
export function sendSos(place: Point) {
  return api.post<Alert>('/alerts', {
    category: 'aggression',
    title: '🆘 SOS — Potrzebuję pomocy!',
    description: 'Alarm SOS wysłany z be:Safe.',
    lat: place.lat,
    lng: place.lng,
    radius_m: 500,
  });
}
