import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  errorResponse,
  handleOptions,
  jsonResponse,
} from "../_shared/cors.ts";

type DuplicateRequest = {
  issue_id?: string;
  lat?: number;
  lng?: number;
  title?: string;
  type?: string;
  radius_meters?: number;
  limit?: number;
};

type DuplicateCandidate = {
  issue_id: string;
  issue_number: number;
  title: string;
  type: string;
  status: string;
  distance_meters: number;
  title_similarity: number;
  combined_score: number;
};

function titleSimilarity(a: string, b: string): number {
  const wordsA = new Set(a.toLowerCase().split(/\W+/).filter(Boolean));
  const wordsB = new Set(b.toLowerCase().split(/\W+/).filter(Boolean));
  if (wordsA.size === 0 || wordsB.size === 0) return 0;

  let overlap = 0;
  for (const w of wordsA) {
    if (wordsB.has(w)) overlap++;
  }

  return overlap / Math.max(wordsA.size, wordsB.size);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return handleOptions();

  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  try {
    const body = (await req.json()) as DuplicateRequest;
    const radius = body.radius_meters ?? 200;
    const limit = Math.min(body.limit ?? 5, 20);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceKey);

    let lat = body.lat;
    let lng = body.lng;
    let title = body.title ?? "";
    let type = body.type;
    let excludeId = body.issue_id;

    if (body.issue_id) {
      const { data: issue, error: issueError } = await supabase
        .from("issues")
        .select("id, title, type")
        .eq("id", body.issue_id)
        .single();

      if (issueError || !issue) {
        return errorResponse("Issue not found", 404);
      }

      title = issue.title;
      type = issue.type;
      excludeId = issue.id;

      const { data: locationRows } = await supabase.rpc("issue_location", {
        p_issue_id: body.issue_id,
      });

      const location = Array.isArray(locationRows) ? locationRows[0] : locationRows;
      if (location?.lat !== undefined && location?.lng !== undefined) {
        lat = location.lat;
        lng = location.lng;
      }
    }

    if (lat === undefined || lng === undefined) {
      return errorResponse("Provide issue_id or lat/lng");
    }

    const { data: nearby, error: nearbyError } = await supabase.rpc(
      "find_nearby_issues",
      {
        p_lat: lat,
        p_lng: lng,
        p_radius_m: radius,
        p_exclude_id: excludeId ?? null,
        p_limit: limit * 3,
      },
    );

    if (nearbyError) {
      const { data: fallback } = await supabase
        .from("issues")
        .select("id, issue_number, title, type, status, trail_id")
        .neq("status", "closed")
        .limit(50);

      const candidates: DuplicateCandidate[] = (fallback ?? [])
        .filter((i) => i.id !== excludeId)
        .map((i) => {
          const sim = titleSimilarity(title, i.title);
          const typeBoost = type && i.type === type ? 0.2 : 0;
          return {
            issue_id: i.id,
            issue_number: i.issue_number,
            title: i.title,
            type: i.type,
            status: i.status,
            distance_meters: 9999,
            title_similarity: sim,
            combined_score: Math.min(1, sim + typeBoost),
          };
        })
        .filter((c) => c.combined_score >= 0.3)
        .sort((a, b) => b.combined_score - a.combined_score)
        .slice(0, limit);

      return jsonResponse({
        duplicates: candidates,
        method: "fallback_title_match",
        radius_meters: radius,
      });
    }

    const candidates: DuplicateCandidate[] = (nearby ?? []).map(
      (row: {
        id: string;
        issue_number: number;
        title: string;
        type: string;
        status: string;
        distance_m: number;
      }) => {
        const sim = titleSimilarity(title, row.title);
        const typeBoost = type && row.type === type ? 0.25 : 0;
        const distScore = Math.max(0, 1 - row.distance_m / radius);
        const combined = distScore * 0.6 + sim * 0.25 + typeBoost;

        return {
          issue_id: row.id,
          issue_number: row.issue_number,
          title: row.title,
          type: row.type,
          status: row.status,
          distance_meters: Math.round(row.distance_m),
          title_similarity: Math.round(sim * 100) / 100,
          combined_score: Math.round(combined * 100) / 100,
        };
      },
    )
      .filter((c: DuplicateCandidate) => c.combined_score >= 0.35)
      .sort((a: DuplicateCandidate, b: DuplicateCandidate) =>
        b.combined_score - a.combined_score
      )
      .slice(0, limit);

    return jsonResponse({
      duplicates: candidates,
      method: "proximity_and_title",
      radius_meters: radius,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Duplicate search failed";
    return errorResponse(message, 500);
  }
});
