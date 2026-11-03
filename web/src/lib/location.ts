export type Point = { lat: number; lng: number };
export type Place = Point & { label: string; accuracy?: number; timestamp?: number };
export function isPoint(value: unknown): value is Point {
  if (!value || typeof value !== 'object') return false;
  const point = value as Point;
  return (
    Number.isFinite(point.lat) &&
    Number.isFinite(point.lng) &&
    Math.abs(point.lat) <= 90 &&
    Math.abs(point.lng) <= 180
  );
}
export function locate(): Promise<Place> {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation)
      return reject(
        new Error('Ta przeglądarka nie obsługuje lokalizacji. Wpisz adres lub wskaż miejsce.'),
      );
    navigator.geolocation.getCurrentPosition(
      (position) =>
        resolve({
          lat: position.coords.latitude,
          lng: position.coords.longitude,
          accuracy: position.coords.accuracy,
          timestamp: position.timestamp,
          label: 'Moja lokalizacja',
        }),
      () =>
        reject(
          new Error('Nie udało się odczytać lokalizacji. Wpisz adres lub wskaż miejsce na mapie.'),
        ),
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 60000 },
    );
  });
}
