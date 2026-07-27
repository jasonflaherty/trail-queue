import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  errorResponse,
  handleOptions,
  jsonResponse,
} from "../_shared/cors.ts";

type LatLng = { lat: number; lng: number };

type ImportRequest = {
  source: string;
  polygon: LatLng[];
};

type NormalizedTrail = {
  name: string;
  agency?: string;
  length_miles?: number;
  surface?: string;
  trail_number?: string;
  source: string;
  geom_wkt: string;
  external_id?: string;
};

const OVERPASS_URL = "https://overpass-api.de/api/interpreter";

function polygonToOverpass(poly: LatLng[]): string {
  const ring = poly.map((p) => `${p.lat} ${p.lng}`).join(" ");
  const closed = poly.length > 0 &&
      (poly[0].lat !== poly[poly.length - 1].lat ||
        poly[0].lng !== poly[poly.length - 1].lng)
    ? `${ring} ${poly[0].lat} ${poly[0].lng}`
    : ring;
  return `(poly:"${closed}")`;
}

function lineToWkt(coords: number[][]): string {
  const pairs = coords.map(([lng, lat]) => `${lng} ${lat}`).join(", ");
  return `LINESTRING(${pairs})`;
}

function haversineMiles(a: LatLng, b: LatLng): number {
  const R = 3958.8;
  const dLat = (b.lat - a.lat) * Math.PI / 180;
  const dLng = (b.lng - a.lng) * Math.PI / 180;
  const lat1 = a.lat * Math.PI / 180;
  const lat2 = b.lat * Math.PI / 180;
  const h = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

function estimateLengthMiles(coords: number[][]): number {
  let total = 0;
  for (let i = 1; i < coords.length; i++) {
    total += haversineMiles(
      { lat: coords[i - 1][1], lng: coords[i - 1][0] },
      { lat: coords[i][1], lng: coords[i][0] },
    );
  }
  return Math.round(total * 100) / 100;
}

async function fetchOsmTrails(polygon: LatLng[]): Promise<NormalizedTrail[]> {
  if (polygon.length < 3) {
    throw new Error("polygon must contain at least 3 points");
  }

  const poly = polygonToOverpass(polygon);
  const query = `
    [out:json][timeout:60];
    (
      way["highway"~"^(path|footway|cycleway|bridleway)$"]${poly};
    );
    out body;
    >;
    out skel qt;
  `;

  const res = await fetch(OVERPASS_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `data=${encodeURIComponent(query)}`,
  });

  if (!res.ok) {
    throw new Error(`Overpass API error: ${res.status}`);
  }

  const data = await res.json();
  const nodes = new Map<number, [number, number]>();
  const ways: Array<{ id: number; tags?: Record<string, string>; nodes: number[] }> = [];

  for (const el of data.elements ?? []) {
    if (el.type === "node") {
      nodes.set(el.id, [el.lon, el.lat]);
    } else if (el.type === "way") {
      ways.push(el);
    }
  }

  const trails: NormalizedTrail[] = [];
  for (const way of ways) {
    const coords = way.nodes
      .map((id) => nodes.get(id))
      .filter((c): c is [number, number] => c !== undefined);
    if (coords.length < 2) continue;

    const name = way.tags?.name ?? `OSM Way ${way.id}`;
    trails.push({
      name,
      agency: way.tags?.operator ?? way.tags?.brand,
      surface: way.tags?.surface,
      trail_number: way.tags?.ref,
      source: "osm",
      geom_wkt: lineToWkt(coords),
      external_id: String(way.id),
      length_miles: estimateLengthMiles(coords),
    });
  }

  return trails;
}

function stubTrails(source: string, polygon: LatLng[]): NormalizedTrail[] {
  const center = polygon.reduce(
    (acc, p) => ({ lat: acc.lat + p.lat, lng: acc.lng + p.lng }),
    { lat: 0, lng: 0 },
  );
  center.lat /= polygon.length;
  center.lng /= polygon.length;

  const offset = 0.01;
  const coords: number[][] = [
    [center.lng - offset, center.lat - offset],
    [center.lng, center.lat],
    [center.lng + offset, center.lat + offset],
  ];

  const agencyMap: Record<string, string> = {
    usfs: "US Forest Service",
    nps: "National Park Service",
    blm: "Bureau of Land Management",
    oregon: "Oregon GIS",
    washington: "Washington GIS",
    california: "California GIS",
    idaho: "Idaho GIS",
    colorado: "Colorado GIS",
  };

  return [{
    name: `${agencyMap[source] ?? source.toUpperCase()} Demo Trail`,
    agency: agencyMap[source],
    source,
    geom_wkt: lineToWkt(coords),
    length_miles: estimateLengthMiles(coords),
    surface: "dirt",
  }];
}

async function upsertTrails(
  supabase: ReturnType<typeof createClient>,
  trails: NormalizedTrail[],
): Promise<number> {
  let count = 0;

  for (const trail of trails) {
    const { error } = await supabase.rpc("insert_trail_from_wkt", {
      p_name: trail.name,
      p_agency: trail.agency ?? null,
      p_length_miles: trail.length_miles ?? null,
      p_surface: trail.surface ?? null,
      p_trail_number: trail.trail_number ?? null,
      p_source: trail.source,
      p_geom_wkt: trail.geom_wkt,
    });

    if (error) {
      console.error("Trail insert failed:", error.message, trail.name);
      continue;
    }

    count++;
  }

  return count;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return handleOptions();

  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  try {
    const body = (await req.json()) as ImportRequest;
    const { source, polygon } = body;

    if (!source || !Array.isArray(polygon) || polygon.length < 3) {
      return errorResponse("Expected { source, polygon: [{lat,lng}, ...] }");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceKey);

    let trails: NormalizedTrail[];

    switch (source) {
      case "osm":
        trails = await fetchOsmTrails(polygon);
        break;
      case "usfs":
      case "nps":
      case "blm":
      case "oregon":
      case "washington":
      case "california":
      case "idaho":
      case "colorado":
        trails = stubTrails(source, polygon);
        break;
      default:
        return errorResponse(`Unsupported source: ${source}`);
    }

    const { data: job, error: jobError } = await supabase
      .from("import_jobs")
      .insert({ source, status: "running", polygon })
      .select("id")
      .single();

    if (jobError) {
      return errorResponse(jobError.message, 500);
    }

    const trailCount = await upsertTrails(supabase, trails);

    await supabase
      .from("import_jobs")
      .update({
        status: "completed",
        trail_count: trailCount,
        completed_at: new Date().toISOString(),
      })
      .eq("id", job.id);

    return jsonResponse({
      job_id: job.id,
      source,
      trail_count: trailCount,
      trails: trails.map((t) => ({ name: t.name, source: t.source })),
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Import failed";
    return errorResponse(message, 500);
  }
});
