// Deno edge function: import trail assets (bridges, trailheads, etc.)
import { corsHeaders, jsonResponse } from '../_shared/cors.ts';

type LatLng = { lat: number; lng: number };

const ASSET_TYPES = [
  'bridge',
  'trailhead',
  'gate',
  'kiosk',
  'sign',
  'campsite',
  'picnic_area',
  'water_crossing',
  'boardwalk',
  'parking_lot',
  'toilet',
  'bench',
] as const;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const polygon = (body.polygon ?? []) as LatLng[];
    const trailId = body.trail_id as string | undefined;

    // Stub: return synthetic assets within bbox of polygon
    const assets = ASSET_TYPES.slice(0, 4).map((type, i) => {
      const anchor = polygon[0] ?? { lat: 45.37, lng: -121.7 };
      return {
        type,
        name: `${type} ${i + 1}`,
        trail_id: trailId ?? null,
        lat: anchor.lat + i * 0.002,
        lng: anchor.lng + i * 0.002,
        source: 'osm',
      };
    });

    return jsonResponse({ ok: true, assets, count: assets.length });
  } catch (error) {
    return jsonResponse(
      { ok: false, error: String(error) },
      400,
    );
  }
});
