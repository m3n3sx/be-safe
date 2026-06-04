// ============ ALERT TYPES ============

export type AlertCategory =
  | 'aggression' | 'theft' | 'accident' | 'fire' | 'flood'
  | 'ice' | 'construction' | 'animal' | 'dark_area' | 'drugs'
  | 'police' | 'weather' | 'other' | 'stranger_danger'
  | 'traffic_danger' | 'playground_hazard' | 'water_hazard' | 'school_zone'
  | 'pothole' | 'dark_passage' | 'broken_lights';

export type AlertStatus = 'active' | 'expired' | 'hidden' | 'removed';
export type VoteType = 'confirm' | 'deny';
export type FamilyRole = 'parent' | 'child';

export interface AlertCategoryInfo {
  key: AlertCategory;
  label: string;
  labelEn: string;
  emoji: string;
  color: string;
  /** Material Symbols outlined name (e.g. 'person_alert'). */
  materialSymbol: string;
}

export const ALERT_CATEGORIES: AlertCategoryInfo[] = [
  { key: 'aggression', label: 'Agresywne osoby', labelEn: 'Aggressive people', emoji: '🤬', color: '#FF1744', materialSymbol: 'person_alert' },
  { key: 'theft', label: 'Kradzież / rozbój', labelEn: 'Theft / robbery', emoji: '🔪', color: '#FF1744', materialSymbol: 'wallet' },
  { key: 'accident', label: 'Wypadek', labelEn: 'Accident', emoji: '💥', color: '#FF6D00', materialSymbol: 'car_crash' },
  { key: 'fire', label: 'Pożar', labelEn: 'Fire', emoji: '🔥', color: '#FF3D00', materialSymbol: 'local_fire_department' },
  { key: 'flood', label: 'Powódź', labelEn: 'Flood', emoji: '🌊', color: '#2979FF', materialSymbol: 'waves' },
  { key: 'ice', label: 'Oblodzenie', labelEn: 'Ice', emoji: '❄️', color: '#00B0FF', materialSymbol: 'severe_cold' },
  { key: 'construction', label: 'Niebezpieczna budowa', labelEn: 'Dangerous construction', emoji: '⛏️', color: '#FFAB00', materialSymbol: 'warning' },
  { key: 'animal', label: 'Niebezpieczne zwierzę', labelEn: 'Dangerous animal', emoji: '🐺', color: '#FF6D00', materialSymbol: 'pets' },
  { key: 'dark_area', label: 'Nieoświetlony teren', labelEn: 'Dark area', emoji: '🌑', color: '#78909C', materialSymbol: 'dark_mode' },
  { key: 'drugs', label: 'Narkotyki', labelEn: 'Drugs', emoji: '💉', color: '#AA00FF', materialSymbol: 'vaccines' },
  { key: 'police', label: 'Akcja policyjna', labelEn: 'Police action', emoji: '🚨', color: '#2979FF', materialSymbol: 'local_police' },
  { key: 'weather', label: 'Zagrożenie pogodowe', labelEn: 'Weather danger', emoji: '⛈️', color: '#1565C0', materialSymbol: 'thunderstorm' },
  { key: 'other', label: 'Inne', labelEn: 'Other', emoji: '⚠️', color: '#FFAB00', materialSymbol: 'more_horiz' },
  { key: 'stranger_danger', label: 'Podejrzana osoba', labelEn: 'Stranger danger', emoji: '😈', color: '#FF1744', materialSymbol: 'visibility' },
  { key: 'traffic_danger', label: 'Niebezpieczne przejście', labelEn: 'Traffic danger', emoji: '☠️', color: '#FF6D00', materialSymbol: 'traffic' },
  { key: 'playground_hazard', label: 'Uszkodzony plac zabaw', labelEn: 'Playground hazard', emoji: '⛔', color: '#FFAB00', materialSymbol: 'child_friendly' },
  { key: 'water_hazard', label: 'Zbiornik wodny', labelEn: 'Water hazard', emoji: '🌀', color: '#2979FF', materialSymbol: 'water' },
  { key: 'school_zone', label: 'Strefa szkolna', labelEn: 'School zone', emoji: '🚸', color: '#FF6D00', materialSymbol: 'school' },
  { key: 'pothole', label: 'Dziura w drodze', labelEn: 'Pothole', emoji: '🕳️', color: '#FFAB00', materialSymbol: 'dangerous' },
  { key: 'dark_passage', label: 'Ciemny zaułek / przejście', labelEn: 'Dark passage', emoji: '🌃', color: '#78909C', materialSymbol: 'nightlight' },
  { key: 'broken_lights', label: 'Niesprawne oświetlenie', labelEn: 'Broken lights', emoji: '💡', color: '#FFAB00', materialSymbol: 'lightbulb' },
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
  app_mode?: 'kids' | 'senior' | 'normal' | string | null;
  phone?: string | null;
  is_kpp?: boolean;
  email_verified?: boolean;
  referral_code?: string | null;
  is_admin?: boolean;
  is_banned?: boolean;
  banned_at?: string | null;
  ban_reason?: string | null;
  is_verified?: boolean;
  verified_role?: string | null;
  created_at?: string;
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
  trust_score?: number;
  is_anonymous?: boolean;
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
  last_lat?: number;
  last_lng?: number;
  last_location_at?: string;
  last_seen_at?: string;
  last_battery_level?: number | null;
  avatar_url?: string | null;
  phone?: string | null;
  app_mode?: string | null;
  school_hours_silent?: boolean;
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
