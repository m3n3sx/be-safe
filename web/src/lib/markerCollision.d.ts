export function clusterItems(
  items: Array<{ id: string; lat: number; lng: number; kind: string; [key: string]: unknown }>,
  options?: {
    project?: (item: { lat: number; lng: number }) => { x: number; y: number };
    pixelThreshold?: number;
    metersThreshold?: number;
  },
): Array<{
  ids: string[];
  items: Array<{ id: string; lat: number; lng: number; kind: string; [key: string]: unknown }>;
  displayOnly: boolean;
  anchor: { lat: number; lng: number };
}>;
export function mercatorProject(
  center: { lat: number; lng: number },
  zoom: number,
  width: number,
  height: number,
): (item: { lat: number; lng: number }) => { x: number; y: number };
