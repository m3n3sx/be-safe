export type Pet = {
  id: string; group_id: string; owner_id: string; name: string; species: string; breed?: string | null; color?: string | null;
  age_years?: number | null; microchip?: string | null; photo_url?: string | null; notes?: string | null;
  status: 'home' | 'lost'; lost_at?: string | null; lost_description?: string | null;
  home_lat?: number | null; home_lng?: number | null; last_seen_lat?: number | null; last_seen_lng?: number | null; last_seen_at?: string | null;
  owner_username?: string; group_name?: string; distance_m?: number;
};
export const speciesLabels: Record<string, string> = { dog: 'Pies', cat: 'Kot', bird: 'Ptak', rabbit: 'Królik', other: 'Inne zwierzę' };
