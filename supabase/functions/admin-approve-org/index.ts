import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  errorResponse,
  handleOptions,
  jsonResponse,
} from "../_shared/cors.ts";

type ApproveRequest = {
  organization_id: string;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return handleOptions();

  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return errorResponse("Authorization required", 401);
    }

    const body = (await req.json()) as ApproveRequest;
    if (!body.organization_id) {
      return errorResponse("organization_id is required");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return errorResponse("Invalid auth token", 401);
    }

    const adminClient = createClient(supabaseUrl, serviceKey);

    const { data: roles } = await adminClient
      .from("user_roles")
      .select("role")
      .eq("user_id", user.id);

    const isAdmin = (roles ?? []).some((r) =>
      r.role === "administrator" || r.role === "land_manager"
    );

    if (!isAdmin) {
      return errorResponse("Administrator or land manager role required", 403);
    }

    const { data: org, error: updateError } = await adminClient
      .from("organizations")
      .update({ approved: true, updated_at: new Date().toISOString() })
      .eq("id", body.organization_id)
      .select("id, name, approved")
      .single();

    if (updateError) {
      return errorResponse(updateError.message, 500);
    }

    if (!org) {
      return errorResponse("Organization not found", 404);
    }

    return jsonResponse({
      organization: org,
      approved_by: user.id,
      approved_at: new Date().toISOString(),
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Approval failed";
    return errorResponse(message, 500);
  }
});
