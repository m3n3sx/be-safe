// Grupowanie markerów na ekranie. Nie zmienia współrzędnych elementów.
// Kotwica grupy jest tylko do narysowania odznaki z licznikiem.

const KIND_ORDER = { sos: 0, hazard: 1, member: 2, aed: 3 };

function haversineMeters(a, b) {
  const r = 6371000;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const lat1 = (a.lat * Math.PI) / 180;
  const lat2 = (b.lat * Math.PI) / 180;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * r * Math.asin(Math.min(1, Math.sqrt(h)));
}

function samePoint(a, b) {
  return Math.abs(a.lat - b.lat) < 1e-5 && Math.abs(a.lng - b.lng) < 1e-5;
}

function clusterItems(items, { project, pixelThreshold = 48, metersThreshold = 15 } = {}) {
  const list = items.map((item) => ({ ...item }));
  const parent = list.map((_, index) => index);
  const find = (index) => (parent[index] === index ? index : (parent[index] = find(parent[index])));
  const unite = (a, b) => {
    parent[find(a)] = find(b);
  };
  const toPoint = project || ((item) => ({ x: item.lng, y: item.lat }));
  for (let i = 0; i < list.length; i += 1) {
    for (let j = i + 1; j < list.length; j += 1) {
      const left = toPoint(list[i]);
      const right = toPoint(list[j]);
      const dx = left.x - right.x;
      const dy = left.y - right.y;
      const closePixels = Math.sqrt(dx * dx + dy * dy) < pixelThreshold;
      const closeMeters = metersThreshold > 0 && haversineMeters(list[i], list[j]) < metersThreshold;
      if (samePoint(list[i], list[j]) || closeMeters || closePixels) unite(i, j);
    }
  }
  const buckets = new Map();
  list.forEach((item, index) => {
    const root = find(index);
    if (!buckets.has(root)) buckets.set(root, []);
    buckets.get(root).push(item);
  });
  return [...buckets.values()].map((bucket) => {
    const itemsSorted = bucket.slice().sort((a, b) => {
      const byKind = (KIND_ORDER[a.kind] ?? 9) - (KIND_ORDER[b.kind] ?? 9);
      if (byKind) return byKind;
      return String(a.id).localeCompare(String(b.id));
    });
    const identical = itemsSorted.every((item) => samePoint(item, itemsSorted[0]));
    const lat = identical
      ? itemsSorted[0].lat
      : itemsSorted.reduce((sum, item) => sum + item.lat, 0) / itemsSorted.length;
    const lng = identical
      ? itemsSorted[0].lng
      : itemsSorted.reduce((sum, item) => sum + item.lng, 0) / itemsSorted.length;
    return {
      ids: itemsSorted.map((item) => item.id),
      items: itemsSorted,
      displayOnly: itemsSorted.length > 1,
      anchor: { lat, lng },
    };
  });
}

function mercatorProject(center, zoom, width, height) {
  const scale = 256 * 2 ** zoom;
  const xOf = (lng) => ((lng + 180) / 360) * scale;
  const yOf = (lat) => {
    const clamped = Math.max(-85, Math.min(85, lat));
    const s = Math.sin((clamped * Math.PI) / 180);
    return (0.5 - Math.log((1 + s) / (1 - s)) / (4 * Math.PI)) * scale;
  };
  const cx = xOf(center.lng);
  const cy = yOf(center.lat);
  return (item) => ({
    x: xOf(item.lng) - cx + width / 2,
    y: yOf(item.lat) - cy + height / 2,
  });
}

module.exports = { clusterItems, haversineMeters, mercatorProject };
