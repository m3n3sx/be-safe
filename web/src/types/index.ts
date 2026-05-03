// ============ ALERT TYPES ============

export type AlertCategory =
  | 'aggression' | 'theft' | 'accident' | 'fire' | 'flood'
  | 'ice' | 'construction' | 'animal' | 'dark_area' | 'drugs'
  | 'police' | 'weather' | 'other' | 'stranger_danger'
  | 'traffic_danger' | 'playground_hazard' | 'water_hazard' | 'school_zone';

export type AlertStatus = 'active' | 'expired' | 'hidden' | 'removed';
export type VoteType = 'confirm' | 'deny';
export type FamilyRole = 'parent' | 'child';

export interface AlertCategoryInfo {
  key: AlertCategory;
  label: string;
  labelEn: string;
  emoji: string;
  color: string;
}

export const ALERT_CATEGORIES: AlertCategoryInfo[] = [
  { key: 'aggression', label: 'Agresywne osoby', labelEn: 'Aggressive people', emoji: '🤬', color: '#FF1744' },
  { key: 'theft', label: 'Kradzież / rozbój', labelEn: 'Theft / robbery', emoji: '🔪', color: '#FF1744' },
  { key: 'accident', label: 'Wypadek', labelEn: 'Accident', emoji: '💥', color: '#FF6D00' },
  { key: 'fire', label: 'Pożar', labelEn: 'Fire', emoji: '🔥', color: '#FF3D00' },
  { key: 'flood', label: 'Powódź', labelEn: 'Flood', emoji: '🌊', color: '#2979FF' },
  { key: 'ice', label: 'Oblodzenie', labelEn: 'Ice', emoji: '❄️', color: '#00B0FF' },
  { key: 'construction', label: 'Niebezpieczna budowa', labelEn: 'Dangerous construction', emoji: '⛏️', color: '#FFAB00' },
  { key: 'animal', label: 'Niebezpieczne zwierzę', labelEn: 'Dangerous animal', emoji: '🐺', color: '#FF6D00' },
  { key: 'dark_area', label: 'Nieoświetlony teren', labelEn: 'Dark area', emoji: '🌑', color: '#78909C' },
  { key: 'drugs', label: 'Narkotyki', labelEn: 'Drugs', emoji: '💉', color: '#AA00FF' },
  { key: 'police', label: 'Akcja policyjna', labelEn: 'Police action', emoji: '🚨', color: '#2979FF' },
  { key: 'weather', label: 'Zagrożenie pogodowe', labelEn: 'Weather danger', emoji: '⛈️', color: '#1565C0' },
  { key: 'other', label: 'Inne', labelEn: 'Other', emoji: '⚠️', color: '#FFAB00' },
  { key: 'stranger_danger', label: 'Podejrzana osoba', labelEn: 'Stranger danger', emoji: '😈', color: '#FF1744' },
  { key: 'traffic_danger', label: 'Niebezpieczne przejście', labelEn: 'Traffic danger', emoji: '☠️', color: '#FF6D00' },
  { key: 'playground_hazard', label: 'Uszkodzony plac zabaw', labelEn: 'Playground hazard', emoji: '⛔', color: '#FFAB00' },
  { key: 'water_hazard', label: 'Zbiornik wodny', labelEn: 'Water hazard', emoji: '🌀', color: '#2979FF' },
  { key: 'school_zone', label: 'Strefa szkolna', labelEn: 'School zone', emoji: '🚸', color: '#FF6D00' },
];

export function getCategoryInfo(cat: AlertCategory): AlertCategoryInfo {
  return ALERT_CATEGORIES.find(c => c.key === cat) || ALERT_CATEGORIES[12]; // fallback: 'other'
}

// ============ MODELS ============

export interface User {
  id: string;
  email: string;
  username: string;
  avatar_url?: string;
  alert_radius_m: number;
  reputation_score: number;
  is_child: boolean;
}

export interface Alert {
  id: string;
  author_id: string;
  category: AlertCategory;
  title: string;
  description?: string;
  photo_url?: string;
  lat: number;
  lng: number;
  radius_m: number;
  status: AlertStatus;
  confirms: number;
  denies: number;
  distance_m?: number;
  expires_at: string;
  created_at: string;
  author_username?: string;
}

export interface AlertComment {
  id: string;
  alert_id: string;
  user_id: string;
  content: string;
  created_at: string;
  username?: string;
}

export interface FamilyGroup {
  id: string;
  name: string;
  owner_id: string;
  invite_code: string;
  created_at: string;
  role?: FamilyRole;
}

export interface FamilyMember {
  id: string;
  user_id: string;
  username: string;
  role: FamilyRole;
  tracking_enabled: boolean;
  lat?: number;
  lng?: number;
  last_location_at?: string;
}

export interface Geofence {
  id: string;
  group_id: string;
  name: string;
  lat: number;
  lng: number;
  radius_m: number;
  is_active: boolean;
}

export interface AlertStats {
  today: number;
  week: number;
  total: number;
  top_categories: { category: AlertCategory; count: number }[];
  trend: { date: string; count: number }[];
}

export interface RankingUser {
  id: string;
  username: string;
  avatar_url?: string;
  alert_count: number;
  total_confirms: number;
  reputation_score: number;
}

export interface LocationHistory {
  lat: number;
  lng: number;
  recorded_at: string;
}
