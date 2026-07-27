import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  errorResponse,
  handleOptions,
  jsonResponse,
} from "../_shared/cors.ts";

type PlanRequest = {
  crew_id?: string;
  trail_id?: string;
  issue_ids?: string[];
  available_hours?: number;
  crew_size?: number;
  date?: string;
};

type PlannedIssue = {
  issue_id: string;
  issue_number: number;
  title: string;
  type: string;
  priority: string;
  estimated_hours: number;
  estimated_crew_size: number;
  trail_name: string | null;
  rationale: string;
};

type WorkdayPlan = {
  date: string;
  crew_size: number;
  available_hours: number;
  planned_hours: number;
  issues: PlannedIssue[];
  tools_needed: string[];
  certifications_needed: string[];
  notes: string[];
};

const PRIORITY_ORDER: Record<string, number> = {
  critical: 0,
  high: 1,
  medium: 2,
  low: 3,
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return handleOptions();

  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  try {
    const body = (await req.json()) as PlanRequest;
    const availableHours = body.available_hours ?? 6;
    const crewSize = body.crew_size ?? 4;
    const planDate = body.date ?? new Date().toISOString().slice(0, 10);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceKey);

    let query = supabase
      .from("issues")
      .select(`
        id, issue_number, title, type, priority, status,
        estimated_hours, estimated_crew_size, trail_id,
        trails ( name )
      `)
      .in("status", ["open", "assigned", "scheduled"])
      .order("priority", { ascending: true });

    if (body.issue_ids?.length) {
      query = query.in("id", body.issue_ids);
    } else if (body.trail_id) {
      query = query.eq("trail_id", body.trail_id);
    } else if (body.crew_id) {
      query = query.or(`crew_id.eq.${body.crew_id},crew_id.is.null`);
    }

    const { data: issues, error } = await query.limit(30);

    if (error) {
      return errorResponse(error.message, 500);
    }

    const sorted = (issues ?? []).sort((a, b) => {
      const pa = PRIORITY_ORDER[a.priority] ?? 9;
      const pb = PRIORITY_ORDER[b.priority] ?? 9;
      if (pa !== pb) return pa - pb;
      return (a.estimated_hours ?? 3) - (b.estimated_hours ?? 3);
    });

    const planned: PlannedIssue[] = [];
    let hoursUsed = 0;
    const tools = new Set<string>();
    const certs = new Set<string>();

    for (const issue of sorted) {
      const estHours = issue.estimated_hours ?? 3;
      const estCrew = issue.estimated_crew_size ?? 2;

      if (hoursUsed + estHours > availableHours) continue;
      if (estCrew > crewSize) continue;

      planned.push({
        issue_id: issue.id,
        issue_number: issue.issue_number,
        title: issue.title,
        type: issue.type,
        priority: issue.priority,
        estimated_hours: estHours,
        estimated_crew_size: estCrew,
        trail_name: issue.trails?.name ?? null,
        rationale: `${issue.priority} priority ${issue.type} — fits remaining ${availableHours - hoursUsed}h`,
      });

      hoursUsed += estHours;

      const { data: issueTools } = await supabase
        .from("issue_tools")
        .select("tool")
        .eq("issue_id", issue.id);
      for (const t of issueTools ?? []) tools.add(t.tool);

      const { data: issueCerts } = await supabase
        .from("issue_certifications")
        .select("certification")
        .eq("issue_id", issue.id);
      for (const c of issueCerts ?? []) certs.add(c.certification);
    }

    const plan: WorkdayPlan = {
      date: planDate,
      crew_size: crewSize,
      available_hours: availableHours,
      planned_hours: hoursUsed,
      issues: planned,
      tools_needed: [...tools],
      certifications_needed: [...certs],
      notes: planned.length === 0
        ? ["No issues fit the available time and crew size. Try increasing hours or crew."]
        : [
          `Prioritized ${planned.length} issue(s) by severity and duration.`,
          "Verify tool cache and PPE before dispatch.",
        ],
    };

    return jsonResponse({ plan, method: "greedy_priority_scheduler" });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Planning failed";
    return errorResponse(message, 500);
  }
});
