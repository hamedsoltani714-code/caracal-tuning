import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ success: false, error: "Method not allowed" }, 405);

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !anonKey || !serviceKey) throw new Error("Supabase environment variables are missing.");

    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) return json({ success: false, error: "Unauthorized" }, 401);

    const authClient = createClient(supabaseUrl, anonKey);
    const { data: authData, error: authError } = await authClient.auth.getUser(authHeader.slice(7));
    if (authError || !authData.user) return json({ success: false, error: "Invalid session" }, 401);

    if (authData.user.email?.toLowerCase() !== "hamed.soltani714@gmail.com") {
      return json({ success: false, error: "Only the verified owner can delete administrators." }, 403);
    }

    const adminClient = createClient(supabaseUrl, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: ownerProfile, error: ownerError } = await adminClient
      .from("profiles").select("role").eq("id", authData.user.id).maybeSingle();
    if (ownerError || ownerProfile?.role !== "owner") {
      return json({ success: false, error: "Owner role verification failed." }, 403);
    }

    const body = await req.json();
    const targetId = String(body.user_id || "").trim();
    if (!targetId || targetId === authData.user.id) {
      return json({ success: false, error: "Invalid administrator account." }, 400);
    }

    const { data: target, error: targetError } = await adminClient
      .from("profiles").select("id,role,email").eq("id", targetId).maybeSingle();
    if (targetError) throw targetError;
    if (!target || target.role !== "admin") {
      return json({ success: false, error: "Administrator account was not found." }, 404);
    }

    const { error: deleteError } = await adminClient.auth.admin.deleteUser(targetId);
    if (deleteError) throw deleteError;

    return json({ success: true, message: "Administrator deleted.", email: target.email });
  } catch (error) {
    console.error("delete-admin error:", error);
    return json({
      success: false,
      error: error instanceof Error ? error.message : "Unexpected server error.",
    }, 500);
  }
});
