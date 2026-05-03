export const GOOGLE_MAPS_API_KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY || 'AIzaSyCRg3frfmPXG6caSjel2c_nFbkb8bMIqYU';
export const SOCKET_URL = process.env.NEXT_PUBLIC_SOCKET_URL || 'https://alert.u235.pl';
export const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'https://alert.u235.pl/api/v1';

export const DEFAULT_CENTER = { lat: 52.2297, lng: 21.0122 }; // Warsaw
export const DEFAULT_ZOOM = 13;

export const DURATION_OPTIONS = [
  { value: 1, label: '1h' },
  { value: 3, label: '3h' },
  { value: 6, label: '6h' },
  { value: 12, label: '12h' },
  { value: 24, label: '24h' },
];

export const DARK_MAP_STYLES: google.maps.MapTypeStyle[] = [
  { elementType: 'geometry', stylers: [{ color: '#212121' }] },
  { elementType: 'labels.text.stroke', stylers: [{ color: '#212121' }] },
  { elementType: 'labels.text.fill', stylers: [{ color: '#757575' }] },
  { featureType: 'road', elementType: 'geometry', stylers: [{ color: '#2c2c2c' }] },
  { featureType: 'road', elementType: 'geometry.stroke', stylers: [{ color: '#212121' }] },
  { featureType: 'road.highway', elementType: 'geometry', stylers: [{ color: '#3c3c3c' }] },
  { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#000000' }] },
  { featureType: 'water', elementType: 'labels.text.fill', stylers: [{ color: '#3d3d3d' }] },
  { featureType: 'poi.business', stylers: [{ visibility: 'off' }] },
  { featureType: 'transit', elementType: 'labels.icon', stylers: [{ visibility: 'off' }] },
];

export const LIGHT_MAP_STYLES: google.maps.MapTypeStyle[] = [
  { featureType: 'poi.business', stylers: [{ visibility: 'off' }] },
  { featureType: 'poi', elementType: 'labels.icon', stylers: [{ saturation: -100 }] },
  { featureType: 'transit', elementType: 'labels.icon', stylers: [{ saturation: -100 }] },
];
