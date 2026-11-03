export const GOOGLE_MAPS_API_KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY || '';
export const SOCKET_URL = process.env.NEXT_PUBLIC_SOCKET_URL || 'https://besafe.org.pl';
export const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'https://besafe.org.pl/api/v1';
// A browsing starting point only; never a substitute for a user's location.
export const DEFAULT_CENTER = { lat: 52.2297, lng: 21.0122 };
export const DEFAULT_ZOOM = 13;
export const DURATION_OPTIONS = [1, 3, 6, 12, 24].map((value) => ({
  value,
  label: `${value} godz.`,
}));
export const LIGHT_MAP_STYLES: google.maps.MapTypeStyle[] = [];
export const DARK_MAP_STYLES: google.maps.MapTypeStyle[] = [
  { elementType: 'geometry', stylers: [{ color: '#192530' }] },
  { elementType: 'labels.text.fill', stylers: [{ color: '#b9c8d4' }] },
  { elementType: 'labels.text.stroke', stylers: [{ color: '#101820' }] },
  { featureType: 'road', elementType: 'geometry', stylers: [{ color: '#415361' }] },
  { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#102f48' }] },
  { featureType: 'poi.park', elementType: 'geometry', stylers: [{ color: '#204237' }] },
];
