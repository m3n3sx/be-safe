export function distance(meters?: number) {
  if (meters === undefined || !Number.isFinite(Number(meters))) return 'Odległość nieznana';
  return meters < 1000 ? `${Math.round(meters)} m` : `${(meters / 1000).toLocaleString('pl-PL', { maximumFractionDigits: 1 })} km`;
}
export function relativeTime(iso: string) {
  const seconds = (new Date(iso).getTime() - Date.now()) / 1000;
  if (!Number.isFinite(seconds)) return 'Czas nieznany';
  const format = new Intl.RelativeTimeFormat('pl', { numeric: 'auto' });
  if (Math.abs(seconds) < 60) return 'przed chwilą';
  if (Math.abs(seconds) < 3600) return format.format(Math.round(seconds / 60), 'minute');
  if (Math.abs(seconds) < 86400) return format.format(Math.round(seconds / 3600), 'hour');
  return format.format(Math.round(seconds / 86400), 'day');
}
