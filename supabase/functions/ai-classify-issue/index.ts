import {
  errorResponse,
  handleOptions,
  jsonResponse,
} from "../_shared/cors.ts";

type ClassifyRequest = {
  description?: string;
  labels?: string[];
  title?: string;
};

type Classification = {
  type: string;
  priority: string;
  estimated_crew_size: number;
  estimated_hours: number;
  estimated_duration_label: string;
  required_tools: string[];
  required_certifications: string[];
  safety_concerns: string | null;
  confidence: number;
};

const KEYWORD_RULES: Array<{
  patterns: RegExp[];
  type: string;
  priority: string;
  crew: number;
  hours: number;
  tools: string[];
  certs: string[];
  safety: string | null;
}> = [
  {
    patterns: [/fallen?\s*tree/i, /blow\s*down/i, /wind\s*throw/i, /log\s*across/i],
    type: "blowdown",
    priority: "high",
    crew: 2,
    hours: 3,
    tools: ["Crosscut saw", "Loppers", "Wedges"],
    certs: ["USFS Crosscut A"],
    safety: "Check for hung branches before cutting.",
  },
  {
    patterns: [/erosion/i, /tread\s*loss/i, /outslope/i, /rut/i],
    type: "erosion",
    priority: "medium",
    crew: 4,
    hours: 6,
    tools: ["McLeod", "Pulaski", "Shovel"],
    certs: [],
    safety: null,
  },
  {
    patterns: [/wash\s*out/i, /washout/i, /culvert/i, /flooded/i],
    type: "washout",
    priority: "high",
    crew: 4,
    hours: 8,
    tools: ["Shovel", "Rock bar", "Drainage tools"],
    certs: [],
    safety: "Unstable tread edges possible.",
  },
  {
    patterns: [/bridge.*plank/i, /missing.*plank/i, /deck\s*board/i],
    type: "missing_bridge_plank",
    priority: "critical",
    crew: 3,
    hours: 4,
    tools: ["Drill", "Lag bolts", "Replacement plank"],
    certs: [],
    safety: "Do not cross until repaired.",
  },
  {
    patterns: [/bridge.*damage/i, /broken.*bridge/i, /handrail/i],
    type: "bridge_damage",
    priority: "high",
    crew: 3,
    hours: 5,
    tools: ["Drill", "Hammer", "Lumber"],
    certs: [],
    safety: "Inspect structural members before use.",
  },
  {
    patterns: [/missing.*sign/i, /blank.*sign/i, /sign\s*post.*empty/i],
    type: "missing_sign",
    priority: "low",
    crew: 1,
    hours: 1,
    tools: ["Drill", "Screws", "Sign blank"],
    certs: [],
    safety: null,
  },
  {
    patterns: [/broken.*sign/i, /bent.*sign/i, /damaged.*kiosk/i],
    type: "broken_sign",
    priority: "low",
    crew: 2,
    hours: 2,
    tools: ["Drill", "Post level", "Concrete mix"],
    certs: [],
    safety: null,
  },
  {
    patterns: [/brush/i, /overgrowth/i, /bramble/i, /encroach/i],
    type: "brush_overgrowth",
    priority: "medium",
    crew: 3,
    hours: 4,
    tools: ["Loppers", "Hand saw", "McLeod"],
    certs: [],
    safety: null,
  },
  {
    patterns: [/drainage/i, /blocked.*ditch/i, /waterbar/i, /clogged/i],
    type: "drainage_blocked",
    priority: "medium",
    crew: 3,
    hours: 3,
    tools: ["McLeod", "Shovel", "Rock bar"],
    certs: [],
    safety: null,
  },
  {
    patterns: [/rock\s*slide/i, /talus/i, /boulder/i, /landslide/i],
    type: "rock_slide",
    priority: "high",
    crew: 4,
    hours: 6,
    tools: ["Rock bar", "Pry bar", "Shovel"],
    certs: [],
    safety: "Loose rock hazard; wear helmets.",
  },
  {
    patterns: [/collapse/i, /slump/i, /failed.*slope/i],
    type: "trail_collapse",
    priority: "critical",
    crew: 5,
    hours: 8,
    tools: ["McLeod", "Pulaski", "Shovel", "Rock bar"],
    certs: [],
    safety: "Keep crew off unstable tread.",
  },
  {
    patterns: [/hazard.*tree/i, /dead.*tree/i, /snag/i, /leaner/i],
    type: "hazard_tree",
    priority: "critical",
    crew: 2,
    hours: 2,
    tools: ["Crosscut saw", "Wedges"],
    certs: ["USFS Crosscut A", "Chainsaw cert (if applicable)"],
    safety: "Feller must assess lean and bind.",
  },
  {
    patterns: [/vandal/i, /graffiti/i, /spray\s*paint/i],
    type: "vandalism",
    priority: "medium",
    crew: 2,
    hours: 2,
    tools: ["Graffiti remover", "Wire brush", "Paint"],
    certs: [],
    safety: null,
  },
  {
    patterns: [/campsite/i, /fire\s*ring/i, /illegal.*camp/i],
    type: "campsite_damage",
    priority: "medium",
    crew: 3,
    hours: 3,
    tools: ["McLeod", "Trash bags", "Hand tools"],
    certs: [],
    safety: null,
  },
  {
    patterns: [/illegal.*trail/i, /social\s*trail/i, /user.*created/i],
    type: "illegal_trail",
    priority: "high",
    crew: 4,
    hours: 5,
    tools: ["Loppers", "Hand saw", "Signage"],
    certs: [],
    safety: null,
  },
];

function durationLabel(hours: number): string {
  const low = Math.max(1, Math.floor(hours));
  const high = low + 2;
  return `${low}–${high} hrs`;
}

function classifyText(text: string): Classification {
  const normalized = text.toLowerCase();

  for (const rule of KEYWORD_RULES) {
    if (rule.patterns.some((p) => p.test(normalized))) {
      return {
        type: rule.type,
        priority: rule.priority,
        estimated_crew_size: rule.crew,
        estimated_hours: rule.hours,
        estimated_duration_label: durationLabel(rule.hours),
        required_tools: rule.tools,
        required_certifications: rule.certs,
        safety_concerns: rule.safety,
        confidence: 0.82,
      };
    }
  }

  return {
    type: "other",
    priority: "medium",
    estimated_crew_size: 2,
    estimated_hours: 3,
    estimated_duration_label: "2–4 hrs",
    required_tools: ["Hand tools"],
    required_certifications: [],
    safety_concerns: null,
    confidence: 0.45,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return handleOptions();

  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  try {
    const body = (await req.json()) as ClassifyRequest;
    const parts = [
      body.title ?? "",
      body.description ?? "",
      ...(body.labels ?? []),
    ].filter(Boolean);

    if (parts.length === 0) {
      return errorResponse("Provide description, labels, or title");
    }

    const result = classifyText(parts.join(" "));
    return jsonResponse({ classification: result, method: "keyword_heuristic" });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Classification failed";
    return errorResponse(message, 500);
  }
});
