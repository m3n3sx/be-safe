export const GOOGLE_MAPS_API_KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY || 'AIzaSyCuEqShVm8H-_7rxLy6uLTq4xUbCxFg7UI';
export const SOCKET_URL = process.env.NEXT_PUBLIC_SOCKET_URL || 'https://besafe.org.pl';
export const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'https://besafe.org.pl/api/v1';

export const DEFAULT_CENTER = { lat: 52.2297, lng: 21.0122 }; // Warsaw
export const DEFAULT_ZOOM = 13;

export const DURATION_OPTIONS = [
  { value: 1, label: '1h' },
  { value: 3, label: '3h' },
  { value: 6, label: '6h' },
  { value: 12, label: '12h' },
  { value: 24, label: '24h' },
];

/**
 * Monochrome map styles tuned to the Serenity Guard design system.
 *
 * Goals:
 *  - Strip all colour saturation so coral / mint / navy markers pop.
 *  - Light mode = warm-tinted neutral greys against the `#fcf8f9` app surface.
 *  - Dark  mode = navy-tinted neutral greys against the `#1a2027` app surface.
 *  - Hide commercial POI and transit icons; keep landscape, water and roads.
 */

export const LIGHT_MAP_STYLES: google.maps.MapTypeStyle[] = [
  // Global desaturation
  { elementType: 'geometry', stylers: [{ color: '#e6e6ea' }, { saturation: -100 }] },
  { elementType: 'labels.text.fill', stylers: [{ color: '#5e5e66' }] },
  { elementType: 'labels.text.stroke', stylers: [{ color: '#fcf8f9' }, { weight: 3 }] },
  { elementType: 'labels.icon', stylers: [{ visibility: 'off' }] },

  // Land / landscape
  { featureType: 'landscape', elementType: 'geometry', stylers: [{ color: '#dcdce0' }, { saturation: -100 }] },
  { featureType: 'landscape.natural', elementType: 'geometry', stylers: [{ color: '#d6d6da' }] },

  // Roads
  { featureType: 'road', elementType: 'geometry', stylers: [{ color: '#ffffff' }] },
  { featureType: 'road', elementType: 'geometry.stroke', stylers: [{ color: '#cfcfd4' }] },
  { featureType: 'road.highway', elementType: 'geometry', stylers: [{ color: '#f0f0f3' }] },
  { featureType: 'road.highway', elementType: 'geometry.stroke', stylers: [{ color: '#c5c6cb' }] },
  { featureType: 'road.arterial', elementType: 'geometry', stylers: [{ color: '#fafafc' }] },

  // Water
  { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#c4c4cc' }, { saturation: -100 }] },
  { featureType: 'water', elementType: 'labels.text.fill', stylers: [{ color: '#7a7a80' }] },

  // POI / parks
  { featureType: 'poi', elementType: 'geometry', stylers: [{ color: '#d1d1d5' }, { saturation: -100 }] },
  { featureType: 'poi.park', elementType: 'geometry', stylers: [{ color: '#cfd4d2' }] },
  { featureType: 'poi.business', stylers: [{ visibility: 'off' }] },
  { featureType: 'poi.medical', stylers: [{ visibility: 'off' }] },
  { featureType: 'poi.attraction', stylers: [{ visibility: 'off' }] },

  // Transit
  { featureType: 'transit', stylers: [{ visibility: 'off' }] },

  // Administrative
  { featureType: 'administrative', elementType: 'geometry.stroke', stylers: [{ color: '#b6b6bc' }] },
  { featureType: 'administrative.land_parcel', stylers: [{ visibility: 'off' }] },
];

export const DARK_MAP_STYLES: google.maps.MapTypeStyle[] = [
  // Global desaturation
  { elementType: 'geometry', stylers: [{ color: '#232a32' }, { saturation: -100 }] },
  { elementType: 'labels.text.fill', stylers: [{ color: '#9ea1a8' }] },
  { elementType: 'labels.text.stroke', stylers: [{ color: '#1a2027' }, { weight: 3 }] },
  { elementType: 'labels.icon', stylers: [{ visibility: 'off' }] },

  // Land / landscape
  { featureType: 'landscape', elementType: 'geometry', stylers: [{ color: '#1f262d' }, { saturation: -100 }] },
  { featureType: 'landscape.natural', elementType: 'geometry', stylers: [{ color: '#222931' }] },

  // Roads
  { featureType: 'road', elementType: 'geometry', stylers: [{ color: '#2c343d' }] },
  { featureType: 'road', elementType: 'geometry.stroke', stylers: [{ color: '#1a2027' }] },
  { featureType: 'road.highway', elementType: 'geometry', stylers: [{ color: '#3b454f' }] },
  { featureType: 'road.highway', elementType: 'geometry.stroke', stylers: [{ color: '#1a2027' }] },
  { featureType: 'road.arterial', elementType: 'geometry', stylers: [{ color: '#303841' }] },

  // Water
  { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#11171c' }, { saturation: -100 }] },
  { featureType: 'water', elementType: 'labels.text.fill', stylers: [{ color: '#4a525a' }] },

  // POI / parks
  { featureType: 'poi', elementType: 'geometry', stylers: [{ color: '#1c232a' }, { saturation: -100 }] },
  { featureType: 'poi.park', elementType: 'geometry', stylers: [{ color: '#1d262b' }] },
  { featureType: 'poi.business', stylers: [{ visibility: 'off' }] },
  { featureType: 'poi.medical', stylers: [{ visibility: 'off' }] },
  { featureType: 'poi.attraction', stylers: [{ visibility: 'off' }] },

  // Transit
  { featureType: 'transit', stylers: [{ visibility: 'off' }] },

  // Administrative
  { featureType: 'administrative', elementType: 'geometry.stroke', stylers: [{ color: '#3a424c' }] },
  { featureType: 'administrative.land_parcel', stylers: [{ visibility: 'off' }] },
];
