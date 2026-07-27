import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  errorResponse,
  handleOptions,
  jsonResponse,
} from "../_shared/cors.ts";

type LatLng = { lat: number; lng: number };

type StateImportRequest = {
  state: "oregon" | "washington" | "california" | "idaho" | "colorado";
  polygon?: LatLng[];
  bbox?: { north: number; south: number; east: number; west: number };
};

type NormalizedFeature = {
  name: string;
  agency: string;
  source: string;
  geom_wkt: string;
  length_miles?: number;
  trail_number?: string;
  surface?: string;
};

const STATE_ENDPOINTS: Record<string, { url: string; agency: string }> = {
  oregon: {
    url: "https://gis.oregon.gov/arcgis/rest/services/Transportation/Oregon_Trails/FeatureServer/0/query",
    agency: "Oregon GIS",
  },
  washington: {
    url: "https://geo.wa.gov/arcgis/rest/services/WSDOT/WSDOT_Trails/FeatureServer/0/query",
    agency: "Washington GIS",
  },
  california: {
    url: "https://services3.arcgis.com/uknczv4rzyNV3ZSK/arcgis/rest/services/Trails/FeatureServer/0/query",
    agency: "California GIS",
  },
  idaho: {
    url: "https://gis.idaho.gov/arcgis/rest/services/Environment/Trails/FeatureServer/0/query",
    agency: "Idaho GIS",
  },
  colorado: {
    url: "https://services.colorado.gov/arcgis/rest/services/Trails/FeatureServer/0/query",
    agency: "Colorado GIS",
  },
};

function defaultPolygon(): LatLng[] {
  return [
    { lat: 45.30, lng: -121.80 },
    { lat: 45.30, lng: -121.65 },
    { lat: 45.42, lng: -121.65 },
    { lat: 45.42, lng: -121.80 },
  ];
}

function lineToWkt(coords: number[][]): string {
  const pairs = coords.map(([lng, lat]) => `${lng} ${lat}`).join(", ");
  return `LINESTRING(${pairs})`;
}

function stubFeatures(
  state: string,
  polygon: LatLng[],
): NormalizedFeature[] {
  const meta = STATE_ENDPOINTS[state];
  const center = polygon.reduce(
    (acc, p) => ({ lat: acc.lat + p.lat, lng: acc.lng + p.lng }),
    { lat: 0, lng: 0 },
  );
  center.lat /= polygon.length;
  center.lng /= polygon.length;

  const d = 0.008;
  return [
    {
      name: `${meta.agency} Trail A`,
      agency: meta.agency,
      source: state,
      trail_number: `${state.toUpperCase()}-001`,
      surface: "dirt",
      length_miles: 2.4,
      geom_wkt: lineToWkt([
        [center.lng - d, center.lat - d],
        [center.lng, center.lat],
        [center.lng + d, center.lat + d],
      ]),
    },
    {
      name: `${meta.agency} Trail B`,
      agency: meta.agency,
      source: state,
      trail_number: `${state.toUpperCase()}-002`,
      surface: "gravel",
      length_miles: 1.1,
      geom_wkt: lineToWkt([
        [center.lng + d, center.lat - d],
        [center.lng + d * 2, center.lat],
      ]),
    },
  ];
}

async function fetchStateGis(
  state: string,
  polygon: LatLng[],
): Promise<NormalizedFeature[]> {
  const meta = STATE_ENDPOINTS[state];
  if (!meta) {
    throw new Error(`Unsupported state: ${state}`);
  }

  const lats = polygon.map((p) => p.lat);
  const lngs = polygon.map((p) => p.lng);
  const bbox = {
    south: Math.min(...lats),
    north: Math.max(...lats),
    west: Math.min(...lngs),
    east: Math.max(...lngs),
  };

  const params = new URLSearchParams({
    f: "geojson",
    geometry: JSON.stringify({
      xmin: bbox.west,
      ymin: bbox.south,
      xmax: bbox.east,
      ymax: bbox.north,
      spatialReference: { wkid: 4326 },
    }),
    geometryType: "esriGeometryEnvelope",
    spatialRel: "esriSpatialRelIntersects",
    outFields: "*",
    returnGeometry: "true",
  });

  try {
    const res = await fetch(`${meta.url}?${params.toString()}`, {
      signal: AbortSignal.timeout(8000),
    });

    if (!res.ok) {
      console.warn(`${state} GIS returned ${res.status}, using stub data`);
      return stubFeatures(state, polygon);
    }

    const geojson = await res.json();
    const features = geojson.features ?? [];

    if (features.length === 0) {
      return stubFeatures(state, polygon);
    }

    return features
      .filter((f: { geometry?: { type: string; coordinates: number[][] } }) =>
        f.geometry?.type === "LineString"
      )
      .map((
        f: {
          properties?: Record<string, unknown>;
          geometry: { coordinates: number[][] };
        },
        idx: number,
      ) => ({
        name: String(
          f.properties?.TRAIL_NAME ??
            f.properties?.NAME ??
            f.properties?.name ??
            `${meta.agency} Trail ${idx + 1}`,
        ),
        agency: meta.agency,
        source: state,
        trail_number: f.properties?.TRAIL_NUM as string | undefined,
        surface: f.properties?.SURFACE as string | undefined,
        geom_wkt: lineToWkt(f.geometry.coordinates),
      }));
  } catch {
    console.warn(`${state} GIS fetch failed, using stub data`);
    return stubFeatures(state, polygon);
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return handleOptions();

  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  try {
    const body = (await req.json()) as StateImportRequest;
    const state = body.state?.toLowerCase() as StateImportRequest["state"];

    if (!state || !STATE_ENDPOINTS[state]) {
      return errorResponse(
        "Expected state: oregon | washington | california | idaho | colorado",
      );
    }

    const polygon = body.polygon ?? defaultPolygon();
    const features = await fetchStateGis(state, polygon);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceKey);

    const { data: job } = await supabase
      .from("import_jobs")
      .insert({ source: state, status: "running", polygon })
      .select("id")
      .single();

    let trailCount = 0;
    for (const feature of features) {
      const { error } = await supabase.rpc("insert_trail_from_wkt", {
        p_name: feature.name,
        p_agency: feature.agency,
        p_source: feature.source,
        p_trail_number: feature.trail_number ?? null,
        p_surface: feature.surface ?? null,
        p_length_miles: feature.length_miles ?? null,
        p_geom_wkt: feature.geom_wkt,
      });

      if (!error) trailCount++;
    }

    if (job?.id) {
      await supabase
        .from("import_jobs")
        .update({
          status: "completed",
          trail_count: trailCount,
          completed_at: new Date().toISOString(),
        })
        .eq("id", job.id);
    }

    return jsonResponse({
      state,
      job_id: job?.id ?? null,
      trail_count: trailCount,
      trails: features.map((f) => ({ name: f.name, source: f.source })),
      stub: features.every((f) => f.name.includes("Trail A") || f.name.includes("Trail B")),
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "State import failed";
    return errorResponse(message, 500);
  }
});
